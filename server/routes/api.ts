import { Router } from 'express'

const router = Router()

router.get('/', (_req, res) => {
  res.json({ message: 'L2RR2L API', version: '1.0.0' })
})

export default router
