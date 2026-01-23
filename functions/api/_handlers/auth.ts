/**
 * Auth handler for Cloudflare Functions
 * Handles /api/auth/* routes
 */

import bcrypt from 'bcryptjs'
import type { Env } from '../../types'
import { jsonResponse, errorResponse } from '../[[path]]'
import { generateToken, requireAuth } from './utils/auth'

interface UserRow {
  id: string
  email: string
  password_hash: string
  name: string
  created_at: string
  updated_at: string
}

/**
 * Handle auth routes
 */
export async function handleAuth(
  request: Request,
  env: Env,
  pathSegments: string[]
): Promise<Response> {
  const action = pathSegments[0] || ''

  switch (action) {
    case 'register':
      if (request.method === 'POST') {
        return await handleRegister(request, env)
      }
      break

    case 'login':
      if (request.method === 'POST') {
        return await handleLogin(request, env)
      }
      break

    case 'me':
      if (request.method === 'GET') {
        return await handleMe(request, env)
      }
      break
  }

  return errorResponse('Method not allowed', 405)
}

/**
 * POST /api/auth/register
 */
async function handleRegister(request: Request, env: Env): Promise<Response> {
  const body = await request.json() as { email?: string; password?: string; name?: string }
  const { email, password, name } = body

  if (!email || !password || !name) {
    return errorResponse('Email, password, and name are required', 400)
  }

  // Check if email exists
  const existing = await env.DB.prepare(
    'SELECT id FROM users WHERE email = ?'
  ).bind(email).first<{ id: string }>()

  if (existing) {
    return errorResponse('Email already registered', 409)
  }

  // Hash password and create user
  const id = crypto.randomUUID()
  const passwordHash = await bcrypt.hash(password, 10)

  await env.DB.prepare(
    'INSERT INTO users (id, email, password_hash, name) VALUES (?, ?, ?, ?)'
  ).bind(id, email, passwordHash, name).run()

  const token = generateToken({ userId: id, email }, env)

  return jsonResponse(
    {
      user: { id, email, name },
      token,
    },
    201
  )
}

/**
 * POST /api/auth/login
 */
async function handleLogin(request: Request, env: Env): Promise<Response> {
  const body = await request.json() as { email?: string; password?: string }
  const { email, password } = body

  if (!email || !password) {
    return errorResponse('Email and password are required', 400)
  }

  const user = await env.DB.prepare(
    'SELECT * FROM users WHERE email = ?'
  ).bind(email).first<UserRow>()

  if (!user) {
    return errorResponse('Invalid credentials', 401)
  }

  const validPassword = await bcrypt.compare(password, user.password_hash)
  if (!validPassword) {
    return errorResponse('Invalid credentials', 401)
  }

  const token = generateToken({ userId: user.id, email: user.email }, env)

  return jsonResponse({
    user: { id: user.id, email: user.email, name: user.name },
    token,
  })
}

/**
 * GET /api/auth/me
 */
async function handleMe(request: Request, env: Env): Promise<Response> {
  const authResult = requireAuth(request, env)
  if ('error' in authResult) {
    return authResult.error
  }

  const user = await env.DB.prepare(
    'SELECT id, email, name, created_at FROM users WHERE id = ?'
  ).bind(authResult.user.userId).first<Omit<UserRow, 'password_hash' | 'updated_at'>>()

  if (!user) {
    return errorResponse('User not found', 404)
  }

  return jsonResponse({ user })
}
