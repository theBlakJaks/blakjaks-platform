'use client'

import { cn } from '@/lib/utils'

interface Tab {
  id: string
  label: string
}

interface TabsProps {
  tabs: Tab[]
  activeTab: string
  onChange: (tabId: string) => void
}

export default function Tabs({ tabs, activeTab, onChange }: TabsProps) {
  return (
    <div className="flex gap-1 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-1">
      {tabs.map((tab) => (
        <button
          key={tab.id}
          onClick={() => onChange(tab.id)}
          className={cn(
            'rounded-lg px-4 py-2 text-sm font-medium transition-all',
            activeTab === tab.id
              ? 'gold-gradient text-black'
              : 'text-[var(--color-text-muted)] hover:text-white hover:bg-[var(--color-bg-hover)]',
          )}
        >
          {tab.label}
        </button>
      ))}
    </div>
  )
}
