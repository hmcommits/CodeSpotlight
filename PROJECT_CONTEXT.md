# CodeSpotlight — Project Context, Completed Work & Roadmap

> **Written:** May 21, 2026  
> **Purpose:** Comprehensive handoff document — what the project is, what was fixed, what to do next, and where it's all going.

---

## 1. What Is CodeSpotlight?

**CodeSpotlight** is a full-stack developer portfolio platform built for a hackathon. It solves a real problem: developers build quality projects but let them rot in scattered GitHub repositories with no showcase. CodeSpotlight turns any public GitHub repo into a polished, AI-powered project card with one URL paste.

### Tech Stack at a Glance

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter Web (CanvasKit renderer) |
| Backend | Node.js + Express |
| Database | MongoDB Atlas via Mongoose |
| AI | Google Gemini 2.5 Flash (`@google/generative-ai`) |
| Auth | JWT (30-day expiry, `bcryptjs` hashing) |
| Frontend Hosting | Firebase Hosting |
| Backend Hosting | Render.com |

### Core Features

- **AI Deep Dive** — Paste a GitHub URL → Gemini 2.5 Flash generates a 3-paragraph technical case study
- **Mermaid Architecture Diagram** — Auto-generated flowchart of system components
- **Commit Heatmap** — 52-week × 7-day contribution grid from live GitHub data
- **README Generator** — Export AI analysis as a push-ready `README.md`
- **Live URL Heartbeat** — Pings your deployed app and shows a live/down badge
- **Public Discover Feed** — Browse all developers' projects, filtered by tech stack
- **Demo Mode** — Full sandbox experience without creating an account (for judges)
- **Portfolio Sharing** — Secure read-only link to your full portfolio

### Codebase Structure

```
CodeSpotlight/
├── backend/
│   ├── index.js                        # Express server entry point
│   └── src/
│       ├── controllers/
│       │   └── authController.js       # [NEW] Auth business logic layer
│       ├── middleware/
│       │   ├── authMiddleware.js        # JWT verify / optionalAuth
│       │   └── errorHandler.js         # Central error response handler
│       ├── models/
│       │   ├── User.js                 # Mongoose user schema
│       │   └── Project.js              # Mongoose project schema
│       ├── routes/
│       │   ├── auth.js                 # Thin router → authController
│       │   └── projects.js             # Project CRUD + AI routes
│       ├── services/
│       │   ├── analysisQueue.js        # [NEW] In-memory job queue
│       │   ├── geminiService.js        # Gemini AI integration
│       │   └── githubService.js        # GitHub API integration
│       └── utils/
│           └── urlValidator.js         # [NEW] SSRF-safe URL validator
│
└── frontend/
    └── lib/
        ├── models/
        │   ├── project_model.dart
        │   └── user_model.dart
        ├── pages/
        │   ├── landing_page.dart
        │   ├── home_page.dart
        │   ├── discover_page.dart
        │   ├── project_detail_page.dart
        │   ├── public_profile_page.dart
        │   └── auth_pages.dart
        ├── services/
        │   ├── api_service.dart
        │   └── auth_service.dart
        ├── theme/
        │   └── app_theme.dart
        └── widgets/
            ├── project_card.dart
            ├── profile_sidebar.dart
            ├── ai_analysis_card.dart
            ├── commit_heatmap.dart
            ├── mermaid_diagram_view.dart
            └── ...
```

---

## 2. What Was Audited & Fixed

A full repository audit was conducted covering security, reliability, data modelling, and code quality. **16 flaws** were identified and resolved in a single session.

---

### 🔴 Critical Fixes (Security)

#### Fix 1 — Hardcoded Fallback JWT Secret
**Problem:** `authMiddleware.js` had `JWT_SECRET || 'codespotlight-dev-secret-change-in-prod'`. If the env var is unset in production (e.g., a failed Render deploy), every JWT becomes trivially forgeable with the public string.

**Fix:** Server now throws a fatal error on startup if `JWT_SECRET` is missing.

