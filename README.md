# CodeSpotlight ✨

> **An AI-powered developer portfolio platform** — submit any public GitHub repo, get a beautifully rendered case study with architecture diagrams, commit heatmaps, language visualizations, and a fully-formatted Markdown README.

[![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-Backend-339933?logo=node.js)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?logo=mongodb)](https://mongodb.com/atlas)
[![Gemini](https://img.shields.io/badge/Gemini-2.5--Flash-4285F4?logo=google)](https://aistudio.google.com)

---

## What It Does

Paste a GitHub URL → CodeSpotlight fetches the repo metadata, file tree, and key files, then runs a Gemini AI analysis to generate:

- **Technical Deep Dive** — a 3-paragraph case study explaining what the project does, hard problems solved, and architectural decisions made.
- **Auto-Generated READMEs** — an instantly generated, fully-formatted Markdown README that you can preview and copy directly to your GitHub repo.
- **Architecture Diagram** — a Mermaid.js flowchart showing components and data flow, rendered in a sandboxed iframe.
- **Commit Heatmap** — 52-week × 7-day real GitHub contribution grid with intensity mapping.
- **Language Constellation** — animated bubble chart of language usage proportional to bytes of code.
- **Live Status Badge** — heartbeat check on the deployed URL.

### New Features (v2)
- **Authentication & Profiles:** Secure JWT-based login system with customizable profiles and social links (LinkedIn, Twitter, Portfolio, GitHub).
- **Public Discoverability:** A global "Discover" feed where developers can showcase their top projects.
- **Read-Only Sharing:** Share a secure, read-only link to your portfolio with recruiters without exposing edit/delete controls.

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter Web (Canvas Kit renderer) |
| Routing | go_router — shareable deep links & public feeds |
| Backend | Node.js + Express + JWT Authentication |
| Database | MongoDB Atlas (M0 free tier) |
| AI | Gemini 2.5 Flash (via `@google/generative-ai`) |
| GitHub Data | GitHub REST API v3 (PAT-authenticated) |
| Diagrams | Mermaid.js v11 (iframe-sandboxed) |
| Markdown | `flutter_markdown` |
| Hosting | Firebase Hosting (frontend) + Render.com (backend) |

## Running Locally

### Prerequisites
- Flutter 3.x with Web target enabled
- Node.js 18+
- MongoDB Atlas free cluster
- Gemini API key (free tier at [aistudio.google.com](https://aistudio.google.com))
- GitHub Personal Access Token (public repo scope)

### 1. Backend
```bash
cd backend
cp .env.example .env
# Fill in GITHUB_PAT, GEMINI_API_KEY, MONGODB_URI, and JWT_SECRET in .env
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
2. Build Command: `npm install`
3. Start Command: `npm start`
4. Set Environment Variables: 
   - `GITHUB_PAT`
   - `GEMINI_API_KEY`
   - `MONGODB_URI`
   - `JWT_SECRET` (Required for authentication)
   - `CLIENT_URL` (Your Firebase URL for CORS)

### Frontend → Firebase Hosting
```bash
cd frontend
flutter build web --release --dart-define=BACKEND_URL=https://YOUR-APP.onrender.com/api
firebase deploy --only hosting
```

## Project Structure

```
CodeSpotlight/
├── frontend/                    ← Flutter Web
│   └── lib/
│       ├── main.dart
│       ├── router/app_router.dart    ← go_router routes
│       ├── models/
│       ├── pages/
│       │   ├── home_page.dart              ← User Dashboard
│       │   ├── discover_page.dart          ← Public Feed
│       │   ├── landing_page.dart           ← Marketing Page
│       │   ├── project_detail_page.dart    ← Case Study & Diagrams
│       │   └── add_project_sheet.dart
│       ├── services/
│       │   ├── api_service.dart
│       │   └── auth_service.dart           ← JWT & Session Management
│       ├── theme/app_theme.dart
│       └── widgets/
│           ├── profile_sidebar.dart        ← User info & Social Links
│           ├── mermaid_diagram_view.dart   ← iframe-based Mermaid renderer
│           ├── commit_heatmap.dart         ← CustomPainter 52×7 grid
│           ├── language_constellation.dart ← Animated bubble chart
│           └── ai_analysis_card.dart       ← Tabbed Markdown/Preview UI
├── backend/
│   └── src/
│       ├── services/
│       │   ├── geminiService.js    ← AI prompt + Mermaid sanitizer
│       │   └── githubService.js    ← GitHub API extraction
│       ├── routes/
│       │   ├── auth.js             ← Registration, Login, Profile
│       │   └── projects.js         ← Public and Private Project endpoints
│       └── models/
│           ├── User.js
│           └── Project.js
└── deploy.sh                    ← One-command build + deploy script
```

## Environment Variables

### Backend (`.env`)
| Variable | Description |
|---|---|
| `GITHUB_PAT` | GitHub Personal Access Token |
| `GEMINI_API_KEY` | Google AI Studio key |
| `MONGODB_URI` | MongoDB Atlas connection string |
| `JWT_SECRET` | Secret key for signing authentication tokens |
| `CLIENT_URL` | Firebase Hosting URL (used for CORS policy) |
| `PORT` | `3000` |

### Frontend (build-time)
```bash
--dart-define=BACKEND_URL=https://your-backend.onrender.com/api
```

## License

MIT
