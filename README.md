<div align="center">

# CodeSpotlight ✨

**The Developer Proof-of-Work Platform**

[![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-Backend-339933?logo=node.js)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?logo=mongodb)](https://mongodb.com/atlas)
[![Gemini](https://img.shields.io/badge/Gemini-2.5--Flash-4285F4?logo=google)](https://aistudio.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

*Transform any public GitHub repository into a beautifully rendered, AI-powered case study.*

**Live Application / Deployment Link:** https://codespotlight-hm.web.app
<br>
**Watch Demo:** https://youtu.be/BZO2LhEN5AU

</div>

---

### 🚨 Problem Statement
The Developer Proof-of-Work Platform 🚀:

Many developers build great projects but lose them in scattered GitHub repositories. Built a centralized showcase directory where developers can host their deployed projects, tag their tech stack, and attach demo videos. Include filtering options (e.g., MERN, Web3, AI) for easy discovery.

## 📖 Overview

**CodeSpotlight** is a centralized showcase directory where developers can host their deployed projects, generate AI-powered technical deep-dives, and present their work to recruiters through a polished, read-only portfolio interface.

Paste a GitHub URL, and CodeSpotlight's integration with Gemini AI and the GitHub API instantly generates architecture diagrams, commit heatmaps, language visualizations, and a fully formatted Markdown README.

---

## ✨ Features

- **🤖 AI Technical Deep Dive:** Gemini 2.5 Flash generates a comprehensive case study explaining the project's purpose, the hardest problems solved, and the architectural decisions made.
- **📄 Auto-Generated READMEs:** Export your AI-generated project analysis to beautiful, fully-formatted Markdown, ready to be pushed directly to your GitHub repository.
- **🏗️ Architecture Diagrams:** Auto-generated Mermaid.js flowcharts visualize components, data flow, and system interactions in a secure sandboxed iframe.
- **🔥 Commit Heatmap:** A real 52-week × 7-day contribution grid pulled live from GitHub to showcase consistent effort.
- **🌍 Public Discoverability:** A global "Discover" feed where developers can browse top projects filtered by tech stack (MERN, Web3, AI, etc.).
- **🔐 Secure Portfolio Sharing:** Share a read-only link to your portfolio with recruiters without exposing edit/delete controls. Includes customizable social links (LinkedIn, Twitter, Portfolio).

---

## 🛠️ Tech Stack

### Frontend
- **Framework:** Flutter Web (Canvas Kit)
- **Routing:** `go_router` for shareable deep links
- **Markdown:** `flutter_markdown`
- **Hosting:** Firebase Hosting

### Backend
- **Framework:** Node.js + Express
- **Authentication:** JWT (JSON Web Tokens)
- **Database:** MongoDB Atlas (Mongoose)
- **AI Integration:** `@google/generative-ai` (Gemini 2.5 Flash)
- **Hosting:** Render.com

---

## 🌐 Deployment Information

This project is fully deployed and accessible live for the hackathon judging process:
- **Frontend (Flutter Web):** Deployed on **Firebase Hosting**
- **Backend (Node.js/Express):** Deployed on **Render.com**
- **Database (MongoDB):** Hosted on **MongoDB Atlas**
- **Live URL:** https://codespotlight-hm.web.app

---

> **🚨 FOR HACKATHON JUDGES:** You do **not** need to create an account to test the platform! Simply click the **"Try Demo"** button on the landing page to enter a secure, temporary sandbox session where you can generate AI case studies immediately.

## 🚀 Getting Started

Follow these instructions to set up the project locally.

### Prerequisites

- [Node.js](https://nodejs.org/en/) (v18 or higher)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x with Web target enabled)
- A [MongoDB Atlas](https://www.mongodb.com/cloud/atlas/register) cluster URI
- A Google [Gemini API Key](https://aistudio.google.com/)
- A GitHub Personal Access Token (PAT)

### 1. Backend Setup

```bash
# Navigate to the backend directory
cd backend

# Copy the environment template
cp .env.example .env
```

**Configure Environment Variables (`backend/.env`):**
| Variable | Description |
|---|---|
| `PORT` | API port (default: `3000`) |
| `MONGODB_URI` | MongoDB Atlas connection string |
| `JWT_SECRET` | Secret key for signing authentication tokens |
| `GITHUB_PAT` | GitHub Personal Access Token (public repo scope) |
| `GEMINI_API_KEY` | Google AI Studio key |
| `CLIENT_URL` | Frontend URL for CORS (e.g., `http://localhost:52870`) |

```bash
# Install dependencies
npm install

# Start the development server
npm run dev
```

### 2. Frontend Setup

```bash
# Open a new terminal and navigate to the frontend directory
cd frontend

# Get dependencies
flutter pub get

# Run the Flutter web app (Chrome)
flutter run -d chrome
```
*Note: The frontend is configured to communicate with `http://localhost:3000/api` by default.*

---

## 📂 Project Structure

```text
CodeSpotlight/
├── backend/
│   ├── src/
│   │   ├── controllers/      # Route logic
│   │   ├── models/           # Mongoose schemas (User, Project)
│   │   ├── routes/           # Express routes (auth.js, projects.js)
│   │   └── services/         # Integrations (geminiService.js, githubService.js)
│   └── index.js              # Server entry point
│
├── frontend/
│   ├── lib/
│   │   ├── models/           # Dart data models
│   │   ├── pages/            # UI Screens (Dashboard, Discover, Detail)
│   │   ├── services/         # API & Auth clients
│   │   ├── theme/            # Global AppTheme and styling
│   │   └── widgets/          # Reusable UI (Cards, Heatmap, Mermaid)
│   └── web/                  # Web-specific assets (index.html)
│
└── deploy.sh                 # Deployment automation script
```

---

## 🌐 Deployment

### Deploying the Backend (Render)
1. Connect your GitHub repository to [Render](https://render.com/).
2. Create a new **Web Service**.
3. Set the Root Directory to `backend`.
4. Set Build Command to `npm install`.
5. Set Start Command to `npm start`.
6. Add all environment variables from your `.env` file to the Render dashboard.

### Deploying the Frontend (Firebase)
```bash
cd frontend

# Build the app, injecting the production backend URL
flutter build web --release --dart-define=BACKEND_URL=https://<YOUR-RENDER-URL>.onrender.com/api

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<div align="center">
  <b>Built with ❤️ for the developer community.</b>
</div>
