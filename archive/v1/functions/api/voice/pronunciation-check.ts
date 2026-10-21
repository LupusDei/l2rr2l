// Pronunciation Check API endpoint
// POST /api/voice/pronunciation-check - Check pronunciation accuracy

interface PronunciationRequest {
  audio: string // base64 encoded audio
  expectedText: string
}

interface Env {
  ELEVENLABS_API_KEY?: string
}

export const onRequestPost: PagesFunction<Env> = async (context) => {
  // For now, pronunciation checking is handled client-side using Web Speech API
  // This endpoint is a placeholder for future server-side pronunciation analysis

  try {
    const body = await context.request.json() as PronunciationRequest

    if (!body.expectedText) {
      return Response.json({ error: 'Expected text is required' }, { status: 400 })
    }

    // Return a message indicating client-side handling
    return Response.json({
      message: 'Pronunciation checking is handled client-side using Web Speech API',
      useClientSide: true
    })
  } catch (error) {
    console.error('Pronunciation check error:', error)
    return Response.json(
      { error: 'Pronunciation check unavailable', useClientSide: true },
      { status: 503 }
    )
  }
}
