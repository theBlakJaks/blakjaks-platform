import { Construction } from 'lucide-react'

export default function ComingSoon() {
  return (
    <div className="flex flex-col items-center justify-center py-24 text-slate-400">
      <Construction size={48} className="mb-4" />
      <h2 className="text-xl font-semibold text-slate-600">Coming Soon</h2>
      <p className="mt-1 text-sm">This page is under construction.</p>
    </div>
  )
}
