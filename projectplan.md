## 🛑 The Problem: The "GitHub Graveyard"
Developers spend hundreds of hours building complex systems, but those projects often "die" as cold links in a GitHub profile.
1.  **Low Visibility:** Recruiters and collaborators rarely dig into folders to see code quality or architecture.
2.  **Context Loss:** A README often fails to explain the "why" and "how" behind technical decisions.
3.  **Discovery Friction:** Finding high-quality, deployed projects in specific niches (AI, Web3, MERN) across scattered repos is nearly impossible.
4.  **Static Portfolios:** Traditional portfolio sites are manual, tedious to update, and lack verified "Proof-of-Work."

---

## 💡 The Solution: CodeSpotlight (Powered by DevBento)
**CodeSpotlight** is an AI-integrated, Flutter Web showcase directory that automatically audits and visualizes GitHub repositories into a stunning **Bento Box UI.** It acts as a "Trust Layer" between the developer's code and the viewer's eyes.

---

## 🔥 Core Features

### 1. Centralized Showcase
A sleek, searchable gallery where projects are categorized by domain (AI, Web3, MERN, Flutter, etc.).

### 2. Live Deployment Pinger *(MVP)*
Every project card features a live "Heartbeat" status badge. The backend pings the project's deployed URL and shows **Live ✅ / Down ❌** in real time.

### 3. Video-First Discovery *(MVP)*
Project cards support auto-playing video demo loops on hover instead of static screenshots.

### 4. Advanced Discovery Filters *(MVP)*
A Flutter chip-filtering system to sort by tech stack (MERN, AI, Flutter, Web3, etc.).

---

## 🧠 Innovation Features

### Feature 1: AI Technical Architect (Gemini Integration) *(MVP — Pre-computed)*

> **Demo-Safety Strategy:** AI analysis is triggered **once at project submission time** and the result is persisted to the database. The demo never calls the Gemini API live—it serves cached summaries. This guarantees zero AI latency or quota failure during a live demo.

