# CodeSpotlight ✨

> **An AI-powered developer portfolio platform** — submit any public GitHub repo, get a beautifully rendered case study with architecture diagrams, commit heatmaps, and language visualizations.

[![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-Backend-339933?logo=node.js)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?logo=mongodb)](https://mongodb.com/atlas)
[![Gemini](https://img.shields.io/badge/Gemini-2.5--Flash-4285F4?logo=google)](https://aistudio.google.com)

---

## What It Does

Paste a GitHub URL → CodeSpotlight fetches the repo metadata, file tree, and key files, then runs a Gemini AI analysis to generate:

- **Technical Deep Dive** — a 3-paragraph case study explaining what the project does, hard problems solved, and architectural decisions made
- **Architecture Diagram** — a Mermaid.js flowchart showing components and data flow, rendered in a sandboxed iframe
- **Commit Heatmap** — 52-week × 7-day real GitHub contribution grid with intensity mapping
- **Language Constellation** — animated bubble chart of language usage proportional to bytes of code
- **Live Status Badge** — heartbeat check on the deployed URL

## Screenshots

> *(Add screenshots here after deploying)*

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter Web (Canvas Kit renderer) |
| Routing | go_router — shareable `/project/:id` deep links |
| Backend | Node.js + Express |
| Database | MongoDB Atlas (M0 free tier) |
| AI | Gemini 2.5 Flash (via `@google/generative-ai`) |
| GitHub Data | GitHub REST API v3 (PAT-authenticated) |
| Diagrams | Mermaid.js v11 (iframe-sandboxed) |
| Hosting | Firebase Hosting (frontend) + Render.com (backend) |

## Running Locally

### Prerequisites
- Flutter 3.x with Chrome target enabled
- Node.js 18+
- MongoDB Atlas free cluster
- Gemini API key (free tier at [aistudio.google.com](https://aistudio.google.com))
- GitHub Personal Access Token (public repo scope)

### 1. Backend
```bash
cd backend
cp .env.example .env
# Fill in GITHUB_PAT, GEMINI_API_KEY, MONGODB_URI in .env
npm install
npm run dev          # Starts on http://localhost:3000
```

### 2. Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

The app connects to `http://localhost:3000/api` by default.

## Deployment

### Backend → Render.com
1. Create a Web Service pointing to this repo, root dir: `backend`
2. Build: `npm install` | Start: `npm start`
3. Set env vars: `GITHUB_PAT`, `GEMINI_API_KEY`, `MONGODB_URI`, `ALLOWED_ORIGIN`, `PORT=3000`

### Frontend → Firebase Hosting
```bash
cd frontend
flutter build web --release --dart-define=BACKEND_URL=https://YOUR-APP.onrender.com/api
firebase deploy --only hosting
```

See [`deployment_guide.md`](deployment_guide.md) for the full step-by-step.

## Project Structure

```
CodeSpotlight/
├── frontend/                    ← Flutter Web
│   └── lib/
│       ├── main.dart
│       ├── router/app_router.dart    ← go_router routes
│       ├── models/
│       ├── pages/
│       │   ├── home_page.dart
│       │   ├── project_detail_page.dart
│       │   └── add_project_sheet.dart
│       ├── services/api_service.dart
│       ├── theme/app_theme.dart
│       └── widgets/
│           ├── mermaid_diagram_view.dart   ← iframe-based Mermaid renderer
│           ├── commit_heatmap.dart         ← CustomPainter 52×7 grid
│           ├── language_constellation.dart ← Animated bubble chart
│           ├── video_player_view.dart      ← YouTube / Loom / MP4 embed
│           └── ai_analysis_card.dart
├── backend/
│   └── src/
│       ├── services/
│       │   ├── geminiService.js    ← AI prompt + Mermaid sanitizer
│       │   └── githubService.js    ← GitHub API extraction
│       ├── routes/projects.js
│       └── models/Project.js
├── render.yaml                  ← Render.com IaC config
└── deploy.sh                    ← One-command build + deploy script
```

## Environment Variables

### Backend (`.env`)
| Variable | Description |
|---|---|
| `GITHUB_PAT` | GitHub Personal Access Token |
| `GEMINI_API_KEY` | Google AI Studio key |
| `MONGODB_URI` | MongoDB Atlas connection string |
| `ALLOWED_ORIGIN` | Firebase Hosting URL (CORS) |
| `PORT` | `3000` |

### Frontend (build-time)
```bash
--dart-define=BACKEND_URL=https://your-backend.onrender.com/api
```

## License

MIT
