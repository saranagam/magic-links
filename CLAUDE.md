# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- `npm run dev` — start Vite dev server (defaults to http://localhost:5173)
- `npm run build` — production build to `dist/`
- `npm run preview` — serve the built `dist/` locally
- `npm run lint` — ESLint over the repo (flat config in `eslint.config.js`)

There is no test runner configured in this project.

## Environment

The app requires a `.env` (git-ignored) with:

```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=...
```

`.env.example` documents the required keys. If either var is missing, `App.jsx` renders a "Local Development Setup" screen instead of the app rather than crashing.

## Architecture

This is a Supabase-backed URL shortener. Almost the entire application lives in a single component, **`src/App.jsx`** — there is no router, no state library, and no separate backend. `main.jsx` just mounts `<App>`.

**Backend is Supabase only.** The client is created once at module scope (`src/App.jsx`) from the env vars. Two tables are used directly from the browser:
- `urls` — columns `short_code`, `original_url`, `user_id`, `clicks`, `created_at`
- `click_events` — columns `short_code`, `referrer`, `user_agent`, `clicked_at`

**No authentication.** Users are identified by an anonymous UUID generated in `getSessionId()` and stored in `localStorage` (`anon_session_id`). This `user_id` scopes the "My Links" dashboard to the current browser. Anyone can read/write via the anon key, so access rules depend entirely on Supabase Row Level Security.

**Redirection is client-side.** On load, an effect reads `window.location.pathname`; a non-empty path (e.g. `/aB3x9`) is treated as a `short_code`. It looks the code up in `urls`, increments `clicks`, inserts a `click_events` row (capturing `document.referrer` and `navigator.userAgent`), then sets `window.location.href` to the original URL. This is why `vercel.json` rewrites **all** routes to `/index.html` — the SPA must load for any path so it can resolve the short code. Locally, `vite preview`/`dev` serve `index.html` for unknown paths similarly.

**UI is a two-tab SPA** driven by `activeTab` state (`"shorten"` | `"dashboard"`): the shorten form and the "My Links" table. Short codes are 6-char random alphanumeric (`generateShortCode`). `simulateRedirect` is the in-app "test link" path that increments clicks without a full navigation.

**Styling is Tailwind via CDN**, loaded from `<script src="https://cdn.tailwindcss.com">` in `index.html`. There is no Tailwind/PostCSS build step or config — utility classes are interpreted at runtime in the browser. `src/index.css` and `src/App.css` hold only minor supplemental styles.

**Analytics helpers** in `App.jsx`: `formatReferrer` maps known referrer hostnames to friendly labels, and `getReferrerColor` maps those labels to Tailwind color classes for badges.

## Deployment

Deployed on Vercel. `vercel.json` provides the SPA rewrite that makes short-code URLs work in production.

## Notes

- `update_dashboard.cjs` and `comment_dashboard.cjs` are one-off codemod scripts that toggle feature blocks in `App.jsx` by string replacement. They are stale (they reference sections no longer present) and are not part of the build or lint pipeline — treat them as dev scratch, not tooling.
