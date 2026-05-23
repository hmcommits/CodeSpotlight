# Portfolio Builder — API Contract

## Endpoints

### `PATCH /api/auth/me/portfolio`
Update the authenticated user's portfolio settings.

**Auth:** Required (Bearer JWT)

**Body:**
```json
{
  "bio": "Full-stack dev obsessed with clean architecture",
  "avatarUrl": "https://avatars.githubusercontent.com/u/...",
  "portfolioTemplate": "minimal" | "grid" | "terminal" | "glassmorphic",
  "portfolioPublished": true
}
```

**Returns:** `{ user }`

---

### `POST /api/auth/me/slug`
Claim a vanity slug for the portfolio URL (e.g. `/p/harshm`).

**Auth:** Required (Bearer JWT)

**Body:**
```json
{ "slug": "harshm" }
```

**Constraints:** 3–30 chars, only `a-z`, `0-9`, `-`, `_`

**Returns:** `{ user }` on success, `409` if slug is already taken

---

### `GET /api/portfolio/:slug`
Fetch a user's published portfolio by their vanity slug.

**Auth:** None (fully public)

**Returns:**
```json
{
  "user": {
    "id": "...",
    "name": "Harsh M",
    "bio": "Full-stack dev...",
    "avatarUrl": "https://...",
    "portfolioTemplate": "grid",
    "portfolioSlug": "harshm",
    "socialLinks": {
      "github": "https://github.com/hmcommits",
      "linkedin": "",
      "twitter": "",
      "portfolio": ""
    },
    "memberSince": "2025-01-01T00:00:00Z"
  },
  "projects": [
    {
      "_id": "...",
      "fullName": "hmcommits/CodeSpotlight",
      "description": "...",
      "primaryLanguage": "Dart",
      "techStack": ["Flutter", "Node.js"],
      "stars": 12,
      "forks": 2,
      "liveUrl": "https://...",
      "aiSummary": "...",
      "featured": true,
      "displayOrder": 0,
      "isPublicOnPortfolio": true,
      "customDescription": ""
    }
  ],
  "stats": {
    "totalRepos": 5,
    "totalStars": 47,
    "totalForks": 8,
    "liveDeployments": 3,
    "aiAnalyzed": 5
  }
}
```

**Notes:**
- Only returns projects where `isPublicOnPortfolio: true`
- Projects sorted by `displayOrder ASC`, then `createdAt DESC`
- Returns `404` if slug not found or `portfolioPublished: false`