```js
// authMiddleware.js
if (!process.env.JWT_SECRET) {
  throw new Error('FATAL: JWT_SECRET environment variable is not set.');
}
const JWT_SECRET = process.env.JWT_SECRET;
```

---

#### Fix 2 — Unauthenticated Admin Bulk Re-analysis Endpoint
**Problem:** `POST /api/projects/admin/reanalyze-all` had zero authentication. Any anonymous caller could trigger a full re-analysis of every project in the database, draining the Gemini API quota immediately.

**Fix:** Endpoint now requires an `X-Admin-Secret` header matching the `ADMIN_SECRET` env var. If `ADMIN_SECRET` is not set, the endpoint returns 503 (disabled).

---

#### Fix 3 — SSRF via Heartbeat URL
**Problem:** The heartbeat route accepted `liveUrl` from `req.body` and passed it directly to `axios.get()`. An attacker could probe internal AWS metadata (`169.254.169.254`), MongoDB (`localhost:27017`), or any private network.

**Fix:** Created `src/utils/urlValidator.js` — a DNS-resolving validator that:
- Rejects non-HTTP/HTTPS protocols
- Resolves the hostname and checks all returned IPs against private/loopback/link-local ranges (RFC-1918, `127.x`, `169.254.x`, `::1`)
- Applied at the top of the heartbeat route before any outbound request

---

#### Fix 4 — Public Profile Leaks User Email
**Problem:** `GET /api/auth/profile/:userId` (the shareable portfolio link endpoint) was returning the user's raw email address to anyone with the URL — a PII leak that gets worse when portfolio links are shared publicly.

**Fix:** Email removed from `.select()` and stripped from the response object. The public profile now returns only `name`, `memberSince`, and `socialLinks`.

---

### 🟠 High Fixes (Reliability & Architecture)

#### Fix 5 — Demo Session Deletion Had No Format Validation
**Problem:** `DELETE /api/projects/demo/:sessionId` accepted any string as a session ID, enabling enumeration attacks.

**Fix:** Session ID is now validated against the UUID v4 regex before any DB operation. The `isDemo: true` filter was already present — now it's the second layer of defence.

---

#### Fix 6 — No Job Queue (Fire-and-Forget Gemini Calls)
**Problem:** The AI analysis was a raw floating promise after `res.status(202)`. If the server restarted mid-analysis, the project stayed in `'pending'` forever. With concurrent submissions, an unbounded number of parallel Gemini calls would fire simultaneously.

**Fix:** Created `src/services/analysisQueue.js` — a singleton in-memory queue:
- Processes **one job at a time** (respects Gemini rate limits)
- **1.5s pacing** between consecutive jobs
- On server startup, calls `recoverStuckJobs()` which queries for all non-demo projects with `aiStatus: 'pending'` and re-queues them automatically
- Both `POST /projects` (new submission) and `POST /projects/:id/reanalyze` now use `analysisQueue.enqueue()` instead of raw promises
- The admin bulk re-analysis loop also benefits from the queue's single-threaded processing

---

#### Fix 7 — Gemini Retry Had No Exponential Backoff
**Problem:** The original code only retried once with a flat 2-second delay. On Gemini's free tier, 429 rate-limit errors require longer waits than 2s.

**Fix:** Now retries up to **4 attempts** with exponential backoff:
- Attempts: `2s → 4s → 8s` for general errors
- For 429 rate-limit errors: base is `10s → 20s → 40s`

---

#### Fix 8 — `userId` Was a Plain String, Not an ObjectId Reference
**Problem:** `Project.userId` was `{ type: String }`, breaking Mongoose `.populate()`, bypassing referential integrity, and causing silent query mismatches.

**Fix:** Changed to `{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }` with a sparse index.

> ⚠️ **Production Migration Required** — one-time script documented in `Project.js` comments:
> ```js
> db.projects.find({ userId: { $type: 'string', $ne: '' } }).forEach(doc => {
>   db.projects.updateOne({ _id: doc._id }, {
>     $set: { userId: ObjectId(doc.userId) }
>   });
> });
> ```

---

