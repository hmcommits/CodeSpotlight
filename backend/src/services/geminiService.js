const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * Build the prompt for Gemini, passing repo context as structured text.
 */
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
2. "mermaid": A valid Mermaid.js diagram using "graph TD" format showing the project architecture (components, data flow, key interactions). Keep it concise — max 12 nodes.

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

IMPORTANT: Return ONLY the raw JSON object. No markdown code fences, no explanation, just the JSON.`;
}

/**
 * Generate AI analysis for a repository.
 * Retries once on failure with a 2-second delay.
 * Returns { summary, mermaid } or throws.
 */
async function generateProjectAnalysis(repoContext) {
  const prompt = buildPrompt(repoContext);

  for (let attempt = 1; attempt <= 2; attempt++) {
    try {
      const result = await model.generateContent(prompt);
      const text = result.response.text().trim();

      // Strip markdown fences if the model wraps it anyway
      const cleaned = text.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '').trim();

      const parsed = JSON.parse(cleaned);

      if (!parsed.summary || !parsed.mermaid) {
        throw new Error('Gemini response missing required fields');
      }

      return { summary: parsed.summary, mermaid: parsed.mermaid };
    } catch (err) {
      if (attempt === 2) {
        throw new Error(`Gemini analysis failed after 2 attempts: ${err.message}`);
      }
      console.warn(`Gemini attempt ${attempt} failed, retrying in 2s...`, err.message);
      await sleep(2000);
    }
  }
}

module.exports = { generateProjectAnalysis };
