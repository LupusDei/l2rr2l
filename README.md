# L2RR2L - Learn to Read, Read to Learn

A web application to teach young kids how to read through engaging, personalized learning experiences.

## Vision

L2RR2L uses best-in-class methodologies for teaching reading:
- **Phonetics** - Sound-based learning with audio feedback
- **Pattern Recognition** - Visual and linguistic patterns
- **Gamification** - Fun challenges and rewards
- **AI-Powered Personalization** - Adapts to each child's learning style
- **Parental Insights** - Progress tracking and recommendations

## Tech Stack

- React + TypeScript (Vite)
- AI/ML for personalization
- Responsive design for tablets and desktop

## Getting Started

```bash
npm install
npm run dev
```

## Environment Variables

Copy `.env.example` to `.env` and configure the required variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `ELEVENLABS_API_KEY` | Yes | API key for voice features (text-to-speech, pronunciation) |
| `XAI_API_KEY` | No | xAI/Grok API key for AI features |
| `ANTHROPIC_API_KEY` | No | Alternative AI provider |
| `JWT_SECRET` | Production | Secret for JWT authentication |
| `PORT` | No | Server port (default: 3001) |
| `NODE_ENV` | No | Environment (development/production) |

## Deployment

### Cloudflare Pages

The frontend is configured for Cloudflare Pages deployment.

**Build settings:**
- Build command: `npm run build`
- Build output directory: `dist`
- Root directory: `/`

**Environment Variables (Cloudflare Dashboard):**

Configure these in Cloudflare Pages > Settings > Environment Variables:

1. **Production variables:**
   - `ELEVENLABS_API_KEY` - Your ElevenLabs API key (encrypt this)
   - `NODE_ENV` - Set to `production`

2. **Optional AI variables:**
   - `XAI_API_KEY` or `ANTHROPIC_API_KEY` - For AI-powered features

Note: The backend server requires separate deployment (e.g., Railway, Render, or Cloudflare Workers).

## License

MIT