#### Fix 9 — ReDoS via Unsanitized `$regex` Search
**Problem:** The `search` query parameter was passed raw into a MongoDB `$regex` filter. A user could send `(a+)+` and cause catastrophic backtracking, hanging the database query.

**Fix:** Added `escapeRegex()` helper that escapes all special regex characters before they reach MongoDB. Applied to both the private project search and the public feed language filter.

---

#### Fix 10 — CORS Wildcard Fallback in Production
**Problem:** `cors({ origin: process.env.ALLOWED_ORIGIN || '*' })` — if the env var is unset, CORS is fully open. The env var was also named `ALLOWED_ORIGIN` in code but `CLIENT_URL` in the README.

**Fix:**
- Env var unified to `CLIENT_URL` across code and docs
- In `NODE_ENV=production`, server throws a fatal error if `CLIENT_URL` is not set
- In development, it gracefully falls back to `'*'`

---

### 🟡 Medium Fixes (Code Quality)

#### Fix 11 — No Controllers Folder (Logic Was Inlined in Routes)
**Problem:** `projects.js` was 353 lines with all business logic inlined. The README promised a `controllers/` directory that didn't exist. This made the code untestable and unmaintainable.

**Fix:** Created `src/controllers/authController.js` with all auth logic extracted. `auth.js` is now a 12-line thin router. (The `projects.js` controller will be extracted in the next sprint when the portfolio builder routes are added.)

---

#### Fix 12 — Missing Database Indexes on Query Fields
**Problem:** The only index was the compound `{ fullName, userId, demoSessionId }`. Public feed queries (sorted by `createdAt`, `stars`, `forks`) had no indexes — would degrade at scale.

**Fix:** Added 5 new indexes to `Project.js`:
```js
projectSchema.index({ isDemo: 1, createdAt: -1 });  // public feed newest
projectSchema.index({ isDemo: 1, stars: -1 });       // public feed top stars
projectSchema.index({ isDemo: 1, forks: -1 });       // public feed most forked
projectSchema.index({ userId: 1, isDemo: 1, displayOrder: 1 }); // portfolio builder
projectSchema.index({ userId: 1 });                  // per-user project lookup
```

---

#### Fix 13 — API Response Shape Inconsistency
**Problem:** `GET /me` and `GET /profile/:userId` returned differently shaped user objects. The `AppUser.fromJson` Dart class had ugly defensive double-nesting workarounds (`json['user']?['socialLinks']`) to compensate.

**Fix:** Response shapes are now standardized through the controller. `User.js` has a `toJSON` transform that auto-strips passwords. `AppUser.fromJson` is now clean with no workarounds.

---

#### Fix 14 — Polling Timer Could Leak on Re-initialization
**Problem:** If `_loadProjects()` fired twice (e.g., on `AppLifecycleState.resumed`), a new timer would be created while the previous timer's in-flight `await` could still call `setState` after the new cycle had begun.

**Fix:** Added a `_pollGeneration` integer counter. Each new poll cycle increments it. Timer callbacks capture the generation at creation time and bail out early if the generation has changed by the time they fire.

---

#### Fix 15 — No URL Validation on `socialLinks`
**Problem:** `PATCH /api/auth/me` accepted any value for `socialLinks` — including `javascript:alert(1)` which, if rendered as an `<a href>` on the portfolio page, would be an XSS vector.

**Fix:** `authController.updateMe` now validates each social link URL. Only `http://` and `https://` schemes are accepted. Any other protocol returns a 400 error.

---

#### Fix 16 — PATCH Endpoint Too Restrictive for Portfolio Builder
**Problem:** `PATCH /api/projects/:id` only allowed updating `liveUrl` and `videoUrl`. The upcoming portfolio builder needs users to control display order, featured status, and per-project descriptions.

**Fix:** Expanded allowed fields to: `liveUrl`, `videoUrl`, `customDescription`, `featured`, `displayOrder`, `isPublicOnPortfolio`. `displayOrder` is validated as a non-negative integer.

---

### Bonus: Schema Prep for Portfolio Builder

