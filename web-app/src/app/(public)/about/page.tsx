'use client'

import Link from 'next/link'
import { Shield, Users, Coins, Heart, Mail, ExternalLink, Scan, TrendingUp, Zap, Globe } from 'lucide-react'
import GoldButton from '@/components/ui/GoldButton'
import Card from '@/components/ui/Card'

const values = [
  {
    icon: Shield,
    title: 'Radical Transparency',
    description: 'Every dollar in our treasury is publicly verifiable on the Polygon blockchain. Our Transparency Dashboard shows live balances, scan counts, and comp payouts in real time. We have nothing to hide.',
  },
  {
    icon: Users,
    title: 'Community First',
    description: 'BlakJaks members govern key decisions through on-chain voting. From new flavors to comp rate adjustments, the community has a real voice. This is your brand, not just ours.',
  },
  {
    icon: Coins,
    title: 'Real Rewards',
    description: 'No points, no gimmicks. We pay real USDT cryptocurrency directly to your wallet. Withdraw anytime, no minimum balance. Your loyalty earns you real money.',
  },
  {
    icon: Heart,
    title: 'Fair Play',
    description: 'Our tiered comp system rewards every member at every level. Whether you scan 1 tin or 100, you earn. Higher tiers unlock bigger prizes, but everyone gets paid.',
  },
]

const howItWorksSteps = [
  {
    icon: Scan,
    title: 'Proof of Purchase',
    description: 'Every BlakJaks tin contains a unique POP (Proof of Purchase) QR code. This code is cryptographically generated and single-use, ensuring each scan is authentic and verified.',
  },
  {
    icon: Coins,
    title: 'Instant Comps',
    description: 'When you scan a POP code, our system verifies it on-chain and immediately sends your USDT comp to your BlakJaks wallet. Comps are funded from our transparent treasury pools.',
  },
  {
    icon: TrendingUp,
    title: 'Tier Progression',
    description: 'Your quarterly scan count determines your tier: Standard, VIP, High Roller, or Whale. Higher tiers unlock larger per-scan comps, monthly bonuses, exclusive channels, and comp prize eligibility up to $200,000.',
  },
  {
    icon: Zap,
    title: 'Withdraw Anytime',
    description: 'Your USDT balance is always yours. Withdraw to any Polygon-compatible wallet at any time. No lock-ups, no waiting periods, no minimum balance requirements.',
  },
]

