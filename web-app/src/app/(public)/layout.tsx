'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Menu, X } from 'lucide-react'
import Logo from '@/components/ui/Logo'
import GoldButton from '@/components/ui/GoldButton'
import { cn } from '@/lib/utils'

const navLinks = [
  { href: '/', label: 'Home' },
  { href: '/about', label: 'About' },
  { href: '/transparency', label: 'Transparency' },
]

export default function PublicLayout({ children }: { children: React.ReactNode }) {
  const [mobileOpen, setMobileOpen] = useState(false)
  const pathname = usePathname()

  return (
    <div className="min-h-screen flex flex-col">
      {/* Header */}
      <header className="sticky top-0 z-40 border-b border-[var(--color-border)] bg-[var(--color-bg)]/95 backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <Link href="/">
            <Logo size="md" />
          </Link>

          {/* Desktop Nav */}
          <nav className="hidden md:flex items-center gap-8">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={cn(
                  'text-sm font-medium transition-colors',
                  pathname === link.href ? 'text-[var(--color-gold)]' : 'text-[var(--color-text-muted)] hover:text-white',
                )}
              >
                {link.label}
              </Link>
            ))}
          </nav>

          {/* Desktop Auth Buttons */}
          <div className="hidden md:flex items-center gap-3">
            <Link href="/login">
              <GoldButton variant="ghost" size="sm">Log In</GoldButton>
            </Link>
            <Link href="/signup">
              <GoldButton size="sm">Sign Up</GoldButton>
            </Link>
          </div>

          {/* Mobile Menu Button */}
          <button
            className="md:hidden p-2 text-[var(--color-text-muted)] hover:text-white"
            onClick={() => setMobileOpen(!mobileOpen)}
          >
            {mobileOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>

        {/* Mobile Menu */}
        {mobileOpen && (
          <div className="md:hidden border-t border-[var(--color-border)] bg-[var(--color-bg)]">
            <nav className="flex flex-col gap-1 p-4">
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  onClick={() => setMobileOpen(false)}
                  className={cn(
                    'rounded-lg px-4 py-2.5 text-sm font-medium transition-colors',
                    pathname === link.href ? 'text-[var(--color-gold)] bg-[var(--color-gold)]/10' : 'text-[var(--color-text-muted)] hover:bg-[var(--color-bg-hover)]',
                  )}
                >
                  {link.label}
                </Link>
              ))}
              <div className="mt-4 flex flex-col gap-2 border-t border-[var(--color-border)] pt-4">
                <Link href="/login" onClick={() => setMobileOpen(false)}>
                  <GoldButton variant="secondary" fullWidth>Log In</GoldButton>
                </Link>
                <Link href="/signup" onClick={() => setMobileOpen(false)}>
                  <GoldButton fullWidth>Sign Up</GoldButton>
                </Link>
              </div>
            </nav>
          </div>
        )}
      </header>

      {/* Main Content */}
      <main className="flex-1">{children}</main>

      {/* Footer */}
      <footer className="border-t border-[var(--color-border)] bg-[var(--color-bg-card)]">
        <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 gap-8 md:grid-cols-5">
            <div className="col-span-2 md:col-span-1">
              <Logo size="sm" />
              <p className="mt-3 text-sm text-[var(--color-text-dim)]">
                Premium nicotine pouches with blockchain-verified transparency.
              </p>
            </div>
            <div>
              <h4 className="text-sm font-semibold text-white mb-3">Product</h4>
              <ul className="space-y-2 text-sm text-[var(--color-text-dim)]">
                <li><Link href="/about" className="hover:text-white transition-colors">Flavors</Link></li>
                <li><Link href="/transparency" className="hover:text-white transition-colors">Transparency</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="text-sm font-semibold text-white mb-3">Company</h4>
              <ul className="space-y-2 text-sm text-[var(--color-text-dim)]">
                <li><Link href="/about" className="hover:text-white transition-colors">About</Link></li>
                <li><Link href="/about" className="hover:text-white transition-colors">Careers</Link></li>
                <li><Link href="/about" className="hover:text-white transition-colors">Press</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="text-sm font-semibold text-white mb-3">Legal</h4>
              <ul className="space-y-2 text-sm text-[var(--color-text-dim)]">
                <li><Link href="/about" className="hover:text-white transition-colors">Privacy</Link></li>
                <li><Link href="/about" className="hover:text-white transition-colors">Terms</Link></li>
                <li><Link href="/about" className="hover:text-white transition-colors">Age Policy</Link></li>
              </ul>
            </div>
            <div>
              <h4 className="text-sm font-semibold text-white mb-3">Social</h4>
              <ul className="space-y-2 text-sm text-[var(--color-text-dim)]">
                <li><a href="#" className="hover:text-white transition-colors">Twitter</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Discord</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Instagram</a></li>
              </ul>
            </div>
          </div>
          <div className="mt-8 border-t border-[var(--color-border)] pt-8 text-center text-xs text-[var(--color-text-dim)]">
            &copy; {new Date().getFullYear()} BlakJaks. All rights reserved.
          </div>
        </div>
      </footer>
    </div>
  )
}
