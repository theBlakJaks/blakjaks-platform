'use client'

import { useEffect, useState } from 'react'
import { CheckCircle, XCircle, Info, X } from 'lucide-react'
import { cn } from '@/lib/utils'

type ToastType = 'success' | 'error' | 'info'

interface ToastMessage {
  id: string
  type: ToastType
  message: string
}

let addToast: (type: ToastType, message: string) => void

export function toast(type: ToastType, message: string) {
  addToast?.(type, message)
}

export default function ToastContainer() {
  const [toasts, setToasts] = useState<ToastMessage[]>([])

  useEffect(() => {
    addToast = (type, message) => {
      const id = Date.now().toString()
      setToasts((prev) => [...prev, { id, type, message }])
      setTimeout(() => setToasts((prev) => prev.filter((t) => t.id !== id)), 4000)
    }
  }, [])

  const icons = {
    success: <CheckCircle size={18} className="text-emerald-400" />,
    error: <XCircle size={18} className="text-red-400" />,
    info: <Info size={18} className="text-blue-400" />,
  }

  const borders = {
    success: 'border-emerald-500/30',
    error: 'border-red-500/30',
    info: 'border-blue-500/30',
  }

  return (
    <div className="fixed bottom-4 right-4 z-[100] flex flex-col gap-2">
      {toasts.map((t) => (
        <div
          key={t.id}
          className={cn(
            'flex items-center gap-3 rounded-xl border bg-[var(--color-bg-card)] px-4 py-3 shadow-lg animate-in slide-in-from-right',
            borders[t.type],
          )}
        >
          {icons[t.type]}
          <span className="text-sm text-[var(--color-text)]">{t.message}</span>
          <button onClick={() => setToasts((prev) => prev.filter((x) => x.id !== t.id))} className="ml-2 text-[var(--color-text-dim)] hover:text-white">
            <X size={14} />
          </button>
        </div>
      ))}
    </div>
  )
}
