import { STATUS_COLORS } from '@/lib/utils'

export default function StatusBadge({ status }: { status: string }) {
  const colors = STATUS_COLORS[status] || STATUS_COLORS.pending
  return (
    <span className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium ${colors}`}>
      {status.replace('_', ' ')}
    </span>
  )
}
