import Modal from './Modal'

interface ConfirmDialogProps {
  open: boolean
  onClose: () => void
  onConfirm: () => void
  title: string
  message: string
  confirmLabel?: string
  variant?: 'danger' | 'primary'
}

export default function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title,
  message,
  confirmLabel = 'Confirm',
  variant = 'primary',
}: ConfirmDialogProps) {
  const btnColor = variant === 'danger'
    ? 'bg-red-600 hover:bg-red-700'
    : 'bg-indigo-600 hover:bg-indigo-700'

  return (
    <Modal open={open} onClose={onClose} title={title}>
      <p className="mb-6 text-sm text-slate-600">{message}</p>
      <div className="flex justify-end gap-3">
        <button
          onClick={onClose}
          className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
        >
          Cancel
        </button>
        <button
          onClick={() => { onConfirm(); onClose() }}
          className={`rounded-lg px-4 py-2 text-sm font-medium text-white ${btnColor}`}
        >
          {confirmLabel}
        </button>
      </div>
    </Modal>
  )
}
