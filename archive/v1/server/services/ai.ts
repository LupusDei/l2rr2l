import { randomUUID } from 'crypto'

export interface ChildProfile {
  name: string
  age: number | null
  gradeLevel: string | null
  learningStyle: string | null
  interests: string[] | null
}

export interface GeneratedLesson {
  id: string
  title: string
  subject: string
  gradeLevel: string
  difficulty: string
  durationMinutes: number
  objectives: string[]
  activities: Activity[]
  materials: string[]
  assessmentCriteria: string[]
  source: 'ai-generated'
}

export interface Activity {
  step: number
  title: string
  instructions: string
  durationMinutes: number
  type: 'introduction' | 'practice' | 'assessment' | 'wrap-up'
}

export interface LessonGenerationRequest {
  childProfile: ChildProfile
  subject: string
  topic?: string
  preferredDuration?: number
}

const SUPPORTED_SUBJECTS = ['reading', 'math', 'science', 'writing', 'art', 'music', 'social-studies']

function buildPrompt(request: LessonGenerationRequest): string {
  const { childProfile, subject, topic, preferredDuration } = request
  const duration = preferredDuration || 30

  const ageContext = childProfile.age
    ? `The child is ${childProfile.age} years old.`
    : ''

  const gradeContext = childProfile.gradeLevel
    ? `They are in ${childProfile.gradeLevel}.`
    : ''

  const learningStyleContext = childProfile.learningStyle
    ? `Their preferred learning style is ${childProfile.learningStyle} (consider visual, auditory, or kinesthetic approaches accordingly).`
    : ''

  const interestsContext = childProfile.interests?.length
    ? `Their interests include: ${childProfile.interests.join(', ')}. Try to incorporate these interests where relevant.`
    : ''

  const topicContext = topic
    ? `The lesson should focus on: ${topic}`
    : `Generate an age-appropriate ${subject} lesson.`

  return `You are an expert educational curriculum designer. Create a personalized lesson plan for a child.

Child Profile:
- Name: ${childProfile.name}
${ageContext}
${gradeContext}
${learningStyleContext}
${interestsContext}

Subject: ${subject}
${topicContext}
Target Duration: ${duration} minutes

Please generate a complete lesson plan in the following JSON format:
{
  "title": "Engaging lesson title",
  "subject": "${subject}",
  "gradeLevel": "appropriate grade level",
  "difficulty": "easy|medium|hard",
  "durationMinutes": ${duration},
  "objectives": ["Learning objective 1", "Learning objective 2", "Learning objective 3"],
  "activities": [
    {
      "step": 1,
      "title": "Activity title",
      "instructions": "Detailed instructions for the parent/teacher",
      "durationMinutes": 5,
      "type": "introduction|practice|assessment|wrap-up"
    }
  ],
  "materials": ["Material 1", "Material 2"],
  "assessmentCriteria": ["How to know the child understood concept 1", "Success indicator 2"]
}

Requirements:
- Make activities engaging and age-appropriate
- Include a mix of activity types
- Keep instructions clear for parents who may not be teachers
- Ensure objectives are measurable
- Materials should be commonly available at home

Return ONLY the JSON object, no additional text.`
}

async function callGrokAPI(prompt: string): Promise<string> {
  const apiKey = process.env.XAI_API_KEY || process.env.GROK_API_KEY

  if (!apiKey) {
    throw new Error('XAI_API_KEY or GROK_API_KEY environment variable is required')
  }

  const response = await fetch('https://api.x.ai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model: 'grok-2-latest',
      messages: [
        { role: 'system', content: 'You are an expert educational curriculum designer. Always respond with valid JSON only.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.7,
      max_tokens: 2000
    })
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Grok API error: ${response.status} - ${error}`)
  }

  const data = await response.json() as { choices: Array<{ message: { content: string } }> }
  return data.choices[0]?.message?.content || ''
}

async function callClaudeAPI(prompt: string): Promise<string> {
  const apiKey = process.env.ANTHROPIC_API_KEY

  if (!apiKey) {
    throw new Error('ANTHROPIC_API_KEY environment variable is required')
  }

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01'
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 2000,
      messages: [
        { role: 'user', content: prompt }
      ]
    })
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Claude API error: ${response.status} - ${error}`)
  }

  const data = await response.json() as { content: Array<{ type: string, text: string }> }
  const textBlock = data.content.find(block => block.type === 'text')
  return textBlock?.text || ''
}

function parseAIResponse(response: string): Omit<GeneratedLesson, 'id' | 'source'> {
  // Extract JSON from response (handles markdown code blocks)
  let jsonStr = response.trim()

  // Remove markdown code fences if present
  if (jsonStr.startsWith('```')) {
    jsonStr = jsonStr.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '')
  }

  const parsed = JSON.parse(jsonStr)

  // Validate required fields
  if (!parsed.title || !parsed.subject || !parsed.objectives || !parsed.activities) {
    throw new Error('Invalid lesson format: missing required fields')
  }

  return {
    title: parsed.title,
    subject: parsed.subject,
    gradeLevel: parsed.gradeLevel || 'unspecified',
    difficulty: parsed.difficulty || 'medium',
    durationMinutes: parsed.durationMinutes || 30,
    objectives: parsed.objectives,
    activities: parsed.activities.map((a: Activity, idx: number) => ({
      step: a.step || idx + 1,
      title: a.title,
      instructions: a.instructions,
      durationMinutes: a.durationMinutes || 5,
      type: a.type || 'practice'
    })),
    materials: parsed.materials || [],
    assessmentCriteria: parsed.assessmentCriteria || []
  }
}

export type AIProvider = 'grok' | 'claude'

export async function generateLesson(
  request: LessonGenerationRequest,
  provider: AIProvider = 'grok'
): Promise<GeneratedLesson> {
  // Validate subject
  if (!SUPPORTED_SUBJECTS.includes(request.subject.toLowerCase())) {
    throw new Error(`Unsupported subject: ${request.subject}. Supported: ${SUPPORTED_SUBJECTS.join(', ')}`)
  }

  const prompt = buildPrompt(request)

  let response: string
  if (provider === 'claude') {
    response = await callClaudeAPI(prompt)
  } else {
    response = await callGrokAPI(prompt)
  }

  const lessonData = parseAIResponse(response)

  return {
    id: randomUUID(),
    ...lessonData,
    source: 'ai-generated'
  }
}

export function getSupportedSubjects(): string[] {
  return [...SUPPORTED_SUBJECTS]
}
