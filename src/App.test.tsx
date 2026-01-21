import { render, screen } from '@testing-library/react'
import App from './App'

describe('App', () => {
  it('renders the app title', () => {
    render(<App />)
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('L2RR2L')
  })

  it('renders the tagline', () => {
    render(<App />)
    expect(screen.getByText('Learn to Read, Read to Learn')).toBeInTheDocument()
  })
})
