import './App.css'

function App() {
  return (
    <div className="app homescreen">
      {/* Decorative floating elements */}
      <div className="decorations" aria-hidden="true">
        <span className="decoration crayon crayon-red">&#9998;</span>
        <span className="decoration crayon crayon-blue">&#9998;</span>
        <span className="decoration crayon crayon-yellow">&#9998;</span>
        <span className="decoration letter letter-a">A</span>
        <span className="decoration letter letter-b">B</span>
        <span className="decoration letter letter-c">C</span>
        <span className="decoration paint paint-splash-1"></span>
        <span className="decoration paint paint-splash-2"></span>
        <span className="decoration star star-1">&#9733;</span>
        <span className="decoration star star-2">&#9733;</span>
      </div>

      <main className="main homescreen-content">
        <div className="logo-container">
          <h1 className="logo">
            <span className="logo-letter logo-l1">L</span>
            <span className="logo-letter logo-2">2</span>
            <span className="logo-letter logo-r1">R</span>
            <span className="logo-letter logo-r2">R</span>
            <span className="logo-letter logo-2b">2</span>
            <span className="logo-letter logo-l2">L</span>
          </h1>
        </div>

        <p className="tagline">Learn to Read, Read to Learn!</p>

        <button className="cta-button" type="button">
          Get Started!
        </button>
      </main>
    </div>
  )
}

export default App
