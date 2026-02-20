import type { Metadata } from 'next'
import { AuthProvider } from '@/lib/auth-context'
import AgeGate from '@/components/AgeGate'
import './globals.css'

export const metadata: Metadata = {
  title: 'BlakJaks',
  description: 'The future of nicotine pouches - premium quality, blockchain-verified transparency',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className="antialiased">
        <AuthProvider>
          <AgeGate>
            {children}
          </AgeGate>
        </AuthProvider>
      </body>
    </html>
  )
}
