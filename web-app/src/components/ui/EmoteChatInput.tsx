'use client'

import { useRef, useEffect, useCallback, forwardRef, useImperativeHandle } from 'react'
import { useEmoteStore, getEmoteUrl } from '@/lib/emote-store'

interface EmoteChatInputProps {
  placeholder?: string
  disabled?: boolean
  className?: string
  maxLength?: number
  onSubmit?: () => void
  onChange?: (text: string, isDeleting: boolean) => void
  onFocus?: () => void
  onBlur?: () => void
  onKeyDown?: (e: React.KeyboardEvent) => void
}

export interface EmoteChatInputHandle {
  insertEmote: (name: string, emoteId: string) => void
  getText: () => string
  clear: () => void
  focus: () => void
  isEmpty: () => boolean
}

/**
 * A contentEditable chat input that renders emote images inline.
 * getText() returns plain text with emote names (e.g. "hello KEKW nice").
 */
const EmoteChatInput = forwardRef<EmoteChatInputHandle, EmoteChatInputProps>(
  ({ placeholder, disabled, className, maxLength, onSubmit, onChange, onFocus, onBlur, onKeyDown }, ref) => {
    const editorRef = useRef<HTMLDivElement>(null)
    const emotes = useEmoteStore(s => s.emotes)
    const prevLengthRef = useRef(0)

    function getPlainText(): string {
      const el = editorRef.current
      if (!el) return ''
      let text = ''
      for (const node of Array.from(el.childNodes)) {
        if (node.nodeType === Node.TEXT_NODE) {
          text += node.textContent || ''
        } else if (node instanceof HTMLImageElement) {
          text += node.getAttribute('data-emote-name') || ''
        } else if (node instanceof HTMLElement) {
          text += node.textContent || ''
        }
      }
      return text
    }

    function placeCaretAtEnd() {
      const el = editorRef.current
      if (!el) return
      const range = document.createRange()
      const sel = window.getSelection()
      range.selectNodeContents(el)
      range.collapse(false)
      sel?.removeAllRanges()
      sel?.addRange(range)
    }

    function insertEmote(name: string, emoteId: string) {
      const el = editorRef.current
      if (!el) return

      // Check character limit (emote name + space before + space after)
      const text = getPlainText()
      const extraChars = name.length + (text.length > 0 && !text.endsWith(' ') ? 1 : 0) + 1
      if (maxLength && text.length + extraChars > maxLength) return

      // Add space before if needed
      if (text.length > 0 && !text.endsWith(' ')) {
        el.appendChild(document.createTextNode(' '))
      }

      // Create emote image element
      const img = document.createElement('img')
      img.src = getEmoteUrl(emoteId, '1x')
      img.alt = name
      img.setAttribute('data-emote-name', name)
      img.style.height = '20px'
      img.style.width = 'auto'
      img.style.display = 'inline-block'
      img.style.verticalAlign = 'middle'
      img.style.margin = '0 1px'
      img.draggable = false
      img.contentEditable = 'false'

      el.appendChild(img)
      el.appendChild(document.createTextNode(' '))
      placeCaretAtEnd()
      el.focus()
      triggerChange()
    }

    function triggerChange() {
      const text = getPlainText()
      const isDeleting = text.length < prevLengthRef.current
      prevLengthRef.current = text.length
      onChange?.(text, isDeleting)
    }

    function clearContent() {
      const el = editorRef.current
      if (!el) return
      el.innerHTML = ''
      triggerChange()
    }

    useImperativeHandle(ref, () => ({
      insertEmote,
      getText: getPlainText,
      clear: clearContent,
      focus: () => { editorRef.current?.focus(); placeCaretAtEnd() },
      isEmpty: () => getPlainText().trim().length === 0,
    }))

    const lastValidHTML = useRef('')

    const handleInput = useCallback(() => {
      if (maxLength) {
        const currentText = getPlainText()
        if (currentText.length > maxLength) {
          const el = editorRef.current
          if (el && lastValidHTML.current) {
            el.innerHTML = lastValidHTML.current
            placeCaretAtEnd()
          }
          return
        }
        lastValidHTML.current = editorRef.current?.innerHTML || ''
      }
      triggerChange()
    }, [onChange, maxLength])

    const handleKeyDown = (e: React.KeyboardEvent) => {
      // Save valid state before keypress
      if (maxLength && editorRef.current) {
        lastValidHTML.current = editorRef.current.innerHTML
      }
      onKeyDown?.(e)
      if (e.key === 'Enter' && !e.shiftKey && !e.defaultPrevented) {
        e.preventDefault()
        onSubmit?.()
      }
    }

    // Handle paste — strip HTML, only allow plain text, respect maxLength
    const handlePaste = (e: React.ClipboardEvent) => {
      e.preventDefault()
      let text = e.clipboardData.getData('text/plain')
      if (maxLength) {
        const current = getPlainText().length
        const remaining = maxLength - current
        if (remaining <= 0) return
        text = text.slice(0, remaining)
      }
      document.execCommand('insertText', false, text)
    }

    const isEmpty = getPlainText().trim().length === 0

    return (
      <div className="relative flex-1">
        <div
          ref={editorRef}
          contentEditable={!disabled}
          suppressContentEditableWarning
          onInput={handleInput}
          onKeyDown={handleKeyDown}
          onPaste={handlePaste}
          onFocus={onFocus}
          onBlur={onBlur}
          className={className}
          style={{ minHeight: '1.5em', whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}
        />
        {isEmpty && placeholder && (
          <span
            className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[var(--color-text-dim)]"
            style={{ fontSize: 'inherit' }}
          >
            {placeholder}
          </span>
        )}
      </div>
    )
  },
)

EmoteChatInput.displayName = 'EmoteChatInput'
export default EmoteChatInput
