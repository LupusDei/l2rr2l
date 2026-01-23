/**
 * Authentication utilities for Cloudflare Functions
 */

import jwt from 'jsonwebtoken'
import type { Env } from '../../../types'

const JWT_EXPIRES_IN = '7d'

export interface JwtPayload {
  userId: string
  email: string
}

/**
 * Get JWT secret from environment
 */
function getJwtSecret(env: Env): string {
  return env.JWT_SECRET || 'dev-secret-change-in-production'
}

/**
 * Generate a JWT token
 */
export function generateToken(payload: JwtPayload, env: Env): string {
  return jwt.sign(payload, getJwtSecret(env), { expiresIn: JWT_EXPIRES_IN })
}

/**
 * Verify a JWT token
 */
export function verifyToken(token: string, env: Env): JwtPayload {
  return jwt.verify(token, getJwtSecret(env)) as JwtPayload
}

/**
 * Extract and verify user from Authorization header
 * Returns null if no valid auth header or token
 */
export function getUserFromRequest(request: Request, env: Env): JwtPayload | null {
  const authHeader = request.headers.get('Authorization')

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null
  }

  const token = authHeader.slice(7)

  try {
    return verifyToken(token, env)
  } catch {
    return null
  }
}

/**
 * Require authentication - returns error response or user payload
 */
export function requireAuth(
  request: Request,
  env: Env
): { user: JwtPayload } | { error: Response } {
  const user = getUserFromRequest(request, env)

  if (!user) {
    return {
      error: new Response(
        JSON.stringify({ error: 'Authorization required' }),
        {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        }
      ),
    }
  }

  return { user }
}
