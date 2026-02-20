const WARNING_TEXT =
  'WARNING: This product contains nicotine. Nicotine is an addictive chemical.'

export default function NicotineWarningBanner() {
  return (
    <div
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        height: '20vh',
        backgroundColor: '#000000',
        color: '#FFFFFF',
        fontFamily: 'Helvetica, Arial, sans-serif',
        fontWeight: 'bold',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        textAlign: 'center',
        padding: '0 1rem',
        zIndex: 9999,
        fontSize: 'clamp(0.6rem, 2.5vw, 2rem)',
        lineHeight: 1.2,
        boxSizing: 'border-box',
      }}
      role="alert"
      aria-live="polite"
    >
      <span
        style={{
          display: 'block',
          maxWidth: '100%',
          overflow: 'hidden',
        }}
      >
        {WARNING_TEXT}
      </span>
    </div>
  )
}
