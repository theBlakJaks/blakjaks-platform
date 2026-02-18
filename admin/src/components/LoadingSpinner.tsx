import { Loader2 } from 'lucide-react'

export default function LoadingSpinner({ className = '' }: { className?: string }) {
  return <Loader2 className={`animate-spin text-indigo-600 ${className}`} size={24} />
}
