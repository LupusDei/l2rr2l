// Lessons API endpoint
// GET /api/lessons - Get list of lessons

interface Lesson {
  id: string
  title: string
  subject: string
  difficulty: number
  duration: number
  description: string
}

// Sample lessons data
const SAMPLE_LESSONS: Lesson[] = [
  {
    id: 'lesson-1',
    title: 'Letter Sounds A-F',
    subject: 'phonics',
    difficulty: 1,
    duration: 10,
    description: 'Learn the sounds of letters A through F'
  },
  {
    id: 'lesson-2',
    title: 'Letter Sounds G-L',
    subject: 'phonics',
    difficulty: 1,
    duration: 10,
    description: 'Learn the sounds of letters G through L'
  },
  {
    id: 'lesson-3',
    title: 'Simple Words',
    subject: 'reading',
    difficulty: 1,
    duration: 15,
    description: 'Read simple three-letter words'
  },
  {
    id: 'lesson-4',
    title: 'Sight Words Set 1',
    subject: 'sight-words',
    difficulty: 1,
    duration: 10,
    description: 'Learn common sight words: the, a, is, it, to'
  },
  {
    id: 'lesson-5',
    title: 'Rhyming Words',
    subject: 'phonics',
    difficulty: 2,
    duration: 12,
    description: 'Find words that rhyme with each other'
  }
]

export const onRequestGet: PagesFunction = async (context) => {
  const url = new URL(context.request.url)
  const subject = url.searchParams.get('subject')
  const difficulty = url.searchParams.get('difficulty')

  let lessons = [...SAMPLE_LESSONS]

  if (subject) {
    lessons = lessons.filter(l => l.subject === subject)
  }

  if (difficulty) {
    const diffNum = parseInt(difficulty, 10)
    if (!isNaN(diffNum)) {
      lessons = lessons.filter(l => l.difficulty === diffNum)
    }
  }

  return Response.json({ lessons })
}
