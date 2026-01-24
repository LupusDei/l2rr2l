# L2RR2L Deployment Guide

Deploy L2RR2L (Learn to Read) to Cloudflare Pages with automatic deployment on push to main.

**Target URL:** https://l2r.justinmmartin.me

## Prerequisites

- Node.js 20+
- npm
- Cloudflare account
- GitHub repository access
- ElevenLabs API key (for voice features)

## Architecture

- **Frontend:** Vite + React, deployed as static files to Cloudflare Pages
- **Backend:** Cloudflare Pages Functions (in `/functions` directory)
- **Database:** Cloudflare D1 (SQLite-compatible)

## Step-by-Step Setup

### 1. Install Dependencies

```bash
cd refinery/rig
npm install
```

### 2. Install Wrangler CLI

```bash
npm install -g wrangler
```

### 3. Authenticate with Cloudflare

```bash
wrangler login
```

This opens a browser for OAuth authentication.

### 4. Create Cloudflare D1 Database

```bash
npm run db:create
# or: wrangler d1 create l2rr2l
```

**Important:** Copy the `database_id` from the output and update `wrangler.toml`:

```toml
[[d1_databases]]
binding = "DB"
database_name = "l2rr2l"
database_id = "your-database-id-here"  # <-- Paste here
```

### 5. Run Database Migrations

```bash
# For production (remote D1)
npm run db:migrate

# For local development
npm run db:migrate:local
```

### 6. Configure Environment Variables

#### For Local Development

Copy the example files:

```bash
cp .env.example .env
cp .dev.vars.example .dev.vars
```

Edit `.dev.vars` with your API keys:

```
ELEVENLABS_API_KEY=your_elevenlabs_api_key
JWT_SECRET=your-secret-key-change-in-production
```

#### For Production (Cloudflare Dashboard)

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Navigate to: **Workers & Pages** > **l2rr2l** > **Settings** > **Environment variables**
3. Add these variables:

| Variable | Description |
|----------|-------------|
| `ELEVENLABS_API_KEY` | Your ElevenLabs API key |
| `JWT_SECRET` | Strong random string for JWT signing |
| `ENVIRONMENT` | Set to `production` |

### 7. Configure Custom Domain

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Navigate to: **Workers & Pages** > **l2rr2l** > **Custom domains**
3. Click **Set up a custom domain**
4. Enter: `l2r.justinmmartin.me`
5. Follow DNS configuration prompts

If using Cloudflare for DNS (recommended):
- A CNAME record is automatically created
- SSL certificate is auto-provisioned

If using external DNS:
- Add CNAME: `l2r` → `l2rr2l.pages.dev`

### 8. Set Up GitHub Actions Auto-Deploy

#### Create Cloudflare API Token

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click **Create Token**
3. Use template: **Edit Cloudflare Workers**
4. Or create custom with permissions:
   - Account > Cloudflare Pages > Edit
   - Account > D1 > Edit
5. Copy the token

#### Add GitHub Secrets

1. Go to your GitHub repo > **Settings** > **Secrets and variables** > **Actions**
2. Add these secrets:

| Secret | Value |
|--------|-------|
| `CLOUDFLARE_API_TOKEN` | Your API token from above |
| `CLOUDFLARE_ACCOUNT_ID` | Find in Cloudflare Dashboard URL or sidebar |

The workflow file (`.github/workflows/deploy.yml`) is already configured to deploy on push to `main`.

## Local Development

### Run Frontend Only (with API proxy)

```bash
npm run dev
```

Opens at http://localhost:5173. API calls proxy to Express server.

### Run Express Backend (for local API testing)

```bash
npm run dev:server
```

Runs Express server on http://localhost:3001.

### Run Both Together

```bash
npm run dev:all
```

### Run with Cloudflare Functions Locally

```bash
npm run dev:cf
```

This uses Wrangler to emulate Cloudflare Pages Functions locally.

### Preview Production Build Locally

```bash
npm run build
npm run preview:cf
```

## Manual Deployment

If you need to deploy manually (without GitHub Actions):

```bash
# Build the app
npm run build

# Deploy to Cloudflare Pages
npm run deploy
# or: wrangler pages deploy dist --project-name=l2rr2l
```

## Deployment Verification

After deployment, verify:

1. **Frontend loads:** Visit https://l2r.justinmmartin.me
2. **API works:** Check browser console for errors
3. **Voice features:** Test Spell the Word game audio
4. **Settings:** Verify settings page loads

## Troubleshooting

### "Failed to load settings" Error

- Check if D1 database is created and migrated
- Verify `database_id` in `wrangler.toml` matches your D1 database
- Run migrations: `npm run db:migrate`

### Voice API 503 Error

- Verify `ELEVENLABS_API_KEY` is set in Cloudflare dashboard
- Check ElevenLabs API quota/limits
- Test API key locally first

### Custom Domain Not Working

- Wait 5-10 minutes for DNS propagation
- Verify CNAME record points to `l2rr2l.pages.dev`
- Check Cloudflare dashboard for SSL certificate status

### GitHub Actions Deploy Failing

- Verify `CLOUDFLARE_API_TOKEN` has correct permissions
- Check `CLOUDFLARE_ACCOUNT_ID` is correct
- Review Actions logs for specific error

## Project Structure

```
refinery/rig/
├── .github/workflows/deploy.yml  # Auto-deploy workflow
├── functions/                    # Cloudflare Pages Functions
│   ├── api/                      # API route handlers
│   ├── _middleware.ts            # Request middleware
│   └── types.ts                  # TypeScript types
├── migrations/                   # D1 database migrations
├── src/                          # React frontend
├── wrangler.toml                 # Cloudflare configuration
├── .dev.vars.example             # Local dev environment template
└── .env.example                  # Environment variables template
```

## Useful Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start Vite dev server |
| `npm run dev:cf` | Start with Cloudflare Functions |
| `npm run build` | Build for production |
| `npm run deploy` | Build and deploy to Cloudflare |
| `npm run db:migrate` | Run D1 migrations (production) |
| `npm run db:migrate:local` | Run D1 migrations (local) |
| `wrangler pages deployment list` | List recent deployments |
| `wrangler d1 execute l2rr2l --command "SELECT * FROM users"` | Query D1 |
