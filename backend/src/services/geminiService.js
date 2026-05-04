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

  // Ensure starts with graph TD
  if (!d.match(/^graph\s+(TD|LR|TB|BT|RL)/i)) {
    d = 'graph TD\n' + d;
  }

  // Fix old-style single arrow: -> becomes -->
  d = d.replace(/->/g, '-->');

  // Fix: Node --> [Label] NextNode --> merge to Node -->|"Label"| NextNode
  // Pattern: --> [some label] NodeId
  d = d.replace(/-->\s*\[([^\]]+)\]\s+(\w+)/g, (_, label, nodeId) => {
    const cleanLabel = label.trim().replace(/"/g, "'");
    return `-->|"${cleanLabel}"| ${nodeId}`;
  });

  // Fix: NodeId(Label) at start of a line (node definition, not arrow target)
  // Converts: User(Patient / Guardian) → User["Patient / Guardian"]
  // Only if NOT followed immediately by [ (that would be Node(subgraph style) which is different)
  d = d.replace(/^(\s*)(\w+)\(([^)]+)\)(?!\s*-->)/gm, (match, indent, id, label) => {
    const cleanLabel = label.trim().replace(/"/g, "'");
    return `${indent}${id}["${cleanLabel}"]`;
  });

  // Fix: double parens ((circle)) → ["label"]
  d = d.replace(/\(\(([^)]+)\)\)/g, '["$1"]');

  // Fix: curly brace nodes with slashes or parens inside → quote the label
  d = d.replace(/\{([^}]*[/()\s][^}]*)\}/g, (_, inner) => {
    return `{"${inner.replace(/"/g, "'")}"}`;
  });

  // Fix: parentheses INSIDE square bracket labels are fine for Mermaid v11,
  // but some versions choke on them. Replace with spaces.
  // e.g. [Mobile Application (React Native)] → [Mobile Application React Native]
  d = d.replace(/\[([^\]]*)\(([^)]*)\)([^\]]*)\]/g, (_, pre, inner, post) => {
    return `["${pre}${inner}${post}".trim()]`;
  });
  // Simpler cleanup: remove parens inside [] labels
  d = d.replace(/\[([^\]]+)\]/g, (match, inner) => {
    if (inner.startsWith('"') || inner.startsWith("'")) return match; // already quoted
    const cleaned = inner.replace(/[()]/g, '');
    return `["${cleaned.replace(/"/g, "'")}"]`;
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
 * Generate AI analysis. Retries once on failure with 2s delay.
 */
async function generateProjectAnalysis(repoContext) {
  const prompt = buildPrompt(repoContext);

  for (let attempt = 1; attempt <= 2; attempt++) {
    try {
      console.log(`🤖 Gemini attempt ${attempt} for ${repoContext.fullName}...`);
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
      console.error(`❌ Gemini attempt ${attempt} failed for ${repoContext.fullName}:`, err.message);
      if (attempt === 2) {
        throw new Error(`Gemini analysis failed after 2 attempts: ${err.message}`);
      }
      await sleep(2000);
    }
  }
}

module.exports = { generateProjectAnalysis };
