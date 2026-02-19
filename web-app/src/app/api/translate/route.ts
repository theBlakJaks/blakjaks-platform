import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  const { text, targetLang = 'en' } = await request.json()

  if (!text) {
    return NextResponse.json({ error: 'Missing text' }, { status: 400 })
  }

  const apiKey = process.env.GOOGLE_TRANSLATE_API_KEY
  if (!apiKey) {
    return NextResponse.json({ error: 'Translation API not configured' }, { status: 500 })
  }

  const url = `https://translation.googleapis.com/language/translate/v2?key=${apiKey}`

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      q: text,
      target: targetLang,
      format: 'text',
    }),
  })

  if (!res.ok) {
    const err = await res.text()
    return NextResponse.json({ error: 'Translation failed', details: err }, { status: 500 })
  }

  const data = await res.json()
  const translation = data.data.translations[0]

  return NextResponse.json({
    translatedText: translation.translatedText,
    detectedLanguage: translation.detectedSourceLanguage,
  })
}
