const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
// gemini-2.5-flash: best free-tier model (fast, high limits, stable as of 2026)
const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ── Mermaid sanitizer ────────────────────────────────────────────────────────
// Fixes the most common Gemini Mermaid mistakes before storing in DB.
function sanitizeMermaid(raw) {
  if (!raw || typeof raw !== 'string') return '';

  let d = raw.trim();

  // Remove markdown code fence wrappers
  d = d.replace(/^```(?:mermaid)?\s*/i, '').replace(/\s*```$/i, '').trim();

  // Ensure starts with a valid graph directive
  if (!d.match(/^graph\s+(TD|LR|TB|BT|RL)/i)) {
    d = 'graph TD\n' + d;
  }

  // Fix old-style single arrow: -> becomes -->
  d = d.replace(/(?<!-)->(?!>)/g, '-->');

  // Fix double parens ((circle)) → ["label"]
  d = d.replace(/\(\(([^)]+)\)\)/g, '["$1"]');

  // Fix node definitions like: NodeId(Label Text) → NodeId["Label Text"]
  // Only at start of a line (node declaration, not mid-arrow)
  d = d.replace(/^([ \t]*)(\w+)\(([^)]+)\)\s*$/gm, (_, indent, id, label) => {
    return `${indent}${id}["${label.trim().replace(/"/g, "'")}"}`;
  });

  // Collapse excessive blank lines
  d = d.replace(/\n{3,}/g, '\n\n');

  return d.trim();
}

function buildPrompt(repoContext) {
  const { fullName, description, primaryLanguage, languages, fileTree, keyFilesContent, techStack, topics } = repoContext;

  const langSummary = Object.entries(languages)
    .map(([lang, bytes]) => `${lang}: ${bytes} bytes`)
    .join(', ');

  const treeSample = fileTree.slice(0, 60).join('\n');

  return `You are a senior software architect reviewing a GitHub repository for a professional portfolio showcase.

Analyze the following repository and return ONLY a valid JSON object with exactly two fields:
1. "summary": A rich, 3-paragraph technical case study written in an engaging, professional tone.
   Paragraph 1: What the project does and why it matters.
   Paragraph 2: The core technical architecture and the hardest engineering problems solved.
   Paragraph 3: Key implementation highlights and what makes this project stand out.

2. "mermaid": A valid Mermaid.js diagram using "graph TD" format. STRICT RULES you MUST follow:
   - Start with exactly: graph TD
   - Maximum 8 nodes total.
   - Node IDs must be a single word (no spaces), e.g.: UserApp, APIServer, Database
   - Node labels MUST use double-quoted square brackets: NodeId["Label Text Here"]
   - NEVER use parentheses () in labels or node IDs — this causes parse errors.
   - Use --> for arrows. Optionally add label: NodeA -->|"action"| NodeB
   - Do NOT use subgraph.
   - Example of valid syntax:
     graph TD
       User["User / Browser"]
       Frontend["Flutter Web App"]
       Backend["Node.js API"]
       DB["MongoDB Atlas"]
       AI["Gemini AI"]
       User -->|"opens"| Frontend
       Frontend -->|"REST calls"| Backend
       Backend -->|"reads/writes"| DB
       Backend -->|"analyze repo"| AI

Repository information:
- Name: ${fullName}
- Description: ${description || 'No description provided'}
- Primary Language: ${primaryLanguage}
- Language breakdown: ${langSummary || 'N/A'}
- Tech stack tags: ${techStack.join(', ') || 'N/A'}
- Topics: ${topics.join(', ') || 'none'}
- File tree sample (first 60 files):
${treeSample}

Key files content:
${keyFilesContent || 'Not available'}

CRITICAL: Return ONLY the raw JSON object. No markdown fences, no \`\`\`json, no explanation text before or after. Just the JSON.`;
}

/**
 * Generate AI analysis.
 * Retries up to 4 times with exponential backoff.
 * 429 rate-limit errors are detected and given a longer initial wait.
 */
async function generateProjectAnalysis(repoContext) {
  const prompt = buildPrompt(repoContext);
  const MAX_ATTEMPTS = 4;

  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    try {
      console.log(`🤖 Gemini attempt ${attempt}/${MAX_ATTEMPTS} for ${repoContext.fullName}...`);
      const result = await model.generateContent(prompt);
      const text = result.response.text().trim();
      console.log(`📝 Raw Gemini response (first 200 chars): ${text.slice(0, 200)}`);

      // Strip markdown fences if the model wraps it anyway
      const cleaned = text
        .replace(/^```(?:json)?\s*/i, '')
        .replace(/\s*```$/i, '')
        .trim();

      const parsed = JSON.parse(cleaned);

      if (!parsed.summary || !parsed.mermaid) {
        throw new Error(`Gemini response missing fields. Got keys: ${Object.keys(parsed).join(', ')}`);
      }

      // Post-process mermaid to fix common syntax issues
      const safeMermaid = sanitizeMermaid(parsed.mermaid);
      console.log(`✅ Gemini analysis complete for ${repoContext.fullName}`);
      return { summary: parsed.summary, mermaid: safeMermaid };
    } catch (err) {
      const isRateLimit = err.message?.includes('429') || err.status === 429;
      console.error(`❌ Gemini attempt ${attempt} failed for ${repoContext.fullName}:`, err.message);

      if (attempt === MAX_ATTEMPTS) {
        throw new Error(`Gemini analysis failed after ${MAX_ATTEMPTS} attempts: ${err.message}`);
      }

      // Exponential backoff: 2s, 4s, 8s. Rate limits get 10s base.
      const baseDelay = isRateLimit ? 10000 : 2000;
      const delay = baseDelay * Math.pow(2, attempt - 1);
      console.log(`⏳ Waiting ${delay / 1000}s before retry...`);
      await sleep(delay);
    }
  }
}

/**
 * Generate a professional GitHub README for a project.
 */
async function generateReadme(ctx) {
  const langList = Object.keys(ctx.languages || {}).join(', ') || ctx.primaryLanguage;
  const prompt = `You are a senior developer writing a professional GitHub README.

Generate a complete, beautiful, well-structured GitHub README.md for the following project.

Project details:
- Name: ${ctx.fullName}
- Description: ${ctx.description || 'A software project'}
- Primary Language: ${ctx.primaryLanguage}
- Languages: ${langList}
- Tech Stack: ${(ctx.techStack || []).join(', ') || 'N/A'}
- Topics: ${(ctx.topics || []).join(', ') || 'none'}
- Live URL: ${ctx.liveUrl || 'N/A'}
- AI Summary: ${ctx.aiSummary ? ctx.aiSummary.slice(0, 600) : 'Not available'}

Requirements:
1. Start with a centered project title and a one-line description
2. Include shields.io badges for the primary language and tech stack
3. Include sections: Features, Tech Stack, Getting Started (with install steps), Usage, Contributing, License
4. Use emojis tastefully for section headers
5. Include a "Live Demo" section if liveUrl is provided
6. Make it impressive and professional — this is a portfolio showcase
7. Return ONLY the raw markdown, no explanation before or after

Return only the README markdown content.`;

  const result = await model.generateContent(prompt);
  return result.response.text().trim();
}

module.exports = { generateProjectAnalysis, generateReadme };
