'use client'

import { useState, useRef } from 'react'
import { Camera, Trash2, Loader2 } from 'lucide-react'
import Avatar from '@/components/ui/Avatar'
import AvatarCropModal from '@/components/ui/AvatarCropModal'
import type { Tier } from '@/lib/types'

interface AvatarUploadProps {
  name: string
  tier?: Tier
  currentAvatarUrl?: string
  onUpload: (file: File) => Promise<{ avatarUrl: string } | { error: string }>
  onDelete: () => Promise<void>
}

const MAX_FILE_SIZE = 10 * 1024 * 1024 // 10 MB
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']

export default function AvatarUpload({ name, tier, currentAvatarUrl, onUpload, onDelete }: AvatarUploadProps) {
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [cropModalOpen, setCropModalOpen] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setError(null)

    if (!ALLOWED_TYPES.includes(file.type)) {
      setError('Invalid file type. Use JPG, PNG, GIF, or WebP.')
      return
    }
    if (file.size > MAX_FILE_SIZE) {
      setError('File too large. Maximum size is 10 MB.')
      return
    }

    setSelectedFile(file)
    setCropModalOpen(true)
    // Reset file input so re-selecting the same file works
    if (fileInputRef.current) fileInputRef.current.value = ''
  }

  const handleCropSave = async (croppedBlob: Blob) => {
    const croppedFile = new File([croppedBlob], 'avatar.webp', { type: 'image/webp' })
    const result = await onUpload(croppedFile)
    if ('error' in result) {
      throw new Error(result.error)
    }
    setSelectedFile(null)
  }

  const handleCropClose = () => {
    setCropModalOpen(false)
    setSelectedFile(null)
  }

  const handleDelete = async () => {
    setDeleting(true)
    setError(null)
    try {
      await onDelete()
    } catch {
      setError('Failed to remove avatar.')
    } finally {
      setDeleting(false)
    }
  }

  return (
    <div className="flex flex-col items-center gap-3">
      {/* Avatar display */}
      <div className="relative group">
        <Avatar name={name} tier={tier} size="xl" avatarUrl={currentAvatarUrl} />

        {/* Hover overlay */}
        <button
          onClick={() => fileInputRef.current?.click()}
          className="absolute inset-0 flex items-center justify-center rounded-full bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer"
        >
          <Camera size={24} className="text-[var(--color-gold)]" />
        </button>
      </div>

      {/* Hidden file input */}
      <input
        ref={fileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/gif,image/webp"
        onChange={handleFileSelect}
        className="hidden"
      />

      {/* Action links */}
      <div className="flex items-center gap-2">
        <button
          onClick={() => fileInputRef.current?.click()}
          className="text-xs text-[var(--color-gold)] hover:text-[var(--color-gold-light)] transition-colors font-medium"
        >
          {currentAvatarUrl ? 'Change Photo' : 'Upload Photo'}
        </button>
        {currentAvatarUrl && (
          <button
            onClick={handleDelete}
            disabled={deleting}
            className="flex items-center gap-1 text-xs text-[var(--color-text-dim)] hover:text-red-400 transition-colors disabled:opacity-50"
          >
            {deleting ? <Loader2 size={12} className="animate-spin" /> : <Trash2 size={12} />}
            Remove
          </button>
        )}
      </div>

      {/* Error message */}
      {error && (
        <p className="text-xs text-red-400 text-center max-w-[250px]">{error}</p>
      )}

      {/* Crop modal */}
      {selectedFile && (
        <AvatarCropModal
          imageFile={selectedFile}
          isOpen={cropModalOpen}
          onClose={handleCropClose}
          onSave={handleCropSave}
        />
      )}
    </div>
  )
}
