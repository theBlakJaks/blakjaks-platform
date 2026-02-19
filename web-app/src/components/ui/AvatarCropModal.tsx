'use client'

import { useState, useCallback, useEffect } from 'react'
import Cropper from 'react-easy-crop'
import type { Area } from 'react-easy-crop'
import { ZoomIn, ZoomOut, Loader2, X } from 'lucide-react'
import GoldButton from '@/components/ui/GoldButton'
import { getCroppedImage } from '@/lib/crop-image'

interface AvatarCropModalProps {
  imageFile: File
  isOpen: boolean
  onClose: () => void
  onSave: (croppedBlob: Blob) => Promise<void>
}

export default function AvatarCropModal({ imageFile, isOpen, onClose, onSave }: AvatarCropModalProps) {
  const [crop, setCrop] = useState({ x: 0, y: 0 })
  const [zoom, setZoom] = useState(1)
  const [croppedAreaPixels, setCroppedAreaPixels] = useState<Area | null>(null)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [imageUrl, setImageUrl] = useState<string | null>(null)

  useEffect(() => {
    if (isOpen && imageFile) {
      const url = URL.createObjectURL(imageFile)
      setImageUrl(url)
      setCrop({ x: 0, y: 0 })
      setZoom(1)
      setError(null)
      return () => URL.revokeObjectURL(url)
    }
  }, [isOpen, imageFile])

  const onCropComplete = useCallback((_: Area, croppedPixels: Area) => {
    setCroppedAreaPixels(croppedPixels)
  }, [])

  const handleSave = async () => {
    if (!croppedAreaPixels || !imageUrl) return
    setSaving(true)
    setError(null)
    try {
      const croppedBlob = await getCroppedImage(imageUrl, croppedAreaPixels)
      await onSave(croppedBlob)
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to upload. Please try again.')
    } finally {
      setSaving(false)
    }
  }

  if (!isOpen || !imageUrl) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/80" onClick={saving ? undefined : onClose} />

      {/* Modal */}
      <div className="relative z-10 w-full max-w-md mx-4 rounded-2xl border border-[var(--color-border)] bg-[#1A1A2E] shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-[var(--color-border)]">
          <h3 className="text-base font-semibold text-white">Edit Profile Photo</h3>
          <button
            onClick={onClose}
            disabled={saving}
            className="text-[var(--color-text-dim)] hover:text-white transition-colors disabled:opacity-50"
          >
            <X size={18} />
          </button>
        </div>

        {/* Crop area */}
        <div className="relative h-[300px] sm:h-[340px] bg-black">
          <Cropper
            image={imageUrl}
            crop={crop}
            zoom={zoom}
            aspect={1}
            cropShape="round"
            showGrid={false}
            onCropChange={setCrop}
            onZoomChange={setZoom}
            onCropComplete={onCropComplete}
            style={{
              containerStyle: { background: '#0a0a0a' },
              cropAreaStyle: { border: '3px solid rgba(212, 175, 55, 0.6)' },
            }}
          />
        </div>

        {/* Zoom slider */}
        <div className="flex items-center gap-3 px-5 py-3">
          <ZoomOut size={16} className="shrink-0 text-[var(--color-text-dim)]" />
          <input
            type="range"
            min={1}
            max={3}
            step={0.05}
            value={zoom}
            onChange={(e) => setZoom(Number(e.target.value))}
            className="flex-1 h-1.5 rounded-full appearance-none bg-[var(--color-border)] [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-[var(--color-gold)] [&::-webkit-slider-thumb]:cursor-pointer"
          />
          <ZoomIn size={16} className="shrink-0 text-[var(--color-text-dim)]" />
        </div>

        {/* Error */}
        {error && (
          <div className="px-5 pb-2">
            <p className="text-xs text-red-400 text-center">{error}</p>
          </div>
        )}

        {/* Actions */}
        <div className="flex items-center justify-end gap-3 px-5 py-4 border-t border-[var(--color-border)]">
          <button
            onClick={onClose}
            disabled={saving}
            className="rounded-lg border border-[var(--color-border)] px-4 py-2 text-sm font-medium text-[var(--color-text-muted)] hover:text-white hover:border-[var(--color-text-muted)] transition-colors disabled:opacity-50"
          >
            Cancel
          </button>
          <GoldButton onClick={handleSave} disabled={saving}>
            {saving ? (
              <>
                <Loader2 size={14} className="animate-spin" />
                <span className="ml-1.5">Saving...</span>
              </>
            ) : (
              'Save'
            )}
          </GoldButton>
        </div>
      </div>
    </div>
  )
}
