'use client'

import { useState, useEffect, useRef } from 'react'
import Link from 'next/link'
import { Scan, Coins, TrendingUp, Shield, Users, ChevronDown, Star, Award, Gem, Crown, CheckCircle2, ExternalLink } from 'lucide-react'
import GoldButton from '@/components/ui/GoldButton'
import Card from '@/components/ui/Card'
import NicotineWarningBanner from '@/components/NicotineWarningBanner'

/* ──────────────────────────── Animated Counter Hook ──────────────────────────── */
function useCountUp(target: number, duration = 2000, start = false) {
  const [value, setValue] = useState(0)
  useEffect(() => {
    if (!start) return
    let raf: number
    const startTime = performance.now()
    const tick = (now: number) => {
      const elapsed = now - startTime
      const progress = Math.min(elapsed / duration, 1)
      const eased = 1 - Math.pow(1 - progress, 3)
      setValue(Math.floor(eased * target))
      if (progress < 1) raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [target, duration, start])
  return value
}

/* ──────────────────────────── Intersection Observer Hook ──────────────────────────── */
function useInView(threshold = 0.2) {
  const ref = useRef<HTMLDivElement>(null)
  const [inView, setInView] = useState(false)
  useEffect(() => {
    const el = ref.current
    if (!el) return
    const obs = new IntersectionObserver(([e]) => { if (e.isIntersecting) setInView(true) }, { threshold })
    obs.observe(el)
    return () => obs.disconnect()
  }, [threshold])
  return { ref, inView }
}

/* ──────────────────────────── FAQ Data ──────────────────────────── */
const faqs = [
  { q: 'What is BlakJaks?', a: 'BlakJaks is a premium nicotine pouch brand with a built-in loyalty program that pays you real USDC cryptocurrency for every tin you scan.' },
  { q: 'How do I earn USDC?', a: 'Simply purchase BlakJaks pouches, scan the unique POP (Proof of Purchase) code inside each tin, and USDC is automatically sent to your wallet on the Polygon blockchain.' },
  { q: 'What are the tier levels?', a: 'There are four tiers: Standard (0-6 quarterly scans), VIP (7-14), High Roller (15-29), and Whale (30+). Higher tiers earn larger comps and unlock exclusive perks.' },
  { q: 'What are comp prizes?', a: 'Members can win $100, $1,000, $10,000, or even a $200,000 luxury trip based on their scan milestones and tier status.' },
  { q: 'Is this really on the blockchain?', a: 'Yes. All treasury wallets are publicly verifiable on Polygon. Visit our Transparency Dashboard to see live balances, scan counts, and comp payouts in real time.' },
  { q: 'How do I withdraw my earnings?', a: 'You can withdraw your USDC balance at any time to any Polygon-compatible wallet. Withdrawals typically process within minutes.' },
  { q: 'Is there an age requirement?', a: 'Yes, you must be 21 years or older to purchase BlakJaks products and participate in the loyalty program. Age verification is required at signup.' },
  { q: 'What makes BlakJaks different from other loyalty programs?', a: 'Full blockchain transparency, real cryptocurrency rewards (not points), community governance where members vote on decisions, and a tiered comp system with prizes up to $200K.' },
]

/* ──────────────────────────── Flavors ──────────────────────────── */
const flavors = [
  { name: 'Spearmint', color: '#4ADE80', icon: '🌿' },
  { name: 'Wintergreen', color: '#2DD4BF', icon: '❄️' },
  { name: 'Bubblegum', color: '#F472B6', icon: '🫧' },
  { name: 'Blue Razz', color: '#60A5FA', icon: '⚡' },
  { name: 'Mint Ice', color: '#67E8F9', icon: '🧊' },
  { name: 'Citrus', color: '#FACC15', icon: '🍋' },
  { name: 'Cinnamon', color: '#F97316', icon: '🔥' },
  { name: 'Coffee', color: '#A78BFA', icon: '☕' },
]

/* ──────────────────────────── Tier Data ──────────────────────────── */
const tiers = [
  { name: 'Standard', icon: Star, scans: '0-6', color: '#EF4444', benefits: ['$0.50 per scan comp', 'Community chat access', 'Governance voting', '$100 comp eligibility'] },
  { name: 'VIP', icon: Award, scans: '7-14', color: '#A1A1AA', benefits: ['Higher scan comps', 'VIP-only channels', 'Monthly tier bonus', '$1,000 comp eligibility'] },
  { name: 'High Roller', icon: Gem, scans: '15-29', color: '#D4AF37', benefits: ['Premium comp rates', 'High Roller Lounge', 'Priority support', '$10,000 comp eligibility'] },
  { name: 'Whale', icon: Crown, scans: '30+', color: '#E5E7EB', benefits: ['Maximum comp rates', 'Whale Pod exclusive', 'Direct team access', '$200K Trip eligibility'] },
]

/* ──────────────────────────── Comp Tiers ──────────────────────────── */
const compTiers = [
  { amount: '$100', label: 'Starter Comp', description: 'Hit scan milestones to unlock your first major comp.', gradient: 'from-zinc-700 to-zinc-600' },
  { amount: '$1,000', label: 'Silver Comp', description: 'VIP and above members qualify for four-figure comps.', gradient: 'from-zinc-500 to-zinc-400' },
  { amount: '$10,000', label: 'Gold Comp', description: 'High Roller tier unlocks five-figure prize eligibility.', gradient: 'from-[#D4AF37] to-[#E8D48B]' },
  { amount: '$200K', label: 'Luxury Trip', description: 'Whale-exclusive all-expenses-paid luxury vacation.', gradient: 'from-[#E8D48B] to-white' },
]

/* ──────────────────────────── FAQ Accordion Item ──────────────────────────── */
function FAQItem({ q, a }: { q: string; a: string }) {
  const [open, setOpen] = useState(false)
  return (
    <div className="border-b border-[var(--color-border)] last:border-0">
      <button className="flex w-full items-center justify-between py-5 text-left" onClick={() => setOpen(!open)}>
        <span className="text-base font-medium text-white pr-4">{q}</span>
        <ChevronDown className={`h-5 w-5 shrink-0 text-[var(--color-text-muted)] transition-transform duration-300 ${open ? 'rotate-180' : ''}`} />
      </button>
      <div className={`overflow-hidden transition-all duration-300 ${open ? 'max-h-40 pb-5' : 'max-h-0'}`}>
        <p className="text-sm leading-relaxed text-[var(--color-text-muted)]">{a}</p>
      </div>
    </div>
  )
}

/* ──────────────────────────── LANDING PAGE ──────────────────────────── */
export default function LandingPage() {
  const { ref: statsRef, inView: statsInView } = useInView()
  const scanCount = useCountUp(847523, 2500, statsInView)
  const membersCount = useCountUp(24891, 2000, statsInView)
  const usdcPaid = useCountUp(137395, 2500, statsInView)

  const { ref: transparencyRef, inView: transparencyInView } = useInView()
  const liveScanCount = useCountUp(847523, 3000, transparencyInView)

  return (
    <div style={{ paddingTop: '20vh' }} className="overflow-hidden">
      <NicotineWarningBanner />
      {/* ── Keyframe styles ── */}
      <style jsx>{`
        @keyframes float {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-20px); }
        }
        @keyframes shimmer {
          0% { background-position: -200% center; }
          100% { background-position: 200% center; }
        }
        @keyframes pulse-gold {
          0%, 100% { opacity: 0.3; }
          50% { opacity: 0.8; }
        }
        @keyframes fade-up {
          from { opacity: 0; transform: translateY(30px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .animate-float { animation: float 6s ease-in-out infinite; }
        .animate-shimmer {
          background-size: 200% auto;
          animation: shimmer 3s linear infinite;
        }
        .animate-pulse-gold { animation: pulse-gold 3s ease-in-out infinite; }
        .animate-fade-up { animation: fade-up 0.8s ease-out forwards; }
        .delay-100 { animation-delay: 0.1s; }
        .delay-200 { animation-delay: 0.2s; }
        .delay-300 { animation-delay: 0.3s; }
        .delay-400 { animation-delay: 0.4s; }
      `}</style>

      {/* ── HERO ── */}
      <section className="relative min-h-[90vh] flex items-center justify-center px-4 sm:px-6 lg:px-8">
        {/* Background accents */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-[#D4AF37]/5 rounded-full blur-3xl animate-pulse-gold" />
          <div className="absolute bottom-1/4 right-1/4 w-80 h-80 bg-[#D4AF37]/8 rounded-full blur-3xl animate-pulse-gold" style={{ animationDelay: '1.5s' }} />
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-[#D4AF37]/3 rounded-full blur-[120px]" />
        </div>

        <div className="relative z-10 max-w-5xl mx-auto text-center">
          <div className="animate-fade-up">
            <span className="inline-flex items-center gap-2 rounded-full border border-[#D4AF37]/30 bg-[#D4AF37]/10 px-4 py-1.5 text-sm font-medium text-[#D4AF37] mb-8">
              <span className="h-2 w-2 rounded-full bg-[#D4AF37] animate-pulse" />
              Blockchain-Verified Loyalty Program
            </span>
          </div>

          <h1 className="animate-fade-up delay-100 text-5xl sm:text-6xl md:text-7xl lg:text-8xl font-black tracking-tight leading-[0.9] mb-8">
            <span className="text-white">EARN</span>{' '}
            <span className="gold-gradient-text">CRYPTO</span>
            <br />
            <span className="text-white">FROM EVERY</span>{' '}
            <span className="gold-gradient-text">TIN</span>
          </h1>

          <p className="animate-fade-up delay-200 max-w-2xl mx-auto text-lg sm:text-xl text-[var(--color-text-muted)] mb-10 leading-relaxed">
            BlakJaks is the world&apos;s first nicotine pouch brand that pays you real USDC for every tin you scan. Transparent. Verifiable. On-chain.
          </p>

          <div className="animate-fade-up delay-300 flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link href="/signup">
              <GoldButton size="lg" className="text-lg px-10 py-4">
                Join Now
              </GoldButton>
            </Link>
            <a href="#how-it-works">
              <GoldButton variant="secondary" size="lg" className="text-lg px-10 py-4">
                Learn More
              </GoldButton>
            </a>
          </div>

          <div className="animate-fade-up delay-400 mt-16 animate-float">
            <div className="inline-flex items-center gap-3 rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)]/80 backdrop-blur-sm px-6 py-3">
              <span className="text-4xl">&#9824;</span>
              <div className="text-left">
                <p className="text-xs text-[var(--color-text-dim)]">Live Scan Counter</p>
                <p className="text-xl font-bold gold-gradient-text">{(847523).toLocaleString()}+</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── HOW IT WORKS ── */}
      <section id="how-it-works" className="py-24 sm:py-32 px-4 sm:px-6 lg:px-8">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-white mb-4">
              HOW IT <span className="gold-gradient-text">WORKS</span>
            </h2>
            <p className="text-lg text-[var(--color-text-muted)] max-w-xl mx-auto">Three simple steps to start earning real cryptocurrency</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 relative">
            {/* Connector line */}
            <div className="hidden md:block absolute top-16 left-[calc(16.67%+24px)] right-[calc(16.67%+24px)] h-px bg-gradient-to-r from-[#D4AF37]/50 via-[#D4AF37] to-[#D4AF37]/50" />

            {[
              { step: 1, icon: Coins, title: 'Buy BlakJaks', desc: 'Purchase any BlakJaks nicotine pouch tin from an authorized retailer or online.' },
              { step: 2, icon: Scan, title: 'Scan POP Code', desc: 'Open the tin and scan the unique Proof of Purchase QR code with the BlakJaks app.' },
              { step: 3, icon: TrendingUp, title: 'Earn USDC', desc: 'USDC is automatically sent to your wallet on the Polygon blockchain. Withdraw anytime.' },
            ].map(({ step, icon: Icon, title, desc }) => (
              <div key={step} className="relative text-center">
                <div className="inline-flex items-center justify-center w-32 h-32 rounded-full border-2 border-[#D4AF37]/30 bg-[#D4AF37]/5 mb-6 relative">
                  <Icon className="h-12 w-12 text-[#D4AF37]" />
                  <span className="absolute -top-2 -right-2 flex h-10 w-10 items-center justify-center rounded-full gold-gradient text-black font-black text-lg">
                    {step}
                  </span>
                </div>
                <h3 className="text-xl font-bold text-white mb-3">{title}</h3>
                <p className="text-[var(--color-text-muted)] max-w-xs mx-auto">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── TIER SYSTEM ── */}
      <section className="py-24 sm:py-32 px-4 sm:px-6 lg:px-8 bg-[var(--color-bg-card)]/50">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-white mb-4">
              TIER <span className="gold-gradient-text">SYSTEM</span>
            </h2>
            <p className="text-lg text-[var(--color-text-muted)] max-w-xl mx-auto">Scan more, earn more. Level up your rewards with quarterly scan milestones.</p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {tiers.map(({ name, icon: Icon, scans, color, benefits }) => (
              <Card key={name} hover className="relative overflow-hidden group">
                <div className="absolute top-0 left-0 right-0 h-1" style={{ background: color }} />
                <div className="flex items-center gap-3 mb-4">
                  <div className="flex h-12 w-12 items-center justify-center rounded-xl" style={{ backgroundColor: `${color}1a` }}>
                    <Icon size={24} style={{ color }} />
                  </div>
                  <div>
                    <h3 className="font-bold text-white text-lg">{name}</h3>
                    <p className="text-xs text-[var(--color-text-dim)]">{scans} scans/quarter</p>
                  </div>
                </div>
                <ul className="space-y-2.5">
                  {benefits.map((b) => (
                    <li key={b} className="flex items-start gap-2 text-sm text-[var(--color-text-muted)]">
                      <CheckCircle2 size={14} className="mt-0.5 shrink-0" style={{ color }} />
                      {b}
                    </li>
                  ))}
                </ul>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* ── COMP TIERS ── */}
      <section className="py-24 sm:py-32 px-4 sm:px-6 lg:px-8">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-white mb-4">
              COMP <span className="gold-gradient-text">PRIZES</span>
            </h2>
            <p className="text-lg text-[var(--color-text-muted)] max-w-xl mx-auto">Real prizes, real money. Our comp system rewards your loyalty with escalating prize tiers.</p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {compTiers.map(({ amount, label, description, gradient }) => (
              <div key={amount} className="group relative rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6 transition-all hover:-translate-y-1 hover:border-[#D4AF37]/30 overflow-hidden">
                <div className={`absolute inset-0 bg-gradient-to-br ${gradient} opacity-0 group-hover:opacity-5 transition-opacity`} />
                <div className="relative z-10">
                  <p className={`text-4xl font-black mb-1 bg-gradient-to-r ${gradient} bg-clip-text text-transparent`}>
                    {amount}
                  </p>
                  <p className="text-sm font-semibold text-[#D4AF37] mb-3">{label}</p>
                  <p className="text-sm text-[var(--color-text-muted)]">{description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── TRANSPARENCY CALLOUT ── */}
      <section ref={transparencyRef} className="py-24 sm:py-32 px-4 sm:px-6 lg:px-8 bg-[var(--color-bg-card)]/50">
        <div className="max-w-4xl mx-auto text-center">
          <div className="inline-flex items-center justify-center w-20 h-20 rounded-full border-2 border-[#D4AF37]/30 bg-[#D4AF37]/5 mb-8">
            <Shield className="h-10 w-10 text-[#D4AF37]" />
          </div>
          <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-white mb-4">
            VERIFY ON THE <span className="gold-gradient-text">BLOCKCHAIN</span>
          </h2>
          <p className="text-lg text-[var(--color-text-muted)] max-w-2xl mx-auto mb-10">
            Every USDC in our treasury is publicly verifiable on Polygon. No smoke and mirrors &mdash; just transparent, on-chain proof that your rewards are fully funded.
          </p>

          <div className="inline-flex items-center gap-4 rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] px-8 py-5 mb-10">
            <Scan className="h-8 w-8 text-[#D4AF37]" />
            <div className="text-left">
              <p className="text-xs text-[var(--color-text-dim)]">Total Scans Processed</p>
              <p className="text-3xl font-black gold-gradient-text">{liveScanCount.toLocaleString()}</p>
            </div>
          </div>

          <div className="block">
            <Link href="/transparency">
              <GoldButton size="lg" className="gap-2">
                View Transparency Dashboard <ExternalLink size={16} />
              </GoldButton>
            </Link>
          </div>
        </div>
      </section>

      {/* ── PRODUCT SHOWCASE ── */}
      <section className="py-24 sm:py-32 px-4 sm:px-6 lg:px-8">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-white mb-4">
              FLAVOR <span className="gold-gradient-text">LINEUP</span>
            </h2>
            <p className="text-lg text-[var(--color-text-muted)] max-w-xl mx-auto">Eight premium flavors, three strength levels. Find your perfect match.</p>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 sm:gap-6">
            {flavors.map(({ name, color, icon }) => (
              <div
                key={name}
                className="group rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] p-6 text-center transition-all hover:-translate-y-1 hover:border-opacity-50"
                style={{ ['--hover-color' as string]: color }}
              >
                <div
                  className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl text-3xl transition-transform group-hover:scale-110"
                  style={{ backgroundColor: `${color}15` }}
                >
                  {icon}
                </div>
                <h3 className="font-bold text-white">{name}</h3>
                <p className="text-xs text-[var(--color-text-dim)] mt-1">3mg / 6mg / 9mg</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── SOCIAL PROOF / STATS ── */}
      <section ref={statsRef} className="py-24 sm:py-32 px-4 sm:px-6 lg:px-8 bg-[var(--color-bg-card)]/50">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-white mb-4">
              BY THE <span className="gold-gradient-text">NUMBERS</span>
            </h2>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-8">
            {[
              { icon: Users, label: 'Active Members', value: membersCount, suffix: '+' },
              { icon: Coins, label: 'USDC Paid Out', value: usdcPaid, prefix: '$', suffix: '' },
              { icon: Scan, label: 'Scans Processed', value: scanCount, suffix: '+' },
            ].map(({ icon: Icon, label, value, prefix, suffix }) => (
              <div key={label} className="text-center">
                <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-[#D4AF37]/10 mb-4">
                  <Icon className="h-8 w-8 text-[#D4AF37]" />
                </div>
                <p className="text-4xl sm:text-5xl font-black text-white mb-2">
                  {prefix}{value.toLocaleString()}{suffix}
                </p>
                <p className="text-sm text-[var(--color-text-muted)]">{label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── FAQ ── */}
      <section className="py-24 sm:py-32 px-4 sm:px-6 lg:px-8">
        <div className="max-w-3xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-white mb-4">
              COMMON <span className="gold-gradient-text">QUESTIONS</span>
            </h2>
          </div>

          <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-bg-card)] px-6 sm:px-8">
            {faqs.map((faq) => (
              <FAQItem key={faq.q} q={faq.q} a={faq.a} />
            ))}
          </div>
        </div>
      </section>

      {/* ── CTA BANNER ── */}
      <section className="py-24 sm:py-32 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto relative">
          <div className="absolute inset-0 bg-gradient-to-r from-[#D4AF37]/10 via-[#D4AF37]/5 to-[#D4AF37]/10 rounded-3xl blur-xl" />
          <div className="relative rounded-3xl border border-[#D4AF37]/20 bg-[var(--color-bg-card)] p-12 sm:p-16 text-center">
            <div className="text-6xl mb-6">&#9824;</div>
            <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-white mb-4">
              READY TO <span className="gold-gradient-text">EARN</span>?
            </h2>
            <p className="text-lg text-[var(--color-text-muted)] max-w-xl mx-auto mb-10">
              Join thousands of members already earning real USDC from every tin. Sign up takes less than a minute.
            </p>
            <Link href="/signup">
              <GoldButton size="lg" className="text-lg px-12 py-4">
                Join BlakJaks
              </GoldButton>
            </Link>
          </div>
        </div>
      </section>
    </div>
  )
}
