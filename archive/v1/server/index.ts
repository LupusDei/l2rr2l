import express from 'express'
import cors from 'cors'
import { initializeDb, seedLessons } from './db/index.js'
import apiRoutes from './routes/api.js'
import voiceRoutes from './routes/voice.js'
import authRoutes from './routes/auth.js'
import childrenRoutes from './routes/children.js'
import onboardingRoutes from './routes/onboarding.js'
import progressRoutes from './routes/progress.js'
import lessonsRoutes from './routes/lessons.js'

initializeDb()
seedLessons()

const app = express()
const PORT = process.env.PORT || 3001

app.use(cors({
  origin: process.env.NODE_ENV === 'production'
    ? false
    : ['http://localhost:5173', 'http://127.0.0.1:5173'],
  credentials: true
}))

app.use(express.json())

app.use('/api', apiRoutes)
app.use('/api/voice', voiceRoutes)
app.use('/api/auth', authRoutes)
app.use('/api/children', childrenRoutes)
app.use('/api/onboarding', onboardingRoutes)
app.use('/api/progress', progressRoutes)
app.use('/api/lessons', lessonsRoutes)

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() })
})

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`)
})