When a user submits a GitHub repo URL, the backend:
1.  **Fetches repo metadata** via the **GitHub REST API** (`/repos/{owner}/{repo}`) — name, description, language breakdown, stars, forks.
2.  **Fetches the file tree** via **GitHub Trees API** (`/repos/{owner}/{repo}/git/trees/HEAD?recursive=1`) — gets the full directory structure in a single API call, no pagination required.
3.  **Fetches key files** via **GitHub Contents API** (`/repos/{owner}/{repo}/contents/{path}`) — specifically `README.md`, `package.json`, `requirements.txt`, `pubspec.yaml` to understand the stack.
4.  **Sends this context** to **Gemini 1.5 Flash** (free tier, 15 RPM / 1M tokens/day) to generate:
    - A "Technical Deep Dive" case study paragraph.
    - A **Mermaid.js architecture diagram** (returned as a raw string, rendered in the browser via the `mermaid` JS library injected into Flutter Web's `index.html`).
5.  **Saves the output** to MongoDB Atlas so future page loads are instant.

### Feature 2: "Talk to the Code" — Contextual AI Chat *(Stretch Goal)*

> **Simplified & Demo-Safe:** Instead of full RAG (which requires vector DBs), the chatbot works by fetching the relevant file content at query time using the GitHub Contents API and injecting it into the Gemini prompt context. This keeps it **stateless, cheap, and reliable** with no embedding infrastructure needed.

Each project card has a chat icon. A recruiter can ask questions like *"What security measures are in this project?"* The backend:
1. Searches the cached file tree for relevant files matching keywords in the query.
2. Fetches those specific files via the GitHub Contents API.
3. Sends the file content + query to Gemini 1.5 Flash.
4. Returns a grounded, code-specific answer.

### Feature 3: "Proof-of-Effort" Visualizer *(MVP)*

> **Demo-Safety Strategy:** GitHub's REST API is used with a **Personal Access Token (PAT)** stored server-side. This raises the rate limit from **60 req/hr (unauthenticated) to 5,000 req/hr**, completely eliminating rate-limit failures during a demo.

Using the **GitHub REST API**, custom Flutter `CustomPainter` widgets display:
- **Commit Heatmap:** Activity intensity over 52 weeks using `/repos/{owner}/{repo}/stats/commit_activity`.
- **Language Constellation:** Interactive visual where language bubble sizes are proportional to bytes of code, using `/repos/{owner}/{repo}/languages`.

---

## 🎨 UI/UX Design Philosophy: "The Bento Vision"

Built with **Flutter Web** (CanvasKit renderer for high-performance animations):

- **Bento Box Layout:** Information organized into clean, rounded, rectangular modules of varying sizes — not a standard grid.
- **Glassmorphism:** Project cards with a blurred, frosted-glass effect and neon borders reflecting the primary language (Yellow for JS, Blue for Flutter, Green for Python).
- **Fluid Motion:** Flutter `Hero` and `AnimatedContainer` so clicking a card physically expands and "grows" into the full technical case study.
- **Dark Mode:** Deep charcoal background with high-contrast typography.
- **Mermaid Diagrams:** Rendered via the `mermaid` JS library injected into Flutter Web's `index.html`, called from Flutter via `js` interop — no native Flutter renderer needed.

---

## 🛠️ Tech Stack

| Layer | Technology | Hosting (Free Tier) |
|-------|-----------|---------------------|
| **Frontend** | Flutter Web (CanvasKit) | **Firebase Hosting** (10 GB/month free, global CDN) |
| **Backend** | Node.js / Express | **Render.com** or **Vercel** (Free tier) |
| **Database** | MongoDB Atlas | **Atlas Free Tier** (512 MB, always-on) |
| **AI** | Gemini 1.5 Flash API | **Google AI Studio** (Free: 15 RPM, 1M tokens/day) |
| **Auth** | GitHub OAuth 2.0 | Via backend (no paid service needed) |
| **File Storage** | None needed | AI outputs stored directly in MongoDB |

---

## ⚙️ GitHub Data Extraction Strategy (Reliability-First)

This is the most critical part of the system. All GitHub calls go through the **backend** (never from Flutter directly) to protect the PAT and enable caching.

```
User submits GitHub URL
        │
        ▼
Backend validates URL format
        │
        ▼
GitHub REST API call (with PAT — 5,000 req/hr limit)
  ├── GET /repos/{owner}/{repo}          → Basic metadata
  ├── GET /repos/{owner}/{repo}/languages → Language breakdown
  ├── GET /repos/{owner}/{repo}/git/trees/HEAD?recursive=1 → Full file tree (1 call)
  └── GET /repos/{owner}/{repo}/contents/README.md → README content
        │
        ▼
Context assembled → Gemini 1.5 Flash API
        │
        ▼
AI output saved to MongoDB (cached forever)
        │
        ▼
Flutter frontend displays from cache — ZERO live API calls at view time
```

**Fallback Handling:**
- If a repo is **private** → Return a clear error to the user immediately.
- If GitHub API is **slow** → A 10-second timeout with a user-friendly error message.
- If Gemini API **fails** → The repo is still saved with metadata only; AI content shows a "Pending Analysis" badge and can be retried.
- All GitHub responses are **cached in MongoDB** — repeat views of the same repo never call GitHub again.

---

## 🚀 Deployment Plan (100% Free)

1.  **Backend → Render.com or Vercel**
    - **Render.com:** Deploy as a Node.js web service. Set env vars: `GITHUB_PAT`, `GEMINI_API_KEY`, `MONGODB_URI`. Known issue: free tier sleeps after 15 min of inactivity (cold start ~30s) — mitigate with UptimeRobot pinging `/health` every 14 minutes.
    - **Vercel (alternative):** Deploy as serverless functions (`/api` routes). No cold-start sleep issue; each function is stateless. Better for demo reliability — recommended if the backend is structured as REST API routes.

2.  **Frontend → Firebase Hosting**
    - Run `flutter build web --renderer canvaskit`.
    - Deploy with `firebase deploy`.
    - Global CDN ensures fast loads with no cold starts.

3.  **Database → MongoDB Atlas (M0 Free Cluster)**
    - 512 MB is sufficient for storing AI summaries and project metadata.
    - Enable IP whitelist `0.0.0.0/0` so Render's dynamic IPs can connect.

---

## 📋 Development Phases

### Phase 1 — MVP (Demo-Ready) 🎯
- [ ] Flutter Web shell with Bento UI layout and dark theme.
- [ ] Backend: GitHub metadata fetch + MongoDB save.
- [ ] AI summary generation (pre-computed, cached).
- [ ] Project card UI with language, stars, description.
- [ ] Live deployment pinger (heartbeat badge).
- [ ] Tech stack filter chips.

### Phase 2 — Polish
- [ ] Video demo upload & auto-play on hover (originally a Core Feature).
- [ ] Commit heatmap visualizer.
- [ ] Language constellation painter.
- [ ] Mermaid.js architecture diagram rendering.
- [ ] GitHub OAuth login for personalized dashboards.
- [ ] Hero animations — card physically expands into full technical case study.

### Phase 3 — Stretch Goals
- [ ] "Talk to the Code" contextual AI chat.
- [ ] Public share link for individual project spotlights.
- [ ] Personalized developer dashboards post-OAuth.