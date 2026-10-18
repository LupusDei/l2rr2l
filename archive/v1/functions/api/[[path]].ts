/**
 * Cloudflare Pages Functions - API catch-all handler
 *
 * This handles all /api/* routes, mirroring the Express backend structure.
 * Routes are dispatched based on the URL path.
 */

import type { Env } from '../types'
import { handleAuth } from './_handlers/auth'
import { handleVoice } from './_handlers/voice'
import { handleChildren } from './_handlers/children'
import { handleLessons } from './_handlers/lessons'
import { handleProgress } from './_handlers/progress'
import { handleOnboarding } from './_handlers/onboarding'
import { handleVoiceSettings } from './_handlers/voice-settings'

// CORS headers for development
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
}

/**
 * Handle OPTIONS preflight requests
 */
function handleOptions(): Response {
  return new Response(null, {
    status: 204,
    headers: corsHeaders,
  })
}

/**
 * Create a JSON response with CORS headers
 */
export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
    },
  })
}

/**
 * Create an error response
 */
export function errorResponse(error: string, status = 500): Response {
  return jsonResponse({ error }, status)
}

/**
 * Normalize path parameter to array
 */
function normalizePath(path: string | string[] | undefined): string[] {
  if (!path) return []
  if (Array.isArray(path)) return path
  return [path]
}

/**
 * Main API handler - routes requests to appropriate handlers
 */
export const onRequest: PagesFunction<Env> = async (context) => {
  const { request, env, params } = context

  // Handle CORS preflight
  if (request.method === 'OPTIONS') {
    return handleOptions()
  }

  // Get the path segments after /api/
  const pathSegments = normalizePath(params.path)
  const basePath = pathSegments[0] || ''

  try {
    // Route to appropriate handler based on first path segment
    switch (basePath) {
      case '':
        // GET /api/ - API info
        if (request.method === 'GET') {
          return jsonResponse({ message: 'L2RR2L API', version: '1.0.0' })
        }
        break

      case 'auth':
        return await handleAuth(request, env, pathSegments.slice(1))

      case 'voice':
        // Check if it's voice settings or voice API
        if (pathSegments[1] === 'settings') {
          return await handleVoiceSettings(request, env, pathSegments.slice(2))
        }
        return await handleVoice(request, env, pathSegments.slice(1))

      case 'children':
        return await handleChildren(request, env, pathSegments.slice(1))

      case 'lessons':
        return await handleLessons(request, env, pathSegments.slice(1))

      case 'progress':
        return await handleProgress(request, env, pathSegments.slice(1))

      case 'onboarding':
        return await handleOnboarding(request, env, pathSegments.slice(1))
    }

    // If we get here, the route wasn't found
    return errorResponse('Not found', 404)

  } catch (error) {
    console.error('API error:', error)
    return errorResponse(
      error instanceof Error ? error.message : 'Internal server error',
      500
    )
  }
}
