export default function Logo({ size = 'md' }: { size?: 'sm' | 'md' | 'lg' }) {
  const sizes = { sm: 'text-lg', md: 'text-2xl', lg: 'text-4xl' }
  return (
    <div className={`flex items-center gap-2 font-bold ${sizes[size]}`}>
      <span className="gold-gradient-text">♠</span>
      <span className="text-white">BLAK<span className="gold-gradient-text">JAKS</span></span>
    </div>
  )
}