export default function AboutPage() {
  return (
    <div>
      {/* ── Hero ── */}
      <section className="relative py-24 sm:py-32 px-4 sm:px-6 lg:px-8">
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute top-1/3 left-1/4 w-96 h-96 bg-[#D4AF37]/5 rounded-full blur-3xl" />
        </div>
        <div className="relative max-w-4xl mx-auto text-center">
          <span className="inline-flex items-center gap-2 rounded-full border border-[#D4AF37]/30 bg-[#D4AF37]/10 px-4 py-1.5 text-sm font-medium text-[#D4AF37] mb-8">
            Our Story
          </span>
          <h1 className="text-4xl sm:text-5xl md:text-6xl font-black text-white mb-6 leading-tight">
            THE HOUSE ALWAYS <span className="gold-gradient-text">PAYS</span>
          </h1>
          <p className="text-lg sm:text-xl text-[var(--color-text-muted)] max-w-3xl mx-auto leading-relaxed">
            BlakJaks was born from a simple question: what if a nicotine pouch brand actually rewarded its customers instead of just taking their money? We built the answer on the blockchain.
          </p>
        </div>
      </section>

      {/* ── Brand Story ── */}
      <section className="py-16 sm:py-24 px-4 sm:px-6 lg:px-8 bg-[var(--color-bg-card)]/50">
        <div className="max-w-4xl mx-auto">
          <div className="grid md:grid-cols-2 gap-12 items-center">
            <div>
              <h2 className="text-3xl sm:text-4xl font-black text-white mb-6">
                OUR <span className="gold-gradient-text">ORIGIN</span>
              </h2>
              <div className="space-y-4 text-[var(--color-text-muted)] leading-relaxed">
                <p>
                  In 2024, a group of nicotine pouch enthusiasts and blockchain engineers came together with a shared frustration: loyalty programs that offer worthless points and broken promises.
                </p>
                <p>
                  We asked ourselves: what if every purchase was verified on-chain? What if rewards were real cryptocurrency you could withdraw instantly? What if the entire treasury was transparent and publicly auditable?
                </p>
                <p>
                  BlakJaks is the result. A premium nicotine pouch brand where every tin you buy earns you real USDT, every dollar in our treasury is publicly visible, and every major decision is made by the community.
                </p>
              </div>
            </div>
            <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-8">
              <div className="text-center">
                <div className="text-7xl mb-4">&#9824;</div>
                <h3 className="text-2xl font-black text-white mb-2">BLAK<span className="gold-gradient-text">JAKS</span></h3>
                <p className="text-sm text-[var(--color-text-dim)] mb-6">Est. 2024</p>
                <div className="space-y-4">
                  <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
                    <p className="text-2xl font-bold gold-gradient-text">24,891+</p>
                    <p className="text-xs text-[var(--color-text-dim)]">Active Members</p>
                  </div>
                  <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
                    <p className="text-2xl font-bold gold-gradient-text">847,523</p>
                    <p className="text-xs text-[var(--color-text-dim)]">Total Scans</p>
                  </div>
                  <div className="rounded-xl bg-[var(--color-bg-surface)] p-4">
                    <p className="text-2xl font-bold gold-gradient-text">$137,395+</p>
                    <p className="text-xs text-[var(--color-text-dim)]">USDT Paid to Members</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Mission ── */}
      <section className="py-16 sm:py-24 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-3xl sm:text-4xl font-black text-white mb-6">
            OUR <span className="gold-gradient-text">MISSION</span>
          </h2>
          <p className="text-xl text-[var(--color-text-muted)] leading-relaxed max-w-3xl mx-auto">
            To build the most transparent and rewarding consumer brand in the world. We believe that when brands share their success with their customers &mdash; transparently and verifiably &mdash; everyone wins.
          </p>
        </div>
      </section>

      {/* ── How It Works (Detailed) ── */}
      <section className="py-16 sm:py-24 px-4 sm:px-6 lg:px-8 bg-[var(--color-bg-card)]/50">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-black text-white mb-4">
              HOW THE PROGRAM <span className="gold-gradient-text">WORKS</span>
            </h2>
            <p className="text-lg text-[var(--color-text-muted)] max-w-xl mx-auto">
              A detailed look at the mechanics behind the BlakJaks loyalty ecosystem
            </p>
          </div>

          <div className="grid sm:grid-cols-2 gap-6">
            {howItWorksSteps.map(({ icon: Icon, title, description }, i) => (
              <Card key={title} className="relative overflow-hidden">
                <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-[#D4AF37]/30 to-transparent" />
                <div className="flex items-start gap-4">
                  <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-[#D4AF37]/10">
                    <Icon size={24} className="text-[#D4AF37]" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-xs font-bold text-[#D4AF37]">STEP {i + 1}</span>
                    </div>
                    <h3 className="text-lg font-bold text-white mb-2">{title}</h3>
                    <p className="text-sm text-[var(--color-text-muted)] leading-relaxed">{description}</p>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* ── Values ── */}
      <section className="py-16 sm:py-24 px-4 sm:px-6 lg:px-8">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-black text-white mb-4">
              WHAT WE <span className="gold-gradient-text">STAND FOR</span>
            </h2>
          </div>

          <div className="grid sm:grid-cols-2 gap-6">
            {values.map(({ icon: Icon, title, description }) => (
              <Card key={title} hover>
                <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-[#D4AF37]/10 mb-4">
                  <Icon size={24} className="text-[#D4AF37]" />
                </div>
                <h3 className="text-lg font-bold text-white mb-2">{title}</h3>
                <p className="text-sm text-[var(--color-text-muted)] leading-relaxed">{description}</p>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* ── Contact ── */}
      <section className="py-16 sm:py-24 px-4 sm:px-6 lg:px-8 bg-[var(--color-bg-card)]/50">
        <div className="max-w-4xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-black text-white mb-4">
              GET IN <span className="gold-gradient-text">TOUCH</span>
            </h2>
            <p className="text-lg text-[var(--color-text-muted)]">
              Have questions, partnership inquiries, or just want to say hello?
            </p>
          </div>

          <div className="grid sm:grid-cols-3 gap-6">
            <Card className="text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-[#D4AF37]/10 mx-auto mb-4">
                <Mail size={24} className="text-[#D4AF37]" />
              </div>
              <h3 className="font-bold text-white mb-1">Email</h3>
              <a href="mailto:support@blakjaks.com" className="text-sm text-[#D4AF37] hover:underline">
                support@blakjaks.com
              </a>
            </Card>
            <Card className="text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-[#D4AF37]/10 mx-auto mb-4">
                <Globe size={24} className="text-[#D4AF37]" />
              </div>
              <h3 className="font-bold text-white mb-1">Discord</h3>
              <a href="#" className="text-sm text-[#D4AF37] hover:underline">
                Join our server
              </a>
            </Card>
            <Card className="text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-[#D4AF37]/10 mx-auto mb-4">
                <ExternalLink size={24} className="text-[#D4AF37]" />
              </div>
              <h3 className="font-bold text-white mb-1">Twitter / X</h3>
              <a href="#" className="text-sm text-[#D4AF37] hover:underline">
                @BlakJaks
              </a>
            </Card>
          </div>

          <div className="mt-12 text-center">
            <Link href="/transparency">
              <GoldButton variant="secondary" size="lg" className="gap-2">
                View Transparency Dashboard <ExternalLink size={16} />
              </GoldButton>
            </Link>
          </div>
        </div>
      </section>
    </div>
  )
}
