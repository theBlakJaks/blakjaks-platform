'use client'

import { useState, useEffect } from 'react'

const AGE_KEY = 'blakjaks_age_verified'

export default function AgeGate({ children }: { children: React.ReactNode }) {
  // Start as null (unknown) to avoid a flash of the overlay on verified users
  const [verified, setVerified] = useState<boolean | null>(null)

  useEffect(() => {
    const stored = localStorage.getItem(AGE_KEY)
    setVerified(stored === 'true')
  }, [])

  function handleYes() {
    localStorage.setItem(AGE_KEY, 'true')
    setVerified(true)
  }

  function handleNo() {
    window.location.href = 'https://www.google.com'
  }

  // Still reading localStorage — render nothing to avoid layout shift
  if (verified === null) return null

  if (verified) return <>{children}</>

  return (
    <>
      {/* Full-screen dark overlay */}
      <div
        style={{
          position: 'fixed',
          inset: 0,
          zIndex: 99999,
          backgroundColor: 'rgba(0, 0, 0, 0.92)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '1rem',
        }}
        role="dialog"
        aria-modal="true"
        aria-labelledby="age-gate-heading"
      >
        {/* Modal card */}
        <div
          style={{
            backgroundColor: '#111111',
            border: '1px solid #D4AF37',
            borderRadius: '1rem',
            padding: '2.5rem 2rem',
            maxWidth: '420px',
            width: '100%',
            textAlign: 'center',
            boxShadow: '0 0 60px rgba(212, 175, 55, 0.15)',
          }}
        >
          {/* BlakJaks spade logo mark */}
          <div
            style={{
              fontSize: '3rem',
              lineHeight: 1,
              marginBottom: '1rem',
              color: '#D4AF37',
            }}
            aria-hidden="true"
          >
            &#9824;
          </div>

          {/* Brand name */}
          <p
            style={{
              fontFamily: 'Helvetica, Arial, sans-serif',
              fontWeight: 'bold',
              fontSize: '1.1rem',
              letterSpacing: '0.2em',
              color: '#D4AF37',
              marginBottom: '1.5rem',
              textTransform: 'uppercase',
            }}
          >
            BlakJaks
          </p>

          {/* Question */}
          <h1
            id="age-gate-heading"
            style={{
              fontFamily: 'Helvetica, Arial, sans-serif',
              fontWeight: 'bold',
              fontSize: 'clamp(1.25rem, 4vw, 1.75rem)',
              color: '#FFFFFF',
              marginBottom: '0.75rem',
              lineHeight: 1.2,
            }}
          >
            Are you 21 or older?
          </h1>

          <p
            style={{
              fontFamily: 'Helvetica, Arial, sans-serif',
              fontSize: '0.85rem',
              color: '#9CA3AF',
              marginBottom: '2rem',
              lineHeight: 1.5,
            }}
          >
            You must be 21 years of age or older to enter this site.
            This site sells nicotine products.
          </p>

          {/* Buttons */}
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              gap: '0.75rem',
            }}
          >
            <button
              onClick={handleYes}
              style={{
                backgroundColor: '#D4AF37',
                color: '#000000',
                fontFamily: 'Helvetica, Arial, sans-serif',
                fontWeight: 'bold',
                fontSize: '1rem',
                padding: '0.875rem 1.5rem',
                borderRadius: '0.5rem',
                border: 'none',
                cursor: 'pointer',
                width: '100%',
                letterSpacing: '0.05em',
              }}
            >
              Yes, I am 21+
            </button>

            <button
              onClick={handleNo}
              style={{
                backgroundColor: 'transparent',
                color: '#9CA3AF',
                fontFamily: 'Helvetica, Arial, sans-serif',
                fontWeight: 'bold',
                fontSize: '0.95rem',
                padding: '0.875rem 1.5rem',
                borderRadius: '0.5rem',
                border: '1px solid #374151',
                cursor: 'pointer',
                width: '100%',
                letterSpacing: '0.05em',
              }}
            >
              No
            </button>
          </div>
        </div>
      </div>
    </>
  )
}
