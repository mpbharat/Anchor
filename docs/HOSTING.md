# Hosting the Anchor backend (for Merlin)

**Host: Render (Web Service).** Our API is a long-running Node/Express server, which Render runs as-is. Do NOT use Cloudflare Workers for this — Workers is a non-Node isolate runtime and would need the whole API rewritten to Hono. (Cloudflare Pages is only for the Flutter web build, if we host that at all.)

Verified locally: `npm run build` → `dist/index.js`; `npm start` runs it; health at `GET /health`; the server reads `PORT` from the environment (Render injects it).

## Render setup (5 minutes)

1. Render dashboard → **New → Web Service** → connect the GitHub repo `mpbharat/Anchor`.
2. Settings:
   - **Root Directory:** `backend`
   - **Runtime:** Node
   - **Build Command:** `npm install && npm run build`
   - **Start Command:** `npm start`
   - **Health Check Path:** `/health`
   - Node version: repo declares `engines.node >=20`; if Render defaults lower, add env var `NODE_VERSION=20`.
3. Add the environment variables below (Render → Environment). Values are in Bharat's gitignored `backend/.env` — get them from Bharat, do not commit them.
4. Deploy. When it's green, `GET https://<your-service>.onrender.com/health` returns `{"status":"ok"}`.

## Environment variables (names — values from Bharat)

```
OPENAI_API_KEY
OPENAI_BASE_URL          = https://api.openai.com/v1
OPENAI_MODEL             = gpt-4o-mini
OPENROUTER_API_KEY
OPENROUTER_BASE_URL      = https://openrouter.ai/api/v1
EXA_API_KEY
SUPABASE_URL             = https://kdpgslmbvyybulgashxz.supabase.co
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
```

Do NOT set `PORT` — Render provides it and the server already reads it.

## Notes

- **Cold starts:** Render's free tier spins the service down after ~15 min idle, so the first request after idle takes ~50s. For the live demo, hit `/health` a minute before, or use a paid instance to keep it warm.
- **CORS** is open (`cors()`), so the Flutter app can call it from anywhere for the demo.
- **Python integrations** (Maria's extraction + Google read layer) can run as a separate Render service (Runtime: Python, root `integrations`) if we need it hosted; for the demo it can also run locally producing payloads. Decide based on the demo flow.
- After the event: rotate all keys (they were shared over chat).

---

## Info website (Cloudflare Pages) — LIVE

**Live URL:** https://anchor-4zt.pages.dev  (landing at `/`, live app embed at `/app/`)

Neobrutalist landing page (`site/index.html`) with the real Flutter web build embedded in a phone frame. Deployed via wrangler direct upload (project `anchor`).

### Rebuild + redeploy
```bash
# 1. rebuild the web app under /app/
cd app && flutter build web --base-href "/app/" --release && cd ..
# 2. refresh the copy the site serves
rm -rf site/app && mkdir -p site/app && cp -R app/build/web/. site/app/
# 3. deploy (needs .env.cloudflare with CLOUDFLARE_API_TOKEN + CLOUDFLARE_ACCOUNT_ID)
set -a; . ./.env.cloudflare; set +a
npx wrangler pages deploy site --project-name=anchor --branch=main --commit-dirty=true
```

`site/app/` is gitignored (generated). `site/index.html` is the source of the landing page.
Before submitting: drop the Loom/YouTube embed into the `#video` block in `site/index.html`.
