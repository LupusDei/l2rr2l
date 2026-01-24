// Lesson Subjects API endpoint
// GET /api/lessons/subjects - Get list of available subjects

interface Subject {
  id: string
  name: string
  icon: string
  color: string
}

const SUBJECTS: Subject[] = [
  {
    id: 'phonics',
    name: 'Phonics',
    icon: '🔤',
    color: '#4CAF50'
  },
  {
    id: 'reading',
    name: 'Reading',
    icon: '📖',
    color: '#2196F3'
  },
  {
    id: 'sight-words',
    name: 'Sight Words',
    icon: '👀',
    color: '#9C27B0'
  },
  {
    id: 'spelling',
    name: 'Spelling',
    icon: '✏️',
    color: '#FF9800'
  }
]

export const onRequestGet: PagesFunction = async () => {
  return Response.json({ subjects: SUBJECTS })
}
