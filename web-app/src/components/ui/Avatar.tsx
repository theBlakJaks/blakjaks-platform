'use client'

import { useState } from 'react'
import type { Tier } from '@/lib/types'
import { getTierColor } from '@/lib/utils'

interface AvatarProps {
  name: string
  tier?: Tier
  size?: 'sm' | 'md' | 'lg' | 'xl'
  avatarUrl?: string
}

const AVATAR_COLORS = [
  '#5865F2', '#57F287', '#FEE75C', '#EB459E',
  '#ED4245', '#3BA55C', '#FAA61A', '#D4AF37',
]

function getAvatarColor(name: string): string {
  const hash = name.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0)
  return AVATAR_COLORS[hash % AVATAR_COLORS.length]
}

export default function Avatar({ name, tier, size = 'md', avatarUrl }: AvatarProps) {
  const [imgError, setImgError] = useState(false)

  const initials = name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)

  const sizes = {
    sm: 'h-8 w-8 text-xs',
    md: 'h-10 w-10 text-sm',
    lg: 'h-14 w-14 text-lg',
    xl: 'h-32 w-32 text-3xl',
  }
  const borderColor = tier ? getTierColor(tier) : 'var(--color-border-light)'
  const showImage = avatarUrl && !imgError

  return (
    <div
      className={`relative flex items-center justify-center rounded-full border-2 overflow-hidden shrink-0 ${sizes[size]}`}
      style={{
        borderColor,
        backgroundColor: showImage ? 'transparent' : getAvatarColor(name),
      }}
    >
      {showImage ? (
        <img
          src={avatarUrl}
          alt={name}
          className="h-full w-full object-cover"
          onError={() => setImgError(true)}
          draggable={false}
        />
      ) : (
        <span className="font-semibold text-white">{initials}</span>
      )}
    </div>
  )
}
