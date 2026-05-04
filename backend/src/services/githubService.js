const axios = require('axios');

const GITHUB_API = 'https://api.github.com';
const PAT = process.env.GITHUB_PAT;

const headers = () => ({
  Authorization: `Bearer ${PAT}`,
  Accept: 'application/vnd.github+json',
  'X-GitHub-Api-Version': '2022-11-28',
});

const TIMEOUT = 10000; // 10s

/**
 * Parse a GitHub URL and return { owner, repo } or throw.
 */
function validateGitHubUrl(url) {
  try {
    const parsed = new URL(url.trim());
    if (parsed.hostname !== 'github.com') throw new Error('Not a GitHub URL');
    const parts = parsed.pathname.replace(/^\//, '').replace(/\/$/, '').split('/');
    if (parts.length < 2 || !parts[0] || !parts[1]) throw new Error('Invalid path');
    return { owner: parts[0], repo: parts[1] };
  } catch {
    throw new Error('Invalid GitHub URL. Expected: https://github.com/owner/repo');
  }
}

/**
 * Fetch basic repo metadata (name, description, stars, forks, language, topics).
 */
async function fetchRepoMetadata(owner, repo) {
  try {
    const { data } = await axios.get(`${GITHUB_API}/repos/${owner}/${repo}`, {
      headers: headers(),
      timeout: TIMEOUT,
    });
    return {
      description: data.description || '',
      stars: data.stargazers_count || 0,
      forks: data.forks_count || 0,
      primaryLanguage: data.language || 'Unknown',
      topics: data.topics || [],
      defaultBranch: data.default_branch || 'main',
      isPrivate: data.private || false,
    };
  } catch (err) {
    if (err.response?.status === 404) throw new Error('Repository not found. Is it public?');
    if (err.response?.status === 403) throw new Error('Repository is private or API rate limit hit.');
    throw new Error(`GitHub API error: ${err.message}`);
  }
}

/**
 * Fetch language breakdown (bytes per language).
 */
async function fetchLanguages(owner, repo) {
  const { data } = await axios.get(`${GITHUB_API}/repos/${owner}/${repo}/languages`, {
    headers: headers(),
    timeout: TIMEOUT,
  });
  return data; // e.g. { "JavaScript": 12345, "CSS": 3000 }
}

/**
 * Fetch the full file tree in one API call using the Trees API.
 * Returns an array of file paths (blobs only), capped at 500.
 */
async function fetchFileTree(owner, repo, defaultBranch = 'main') {
  try {
    const { data } = await axios.get(
      `${GITHUB_API}/repos/${owner}/${repo}/git/trees/${defaultBranch}?recursive=1`,
      { headers: headers(), timeout: TIMEOUT }
    );
    const files = (data.tree || [])
      .filter((item) => item.type === 'blob')
      .map((item) => item.path)
      .slice(0, 500);
    return files;
  } catch {
    return []; // non-fatal — we'll still proceed without the file tree
  }
}

/**
 * Fetch the raw content of a single file, decoded from base64.
 * Returns null if the file doesn't exist.
 */
async function fetchFileContent(owner, repo, filePath) {
  try {
    const { data } = await axios.get(
      `${GITHUB_API}/repos/${owner}/${repo}/contents/${filePath}`,
      { headers: headers(), timeout: TIMEOUT }
    );
    if (data.encoding === 'base64') {
      return Buffer.from(data.content, 'base64').toString('utf8');
    }
    return data.content || '';
  } catch {
    return null;
  }
}

/**
 * Infer tech stack tags from language, topics, and file tree.
 */
function inferTechStack(languages, fileTree, topics) {
  const stack = new Set();
  const allText = [...fileTree, ...topics].join(' ').toLowerCase();
  const langKeys = Object.keys(languages).map((l) => l.toLowerCase());

  if (allText.includes('package.json') && (allText.includes('react') || allText.includes('next'))) stack.add('React');
  if (allText.includes('pubspec.yaml') || langKeys.includes('dart')) stack.add('Flutter');
  if (langKeys.includes('python') && (allText.includes('requirements') || allText.includes('torch') || allText.includes('tensorflow') || allText.includes('ml'))) stack.add('AI/ML');
  if (allText.includes('web3') || allText.includes('solidity') || allText.includes('hardhat')) stack.add('Web3');
  if (allText.includes('express') || allText.includes('node')) stack.add('Node.js');
  if (allText.includes('mongo') || allText.includes('mongoose')) stack.add('MongoDB');
  if ((stack.has('React') || stack.has('Node.js')) && stack.has('MongoDB')) stack.add('MERN');
  if (langKeys.includes('go')) stack.add('Go');
  if (langKeys.includes('rust')) stack.add('Rust');
  if (langKeys.includes('typescript')) stack.add('TypeScript');
  if (langKeys.includes('javascript') && !stack.has('React')) stack.add('JavaScript');

  return [...stack];
}

/**
 * Fetch key config files (README, package.json, requirements.txt, etc.)
 * to give the AI context about the project.
 */
async function fetchKeyFiles(owner, repo, fileTree) {
  const candidates = [
    'README.md', 'readme.md', 'README.MD',
    'package.json',
    'requirements.txt',
    'pubspec.yaml',
    'Cargo.toml',
    'go.mod',
    'pyproject.toml',
  ];

  const toFetch = candidates.filter((c) => fileTree.includes(c)).slice(0, 3);

  const results = await Promise.all(
    toFetch.map(async (file) => {
      const content = await fetchFileContent(owner, repo, file);
      return content ? `### ${file}\n${content.slice(0, 1500)}` : null;
    })
  );

  return results.filter(Boolean).join('\n\n').slice(0, 4000);
}

/**
 * Master function — runs all fetches in parallel and assembles the full repo context.
 */
async function extractAllRepoData(owner, repo) {
  const metadata = await fetchRepoMetadata(owner, repo);

  if (metadata.isPrivate) {
    throw new Error('This repository is private. Please use a public repository.');
  }

  const [languages, fileTree] = await Promise.all([
    fetchLanguages(owner, repo),
    fetchFileTree(owner, repo, metadata.defaultBranch),
  ]);

  const keyFilesContent = await fetchKeyFiles(owner, repo, fileTree);
  const techStack = inferTechStack(languages, fileTree, metadata.topics);

  return {
    owner,
    repo,
    fullName: `${owner}/${repo}`,
    ...metadata,
    languages,
    fileTree,
    keyFilesContent,
    techStack,
  };
}

module.exports = {
  validateGitHubUrl,
  fetchRepoMetadata,
  fetchLanguages,
  fetchFileTree,
  fetchFileContent,
  fetchKeyFiles,
  inferTechStack,
  extractAllRepoData,
};