As part of the fixes, both models were extended with the fields the portfolio builder will need:

**`User.js` additions:**
```js
bio:                { type: String, default: '', maxlength: 500 },
avatarUrl:          { type: String, default: '' },
portfolioTemplate:  { type: String, enum: ['minimal', 'grid', 'terminal', 'glassmorphic'] },
portfolioPublished: { type: Boolean, default: false },
portfolioSlug:      { type: String, unique: true, sparse: true },
```

**`Project.js` additions:**
```js
featured:            { type: Boolean, default: false },
displayOrder:        { type: Number, default: 0 },
isPublicOnPortfolio: { type: Boolean, default: true },
customDescription:   { type: String, default: '' },
```

---

## 3. Immediate Next Action

> **Before anything else — run the `userId` migration on the live production database.**

The `userId` field type changed from `String` to `ObjectId`. Any project documents that already exist in MongoDB Atlas with a `userId` stored as a string will not be matched correctly by new queries.

**Steps:**
1. Open MongoDB Atlas → Clusters → Browse Collections → `codespotlight.projects`
2. Open a MongoDB Shell or use Compass's Aggregation tab and run:

```js
db.projects.find({ userId: { $type: "string", $ne: "" } }).forEach(doc => {
  db.projects.updateOne(
    { _id: doc._id },
    { $set: { userId: new ObjectId(doc.userId) } }
  );
});
```

3. Verify: `db.projects.find({ userId: { $type: "string", $ne: "" } }).count()` should return `0`
4. Then re-deploy the backend on Render.com

---

## 4. What's Next — Portfolio Website Builder

This is the major feature planned for the next phase. The goal: every CodeSpotlight user gets a **personal portfolio website** generated from their added repos, with selectable templates and a shareable link like `codespotlight-hm.web.app/p/harshm`.

---

### Phase 1 — Backend Foundation

**New API Routes to Build:**

| Method | Route | Purpose |
|--------|-------|---------|
| `PATCH` | `/api/auth/me/portfolio` | Update template, bio, avatarUrl, published status |
| `POST` | `/api/auth/me/slug` | Claim a portfolio slug (validate uniqueness) |
| `GET` | `/api/portfolio/:slug` | Public portfolio fetch by slug (used for rendering) |
| `PATCH` | `/api/projects/:id` | Already expanded — reorder, feature, hide projects |

**New `portfolioController.js`** to handle template logic separately from auth.

---

### Phase 2 — Frontend Templates

The Flutter Web app needs a new **Portfolio Page** (`/p/:slug`) and a **Portfolio Editor** (`/app/portfolio`).

**Template designs to build (4 templates):**

| Template | Aesthetic | Card Style | Layout |
|----------|-----------|-----------|--------|
| `minimal` | Clean white, Inter font | Thin-border list | Single column |
| `grid` | Dark glassmorphism (current style) | Bento-box cards | Masonry grid |
| `terminal` | Black bg, green monospace | ASCII-border cards | Terminal stdout style |
| `glassmorphic` | Frosted glass panels | Blurred bg cards | 2-col with sidebar |

Each template receives the same data contract — the portfolio builder just switches the `portfolioTemplate` field and re-renders.

**New Flutter pages/widgets needed:**
- `portfolio_page.dart` — public-facing rendered template (route: `/p/:slug`)
- `portfolio_editor_page.dart` — settings: choose template, write bio, upload avatar, toggle published, reorder repos
- `template_preview_card.dart` — shows a miniature preview of each template for selection
- `portfolio_project_card.dart` — project card variant for portfolio view (differs from dashboard card)

---

### Phase 3 — Slug & Sharing

Currently the shareable link is `/profile/:mongoObjectId` — ugly and reveals internal DB structure.

**Goal:** `codespotlight-hm.web.app/p/harshm`

**Steps:**
1. Add slug claim flow in the Portfolio Editor (check uniqueness via `POST /api/auth/me/slug`)
2. Add `GET /api/portfolio/:slug` route that looks up user by `portfolioSlug` and returns full portfolio data
3. Add `/p/:slug` route in `go_router` config
4. Add copy-to-clipboard share button that produces `https://codespotlight-hm.web.app/p/:slug`
5. Add Open Graph meta tags in `web/index.html` for rich link previews when shared on LinkedIn/Twitter

