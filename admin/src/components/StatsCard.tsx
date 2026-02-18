import { TrendingUp, TrendingDown, type LucideIcon } from 'lucide-react'
import { formatPercentage } from '../utils/formatters'

interface StatsCardProps {
  icon: LucideIcon
  label: string
  value: string
  trend?: number
}

export default function StatsCard({ icon: Icon, label, value, trend }: StatsCardProps) {
  return (
    <div className="rounded-xl bg-white p-6 shadow-sm">
      <div className="flex items-center justify-between">
        <div className="rounded-lg bg-indigo-50 p-3">
          <Icon size={24} className="text-indigo-600" />
        </div>
        {trend !== undefined && (
          <div className={`flex items-center gap-1 text-sm font-medium ${trend >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>
            {trend >= 0 ? <TrendingUp size={16} /> : <TrendingDown size={16} />}
            {formatPercentage(trend)}
          </div>
        )}
      </div>
      <div className="mt-4">
        <p className="text-sm text-slate-500">{label}</p>
        <p className="text-2xl font-bold text-slate-900">{value}</p>
      </div>
    </div>
  )
}
