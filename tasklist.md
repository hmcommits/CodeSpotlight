# ✅ CodeSpotlight — Phase-Wise Task List

> **Deployment Target:** Firebase Hosting (Flutter frontend) + Render.com or Vercel (Node.js backend) + MongoDB Atlas (DB)
> **Legend:** `[ ]` Not started · `[/]` In progress · `[x]` Done

---

## ⚙️ Phase 0 — Environment & Project Setup
> One-time setup. Must be 100% complete before writing any feature code.

### 0.1 Accounts & API Keys
- [ ] Create / verify **Google Firebase** account and create a new project named `codespotlight`.
- [ ] Enable **Firebase Hosting** in the Firebase Console.
- [ ] Install Firebase CLI: `npm install -g firebase-tools` and run `firebase login`.
- [ ] Create a **MongoDB Atlas** account and spin up an **M0 Free Cluster** (region: closest to your backend host).
- [ ] Create a MongoDB database user with `readWrite` permissions; save the connection URI.
- [ ] Set MongoDB Atlas Network Access → IP Whitelist to `0.0.0.0/0` (required for Render's dynamic IPs).
- [ ] Create a **Google AI Studio** account and generate a **Gemini API Key** (free tier — Gemini 1.5 Flash).
- [ ] Generate a **GitHub Personal Access Token (PAT)** with scopes: `repo` (read-only is sufficient for public repos), `read:user`.
- [ ] Create a **Render.com** account (or **Vercel** account) for the backend.

### 0.2 Repository Structure
- [ ] Initialize a Git repository in the project root.
- [ ] Create the following folder structure:
  ```
  CodeSpotlight/
  ├── frontend/          ← Flutter Web app
  ├── backend/           ← Node.js / Express API
  ├── .github/
  │   └── workflows/     ← (optional CI)
  ├── projectplan.md
  └── tasklist.md
  ```
- [ ] Add a root `.gitignore` covering Flutter, Node.js, and environment files.
- [ ] Create `backend/.env` (gitignored) with:
  ```
  GITHUB_PAT=your_pat_here
  GEMINI_API_KEY=your_key_here
  MONGODB_URI=your_atlas_uri_here
  PORT=3000
  ALLOWED_ORIGIN=https://your-firebase-app.web.app
  ```

### 0.3 Flutter Project Init
- [ ] Inside `frontend/`, create the Flutter Web project: `flutter create . --platforms=web`.
- [ ] Verify Flutter Web runs: `flutter run -d chrome`.
- [ ] Add dependencies to `pubspec.yaml`:
  - `http` — API calls to backend.
  - `flutter_animate` — micro-animations.
  - `google_fonts` — Inter / Space Grotesk typography.
  - `cached_network_image` — project thumbnails.
  - `flutter_svg` — language icons.
  - `url_launcher` — open GitHub/live links.
  - `js` — interop for Mermaid.js rendering (Phase 2).

### 0.4 Node.js Backend Init
- [ ] Inside `backend/`, run `npm init -y`.
- [ ] Install dependencies:
  ```bash
  npm install express mongoose cors dotenv axios @google/generative-ai
  npm install --save-dev nodemon
  ```
- [ ] Create `backend/src/` directory structure:
  ```
  backend/
  ├── src/
  │   ├── routes/
  │   ├── controllers/
  │   ├── services/
  │   ├── models/
  │   └── middleware/
  ├── index.js
  ├── .env
  └── package.json
  ```
- [ ] Configure `package.json` scripts: `"dev": "nodemon index.js"`, `"start": "node index.js"`.

---

## 🏗️ Phase 1 — MVP (Demo-Ready)
> Goal: A fully functional, deployed application ready to demo. Every task here is a hard requirement.

### 1.1 Backend — Data Models (MongoDB / Mongoose)

- [ ] **`Project` Model** (`src/models/Project.js`):
  ```js
  {
    owner: String,           // GitHub username
    repo: String,            // Repository name
    fullName: String,        // "owner/repo"
    description: String,
    stars: Number,
    forks: Number,
    primaryLanguage: String,
    languages: Object,       // { "JavaScript": 12345, "CSS": 3000 }
    topics: [String],        // GitHub repo topics (tags)
    techStack: [String],     // Inferred: ["MERN", "AI", "Flutter"]
    readmeContent: String,   // Raw README text (truncated to 3000 chars)
    fileTree: [String],      // Array of file paths from Trees API
    aiSummary: String,       // Gemini-generated case study
    mermaidDiagram: String,  // Gemini-generated Mermaid.js string
    aiStatus: {              // "pending" | "done" | "failed"
      type: String,
      default: "pending"
    },
    liveUrl: String,         // Optional deployed URL
    videoUrl: String,        // Optional demo video URL (Phase 2)
    heartbeatStatus: {       // "live" | "down" | "unknown"
      type: String,
      default: "unknown"
    },
    lastHeartbeatCheck: Date,
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now }
  }
  ```

### 1.2 Backend — GitHub Data Extraction Service

- [ ] Create `src/services/githubService.js`.
- [ ] Implement `validateGitHubUrl(url)` — parse and validate `https://github.com/{owner}/{repo}` format.
- [ ] Implement `fetchRepoMetadata(owner, repo)`:
  - Call `GET https://api.github.com/repos/{owner}/{repo}` with `Authorization: Bearer {PAT}` header.
  - Extract: `name`, `description`, `stargazers_count`, `forks_count`, `language`, `topics`.
  - Handle 404 (repo not found) and 403 (private repo) with specific error messages.
  - Set a **10-second axios timeout**.
- [ ] Implement `fetchLanguages(owner, repo)`:
  - Call `GET https://api.github.com/repos/{owner}/{repo}/languages`.
  - Returns an object like `{ "JavaScript": 12000, "CSS": 3000 }`.
- [ ] Implement `fetchFileTree(owner, repo)`:
  - Call `GET https://api.github.com/repos/{owner}/{repo}/git/trees/HEAD?recursive=1`.
  - Extract `tree[].path` where `type === "blob"` (files only).
  - **Single API call — no pagination.** Truncate to 500 paths max to stay within Gemini context limits.
- [ ] Implement `fetchFileContent(owner, repo, filePath)`:
  - Call `GET https://api.github.com/repos/{owner}/{repo}/contents/{filePath}`.
  - Decode base64 content: `Buffer.from(data.content, 'base64').toString('utf8')`.
  - Return `null` on 404 (file doesn't exist).
- [ ] Implement `fetchKeyFiles(owner, repo, fileTree)`:
  - Check file tree for `README.md`, `package.json`, `requirements.txt`, `pubspec.yaml`, `Cargo.toml`, `go.mod`.
  - Fetch whichever exist (max 3 files to limit API calls).
  - Concatenate content, truncated to 3000 characters total.
- [ ] Implement `inferTechStack(languages, fileTree, topics)`:
  - Rule-based tagging: if `package.json` exists + `express` in content → tag `Node.js`; if `pubspec.yaml` → tag `Flutter`; if `requirements.txt` + `torch` → tag `AI/ML`; etc.
  - Returns an array like `["MERN", "AI"]`.
- [ ] Add a central `extractAllRepoData(owner, repo)` function that calls all of the above in parallel using `Promise.all` where safe.

### 1.3 Backend — Gemini AI Service

- [ ] Create `src/services/geminiService.js`.
- [ ] Initialize `@google/generative-ai` with `GEMINI_API_KEY`.
- [ ] Use model: `gemini-1.5-flash` (free tier).
- [ ] Implement `generateProjectAnalysis(repoContext)`:
  - `repoContext` includes: repo name, description, languages, file tree, key file contents.
  - **Prompt structure:**
    ```
    You are a senior software architect. Analyze this GitHub repository and return ONLY valid JSON with two fields:
    1. "summary": A 3-paragraph Technical Deep Dive case study explaining what the project does,
       the hardest technical problems solved, and the architectural decisions made.
    2. "mermaid": A valid Mermaid.js flowchart diagram showing the project's architecture
       (components, data flow, key interactions). Use "graph TD" format.

    Repository context:
    Name: {name}
    Description: {description}
    Languages: {languages}
    File tree (sample): {fileTree}
    Key files content: {keyFiles}
    ```
  - Parse the JSON response; handle malformed JSON with a try/catch.
  - Return `{ summary: string, mermaid: string }`.
- [ ] Implement retry logic: if Gemini fails, retry once after 2 seconds before marking as `failed`.

### 1.4 Backend — API Routes & Controllers

- [ ] Create `src/routes/projects.js` with the following endpoints:

  **`POST /api/projects`** — Submit a new project
  - [ ] Validate GitHub URL format.
  - [ ] Check if the repo already exists in MongoDB (return cached data if yes).
  - [ ] Call `extractAllRepoData()` to fetch from GitHub.
  - [ ] Save the project to MongoDB with `aiStatus: "pending"`.
  - [ ] Respond immediately to the client with the saved project (202 Accepted).
  - [ ] **Asynchronously** trigger `generateProjectAnalysis()` and update the document when done.

  **`GET /api/projects`** — Get all projects
  - [ ] Support query parameters: `?stack=MERN`, `?language=JavaScript`, `?search=chatbot`.
  - [ ] Return projects sorted by `createdAt` descending.

  **`GET /api/projects/:id`** — Get a single project by ID
  - [ ] Return full project data including `aiSummary` and `mermaidDiagram`.

  **`POST /api/projects/:id/heartbeat`** — Check live deployment status
  - [ ] Accept `{ liveUrl: string }` in body.
  - [ ] Use `axios.get(liveUrl, { timeout: 8000 })` to ping the URL.
  - [ ] Update `heartbeatStatus` and `lastHeartbeatCheck` in the DB.
  - [ ] Return `{ status: "live" | "down" }`.

  **`GET /api/health`** — Health check (used by UptimeRobot)
  - [ ] Return `{ status: "ok", timestamp: Date.now() }` with 200.

- [ ] Create `src/middleware/errorHandler.js` — centralized error handler returning `{ error: string, code: string }`.
- [ ] Configure CORS in `index.js` to allow only `ALLOWED_ORIGIN`.
- [ ] Connect to MongoDB in `index.js` using `mongoose.connect(MONGODB_URI)`.

### 1.5 Frontend — Design System & Theme

- [ ] In `frontend/lib/theme/`, create `app_theme.dart`:
  - Background: `#0D0D0D` (deep charcoal).
  - Surface: `#1A1A1A` (card background).
  - Primary accent: `#6C63FF` (electric violet).
  - Secondary accent: `#00D9FF` (cyan).
  - Text primary: `#F0F0F0`, text secondary: `#8A8A8A`.
  - Border radius tokens: `12px` (cards), `8px` (chips), `24px` (buttons).
  - Language color map: `JS → #F7DF1E`, `Python → #3572A5`, `Flutter/Dart → #54C5F8`, `Go → #00ADD8`, `Rust → #CE422B`, etc.
- [ ] Apply `google_fonts` — use **Inter** for body text, **Space Grotesk** for headings.

### 1.6 Frontend — Core Widgets

- [ ] **`ProjectCard` widget** (`lib/widgets/project_card.dart`):
  - Glassmorphism container: `BackdropFilter`, `ImageFilter.blur(sigmaX: 12, sigmaY: 12)`, border with language color.
  - Display: Repo name (Space Grotesk bold), description (2-line overflow), primary language chip, stars count, forks count.
  - Heartbeat status badge (green pulse for Live, red dot for Down, grey for Unknown).
  - Neon left border whose color maps to the primary language.
  - `InkWell` tap → navigate to `ProjectDetailPage` using Flutter `Hero` animation.
  - `AnimatedContainer` for hover scale effect on web (`MouseRegion`).

- [ ] **`TechFilterChip` widget** (`lib/widgets/tech_filter_chip.dart`):
  - Selectable chip with selected state (filled accent color) vs unselected (outlined).
  - Options: All · AI/ML · MERN · Flutter · Web3 · Python · Go · Rust.

- [ ] **`HeartbeatBadge` widget** (`lib/widgets/heartbeat_badge.dart`):
  - Green pulsing dot animation (using `flutter_animate` `scale` + `fade` loop) for `live`.
  - Red static dot for `down`.
  - Grey dot for `unknown`.

- [ ] **`LanguageBar` widget** (`lib/widgets/language_bar.dart`):
  - Horizontal segmented bar showing language percentage breakdown with language colors.

- [ ] **`LoadingBentoCard` widget** — Shimmer placeholder while data loads.

### 1.7 Frontend — Pages

- [ ] **`HomePage`** (`lib/pages/home_page.dart`):
  - Top app bar: Logo ("CodeSpotlight" in gradient text) + "Add Project" button.
  - Search bar below app bar (live filter by repo name / description).
  - Horizontal scrollable `TechFilterChip` row.
  - **Bento Box grid layout:** Use `Wrap` or `MasonryGridView` with cards of varying sizes (featured projects get wider tiles).
  - Empty state widget: illustrated message when no projects match filter.
  - Floating Action Button → opens `AddProjectSheet`.

- [ ] **`AddProjectSheet`** (bottom sheet, `lib/pages/add_project_sheet.dart`):
  - `TextFormField` for GitHub URL input with validation.
  - Optional: `TextFormField` for live deployment URL.
  - "Analyze Repository" submit button with loading spinner.
  - Show progress steps during submission: `Fetching metadata...` → `Running AI analysis...` → `Done!`
  - Error display with friendly messages (e.g., "This repo is private" or "GitHub rate limit hit, try again in a minute").

- [ ] **`ProjectDetailPage`** (`lib/pages/project_detail_page.dart`):
  - `Hero` animation expanding from card.
  - Full layout sections:
    - **Header:** Repo name, owner avatar, stars, forks, language bar.
    - **AI Summary:** "Technical Deep Dive" text with a subtle gradient fade-in animation.
    - **Architecture Diagram:** Mermaid.js rendering panel (Phase 2 polish) — for MVP show a placeholder "Diagram loading..." card.
    - **Proof-of-Effort:** Commit heatmap + Language constellation (Phase 2) — MVP shows a placeholder.
    - **Links:** "Open on GitHub" + "Visit Live Site" buttons.
  - Back button returns to `HomePage` with reverse `Hero`.

### 1.8 Frontend — API Service

- [ ] Create `lib/services/api_service.dart`:
  - `static const String baseUrl = 'https://your-backend.onrender.com/api';`
  - `Future<List<Project>> getProjects({String? stack, String? search})`.
  - `Future<Project> submitProject(String githubUrl, {String? liveUrl})`.
  - `Future<Project> getProjectById(String id)`.
  - `Future<HeartbeatResult> checkHeartbeat(String id, String liveUrl)`.
  - All methods use `http` package; handle `HttpException`, timeouts (15s), and non-200 status codes.

- [ ] Create `lib/models/project_model.dart`:
  - Dart `Project` data class with `fromJson` factory and `toJson` method.
  - Include all fields from the MongoDB schema.

### 1.9 Integration & Local Testing

- [ ] Run the backend locally (`npm run dev`) and test all endpoints using a REST client (e.g., curl or Postman):
  - [ ] `POST /api/projects` with a real public GitHub URL.
  - [ ] Verify MongoDB document is created with `aiStatus: "done"` after ~10 seconds.
  - [ ] `GET /api/projects` returns the project.
  - [ ] `POST /api/projects/:id/heartbeat` returns `live` for a known live URL.
  - [ ] `GET /api/health` returns 200.
- [ ] Run Flutter Web locally (`flutter run -d chrome`) and test:
  - [ ] `HomePage` loads and displays all projects from the backend.
  - [ ] Filter chips filter correctly.
  - [ ] `AddProjectSheet` submits a repo and new card appears.
  - [ ] Tapping a card navigates to `ProjectDetailPage` with `Hero` animation.
  - [ ] Heartbeat badge reflects correct status.

---

## 🚀 Phase 1 — Deployment

### 1.10 Backend Deployment (Choose One)

#### Option A: Render.com
- [ ] Push backend to GitHub.
- [ ] In Render dashboard: New → Web Service → connect GitHub repo.
- [ ] Set **Root Directory** to `backend/`.
- [ ] Set **Build Command:** `npm install`.
- [ ] Set **Start Command:** `npm start`.
- [ ] Add Environment Variables: `GITHUB_PAT`, `GEMINI_API_KEY`, `MONGODB_URI`, `ALLOWED_ORIGIN`, `PORT=3000`.
- [ ] Deploy and verify the live URL: `GET https://your-app.onrender.com/api/health` returns `{ status: "ok" }`.
- [ ] Set up **UptimeRobot** (free): create an HTTP monitor pinging `/api/health` every 5 minutes to prevent sleep.

#### Option B: Vercel (Serverless)
- [ ] Restructure backend routes to work as Vercel serverless functions under `backend/api/` directory.
- [ ] Add `vercel.json` at `backend/` root:
  ```json
  {
    "version": 2,
    "builds": [{ "src": "index.js", "use": "@vercel/node" }],
    "routes": [{ "src": "/api/(.*)", "dest": "/index.js" }]
  }
  ```
- [ ] Run `vercel --prod` from `backend/` directory.
- [ ] Add Environment Variables in Vercel Dashboard: `GITHUB_PAT`, `GEMINI_API_KEY`, `MONGODB_URI`, `ALLOWED_ORIGIN`.
- [ ] Verify: `GET https://your-app.vercel.app/api/health` returns 200.

### 1.11 Frontend Deployment (Firebase Hosting)
- [ ] Update `lib/services/api_service.dart` — set `baseUrl` to the deployed backend URL.
- [ ] Run `flutter build web --renderer canvaskit` inside `frontend/`.
- [ ] Run `firebase init hosting` — set public directory to `build/web`, configure as SPA (rewrite all to `index.html`).
- [ ] Run `firebase deploy`.
- [ ] Verify the app loads at `https://codespotlight-xxxx.web.app`.
- [ ] Update backend's `ALLOWED_ORIGIN` environment variable to the Firebase Hosting URL and redeploy backend.
- [ ] End-to-end smoke test on the live deployed app:
  - [ ] Submit a GitHub repo.
  - [ ] Wait for AI analysis to complete.
  - [ ] Verify card appears with correct data and heartbeat status.

---

## ✨ Phase 2 — Polish

> Goal: Elevate the demo experience with animations, richer data visualizations, and Video-First Discovery.

### 2.1 Video-First Discovery *(Core Feature — Restored)*
- [ ] Add `videoUrl` field support to the `AddProjectSheet` (text input for a video link, e.g., YouTube/Loom/direct `.mp4`).
- [ ] On `ProjectCard`: if `videoUrl` is set, show a video thumbnail with a play icon overlay.
- [ ] On `ProjectDetailPage` header: embed a video player widget (use `chewie` + `video_player` packages for direct video, or a `WebView` / `HtmlElementView` for YouTube embeds).
- [ ] On `HomePage` card hover (`MouseRegion` on web): auto-play the video loop as a muted preview.
- [ ] Fallback: if no video, show a generated language-colored gradient placeholder.

### 2.2 Commit Heatmap — Proof-of-Effort Visualizer
- [ ] Add backend endpoint: `GET /api/projects/:id/commit-activity` → calls `/repos/{owner}/{repo}/stats/commit_activity` and caches the result in MongoDB.
- [ ] Create Flutter `CustomPainter` widget `CommitHeatmapPainter`:
  - 52-column × 7-row grid of rounded rectangles.
  - Color intensity: from `#1A1A1A` (0 commits) to `#6C63FF` (max commits).
  - Tooltip on hover showing week and count.
- [ ] Display heatmap in `ProjectDetailPage` under "Proof-of-Effort" section.

### 2.3 Language Constellation Visualizer
- [ ] Add backend endpoint: `GET /api/projects/:id/languages` → returns language data (already cached in MongoDB from Phase 1).
- [ ] Create Flutter `CustomPainter` widget `LanguageConstellationPainter`:
  - Each language is a bubble/circle; size ∝ bytes of code.
  - Color matches the language color map from `app_theme.dart`.
  - Labels inside each bubble (language name + percentage).
  - Subtle animated float effect using `AnimationController` with `sin` offset.
- [ ] Display constellation in `ProjectDetailPage`.

### 2.4 Mermaid.js Architecture Diagram Rendering
- [ ] Inject `mermaid` JS library into `frontend/web/index.html`:
  ```html
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <script>mermaid.initialize({ startOnLoad: false, theme: 'dark' });</script>
  ```
- [ ] Create a `MermaidDiagramView` Flutter widget using `HtmlElementView` (web only):
  - Registers an HTML `div` with a unique `viewType`.
  - Calls `mermaid.render(id, diagramString)` via `js` interop.
  - Displays the rendered SVG.
- [ ] Show the Mermaid diagram in `ProjectDetailPage` where the Phase 1 placeholder was.
- [ ] Handle malformed Mermaid strings gracefully (catch render errors, show fallback text).

### 2.5 Fluid Animation Polish
- [ ] Fully implement `Hero` animation for card → detail page transition:
  - Wrap `ProjectCard` outer container and `ProjectDetailPage` header with matching `Hero(tag: 'project-${project.id}')`.
- [ ] Add staggered entrance animation on `HomePage`: cards animate in with `flutter_animate` — slide up + fade in, 50ms delay between each card.
- [ ] Add `AnimatedSwitcher` for filter changes — projects smoothly fade/scale in/out when filter chips change.
- [ ] Add `AnimatedContainer` pulse on heartbeat badge every 3 seconds for `live` status.

### 2.6 GitHub OAuth Login (Optional — for personalized views)
- [ ] Backend: implement GitHub OAuth 2.0 flow:
  - `GET /api/auth/github` → redirect to GitHub OAuth.
  - `GET /api/auth/github/callback` → exchange code for token, create/find user in MongoDB, return JWT.
- [ ] Frontend: "Login with GitHub" button on `HomePage`.
- [ ] After login: show a "My Projects" tab filtering projects by the logged-in user's GitHub handle.
- [ ] Store JWT in `SharedPreferences`; include as `Authorization: Bearer {token}` on relevant API calls.

---

## 💬 Phase 3 — Stretch Goals

> Goal: Advanced features to push beyond the MVP if time permits.

### 3.1 "Talk to the Code" — Contextual AI Chat
- [ ] Add chat icon button to `ProjectDetailPage`.
- [ ] Backend endpoint: `POST /api/projects/:id/chat`:
  - Accept `{ query: string }`.
  - Load cached `fileTree` from MongoDB.
  - Keyword-match the query against file paths to find relevant files (e.g., query "authentication" → look for `auth.js`, `middleware/auth`, `routes/auth`).
  - Fetch top 3 matching file contents via GitHub Contents API.
  - Build Gemini prompt: "You are a code reviewer. Based only on the following source files from the {repoName} project, answer this question: {query}\n\nFiles:\n{fileContents}".
  - Return the Gemini response.
- [ ] Frontend: Chat panel slides up from the bottom of `ProjectDetailPage`:
  - Message list with user messages (right-aligned) and AI responses (left-aligned, with code blocks formatted).
  - Input field + send button.
  - "Analyzing code..." loading state.
  - Disclaimer: "Answers are based only on the repository's source code."

### 3.2 Public Share Link
- [ ] Each `ProjectDetailPage` gets a unique URL: `https://codespotlight.web.app/project/{id}`.
- [ ] Implement Flutter Web routing with `go_router` package.
- [ ] Add deep link support: navigating to `/project/{id}` directly loads the project from the API and shows `ProjectDetailPage` without needing `HomePage` first.
- [ ] "Share" icon button copies the URL to clipboard (use `Clipboard.setData`).
- [ ] Add Open Graph meta tags (generated dynamically via the backend's `/api/projects/:id/og` endpoint) for rich link previews on Slack/Twitter.

### 3.3 Personalized Developer Dashboard
- [ ] Post-GitHub OAuth: user can see a dedicated dashboard with all repos they've submitted.
- [ ] Dashboard shows aggregate stats: total stars across all projects, most used languages, total commits.
- [ ] "Re-analyze" button to trigger a fresh Gemini analysis for any project.
- [ ] Allow editing `liveUrl` and `videoUrl` for submitted projects.

---

## 📦 Pre-Demo Checklist
> Run through this the evening before your demo.

- [ ] Backend is live and `GET /api/health` returns 200 with < 500ms latency.
- [ ] UptimeRobot is actively pinging (no cold starts during demo).
- [ ] At least **3 pre-loaded projects** in MongoDB with `aiStatus: "done"` and varied tech stacks.
- [ ] All 3 pre-loaded projects have a `liveUrl` with `heartbeatStatus: "live"`.
- [ ] Flutter app loads on the Firebase Hosting URL in under 4 seconds.
- [ ] Filter chips correctly filter the pre-loaded projects.
- [ ] Submitting a new test repo completes within 30 seconds (GitHub + Gemini pipeline).
- [ ] `ProjectDetailPage` shows correct AI summary for all pre-loaded projects.
- [ ] Test on an incognito window (no local state) to simulate a recruiter's first visit.
- [ ] Have a backup: if live Gemini call fails during demo, have a pre-loaded project ready to show instead.