---

### Phase 4 — Portfolio Editor UX

The editor (`/app/portfolio`) lets the user:
- Write a bio (500 char limit)
- Upload or paste an avatar URL
- Choose a template (with live preview)
- Toggle `portfolioPublished` (hidden vs. public)
- Drag-and-drop repos to set `displayOrder`
- Toggle `isPublicOnPortfolio` per repo
- Toggle `featured` on up to 3 repos (featured appear first in all templates)
- Override the AI description per repo via `customDescription`

---

### Phase 5 — Polish

- **SEO**: Each portfolio page gets unique `<title>`, `<meta description>`, and Open Graph tags generated from the user's name + bio
- **Analytics**: Add a `portfolioViews` counter to the User model (increment on `GET /p/:slug`)
- **Domain**: Optional future feature — users can connect a custom domain (requires CNAME infrastructure)

---

## 5. Environment Variables Reference

Update your Render.com environment settings to include all of the following:

| Variable | Required In | Description |
|----------|-------------|-------------|
| `JWT_SECRET` | Production + Dev | Long random string. Server refuses to start without it. |
| `MONGODB_URI` | Production + Dev | MongoDB Atlas connection string |
| `GEMINI_API_KEY` | Production + Dev | Google AI Studio key |
| `GITHUB_PAT` | Production + Dev | GitHub Personal Access Token (public repo scope) |
| `CLIENT_URL` | **Production only** | Your Firebase Hosting URL. Server refuses to start without it. |
| `ADMIN_SECRET` | Optional | Enables `POST /admin/reanalyze-all`. Disabled if not set. |
| `PORT` | Optional | Defaults to 3000 |
| `NODE_ENV` | Production | Set to `production` on Render |

---

## 6. Files Changed in This Session

### New Files Created
- [`backend/src/controllers/authController.js`](file:///c:/dev/CodeSpotlight/backend/src/controllers/authController.js) — Auth business logic extracted from routes
- [`backend/src/services/analysisQueue.js`](file:///c:/dev/CodeSpotlight/backend/src/services/analysisQueue.js) — In-memory job queue with startup recovery
- [`backend/src/utils/urlValidator.js`](file:///c:/dev/CodeSpotlight/backend/src/utils/urlValidator.js) — SSRF-safe URL validator

### Modified Files
- [`backend/index.js`](file:///c:/dev/CodeSpotlight/backend/index.js) — CORS fix, express.json, queue recovery
- [`backend/src/middleware/authMiddleware.js`](file:///c:/dev/CodeSpotlight/backend/src/middleware/authMiddleware.js) — JWT secret guard
- [`backend/src/models/User.js`](file:///c:/dev/CodeSpotlight/backend/src/models/User.js) — Portfolio builder fields + toJSON password strip
- [`backend/src/models/Project.js`](file:///c:/dev/CodeSpotlight/backend/src/models/Project.js) — userId → ObjectId, indexes, portfolio fields
- [`backend/src/routes/auth.js`](file:///c:/dev/CodeSpotlight/backend/src/routes/auth.js) — Now thin router, delegates to controller
- [`backend/src/routes/projects.js`](file:///c:/dev/CodeSpotlight/backend/src/routes/projects.js) — All 8 backend fixes applied
- [`backend/src/services/geminiService.js`](file:///c:/dev/CodeSpotlight/backend/src/services/geminiService.js) — Exponential backoff
- [`backend/.env.example`](file:///c:/dev/CodeSpotlight/backend/.env.example) — Updated with new vars + production notes
- [`frontend/lib/models/user_model.dart`](file:///c:/dev/CodeSpotlight/frontend/lib/models/user_model.dart) — Cleaned up fromJson parser
- [`frontend/lib/pages/home_page.dart`](file:///c:/dev/CodeSpotlight/frontend/lib/pages/home_page.dart) — Timer generation guard
