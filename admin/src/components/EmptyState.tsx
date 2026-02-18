import { Inbox } from 'lucide-react'

interface EmptyStateProps {
  title?: string
  message?: string
}

export default function EmptyState({ title = 'No data', message = 'Nothing to show here yet.' }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-slate-400">
      <Inbox size={48} className="mb-4" />
      <h3 className="text-lg font-medium text-slate-600">{title}</h3>
      <p className="text-sm">{message}</p>
    </div>
  )
}
