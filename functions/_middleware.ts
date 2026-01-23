/**
 * Cloudflare Pages Functions middleware
 * Handles CORS and health check
 */

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
}

export const onRequest: PagesFunction = async (context) => {
  const { request } = context
  const url = new URL(request.url)

  // Handle CORS preflight for all routes
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    })
  }

  // Health check endpoint
  if (url.pathname === '/health') {
    return new Response(
      JSON.stringify({
        status: 'ok',
        timestamp: new Date().toISOString(),
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      }
    )
  }

  // Continue to the next handler
  const response = await context.next()

  // Add CORS headers to response
  const newResponse = new Response(response.body, response)
  for (const [key, value] of Object.entries(corsHeaders)) {
    newResponse.headers.set(key, value)
  }

  return newResponse
}
