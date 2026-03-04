# BlakJaks Native App — Fonts

## Included (Google Fonts — OFL)
- `PlayfairDisplay.ttf` — Variable weight font, Playfair Display
- `Sora.ttf` — Variable weight font, Sora
- `Outfit.ttf` — Variable weight font, Outfit

## Required (Commercial — Not Included)
- `Pulpo.otf` — BlakJaks wordmark font. **You must provide this file.**
  - Place the `.otf` file in this folder
  - It is already declared in `Info.plist` under `UIAppFonts`
  - Until added, the logo wordmark will fall back to Playfair Display

## Usage in Code
```swift
// Playfair Display (serif headers)
Text("BLAKJAKS").font(BJFont.playfair(32, weight: .bold))

// Sora (body, UI labels)
Text("Member").font(BJFont.sora(14))

// Outfit (numbers, prices)
Text("$1,250.00").font(BJFont.outfit(24, weight: .heavy))

// Pulpo (logo only — requires Pulpo.otf)
Text("BLAKJAKS").font(BJFont.pulpo(28))
```
