# BlakJaks iOS App — Master Strategy & Design Brief

**Version:** 5.0 (Unified + Xcode Implementation — Platform Alignment Update)  
**Date:** February 19, 2026  
**Platform:** iOS 16.0+ (Swift 5.9, SwiftUI)  
**Xcode:** 15.0+  
**Architecture:** MVVM + Clean Architecture  
**Purpose:** The single authoritative document for designing and building the BlakJaks iOS app — combining feature requirements, development strategy, design standards, Xcode configuration, and implementation patterns into one comprehensive reference.

---

## Table of Contents

1. [Mission Statement](#1-mission-statement)
2. [Project Overview](#2-project-overview)
3. [Development Strategy](#3-development-strategy)
4. [Required Features](#4-required-features)
5. [Navigation Structure](#5-navigation-structure)
6. [Design System & Standards](#6-design-system--standards)
7. [Technical Architecture](#7-technical-architecture)
8. [Xcode Project Configuration](#8-xcode-project-configuration)
9. [Critical User Flows](#9-critical-user-flows)
10. [Platform-Specific Considerations](#10-platform-specific-considerations)
11. [Age Verification & Compliance](#11-age-verification--compliance)
12. [Quality Standards & Agent Guidelines](#12-quality-standards--agent-guidelines)
13. [Battery & Resource Efficiency](#13-battery--resource-efficiency)
14. [Development Phases](#14-development-phases)
15. [Design Deliverables](#15-design-deliverables)
16. [Inspiration & References](#16-inspiration--references)
17. [Quick Reference Cheat Sheet](#17-quick-reference-cheat-sheet)
18. [Final Checklist](#18-final-checklist)

---

## 1. Mission Statement

Design and build a **premium, modern, and highly intuitive iOS app** for BlakJaks — the world's first nicotine brand with crypto rewards. The app must feel like a luxury product while delivering seamless crypto wallet integration, social features, and e-commerce.

**Design Authority:** The developer/agent has full creative control over visual design, UI patterns, animations, and user flows. The requirements below define WHAT features to build, but YOU decide HOW they look and feel — guided by the design standards in Section 6.

**Design Philosophy:** Modern. Intuitive. Premium. Fast. Delightful.

---

## 2. Project Overview

### What is BlakJaks?

BlakJaks is a premium nicotine pouch brand that rewards users with USDT cryptocurrency for scanning QR codes on product tins. Users can spend their crypto via an integrated Oobit card at any Visa merchant.

### Target Audience

- **Age:** 21+ (tobacco product)
- **Tech-Savvy:** Comfortable with crypto but shouldn't need to be experts
- **Premium Seekers:** Value quality, exclusivity, status
- **Social:** Want to engage with brand community

### Core Value Proposition

"Scan. Earn. Spend. Simple crypto rewards for loyal customers."

---

## 3. Development Strategy

### 3.1 Core Philosophy: Vertical Slices

**Build complete features end-to-end, not horizontal layers.**

❌ **Don't do this (Horizontal):**
```
Step 1: Build all ViewModels
Step 2: Build all Views
Step 3: Build all networking
Step 4: Integrate everything (chaos ensues)
```

✅ **Do this (Vertical):**
```
Feature 1: Authentication (View + ViewModel + API + tests) - COMPLETE
Feature 2: Scan & Wallet (View + ViewModel + API + tests) - COMPLETE
Feature 3: Insights Dashboard (View + ViewModel + API + tests) - COMPLETE
```

**Why?** Each completed vertical slice produces a working, testable feature. Multiple agents can work in parallel on separate slices without creating integration nightmares. Every slice is independently demonstrable and shippable.

---

### 3.2 Risk Mitigation

**Biggest Risks & How to Address:**

| Risk | Mitigation Strategy |
| :---- | :---- |
| **Third-party SDK integration fails** | Build mock interfaces first, integrate real SDKs only after UI is working |
| **Performance issues** | Profile early, use LazyVStack from start, follow performance guidelines in Section 12 |
| **API changes break app** | Version APIs (v1, v2), use DTOs for decoupling, protocol-based API client |
| **Design doesn't feel premium** | Get design system right first, iterate on feel before adding features |
| **App Store rejection** | Follow compliance checklist early — age gate, warning banner, privacy labels (tobacco + crypto = extra scrutiny) |
| **Multi-agent code conflicts** | Protocol-based architecture, consistent MVVM patterns, git tagging after each working feature |

**De-risking Tactics:**

1. **Start with mocks:** Don't wait for backend APIs. Build UI with mock data first.
2. **Integrate one SDK at a time:** Don't try to integrate MetaMask + Oobit + AgeChecker simultaneously.
3. **Test on real device early:** Don't rely solely on simulator (Face ID, camera, performance).
4. **Keep rollback points:** Git tag after each working feature.

---

### 3.3 Mock Data Strategy

**Build with mock data FIRST, then swap to real APIs.**

**Why?**
- Don't wait for backend APIs to be ready
- Faster iteration on UI
- Easy to test edge cases (errors, empty states)
- Multiple agents can build features in parallel without backend dependencies

**Architectural Pattern:**

#### Step 1: Protocol-Based API Client

```swift
// APIClient protocol - allows swapping mock/real
protocol APIClientProtocol {
    func login(email: String, password: String) async throws -> AuthResponse
    func getCurrentUser() async throws -> User
    func getProducts() async throws -> [Product]
    func submitScan(qrCode: String) async throws -> ScanResponse
    func getWallet() async throws -> Wallet
    func getTransactions() async throws -> [Transaction]
    func getInsightsOverview() async throws -> InsightsOverview
    // ... all endpoints
}

// Real API client
class APIClient: APIClientProtocol {
    // Real network calls via Alamofire
}

// Mock API client (for development)
class MockAPIClient: APIClientProtocol {
    func getCurrentUser() async throws -> User {
        return User(
            id: "123",
            name: "Joshua",
            email: "josh@example.com",
            tier: "High Roller",
            memberId: "BJ-0001-HR",
            walletAddress: "0x1234...5678"
        )
    }
}
```

#### Step 2: MockData Folder

```
MockData/
  ├── MockUser.swift
  ├── MockProducts.swift
  ├── MockTransactions.swift
  ├── MockScans.swift
  ├── MockInsights.swift
  ├── MockComps.swift
  └── MockAPIClient.swift
```

Each file should contain realistic sample data matching real API response formats.

#### Step 3: Toggle in App Initialization

```swift
// In BlakJaksApp.swift
let useMockData = true  // Toggle this

let apiClient: APIClientProtocol = useMockData 
    ? MockAPIClient() 
    : APIClient.shared
```

**Benefit:** Build entire features with mock data, then flip one switch to test with real APIs.

---

### 3.4 SDK Integration Order

**Integrate SDKs in this dependency order — never skip ahead.**

| SDK | Integrate When | Dependency |
| :---- | :---- | :---- |
| **Alamofire** | First — before any feature | Required for all API calls |
| **KeychainAccess** | With Authentication | Required for JWT token storage |
| **MetaMask Embedded Wallets SDK** | After Scan & Wallet UI works with mocks | Required before Oobit (wallet must exist first) |
| **Kintsugi** | After Checkout UI works with mocks | Tax calculation for checkout |
| **AgeChecker.net** | After Checkout UI works with mocks | Age verification for checkout |
| **Oobit Plug & Pay SDK** | After MetaMask is working | Card links to wallet — MetaMask must work first |
| **Socket.IO-Client-Swift** | After Social Hub UI works with mocks | Socket.io for real-time chat (backend uses python-socketio) |
| **APNs (Apple Push Notifications)** | After core features complete | Push notifications — native, no Firebase on iOS |
| **Intercom** | With Profile & Settings | Customer support chat |

**Rule:** Always build the UI with mocks first, then integrate the real SDK.

---

### 3.5 Git Tagging Strategy

**Tag after each working feature for rollback safety:**

```shell
# After each working feature
git add .
git commit -m "feat: Add [FEATURE] with [DETAILS]"
git tag v0.[X]-[feature]-working
git push
git push --tags
```

**Example progression:**

```
v0.1-auth-working
v0.2-scan-wallet-ui-working
v0.3-insights-dashboard-working
v0.4-shop-checkout-working
v0.5-metamask-integration-working
v0.6-oobit-integration-working
v0.7-social-hub-working
v0.8-profile-settings-working
v0.9-polish-complete
v1.0-launch
```

**Why tags?** If something breaks, you can instantly go back to the last working version. Critical when multiple agents are committing code.

---

## 4. Required Features (WHAT to Build)

### 4.1 Authentication

**Required Flows:**

1. **Splash/Welcome Screen**
   - Brief intro to BlakJaks
   - "Get Started" CTA
   - "I already have an account" link

2. **Signup**
   - Email, password, confirm password
   - First name, last name
   - Birthdate (must be 21+)
   - Accept Terms & Conditions
   - Auto-create crypto wallet on signup (MetaMask Embedded Wallets SDK)

3. **Login**
   - Email, password
   - "Forgot password?" link
   - Face ID / Touch ID option (after first login)

4. **Forgot Password**
   - Enter email
   - Receive reset link
   - Set new password

**Backend Integration:**

- API: `POST /auth/signup`, `POST /auth/login`, `POST /auth/reset-password`
- Store: JWT token in Keychain
- Wallet: Auto-create on signup via MetaMask Embedded Wallets SDK

**Design Freedom:**

- Social login UI (optional visual, not functional yet)
- Onboarding flow (swipeable cards explaining app)
- Face ID enrollment prompt
- Welcome animation

---

### 4.2 Insights / Transparency Dashboard

**Purpose:** A platform-wide transparency dashboard showing real-time metrics, treasury balances, comp data, partner stats, and system health. This replaces a traditional "Home" screen — BlakJaks leads with radical transparency.

**Navigation Pattern:** Full-screen menu of 5 sub-pages, each opening as an overlay with a back button. The menu items fill the space between the warning banner and bottom nav bar.

**Required Menu Items (Main View):**

1. **Overview**
2. **Treasury**
3. **Systems**
4. **Comps**
5. **Partners**

Each menu item should be a large, full-width button with the page title in a display/serif font, a right-arrow indicator, and an animated canvas background (generative art: particle networks, wave patterns, etc.) for a premium, living feel.

---

**4.2.1 Overview Sub-Page**

**Required Elements:**

- **Global Scan Counter**
  - Large animated counter showing total lifetime scans across all users
  - Live pulse indicator showing "today's scans" count
  - Real-time feel (counter ticking up)

- **Key Vitals Ribbon** (horizontally scrollable)
  - Live Comp Pool balance (50% of Gross Profit)
  - Active Members count
  - Payouts (last 24 hours)

- **Live Activity Feed**
  - Auto-scrolling feed of recent platform events
  - Events: new comp payouts, tier upgrades, large scans, new members
  - Each item shows icon, description, and relative timestamp
  - Header with live pulse indicator

- **Next Milestones**
  - Progress bars showing distance to next comp milestone thresholds
  - e.g., "$100 USDT — 8 away", "$1K USDT — 608 away"
  - Color-coded by comp tier

---

**4.2.2 Treasury Sub-Page**

**Required Elements:**

- **Crypto Wallets** (on-chain, verifiable)
  - Member Treasury wallet (balance, address, copy button, "Verify on PolygonScan" link)
  - Affiliate Treasury wallet (same format)
  - Wholesale Treasury wallet (same format)
  - Each shows: wallet name, USDT balance, truncated address, usage bar

- **Bank Accounts** (via Teller.io integration)
  - Primary Operating account (masked last 4 digits, balance)
  - Reserve Account
  - Comp Pool Account
  - "Last Teller sync" timestamp

- **90-Day Balance History**
  - Sparkline charts for each treasury (Member, Affiliate, Wholesale)
  - Color-coded per treasury type

- **Reconciliation Status**
  - Badge showing "Balanced" or "Alert"
  - Last reconciliation timestamp
  - Tolerance info (e.g., "Daily 5AM · ±$10 tolerance")

- **Payout Ledger**
  - Table showing all payout types, counts, totals, and percentages
  - Types: Crypto $100, Crypto $1K, Crypto $10K, Trip $200K, Casino, $50 Guarantee, 21% Match, Pool 5%, Wholesale
  - Total row at bottom

---

**4.2.3 Systems Sub-Page**

**Required Elements:**

- **Comp Budget Health**
  - Gauge/progress bar showing budget utilization percentage
  - Status badge (Normal, Warning, Critical)
  - Monthly Gross Profit, Budget (50%), Actual Spend
  - Projected end-of-month percentage

- **Payout Pipeline**
  - Queue count, average confirmation time, success rate
  - 24h payouts count and value
  - Pending and failed counts

- **Scan Velocity**
  - Current scans/minute
  - Peak scans/minute
  - Last hour total
  - Processing metrics: avg processing time, P95 latency, error rate, worker count

- **Vault Economy**
  - Chips vaulted, bonus issued, expired counts
  - Vault rules display (e.g., "1 bonus/5 per mo · 365d expiry")

- **Reconciliation Status** (duplicate from Treasury for quick access)
  - Balanced/Alert badge with timestamp

- **Tier Distribution**
  - Stacked bar showing member distribution across tiers
  - Legend: Standard, VIP, High Roller, Whale with counts

---

**4.2.4 Comps Sub-Page**

**Required Elements:**

- **Prize Tiers Grid**
  - Cards for each comp tier: $100, $1,000, $10,000, $200K Trip
  - Each shows: amount, total awarded, eligibility rule
  - Color-coded by tier

- **Next Milestones** (global)
  - Progress bars to next milestone for each comp tier
  - Shows "X away" count

- **$200K Trip Comp Section**
  - Currently eligible count
  - Trips awarded (current + lifetime)
  - Progress to next 500K scan milestone
  - Reserve amount held for trips

- **$50 New Member Guarantee**
  - Total guarantees paid, total value

- **Tier Eligibility Table**
  - Comp, Required Tier, Frequency (every X scans)

- **Vault Economy**
  - Chips vaulted, bonus issued, expired
  - Vault rules

---

**4.2.5 Partners Sub-Page**

**Required Elements:**

- **Affiliate Metrics**
  - Active affiliates count (with live indicator)
  - Affiliate chips issued

- **Sunset Engine Status**
  - Active/Inactive badge
  - Last checked timestamp

- **Weekly Pool (5% GP)**
  - Last payout amount and date
  - Currently accruing amount

- **21% Prize Match**
  - Total prize match paid (lifetime)
  - "No cap" indicator

- **Permanent Tier Floors**
  - Cards: VIP (210 tins), High Roller (2,100 tins), Whale (21,000 tins, "for life")

- **Wholesale Program**
  - Active accounts, chips issued, comps awarded, comp value

- **Partner Treasuries**
  - Affiliate Treasury wallet card (balance, address, verify link)
  - Wholesale Treasury wallet card (same format)

- **Partner Activity Feed**
  - Live feed of partner-related events
  - Similar format to Overview live feed

---

**Insights Backend Integration:**

- API: `GET /insights/overview` (global scan count, vitals, milestones)
- API: `GET /insights/treasury` (wallet balances, bank balances, reconciliation)
- API: `GET /insights/systems` (budget health, pipeline, velocity, vault)
- API: `GET /insights/comps` (prize tiers, milestones, guarantees)
- API: `GET /insights/partners` (affiliate metrics, wholesale, treasuries)
- API: `GET /insights/feed` (live activity events)
- Socket.io: Namespace `/insights` (real-time counter updates, feed events — via Socket.IO-Client-Swift)
- Integration: Teller.io API for bank account balances
- Integration: Polygon RPC for on-chain wallet verification

**Design Freedom:**

- Animated canvas backgrounds for menu items (generative art)
- Sub-page banner designs and transitions
- Counter animation style
- Sparkline chart rendering
- Feed auto-scroll behavior
- Gauge/progress bar visualizations
- Color palette for different treasury/tier types
- Page transition animations (overlay slide-up)

---

### 4.3 Scan & Wallet (Combined Tab — Center Button)

**Purpose:** The app's primary action hub combining the user's identity card, QR scanning, wallet management, transaction history, scan history, and comp vault into one scrollable screen. This is the center tab accessed via the elevated bubble button in the nav bar.

**Required Sections (scrollable, top to bottom):**

---

**4.3.1 Member Card**

- Full-width premium card with gradient background and subtle stripe pattern
- BlakJaks branding mark
- User's full name (display font)
- Tier icon (playing card suit)
- Member ID (e.g., "BJ-0001-HR")
- Current tier name (e.g., "High Roller") highlighted in gold
- Member since year
- **Tier Progress Bar**
  - Visual progress bar showing position toward next tier
  - Current scan count and target (e.g., "18 scans" → "30 for Whale")
- **Oobit Spend Card** (integrated into member card)
  - Masked card number (•••• •••• •••• 4821)
  - Status badge (Active/Inactive)
  - Card network (Visa)

---

**4.3.2 Scan Circle**

- Large circular button centered on screen
- Tap to open scan modal (full-screen overlay)
- Icon: ♠ spade symbol
- Label: "Tap to Scan"
- Sub-label: "QR or NFC"
- Visual states: idle (dark), scanning (gold glow + shadow)

**Scan Modal (Full-Screen Overlay):**

**State 1: Camera Viewfinder**
1. Full-screen camera view with corner guide brackets
2. Animated laser sweep line
3. Hint text: "Align QR code within frame"
4. "Enter Code Manually" button below viewfinder
5. Close button (X) in header
6. Auto-detect QR code
7. Haptic feedback on successful scan

**State 2: Manual Entry**
1. Icon and title ("Enter Code Manually")
2. Subtitle explaining format
3. Large monospace text input (centered, letter-spaced)
4. Placeholder showing expected format
5. "Submit" button
6. "Back to Camera" link
7. Validate format before submission

**State 3: Confirmation (Rich Modal)**
1. Animated checkmark circle
2. Product name scanned (e.g., "BlakJaks Mint Ice")
3. Scan confirmation text
4. **Tier Progress Card**
   - Quarter/period label (e.g., "Q1 2026 Tier Progress")
   - Current tier name with icon
   - Progress count badge (e.g., "18 / 30")
   - Progress bar (visual fill)
   - Tier range labels (e.g., "High Roller (15+)" → "Whale at 30")
   - Tier bump message (e.g., "+1 scan · 12 more to reach Whale tier")
5. **Comp Earned Card**
   - "Comp Earned" header
   - Large USDT amount earned from this scan
   - Detail text (e.g., "USDT added to your vault · Pending payout")
   - Breakdown row: Lifetime Comps | Wallet Balance | Gold Chips
6. "Done" button

**QR Code Format:**

- Expected: `XXXX-XXXX-XXXX` (12 alphanumeric characters, character set A-Z and 2-9, excluding 0, O, 1, I to avoid ambiguity)
- Example: `A3K7-B9M2-X4P6`
- The QR payload is just the 12-character code; submit via `POST /scans/submit`

**Error Handling:**

- Invalid QR code
- Already scanned QR code
- Server error
- Network error

---

**4.3.3 Wallet Section**

- Section divider: "Wallet"
- **Balance Card** (prominent, centered, with glow border)
  - "Available Balance" label
  - Large USDT amount (display font)
  - "USDT · Polygon" network indicator
  - Action buttons: "Send" and "Receive"
- **Wallet Address** (below balance)
  - Truncated address (0x1234...5678)
  - Copy to clipboard button
  - QR code view (for receiving)

---

**4.3.4 Transactions**

- Section header: "Transactions"
- Chronological list of all wallet transactions
- Each transaction shows:
  - Description (Comp Payout, Oobit Card Spend, Wallet Fund, etc.)
  - Date
  - Amount (+/- with color: green for credits, red for debits)
  - Status indicator
  - Transaction hash (tappable → PolygonScan)
- Filter options: All, Deposits, Withdrawals
- Pending transactions in gray/dimmed state

---

**4.3.5 Scan History**

- Section divider: "Scan History"
- List of recent scans
- Each scan shows:
  - Product name (e.g., "BlakJaks Mint Ice")
  - USDT earned and relative timestamp (e.g., "+$4.50 USDT · 2h ago")
  - Confirmation badge (✓)

---

**4.3.6 Comp Vault**

- Section divider: "Comp Vault"
- **Lifetime Comps Card** (prominent, centered, glow border)
  - "Lifetime Comps" label
  - Large total amount (display font, gold)
  - Breakdown: "Crypto + Trips + Gold Chips"
- **Filter Tabs:** All | Crypto | Trips | Gold Chips
- **Comp History List**
  - Each comp shows:
    - Type icon (₮ for crypto, ✈ for trips, ♠ for gold chips)
    - Description and amount
    - Type and date
    - Status badge (paid, redeemed, available, pending)

---

**4.3.7 Oobit Card Integration**

- Integrated into Member Card section (see 4.3.1)
- Card activation status
- "Activate Oobit Card" button (if not activated)
- "Add to Apple Pay" button (once activated)
- Link to Oobit widget for management

---

**Scan & Wallet Backend Integration:**

- API: `GET /users/me` (user profile, tier, member card data)
- API: `GET /users/me/stats` (tier progress, scan counts)
- API: `POST /scans/submit` (qr_code, timestamp, location?)
- Response: Full rich response per Platform v2 spec: `{success, product_name, usdt_earned, tier_multiplier, tier_progress, comp_earned, milestone_hit}`
- API: `GET /users/me/wallet` (balance, address)
- API: `GET /transactions` (wallet transaction history)
- API: `POST /wallet/withdraw` (address, amount)
- API: `GET /scans/recent` (scan history)
- API: `GET /users/me/comps` (comp vault history)
- SDK: MetaMask Embedded Wallets SDK (wallet access, signing)
- SDK: Oobit Plug & Pay SDK (card activation, Apple Pay)

**Design Freedom:**

- Member card gradient and visual treatment
- Scan circle idle/active animations
- Scan modal transitions and celebration effects
- Wallet card design
- Transaction list layout
- Comp vault card designs
- Section divider styling
- Empty states for new users (no scans, no transactions, no comps)
- Pull-to-refresh
- Loading states and skeletons
- Withdrawal flow UI
- Security confirmations for sends

---

### 4.4 Shop

**Purpose:** E-commerce for purchasing BlakJaks products

**Required Screens:**

**4.4.1 Product Selection (Streamlined Single-Page)**

- **Flavor Selection Grid** (2-column grid of flavor cards)
  - Each flavor card shows:
    - Flavor image/emoji
    - Flavor name (e.g., "Spearmint", "Wintergreen", "Bubblegum", "Bluerazz Ice")
    - Brief descriptor (e.g., "Cool & crisp", "Bold & icy")
    - Selection state: checkmark badge appears when selected
    - Tap to select (single selection)
- **Strength Selector** (horizontal button row)
  - Options: 3mg, 6mg, 9mg, 12mg
  - Tap to select (single selection, gold highlight when active)
- **Quantity & Price Row**
  - Quantity adjuster (+/- buttons with count display)
  - Live price display (updates with quantity, display/serif font)
- **"Add to Cart" Button**
  - Full-width gold gradient CTA
  - Disabled state until flavor and strength are selected
  - Animated shine effect
- **Cart Summary** (below Add to Cart)
  - Shows current cart contents summary when items are added
- **Product Features** (small pill badges)
  - e.g., "$2.99 Flat Shipping", "Free Shipping $50+", "QR Code Inside", "Earn USDT"
- **Cart Button** (in header, top right)
  - Cart icon with item count badge
  - Taps to open cart view

**4.4.2 Cart**

- List of items in cart
- Each item shows:
  - Thumbnail, name, quantity
  - Price per unit
  - Subtotal
  - Quantity adjuster (+/-)
  - Remove button
- Subtotal
- Shipping ($2.99 flat rate, free on orders $50+)
- Tax (calculated at checkout)
- Total
- "Proceed to Checkout" button
- "Continue Shopping" link
- Empty cart state

**4.4.3 Checkout**

- **Step 1: Shipping Address**
  - First/Last name
  - Address line 1, 2
  - City, State, ZIP
  - Country (default: USA)
  - Phone number
  - "Save for future" checkbox

- **Step 2: Age Verification**
  - AgeChecker.net popup integration
  - Auto-fills from shipping address
  - User verifies age via third-party

- **Step 3: Payment**
  - Payment method selector (TBD — pluggable)
  - Billing address (same as shipping checkbox)

- **Step 4: Review & Confirm**
  - Order summary
  - Shipping address
  - Payment method
  - Total breakdown (subtotal, shipping, tax, total)
  - "Place Order" button

**4.4.4 Order Confirmation**

- Order number
- Estimated delivery date
- Email confirmation sent
- "Track Order" button
- "Continue Shopping" button

**Shop Backend Integration:**

- API: `GET /shop/products` (all products with flavors and strengths)
- API: `POST /cart/add` (product_id, flavor, strength, quantity)
- API: `GET /cart` (current cart)
- API: `PUT /cart/update` (item_id, quantity)
- API: `DELETE /cart/remove` (item_id)
- API: `POST /orders/create` (checkout data)
- API: `POST /tax/estimate` (Kintsugi — shipping address, items)
- SDK: AgeChecker.net (age verification popup)

**Design Freedom:**

- Flavor card design and selection animation
- Strength button styling
- Quantity/price row layout
- Add to Cart button effects (shine, haptic)
- Cart UI
- Checkout flow (stepper, tabs, pages)
- Payment UI placeholder
- Order tracking UI
- Empty states

---

### 4.5 Social Hub

**Purpose:** Community engagement via Discord-style channels and live streams

**Required Sections:**

**4.5.1 Channels (Discord-Style)**

**Channel Categories:**

1. **General**
   - #announcements (read-only, admin posts)
   - #general-chat
   - #introductions

2. **High Roller Lounge** (Tier-locked: Gold+)
   - #vip-chat
   - #exclusive-deals

3. **Comps & Crypto**
   - #comp-claims
   - #wallet-talk
   - #trading-tips

4. **Governance**
   - #proposals
   - #voting

**Channel UI:**

- Left sidebar: Category headers (collapsible)
- Channel list under each category
- Lock icon for tier-locked channels
- Unread badge on channels
- "Join" button for voice channels

**Chat View:**

- Message feed (newest at bottom)
- Each message shows:
  - User avatar (or initials)
  - Username
  - Tier badge
  - Timestamp
  - Message content
  - Reactions (optional)
- Message input at bottom
- Emoji picker
- GIF picker (Giphy integration)
- **7TV Animated Emotes**
  - Animated emotes rendered inline in chat messages (WebP/AVIF format)
  - Dedicated tab/section in the media picker alongside GIFs and emoji
  - Emote set curated by BlakJaks admin via 7TV dashboard
  - Emotes cached locally after first load (TTL: 1 hour refresh from API)
  - 7TV CDN serves emote images: `https://cdn.7tv.app`
  - Backend caches the emote set and serves it via API; iOS app renders them inline
- Image upload (optional)
- Scroll to bottom button

**Chat Translation (v1):**

- Messages are stored with their original language tag
- Each message displays a small flag icon showing the original language
- User taps the flag icon to request translation to their preferred language
- Backend translates on demand via Google Cloud Translation API and caches the result (same message + language = cache hit)
- User sets preferred language in Profile → Settings → Language Preference
- Supported languages: English, Spanish, Portuguese

**4.5.2 Live Streams**

**Stream Player:**

- HLS video player (via StreamYard RTMP server)
- Stream title
- Host name
- Viewer count (live)
- "LIVE" badge
- Full screen button

**Live Chat:**

- Real-time chat alongside stream
- Same message format as channels
- Chat moderation indicators

**Schedule:**

- Upcoming streams list
- Past streams (VOD if available)
- "Notify me" button for scheduled streams

**4.5.4 Notifications**

- System notifications (app announcements)
- Social notifications (mentions, replies)
- Comp notifications (USDT received)
- Order notifications (shipping updates)

**Social Hub Backend Integration:**

- Socket.io: Namespace `/social` (real-time chat — via Socket.IO-Client-Swift, backend uses python-socketio)
- API: `GET /social/channels` (channel list)
- API: `GET /social/channels/:id/messages` (chat history)
- API: `POST /social/channels/:id/messages` (send message)
- API: `GET /streaming/live` (current live streams)
- HLS: `https://cdn.blakjaks.com/hls/[stream_key].m3u8` (live video)

**Design Freedom:**

- Channel layout (sidebar, tabs, nested)
- Chat bubble design
- Live stream UI
- Notification center design
- Dark mode optimization

---

### 4.6 Profile & Settings

**Required Sections:**

**4.6.1 Profile Overview**

- Profile picture (avatar upload)
- Username
- Tier badge
- Member since date
- Total scans
- Lifetime USDT earned

**4.6.2 Account Settings**

- Edit profile (name, username, email)
- Change password
- Notification preferences
  - Push notifications toggle
  - Email notifications toggle
  - Notification types (comps, social, orders)
- Biometric login toggle (Face ID)

**4.6.3 Affiliate Dashboard** (if user is affiliate)

- Unique referral code
- Referral link (shareable)
- Total referrals
- Active downline
- Commissions earned (USDT)
- Payout history
- "Share Link" button

**4.6.4 Order History**

- List of past orders
- Each order shows:
  - Order number
  - Date
  - Total amount
  - Status (Processing, Shipped, Delivered)
  - "Track" button
  - "Reorder" button

**4.6.5 Support**

- FAQ / Help Center
- Contact Support button (opens Intercom)
- Report a Problem
- App version info

**4.6.6 Legal**

- Terms & Conditions
- Privacy Policy
- Age Verification Policy

**4.6.7 Logout**

- "Log Out" button (with confirmation)

**Profile Backend Integration:**

- API: `GET /users/me/profile` (profile data)
- API: `PUT /users/me/profile` (update profile)
- API: `POST /users/me/avatar` (upload avatar)
- API: `GET /users/me/orders` (order history)
- API: `GET /affiliate/stats` (affiliate dashboard)
- SDK: Intercom (support chat)

**Design Freedom:**

- Profile layout
- Settings organization
- Affiliate dashboard design
- Order history UI

---

## 5. Navigation Structure

### Bottom Tab Bar (Main Navigation)

**5 Tabs:**

1. **Insights** — Chart/analytics icon (📊)
2. **Shop** — Shopping bag icon (🛍)
3. **Scan & Wallet** — Center bubble button (elevated, prominent — branded "SCAN / WALLET" text)
4. **Social** — Chat bubble icon (💬) with notification badge
5. **Profile** — Person icon (👤)

**Tab Bar Specifications:**

- **Tab bar height:** 49pt (83pt with home indicator)
- **Icon size:** 25-30pt, template rendering
- **Label font:** SF Pro, 10pt, Medium weight
- **Active color:** Gold (#D4AF37)
- **Inactive color:** Secondary label color
- **Center Scan button:** 56-64pt, extends 8-12pt above tab bar, gold background

**Design Requirement:** The Scan & Wallet tab should be visually prominent as an elevated center bubble button (larger than other tabs, circular, with gold border and glow effect) to encourage engagement. It serves as the app's primary action hub combining scanning and wallet functionality.

### Sheet Presentations

```swift
// Quick action sheet
.presentationDetents([.medium])

// Expandable content
.presentationDetents([.medium, .large])
.presentationDragIndicator(.visible)

// Custom height
.presentationDetents([.height(280)])

// Critical flow (checkout, payment)
.fullScreenCover(isPresented: $showCheckout) { }
```

### When to Use What

| Pattern | Use Case |
| :---- | :---- |
| **NavigationStack push** | Drill-down: Product list → Detail |
| **Sheet (.medium)** | Quick actions, filters, product preview |
| **Sheet (.large)** | Forms, detailed content |
| **fullScreenCover** | Onboarding, checkout, age verification |
| **Alert** | Confirmations, destructive actions |

---

## 6. Design System & Standards (HOW You Should Approach It)

### 6.1 Creative Authority

You have **complete creative freedom** on visual design, UI patterns, animations, and user flows. The guidelines below are standards to follow, not rigid constraints — use them as a foundation and apply your best judgment for a premium result.

### 6.2 Visual Design Principles

1. **Premium & Modern**
   - High-end aesthetic (think luxury brands)
   - Clean, spacious layouts
   - Subtle animations and transitions
   - Attention to detail (shadows, gradients, micro-interactions)

2. **Intuitive**
   - Clear visual hierarchy
   - Obvious primary actions
   - Familiar iOS patterns
   - Minimal learning curve

3. **Fast & Responsive**
   - Optimistic UI updates
   - Loading states that don't block
   - Smooth 60fps animations
   - Instant feedback on interactions

4. **Accessible**
   - Support Dynamic Type
   - High contrast ratios
   - VoiceOver labels
   - Color-blind friendly

5. **On-Brand**
   - Reflects BlakJaks identity (premium nicotine + crypto)
   - Sophisticated, not gimmicky
   - Trustworthy (handles money)

### 6.3 Premium Design Principles (BlakJaks-Specific)

1. **Generous spacing.** Use 20pt margins. 32-40pt between sections. White space = luxury.
2. **Subtle animations.** 0.3-0.4s with ease-in-out feels more premium than fast/snappy.
3. **Restrained gold.** Use on <10% of interface. Gold is jewelry, not wallpaper.
4. **Typography hierarchy.** Subtle weight changes (Regular → Semibold) over dramatic size changes.
5. **High-quality imagery.** Consistent lighting, clean backgrounds, 1:1 ratio, high resolution.
6. **Dark surfaces.** Use iOS system backgrounds that elevate lighter for depth.
7. **Avoid pure white on pure black.** Use system label colors for comfortable contrast.
8. **Desaturate in dark mode.** Gold #D4AF37 → consider #C9A961 for large elements.

---

### 6.4 Layout & Spacing System

#### The 8-Point Grid

All spacing and sizing should be multiples of **8pt** (with 4pt for fine adjustments). This creates visual rhythm and consistency.

```
4pt  - Fine adjustment (icon padding, badge offset)
8pt  - Minimum spacing (between related elements)
12pt - Tight spacing (label to value)
16pt - Standard spacing (between components, horizontal margins)
20pt - Comfortable spacing (premium feel, section padding)
24pt - Generous spacing (between card sections)
32pt - Section separation
40pt - Major section separation
```

#### Standard Margins & Padding

| Context | Value | Notes |
| :---- | :---- | :---- |
| **Screen edge margins** | 16-20pt | Use 20pt for premium feel |
| **Card internal padding** | 16-20pt | Match screen margins |
| **Section spacing** | 32-40pt | Between major content blocks |
| **List item vertical padding** | 12-16pt | Standard row breathing room |
| **Grid gutters** | 16pt | Between product cards |
| **Button group spacing** | 12-16pt | Between stacked buttons |

#### Safe Areas

**Never hardcode status bar or bottom heights.** Use SwiftUI's built-in safe area handling.

| Device Type | Top Safe Area | Bottom Safe Area |
| :---- | :---- | :---- |
| Home button (iPhone 8) | 20pt | 0pt |
| Notch (iPhone X-13) | 44-47pt | 34pt |
| Dynamic Island (iPhone 14 Pro+) | 54-59pt | 34pt |

```swift
// ✅ CORRECT: Let SwiftUI handle safe areas
ScrollView {
    content
        .padding(.horizontal, 20)
}

// ❌ WRONG: Hardcoded top padding
content
    .padding(.top, 59) // Will break on different devices
```

#### Content Insets for ScrollView

```swift
// Add space at bottom for tab bar clearance
ScrollView {
    content
}
.safeAreaInset(edge: .bottom, spacing: 20) {
    // Tab bar or floating button
}

// iOS 17+: Use contentMargins for edge-to-edge scrolling
ScrollView {
    content
}
.contentMargins(.horizontal, 20, for: .scrollContent)
```

---

### 6.5 Typography System

#### iOS Type Scale (SF Pro)

Use SwiftUI's built-in text styles. They automatically support Dynamic Type.

| Style | Default Size | Weight | Usage |
| :---- | :---- | :---- | :---- |
| `.largeTitle` | 34pt | Regular | Screen titles (Insights, Shop) |
| `.title` | 28pt | Regular | Section headers |
| `.title2` | 22pt | Regular | Card titles |
| `.title3` | 20pt | Regular | Subsection headers |
| `.headline` | 17pt | **Semibold** | Emphasized body text |
| `.body` | 17pt | Regular | Primary content |
| `.callout` | 16pt | Regular | Secondary descriptions |
| `.subheadline` | 15pt | Regular | Supporting text |
| `.footnote` | 13pt | Regular | Timestamps, metadata |
| `.caption` | 12pt | Regular | Labels, badges |
| `.caption2` | 11pt | Regular | Fine print, disclaimers |

#### Font Selection for BlakJaks

```swift
// UI text: Always use SF Pro (system font) for readability
Text("Hey Joshua!")
    .font(.largeTitle.bold())

// Display/branding: Use serif (New York) for premium headlines
Text("BLAKJAKS")
    .font(.system(.title, design: .serif))

// Monospace: For wallet addresses and balances
Text("0x1234...5678")
    .font(.system(.body, design: .monospaced))
```

**Font Rules:**

- **SF Pro** (sans-serif): All UI text, navigation, buttons, body content
- **New York** (serif): Brand headlines, premium display text, tier names
- **SF Mono**: Wallet addresses, transaction hashes, USDT amounts
- SF Pro Display is used automatically at 20pt+ (tighter spacing)
- SF Pro Text is used automatically below 20pt (wider spacing)

#### Line Height & Spacing

- **Optimal line height:** 1.4-1.6x font size
- **iOS tight leading:** Decreases line height by 2pt
- **iOS loose leading:** Increases line height by 2pt
- **Letter spacing:** SF Pro handles tracking automatically per size
- **Minimum readable size:** 11pt (use sparingly)

```swift
// Adjust line spacing for long-form text
Text(description)
    .font(.body)
    .lineSpacing(4) // Adds 4pt between lines
```

---

### 6.6 Color System & Dark Mode

#### BlakJaks Color Palette

**Use iOS system colors as the foundation** — they automatically adapt to dark/light mode, accessibility settings, and elevated contexts (sheets/modals).

```swift
extension Color {
    // Brand Colors
    static let gold = Color(red: 212/255, green: 175/255, blue: 55/255) // #D4AF37
    static let goldDark = Color(red: 201/255, green: 169/255, blue: 97/255) // #C9A961 (desaturated for dark mode)

    // Backgrounds (system colors — automatically adapt to dark/light mode)
    static let backgroundPrimary = Color(UIColor.systemBackground) // #000000 in dark
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground) // #1C1C1E
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground) // #2C2C2E

    // Semantic Colors
    static let success = Color(UIColor.systemGreen) // #32D74B in dark
    static let error = Color(UIColor.systemRed) // #FF453A in dark
    static let warning = Color(UIColor.systemOrange) // #FF9F0A in dark
    static let info = Color(UIColor.systemBlue) // #0A84FF in dark
}
```

#### Text Color Hierarchy

| Level | SwiftUI Color | Opacity (Dark) | Usage |
| :---- | :---- | :---- | :---- |
| **Primary** | `.primary` / `.label` | 100% | Titles, primary content |
| **Secondary** | `.secondary` | 60% | Subtitles, descriptions |
| **Tertiary** | Color(.tertiaryLabel) | 30% | Placeholder text, timestamps |
| **Quaternary** | Color(.quaternaryLabel) | 18% | Disabled text, watermarks |

#### Dark Mode Elevation (No Shadows)

iOS dark mode uses **lighter surfaces** for elevation, not shadows:

```
Base level:     systemBackground           (#000000)  - Main screen
Elevated L1:    secondarySystemBackground  (#1C1C1E)  - Cards, grouped content
Elevated L2:    tertiarySystemBackground   (#2C2C2E)  - Nested cards, popovers
```

Sheets and modals automatically use elevated colors.

#### Gold Accent Usage Rules

**Use gold (#D4AF37) on 5-10% of screen real estate maximum.** Rarity creates luxury.

```
✅ USE GOLD FOR:                    ❌ DON'T USE GOLD FOR:
- Primary CTA buttons               - Large background areas
- Active tab bar icon                - Body text
- Progress indicators               - Secondary buttons
- Tier badges                       - Disabled states
- Important icons                   - Every interactive element
- Small decorative accents          - Borders on everything
```

#### WCAG Contrast Ratios

| Standard | Normal Text | Large Text (18pt+) |
| :---- | :---- | :---- |
| **AA (Minimum)** | 4.5:1 | 3:1 |
| **AAA (Enhanced)** | 7:1 | 4.5:1 |

**Gold on black:** ~5.5:1 ratio — passes AA for large text. For body text, use white/label colors, not gold.

---

### 6.7 Component Sizing Standards

#### Buttons

| Type | Height | Corner Radius | Usage |
| :---- | :---- | :---- | :---- |
| **Primary (Large)** | 50pt | 16pt or capsule | Main CTA ("Scan QR", "Add to Cart") |
| **Standard** | 44pt | 12pt | Secondary actions |
| **Small/Compact** | 36pt | 8pt | Inline actions (use sparingly) |

- **Minimum width:** 88pt (2x touch target)
- **Horizontal padding:** 16-24pt
- **Full-width:** Screen width minus 40pt (20pt margins each side)

#### Text Fields

| Property | Value |
| :---- | :---- |
| **Height** | 44-50pt |
| **Corner radius** | 12-16pt |
| **Horizontal padding** | 12-16pt |
| **Background** | secondarySystemBackground |
| **Border on focus** | 2pt gold |
| **Border on error** | 2pt systemRed |

#### Cards

| Property | Value |
| :---- | :---- |
| **Corner radius** | 16pt (standard), 20pt (hero cards) |
| **Internal padding** | 16-20pt |
| **Background** | secondarySystemBackground |
| **Shadow** | None in dark mode (use surface color elevation) |
| **Nested element radius** | Parent radius minus padding (e.g., 16-16=0, or 8pt max) |

#### Icons (SF Symbols)

| Context | Size | Weight |
| :---- | :---- | :---- |
| **Tab bar** | 25-30pt | Regular-Medium |
| **Navigation bar** | 22-24pt | Regular |
| **Inline with body text** | 17-20pt | Matches text weight |
| **Standalone/feature** | 28-32pt | Medium |
| **Hero/empty state** | 40-48pt | Light-Regular |

#### Avatars

| Context | Size | Shape |
| :---- | :---- | :---- |
| **Compact list** | 24-32pt | Circle |
| **Feed post** | 40-44pt | Circle |
| **Comment** | 32pt | Circle |
| **Profile header** | 88-96pt | Circle |
| **Full profile** | 120-144pt | Circle |

#### Badges & Tags

- **Height:** 20-24pt
- **Horizontal padding:** 8-12pt
- **Corner radius:** 12pt (pill-shaped)
- **Font:** 12-13pt, Medium/Semibold weight
- **Notification dot (no number):** 8x8pt
- **Notification badge (with number):** 18x18pt min, systemRed

#### Touch Targets

**Minimum touch target: 44x44pt.** This is non-negotiable. Even if the visual element is smaller, ensure the tappable area meets this minimum.

```swift
// Small icon with adequate touch target
Button(action: { }) {
    Image(systemName: "bell")
        .font(.system(size: 20))
}
.frame(minWidth: 44, minHeight: 44) // Ensure touch target
```

---

### 6.8 Iconography

- Use SF Symbols (iOS native) where possible
- Custom icons for brand-specific elements (tier badges, product categories)
- Consistent stroke width and style
- Support light/dark mode

---

### 6.9 Image & Asset Guidelines

#### Scale Factors

Focus on **@2x and @3x** only. @1x is obsolete.

| Scale | Devices | Example (60pt icon) |
| :---- | :---- | :---- |
| @2x | iPads, older iPhones | 120×120px |
| @3x | iPhone X and later | 180×180px |

#### Product Images

- **Catalog grid:** 1:1 square aspect ratio (mandatory for grid consistency)
- **Detail hero:** 1:1 or 4:3
- **Banners:** 16:9
- **Minimum resolution:** 800×800px (@2x), 1200×1200px (@3x)
- **Format:** PNG for product shots, JPEG for lifestyle photos
- **Max file size:** ~300KB per image

#### App Icon

- **App Store:** 1024×1024px (no transparency, no rounded corners — iOS adds them)
- **Design:** Stylized BlakJaks monogram on black/charcoal with gold accent
- **Test at small sizes:** Must be recognizable at 29pt (Settings)

---

### 6.10 Animations & Transitions

#### Duration Standards

| Category | Duration | Use Case |
| :---- | :---- | :---- |
| **Quick** | 0.15-0.2s | Button press, toggle, selection |
| **Standard** | 0.3-0.35s | Screen transitions, card expand |
| **Deliberate** | 0.4-0.5s | Modal presentation, complex transitions |
| **Celebration** | 0.8-1.5s | Confetti, tier level-up |

#### Spring Animations (Preferred)

```swift
// iOS 17+ presets (USE THESE)
withAnimation(.smooth) { }         // Gentle, no bounce
withAnimation(.snappy) { }         // Quick, minimal bounce
withAnimation(.bouncy) { }         // Playful bounce

// Custom spring (iOS 16+)
withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { }
// response: How fast (lower = faster)
// dampingFraction: How bouncy (0 = very bouncy, 1 = no bounce)

// For BlakJaks premium feel:
// - UI transitions: .smooth or .spring(response: 0.35, dampingFraction: 0.85)
// - Button feedback: .spring(response: 0.2, dampingFraction: 0.6)
// - Celebrations: .spring(response: 0.5, dampingFraction: 0.7)
```

#### Screen Transitions

```swift
// Hero animation between product list and detail
.navigationTransition(.zoom(sourceID: product.id, in: namespace))

// Custom transitions
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))

// QR scanner: full screen cover slides up
.fullScreenCover(isPresented: $showScanner) {
    ScannerView()
        .transition(.move(edge: .bottom))
}
```

#### matchedGeometryEffect (Hero Transitions)

```swift
@Namespace var animation

// In product list
ProductCard(product: product)
    .matchedGeometryEffect(id: product.id, in: animation)

// In product detail
ProductDetailImage(product: product)
    .matchedGeometryEffect(id: product.id, in: animation)
```

#### Reduce Motion Support

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// Always provide alternatives
withAnimation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.7)) {
    // State change
}

// Replace complex animations with cross-dissolve
.transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
```

**Recommended Animations:**

- Smooth screen transitions
- Loading skeletons (not spinners)
- Success animations (confetti, checkmarks)
- Tier level-up celebrations
- Micro-interactions (button press, toggle switch)
- Scroll-triggered animations

**Avoid:**

- Laggy animations
- Overly complex 3D effects
- Animations that slow down the app

---

### 6.11 Micro-Interactions

#### Button Press Feedback

```swift
struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
```

#### Counter/Balance Animation

```swift
// iOS 17+: Animated numeric transitions
Text(balance, format: .currency(code: "USD"))
    .contentTransition(.numericText(value: balance))
    .animation(.snappy, value: balance)
```

#### Tier Progress Bar

```swift
struct TierProgressBar: View {
    let progress: Double // 0.0 to 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.gold, .gold.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 8)
    }
}
```

#### Pull-to-Refresh

```swift
ScrollView {
    content
}
.refreshable {
    await viewModel.refresh()
}
// SwiftUI handles the indicator automatically
```

#### Swipe Actions

```swift
ForEach(transactions) { transaction in
    TransactionRow(transaction: transaction)
        .swipeActions(edge: .trailing) {
            Button("Details") { }
                .tint(.gold)
        }
}
```

---

### 6.12 Haptic Feedback Standards

#### When to Use Each Type

| Interaction | Haptic Type | SwiftUI Modifier |
| :---- | :---- | :---- |
| **QR scan success** | `.success` | `.sensoryFeedback(.success, trigger: scanSuccess)` |
| **Button tap** | `.impact(.light)` | `.sensoryFeedback(.impact(.light), trigger: tapped)` |
| **Toggle switch** | `.selection` | `.sensoryFeedback(.selection, trigger: toggled)` |
| **Error/invalid input** | `.error` | `.sensoryFeedback(.error, trigger: errorOccurred)` |
| **Tier level-up** | `.impact(.heavy)` + `.success` | Sequence both |
| **Add to cart** | `.impact(.medium)` | `.sensoryFeedback(.impact(.medium), trigger: addedToCart)` |
| **Pull-to-refresh release** | `.impact(.light)` | Built-in with `.refreshable` |
| **Quantity change (+/-)** | `.selection` | `.sensoryFeedback(.selection, trigger: quantity)` |
| **Delete/destructive** | `.warning` | `.sensoryFeedback(.warning, trigger: deleting)` |

#### Implementation

```swift
// iOS 17+ (preferred)
Button("Scan") { scanAction() }
    .sensoryFeedback(.success, trigger: scanResult)

// iOS 16 fallback
UIImpactFeedbackGenerator(style: .light).impactOccurred()
UINotificationFeedbackGenerator().notificationOccurred(.success)
```

#### Rules

- **Don't overuse.** Haptics lose meaning when everything vibrates.
- **Always pair with visual feedback.** Haptics supplement, never replace.
- **Respect system settings.** Haptics are automatically disabled when user turns them off.
- **Prepare generators.** Call `.prepare()` before time-critical haptics to reduce latency.

---

### 6.13 Loading States

#### Skeleton/Shimmer Loading (Preferred Over Spinners)

```swift
// Simple: Use .redacted modifier
ProductCard(product: .placeholder)
    .redacted(reason: .placeholder)

// Premium: Custom shimmer effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.08), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
            )
            .onAppear { phase = UIScreen.main.bounds.width }
            .clipped()
    }
}
```

#### Loading Strategy

| Load Time | Strategy |
| :---- | :---- |
| **< 0.3s** | No indicator needed |
| **0.3-1.0s** | Subtle opacity transition |
| **1.0-3.0s** | Skeleton/shimmer screens |
| **3.0s+** | Skeleton + progress indicator |

#### Optimistic UI Updates

Update the UI **immediately** before the server responds. Revert if the request fails.

```swift
func addToCart(product: Product) {
    // ✅ Update UI immediately
    cart.items.append(product)

    // Send to server in background
    Task {
        do {
            try await apiClient.addToCart(product.id)
        } catch {
            // Revert on failure
            cart.items.removeAll { $0.id == product.id }
            showError("Failed to add to cart")
        }
    }
}
```

---

### 6.14 Empty States

#### Pattern: Illustration + Message + CTA

```swift
// iOS 17+
ContentUnavailableView(
    "No Scans Yet",
    systemImage: "qrcode.viewfinder",
    description: Text("Scan a BlakJaks tin to start earning USDT")
) {
    Button("Scan Now") { showScanner = true }
        .buttonStyle(.borderedProminent)
        .tint(.gold)
}

// Custom for iOS 16
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.gray)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(actionTitle, action: action)
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.gold)
                .cornerRadius(25)
        }
        .padding(40)
    }
}
```

#### Empty States to Design

| Screen | Icon | Title | Message | CTA |
| :---- | :---- | :---- | :---- | :---- |
| **No scans** | qrcode.viewfinder | "No Scans Yet" | "Scan a BlakJaks tin to earn USDT" | "Scan Now" |
| **Empty cart** | cart | "Cart is Empty" | "Browse our premium collection" | "Shop Now" |
| **No transactions** | dollarsign.circle | "No Transactions" | "Earn your first USDT by scanning" | "Start Earning" |
| **No messages** | bubble.left | "No Messages Yet" | "Join the conversation" | "Say Hello" |
| **No orders** | shippingbox | "No Orders" | "Try our premium products" | "Browse Shop" |

**Make them:**

- Friendly and encouraging
- Actionable (clear next step)
- Illustrated or branded

---

### 6.15 Error States

#### Error Display Hierarchy

| Severity | Pattern | Example |
| :---- | :---- | :---- |
| **Field-level** | Inline text below field, red border | "Invalid email format" |
| **Form-level** | Banner at top of form | "Please fix the errors below" |
| **Action-level** | Toast/snackbar | "Failed to add to cart" |
| **Page-level** | Full-screen with retry | "Network error" |
| **System-level** | Alert dialog | "Session expired" |

#### Form Validation with Shake

```swift
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0
        ))
    }
}

// Usage: Increment a counter to trigger shake
TextField("Email", text: $email)
    .modifier(ShakeEffect(animatableData: CGFloat(attempts)))
    .animation(.spring(response: 0.2, dampingFraction: 0.3), value: attempts)
```

#### Network Error View

```swift
struct NetworkErrorView: View {
    let retryAction: () async -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundStyle(.gray)

            Text("No Connection")
                .font(.title2.bold())

            Text("Check your internet and try again")
                .font(.body)
                .foregroundColor(.secondary)

            Button("Retry") { Task { await retryAction() } }
                .buttonStyle(.borderedProminent)
                .tint(.gold)
        }
    }
}
```

#### Error Principles

- **Clear language:** "Payment failed" not "Error 402"
- **Actionable:** Always provide a next step (retry, contact support, go back)
- **Not scary:** Errors happen. Be reassuring, not alarming.
- **Appropriate scope:** Field errors inline, network errors full-screen
- **Haptic pairing:** `.error` haptic with error animations

---

### 6.16 Success & Celebration Animations

#### QR Scan Success (Critical Flow)

```swift
// 1. Haptic: Heavy impact + success notification
UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
}

// 2. Visual: Confetti + USDT earned amount
// Use ConfettiSwiftUI package
.confettiCannon(counter: $confettiCounter, colors: [.gold, .white, .yellow])

// 3. Animated counter showing earned amount
Text("+$\(earnedAmount, specifier: "%.2f") USDT")
    .font(.system(.title, design: .monospaced).bold())
    .foregroundColor(.gold)
    .contentTransition(.numericText(value: earnedAmount))
```

#### Tier Level-Up Celebration

```
// Multi-phase animation:
// Phase 1: Badge scales up with bounce (0.3s)
// Phase 2: Gold glow pulse (0.5s)
// Phase 3: Confetti burst (1.0s)
// Phase 4: New tier name appears (0.3s)
```

#### Animated Checkmark

```swift
struct AnimatedCheckmark: View {
    @State private var trimEnd: CGFloat = 0

    var body: some View {
        Circle()
            .fill(Color.gold)
            .frame(width: 80, height: 80)
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 22, y: 42))
                    path.addLine(to: CGPoint(x: 35, y: 55))
                    path.addLine(to: CGPoint(x: 58, y: 28))
                }
                .trim(from: 0, to: trimEnd)
                .stroke(.black, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            )
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                    trimEnd = 1.0
                }
            }
    }
}
```

---

### 6.17 Scroll Effects

#### Parallax Header

```swift
ScrollView {
    GeometryReader { geometry in
        let offset = geometry.frame(in: .global).minY

        Image("hero")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(
                width: UIScreen.main.bounds.width,
                height: 300 + (offset > 0 ? offset : 0)
            )
            .offset(y: offset > 0 ? -offset : 0)
            .clipped()
    }
    .frame(height: 300)

    // Rest of content
}
.ignoresSafeArea(edges: .top)
```

#### Sticky Section Headers

```swift
ScrollView {
    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
        Section {
            ForEach(products) { ProductRow(product: $0) }
        } header: {
            Text("Premium Collection")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
        }
    }
}
```

#### Snap Carousel (Product Cards)

```swift
// iOS 17+
ScrollView(.horizontal) {
    LazyHStack(spacing: 20) {
        ForEach(products) { product in
            ProductCard(product: product)
                .frame(width: 300, height: 400)
                .scrollTransition { content, phase in
                    content
                        .scaleEffect(phase.isIdentity ? 1.0 : 0.85)
                        .opacity(phase.isIdentity ? 1.0 : 0.6)
                }
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.viewAligned)
.scrollIndicators(.hidden)
```

#### Infinite Scroll / Pagination

```swift
ForEach(viewModel.products) { product in
    ProductCard(product: product)
        .onAppear {
            if product == viewModel.products.last {
                Task { await viewModel.loadMore() }
            }
        }
}

if viewModel.isLoadingMore {
    ProgressView()
        .tint(.gold)
        .padding()
}
```

---

### 6.18 Feature-Specific Design Notes

**QR Scanner:**

- Full-screen camera with corner guide overlay
- Animated scanning line effect (thin gold line moving vertically)
- Semi-transparent dark overlay outside scan area
- "Can't scan?" button for manual entry
- Success: stop camera, show confetti + USDT earned

**Wallet:**

- Large balance display (monospaced, prominent)
- Truncated address with copy button (0x1234...5678)
- Transaction list with color-coded amounts (+green, -red)
- Pending transactions in gray/dimmed state

**Shop:**

- 2-column grid with 1:1 product images
- Sticky category filter bar
- Cart badge on tab icon
- Multi-step checkout with progress indicator

**Social Hub:**

- Discord-style channel sidebar (collapsible categories)
- Chat bubbles with user avatar, tier badge, timestamp
- "LIVE" badge with pulsing animation on active streams

---

## 7. Technical Architecture

### 7.1 SwiftUI Architecture (MVVM)

**Structure:**

```
Features/
  ├── Authentication/
  │   ├── Views/
  │   │   ├── WelcomeView.swift
  │   │   ├── LoginView.swift
  │   │   ├── SignupView.swift
  │   │   └── FaceIDPromptView.swift
  │   ├── ViewModels/
  │   │   └── AuthViewModel.swift
  │   └── Models/
  │       └── User.swift
  │
  ├── Insights/
  │   ├── Views/
  │   │   ├── InsightsMenuView.swift
  │   │   ├── OverviewView.swift
  │   │   ├── TreasuryView.swift
  │   │   ├── SystemsView.swift
  │   │   ├── CompsView.swift
  │   │   └── PartnersView.swift
  │   ├── ViewModels/
  │   │   └── InsightsViewModel.swift
  │   └── Models/
  │       └── InsightsModels.swift
  │
  ├── ScanWallet/
  │   ├── Views/
  │   │   ├── ScanWalletView.swift
  │   │   ├── MemberCardView.swift
  │   │   ├── ScanModalView.swift
  │   │   ├── WalletSectionView.swift
  │   │   ├── TransactionsView.swift
  │   │   └── CompVaultView.swift
  │   ├── ViewModels/
  │   │   ├── ScanWalletViewModel.swift
  │   │   └── ScannerViewModel.swift
  │   ├── Models/
  │   └── QRScannerController.swift
  │
  └── [Shop, Social, Profile...]
```

**Pattern:**

- Each feature is self-contained
- Views are dumb (no business logic)
- ViewModels handle all data fetching and state
- Models are Codable structs

### 7.2 State Management

**Required Patterns:**

- `@Published` properties in ViewModels
- `@StateObject` for ViewModels in Views
- `@ObservedObject` for passed ViewModels
- `@State` for local UI state
- `@AppStorage` for UserDefaults
- Keychain for sensitive data (JWT token)

**Async Strategy: async/await is the default.** Use async/await for all API calls, data loading, and asynchronous operations. Do NOT use Combine for new code. However, if third-party SDKs expose Combine publishers, properly manage their subscriptions:

```swift
// For any Combine publishers from third-party SDKs
private var cancellables = Set<AnyCancellable>()
// Always cancel subscriptions when no longer needed
```

**ViewModel Contract (all ViewModels must follow this pattern):**

```swift
@MainActor
class FeatureViewModel: ObservableObject {
    // Published properties (state)
    @Published var data: DataType?
    @Published var isLoading = false
    @Published var error: Error?
    
    // Dependencies (protocol-based for mock/real swapping)
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // Use async/await for all API calls
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Use concurrent fetching where possible
            async let items = apiClient.getItems()
            async let stats = apiClient.getStats()
            
            let (i, s) = try await (items, stats)
            self.data = i
        } catch {
            self.error = error
        }
    }
}
```

**View Contract:**

```swift
struct FeatureView: View {
    @StateObject private var viewModel = FeatureViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                // Loading skeleton (not spinner)
            } else if let data = viewModel.data {
                // Content
            } else {
                // Empty state
            }
        }
        .task { await viewModel.loadData() }  // Use .task NOT .onAppear
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
}
```

**Key Rules:**
- Always use `@MainActor` on ViewModels
- Always use `.task` instead of `.onAppear` for async work
- Always use `NavigationStack` instead of `NavigationView`
- Always use `[weak self]` in closures to prevent retain cycles
- Always inject `APIClientProtocol` for testability

### 7.3 Networking

**API Client:**

- Base URL: `https://api.blakjaks.com` (dev: `https://dev-api.blakjaks.com`)
- Use Alamofire for HTTP requests
- JWT authentication (Bearer token)
- async/await for all API calls

**Example:**

```swift
class APIClient {
    static let shared = APIClient()
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        // Implementation
    }
}

enum APIEndpoint {
    case login(email: String, password: String)
    case getCurrentUser
    case submitScan(qrCode: String)
    case getInsightsOverview
    case getWallet
    // ... etc
}
```

**Network Performance Best Practices:**

```swift
// ✅ Use async let for parallel requests
async let profile = apiClient.getProfile()
async let stats = apiClient.getStats()
async let scans = apiClient.getRecentScans()
let (p, s, r) = try await (profile, stats, scans)

// ✅ Request deduplication
// Don't fire the same API call twice simultaneously

// ✅ Pagination
// Load 20 items at a time, fetch more on scroll

// ✅ Image caching with SDWebImage or similar
```

### 7.4 Third-Party SDKs

**Must Integrate:**

1. **MetaMask Embedded Wallets SDK** (Web3Auth)
   - Auto-create wallet on signup
   - Sign transactions for withdrawals
   - Display wallet address

2. **Oobit Plug & Pay (WKWebView widget)**
   - No native Swift SDK exists — Oobit is a React Native SDK only
   - Integration pattern: backend generates a short-lived access token via `POST /v1/widget/auth/create-token`, then iOS loads the Oobit widget URL in a `WKWebView`, passing the token as a parameter
   - Widget handles all card activation, KYC, and Apple Pay setup internally
   - Use `WKScriptMessageHandler` to receive events back from the widget (e.g. activation success)
   - BlakJaks backend stores Oobit card ID and activation status on success

3. **AgeChecker.net Client API**
   - JavaScript popup for age verification
   - Integrate in checkout via WebView

4. **Alamofire**
   - HTTP networking

5. **KeychainAccess**
   - Secure token storage

6. **Socket.IO-Client-Swift** (Socket.io)
   - Real-time social chat and insights updates
   - Socket.io handles reconnection, heartbeat, and room management automatically
   - Backend uses python-socketio

7. **APNs (Apple Push Notification service)**
   - Native iOS push notifications (no Firebase dependency)
   - Register for remote notifications in AppDelegate
   - Handle notification payloads (comp awards, order updates, social mentions)

8. **Intercom**
   - Customer support chat

### 7.5 Persistence

**Local Storage:**

- Keychain: JWT token, wallet private key (via Web3Auth)
- UserDefaults: User preferences, last-selected tab
- CoreData: Offline message cache, transaction history (optional)

### 7.6 Code Signing & Distribution

**Build Configurations:**

- Development (`com.blakjaks.app.dev`)
- Staging (`com.blakjaks.app.staging`)
- Production (`com.blakjaks.app`)

**Provisioning:**

- Development profile for testing
- App Store profile for production

**For complete .xcconfig files, provisioning walkthrough, and Info.plist keys, see Section 8.**

---

## 8. Xcode Project Configuration

**Purpose:** Xcode-specific implementation details for AI agents setting up and configuring the project. Section 7 covers WHAT the architecture is; this section covers HOW to configure it in Xcode.

---

### 8.1 Project Settings

**Create the Xcode project with these exact settings:**

```
Product Name: BlakJaks
Organization Identifier: com.blakjaks
Bundle Identifier: com.blakjaks.app
Interface: SwiftUI
Language: Swift
Storage: None (custom data layer)
Include Tests: ✓
Include UI Tests: ✓
```

**General Tab Configuration:**

```
Display Name: BlakJaks
Bundle Identifier: com.blakjaks.app
Version: 1.0.0
Build: 1

Deployment Info:
  - iPhone only (iPad support planned for future release)
  - iOS 16.0+
  - Portrait orientation only

App Icons: AppIcon (in Assets.xcassets)
Launch Screen: LaunchScreen.storyboard (only storyboard in the project — all other UI is SwiftUI)
```

**Signing & Capabilities (add these):**

```
✓ Push Notifications
✓ Background Modes → Remote notifications
✓ Face ID
✓ Camera (for QR scanning)
✓ Associated Domains (for deep linking)
```

---

### 8.2 Updated Project Structure

**This is the authoritative folder structure reflecting the correct feature set:**

```
BlakJaks/
├── App/
│   ├── BlakJaksApp.swift           # @main app entry point
│   └── AppDelegate.swift           # UIKit bridging for Web3Auth + Firebase
│
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift         # Alamofire wrapper (conforms to APIClientProtocol)
│   │   ├── APIClientProtocol.swift # Protocol for mock/real swapping
│   │   ├── APIEndpoint.swift       # Endpoint definitions
│   │   ├── APIError.swift          # Error types
│   │   └── NetworkMonitor.swift    # Reachability
│   │
│   ├── Storage/
│   │   ├── KeychainManager.swift   # Secure storage (JWT, wallet keys)
│   │   ├── UserDefaultsManager.swift
│   │   └── CoreDataManager.swift   # Local persistence (optional)
│   │
│   ├── Services/
│   │   ├── AuthService.swift       # Authentication
│   │   ├── WalletService.swift     # MetaMask Embedded Wallets integration
│   │   ├── PushNotificationService.swift
│   │   └── SocketIOService.swift   # Real-time chat & insights (Socket.IO-Client-Swift)
│   │
│   └── Extensions/
│       ├── Color+Theme.swift       # Brand colors (gold, system colors)
│       ├── View+Extensions.swift
│       └── String+Extensions.swift
│
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   ├── WelcomeView.swift
│   │   │   ├── LoginView.swift
│   │   │   ├── SignupView.swift
│   │   │   └── FaceIDPromptView.swift
│   │   ├── ViewModels/
│   │   │   └── AuthViewModel.swift
│   │   └── Models/
│   │       └── User.swift
│   │
│   ├── Insights/
│   │   ├── Views/
│   │   │   ├── InsightsMenuView.swift
│   │   │   ├── OverviewView.swift
│   │   │   ├── TreasuryView.swift
│   │   │   ├── SystemsView.swift
│   │   │   ├── CompsView.swift
│   │   │   └── PartnersView.swift
│   │   ├── ViewModels/
│   │   │   └── InsightsViewModel.swift
│   │   └── Models/
│   │       └── InsightsModels.swift
│   │
│   ├── ScanWallet/
│   │   ├── Views/
│   │   │   ├── ScanWalletView.swift      # Combined tab (center bubble)
│   │   │   ├── MemberCardView.swift
│   │   │   ├── ScanModalView.swift
│   │   │   ├── WalletSectionView.swift
│   │   │   ├── TransactionsView.swift
│   │   │   ├── ScanHistoryView.swift
│   │   │   └── CompVaultView.swift
│   │   ├── ViewModels/
│   │   │   ├── ScanWalletViewModel.swift
│   │   │   └── ScannerViewModel.swift
│   │   ├── Models/
│   │   │   ├── Wallet.swift
│   │   │   ├── Transaction.swift
│   │   │   └── Scan.swift
│   │   ├── Services/
│   │   │   └── Web3AuthManager.swift     # MetaMask Embedded Wallets
│   │   └── QRScannerController.swift     # AVFoundation wrapper
│   │
│   ├── Shop/
│   │   ├── Views/
│   │   │   ├── ShopView.swift
│   │   │   ├── ProductSelectionView.swift
│   │   │   ├── CartView.swift
│   │   │   └── CheckoutView.swift
│   │   ├── ViewModels/
│   │   │   ├── ShopViewModel.swift
│   │   │   └── CartViewModel.swift
│   │   └── Models/
│   │       ├── Product.swift
│   │       └── Order.swift
│   │
│   ├── Social/
│   │   ├── Views/
│   │   │   ├── SocialHubView.swift
│   │   │   ├── ChannelListView.swift
│   │   │   ├── ChatView.swift
│   │   │   └── LiveStreamView.swift
│   │   ├── ViewModels/
│   │   │   ├── SocialViewModel.swift
│   │   │   └── ChatViewModel.swift
│   │   └── Services/
│   │       └── WebSocketManager.swift
│   │
│   └── Profile/
│       ├── Views/
│       │   ├── ProfileView.swift
│       │   ├── SettingsView.swift
│       │   └── AffiliateDashboardView.swift
│       ├── ViewModels/
│       │   └── ProfileViewModel.swift
│       └── Models/
│           └── UserProfile.swift
│
├── MockData/
│   ├── MockAPIClient.swift         # Conforms to APIClientProtocol
│   ├── MockUser.swift
│   ├── MockProducts.swift
│   ├── MockTransactions.swift
│   ├── MockScans.swift
│   ├── MockInsights.swift
│   └── MockComps.swift
│
├── Resources/
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/
│   │   ├── Colors/
│   │   └── Images/
│   ├── Fonts/                      # Custom fonts (if any)
│   ├── LaunchScreen.storyboard     # Only storyboard — all other UI is SwiftUI
│   └── Info.plist
│
├── Config/
│   ├── Development.xcconfig
│   ├── Staging.xcconfig
│   ├── Production.xcconfig
│   └── Secrets.xcconfig            # API keys (GITIGNORED)
│
└── Supporting Files/
    └── Entitlements.plist          # App capabilities
```

---

### 8.3 Dependencies (Swift Package Manager)

**Add via: Xcode → File → Add Packages...**

| Package | URL | Version | Purpose |
| :---- | :---- | :---- | :---- |
| **Alamofire** | `https://github.com/Alamofire/Alamofire.git` | 5.8.0+ | HTTP networking |
| **Web3Auth Swift SDK** | `https://github.com/Web3Auth/web3auth-swift-sdk.git` | 11.1.0 | MetaMask Embedded Wallets |
| **KeychainAccess** | `https://github.com/kishikawakatsumi/KeychainAccess.git` | 4.2.2 | Secure token/key storage |
| **Socket.IO-Client-Swift** | `https://github.com/socketio/socket.io-client-swift.git` | 16.0.1+ | Socket.io (real-time chat & insights) |
| **SDWebImageSwiftUI** | `https://github.com/SDWebImage/SDWebImageSwiftUI.git` | 2.2.0+ | Async image loading/caching |
| **Giphy iOS SDK** | `https://github.com/Giphy/giphy-ios-sdk.git` | 2.2.0+ | GIF search & picker in social chat |

**Push Notifications:** Use native APNs (UserNotifications framework) — no Firebase on iOS. No third-party package required.

**QR Scanning:** Use AVFoundation directly (no third-party package needed).

**After adding packages:** Verify all appear under Target → General → Frameworks, Libraries, and Embedded Content.

---

### 8.4 Build Configurations

**Create 3 schemes:** Xcode → Product → Scheme → Manage Schemes...

1. **BlakJaks-Dev** (Development)
2. **BlakJaks-Staging** (Staging)
3. **BlakJaks-Production** (Production)

**Development.xcconfig:**

```
// Development Configuration
API_BASE_URL = https:/$()/dev-api.blakjaks.com
ENVIRONMENT = Development
APP_DISPLAY_NAME = BlakJaks Dev
PRODUCT_BUNDLE_IDENTIFIER = com.blakjaks.app.dev
#include "Secrets.xcconfig"
```

**Staging.xcconfig:**

```
// Staging Configuration
API_BASE_URL = https:/$()/staging-api.blakjaks.com
ENVIRONMENT = Staging
APP_DISPLAY_NAME = BlakJaks Staging
PRODUCT_BUNDLE_IDENTIFIER = com.blakjaks.app.staging
#include "Secrets.xcconfig"
```

**Production.xcconfig:**

```
// Production Configuration
API_BASE_URL = https:/$()/api.blakjaks.com
ENVIRONMENT = Production
APP_DISPLAY_NAME = BlakJaks
PRODUCT_BUNDLE_IDENTIFIER = com.blakjaks.app
#include "Secrets.xcconfig"
```

**Secrets.xcconfig (GITIGNORED!):**

```
// API Keys - DO NOT COMMIT
METAMASK_CLIENT_ID = BJKdrHmpqVrRY8g0iLJE2UWdASj0Xqe2qHz_B-U9fgE_eX92RkHUkCV8KUoadSeHcqYtUjHLuNuty2oGF0vt3L0
SENTRY_DSN = https:/$()/your-sentry-dsn
```

**Accessing Config Values in Code:**

Add to Info.plist:

```xml
<key>APIBaseURL</key>
<string>$(API_BASE_URL)</string>

<key>Environment</key>
<string>$(ENVIRONMENT)</string>
```

Swift struct:

```swift
struct Config {
    static let apiBaseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String else {
            fatalError("API_BASE_URL not set in xcconfig")
        }
        return url
    }()

    static let environment: String = {
        guard let env = Bundle.main.object(forInfoDictionaryKey: "Environment") as? String else {
            return "Development"
        }
        return env
    }()
}
```

---

### 8.5 Code Signing & Provisioning

**Development (for building and testing):**

```
Automatically manage signing: ✓
Team: <Developer Team>
Provisioning Profile: Automatic
```

**Production (for App Store):**

```
Automatically manage signing: ✗ (manual)
Team: <Distribution Team>
Provisioning Profile: App Store Distribution Profile
Certificate: iOS Distribution Certificate
```

**Apple Developer Portal Setup (required before distribution):**

1. **Identifiers → App IDs:** Explicit App ID `com.blakjaks.app` with capabilities: Push Notifications, Associated Domains
2. **Certificates:** iOS Development Certificate (testing) + iOS Distribution Certificate (App Store)
3. **Devices:** Register test device UDIDs
4. **Profiles:** Development Profile, Ad Hoc Profile (TestFlight internal), App Store Profile

**APNs Key for Push Notifications:**

1. Apple Developer Portal → Keys → Create new key
2. Enable: Apple Push Notifications service (APNs)
3. Download `.p8` file
4. Note the Key ID and Team ID
5. Store `.p8`, Key ID, and Team ID in Google Secret Manager — referenced by the backend (FastAPI) to send push notifications directly via APNs HTTP/2 API

---

### 8.6 Info.plist Required Keys

**These keys must be present for core features to work:**

```xml
<dict>
    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>

    <!-- Camera (QR Scanning) -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to scan QR codes on product tins</string>

    <!-- Face ID -->
    <key>NSFaceIDUsageDescription</key>
    <string>Use Face ID for secure login</string>

    <!-- Push Notifications -->
    <key>UIBackgroundModes</key>
    <array>
        <string>remote-notification</string>
    </array>

    <!-- Deep Linking (blakjaks:// URL scheme) -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>blakjaks</string>
            </array>
        </dict>
    </array>

    <!-- Web3Auth Redirect -->
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>blakjaks</string>
    </array>

    <!-- Config values from .xcconfig -->
    <key>APIBaseURL</key>
    <string>$(API_BASE_URL)</string>

    <key>Environment</key>
    <string>$(ENVIRONMENT)</string>
</dict>
```

**Missing any of these will cause silent failures:** No camera description = crash on scan. No URL scheme = Web3Auth redirect fails. No background modes = push notifications don't wake app.

---

### 8.7 SDK Integration Setup Code

**AppDelegate.swift (UIKit bridge for Web3Auth + APNs):**

```swift
import UIKit
import Web3Auth
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register for APNs push notifications
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handle Web3Auth redirect after wallet creation/signing
        Web3Auth.handle(url: url)
        return true
    }
}
```

**BlakJaksApp.swift (App entry point):**

```swift
import SwiftUI

@main
struct BlakJaksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Toggle mock data for development
    static let useMockData = true

    static let apiClient: APIClientProtocol = useMockData
        ? MockAPIClient()
        : APIClient.shared

    var body: some Scene {
        WindowGroup {
            RootView() // Age gate → Auth → Main tab bar
        }
    }
}
```

**Note:** `RootView` should handle the flow: Age Gate → Authentication → Main Tab Bar (5 tabs with center bubble). Never use a generic `ContentView`.

---

### 8.8 App Store Metadata Reference

**These values inform design decisions and asset creation:**

```
Name: BlakJaks
Subtitle: Premium Nicotine Rewards
Category: Lifestyle
Age Rating: 17+ (Tobacco/Alcohol References)
Price: Free

Screenshots Required:
  - 6.7" (iPhone 15 Pro Max) — 1290 × 2796px
  - 6.5" (iPhone 11 Pro Max) — 1242 × 2688px
  - 5.5" (iPhone 8 Plus) — 1242 × 2208px

Promotional Text: "Earn crypto rewards with every tin!"
Keywords: nicotine, rewards, crypto, USDT, pouches
Support URL: https://blakjaks.com/support
Privacy Policy: https://blakjaks.com/privacy
```

**Design implication:** All screens should look excellent at 6.7" (primary screenshot device). The age rating of 17+ means Apple will apply extra scrutiny — ensure warning banner is always visible and age gate is robust.

---

## 9. Critical User Flows (Must Get Right)

### Flow 1: First-Time User (Onboarding to First Scan)

1. User opens app
2. Sees welcome screen
3. Taps "Get Started"
4. Completes signup form
5. Wallet auto-created (background)
6. Sees onboarding carousel (optional)
7. Lands on Scan & Wallet tab (center button)
8. Sees member card and "Tap to Scan" circle
9. Taps scan circle
10. Grants camera permission
11. Scans QR code on tin
12. Sees rich confirmation modal (product name, tier progress, comp earned breakdown)
13. Returns to Scan & Wallet tab, sees updated balance and scan history

**Design Goal:** This flow should be delightful and friction-free. The user should understand the value prop (scan = earn) within 60 seconds.

### Flow 2: Purchase Products with Age Verification

1. User browses Shop
2. Selects flavor, strength, quantity on single page
3. Taps "Add to Cart"
4. Proceeds to checkout
5. Enters shipping address
6. **AgeChecker.net popup appears**
7. User completes age verification
8. Popup closes, checkout continues
9. Enters payment info
10. Reviews order (sees tax calculated via Kintsugi)
11. Confirms order
12. Sees order confirmation
13. Receives email confirmation

**Design Goal:** Age verification should feel seamless, not like a barrier. The popup should match app branding.

### Flow 3: Activate Oobit Card & Add to Apple Pay

1. User has earned USDT
2. Navigates to Scan & Wallet tab (center button)
3. Scrolls to wallet section
4. Taps "Activate Oobit Card"
5. Oobit SDK widget opens (modal)
6. User connects their wallet
7. Oobit performs KYC (handled by Oobit)
8. Virtual card issued
9. User taps "Add to Apple Pay"
10. Apple Pay setup flow
11. Card added
12. User can now spend USDT anywhere

**Design Goal:** This should feel magical — turning crypto into spendable money.

### Flow 4: Watch Live Stream & Chat

1. User navigates to Social Hub
2. Sees "LIVE NOW" badge on stream
3. Taps to watch
4. Video player loads (HLS)
5. Live chat appears below/beside video
6. User sends message in chat
7. Message appears in real-time
8. User can tap to scan during stream
9. Returns to stream after scan

**Design Goal:** Feels like Twitch/YouTube Live — engaging, real-time, community-driven.

---

## 10. Platform-Specific Considerations

### 10.1 iOS-Specific Features

**Must Use:**

- Face ID / Touch ID for login
- Apple Pay integration (via Oobit)
- Haptic feedback for key actions (scan success, tier level-up)
- Dynamic Type support
- Dark Mode (primary), Light Mode (optional)
- Push Notifications (APNs)
- Universal Links (deep linking)

### 10.2 Permissions

**Request at Appropriate Time:**

- Camera (when scanner opens)
- Notifications (after first scan or significant event)
- Face ID (after login)
- Location (optional, for scan verification)

**Design Friendly Permission Requests:**

- Explain WHY you need permission before iOS prompt
- Use custom pre-prompt screens
- Gracefully handle denial

### 10.3 App Store Requirements

**Prepare for:**

- App privacy nutrition label (data collection disclosure)
- Age rating: 17+ (Tobacco/Alcohol References)
- In-app purchases disclosure (even though none yet)
- Content warnings

---

## 11. Age Verification & Compliance

### Warning Banner (CRITICAL)

**Display on all screens:**

- Position: Top of screen, below status bar/notch
- Text: "WARNING: This product contains nicotine. Nicotine is an addictive chemical."
- Style: Black background, white text, bold, uppercase
- Height: ~50-60pt
- Must NOT be dismissible
- Must always be visible

**Implementation:**

```swift
struct WarningBanner: View {
    var body: some View {
        Text("WARNING: This product contains nicotine. Nicotine is an addictive chemical.")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.black)
    }
}
// Place at top of every screen, below status bar
// NEVER dismissible
// ALWAYS visible
```

### Age Gate

**On First Launch (Before Any Content):**

- Full-screen age gate
- "Are you 21 or older?"
- Two buttons: "Yes, I'm 21+" and "No"
- If No: Close app or show "You must be 21+ to use this app"
- If Yes: Store in UserDefaults, never ask again
- Include: "By entering, you certify you are 21+"

**During Checkout:**

- AgeChecker.net popup (third-party verification)
- More robust than simple age gate
- Required for product purchases

---

## 12. Quality Standards & Agent Guidelines

### 12.1 Performance Standards

**Must Meet:**

| Metric | Target |
| :---- | :---- |
| **Cold launch** | < 2 seconds |
| **Frame rate** | 60fps (120fps on ProMotion) |
| **API response** | < 1 second perceived |
| **Image load** | Progressive (placeholder → full) |
| **Memory** | No leaks, < 200MB typical |

**View Performance:**

```swift
// ✅ Use LazyVStack/LazyHStack for long lists
LazyVStack {
    ForEach(products) { ProductRow(product: $0) }
}

// ✅ Use .task instead of .onAppear for async work
.task { await viewModel.loadData() }

// ✅ Avoid expensive computations in body
// Move complex logic to ViewModel

// ✅ Use drawingGroup() for complex overlays
complexView
    .drawingGroup() // Renders to Metal texture

// ✅ Equatable conformance to prevent unnecessary redraws
struct ProductCard: View, Equatable {
    let product: Product
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.product.id == rhs.product.id
    }
}
```

**Memory Management:**

```swift
// ✅ Always use [weak self] in closures
apiClient.fetch { [weak self] result in
    self?.handleResult(result)
}

// ✅ Properly manage any Combine subscriptions from third-party SDKs
private var cancellables = Set<AnyCancellable>()

// ✅ Downsample large images before display
func downsample(imageAt url: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
    let maxDimension = max(pointSize.width, pointSize.height) * scale
    let options = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else { return nil }
    let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimension,
        kCGImageSourceCreateThumbnailWithTransform: true
    ] as CFDictionary
    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else { return nil }
    return UIImage(cgImage: cgImage)
}

// ✅ Limit AVPlayer instances (max 1-2 in memory)
```

**Code Quality:**

- SwiftLint compliant
- No force-unwraps in production code
- Comprehensive error handling
- Async/await for all async operations (Combine only for third-party SDK publishers)
- Memory leak free (always use `[weak self]` in closures)

### 12.2 Accessibility

#### VoiceOver Labels

Every interactive element MUST have an accessibility label.

```swift
// ✅ CORRECT
Button(action: scanQR) {
    Image(systemName: "qrcode.viewfinder")
}
.accessibilityLabel("Scan QR Code")
.accessibilityHint("Opens the camera to scan a BlakJaks tin")

// ✅ Group related elements
VStack {
    Text("$47.50")
    Text("Available Balance")
}
.accessibilityElement(children: .combine)
// VoiceOver reads: "$47.50, Available Balance"

// ✅ Hide decorative elements
Image(decorative: "gold-divider")
    .accessibilityHidden(true)
```

#### Dynamic Type Support

```swift
// ✅ Use @ScaledMetric for custom sizes
@ScaledMetric(relativeTo: .body) var iconSize: CGFloat = 24

// ✅ Clamp Dynamic Type range if layout breaks at extremes
.dynamicTypeSize(.large ... .xxxLarge)

// ✅ Adapt layout for accessibility sizes
@Environment(\.dynamicTypeSize) var dynamicTypeSize

if dynamicTypeSize.isAccessibilitySize {
    VStack { /* Stack vertically at large sizes */ }
} else {
    HStack { /* Side by side at normal sizes */ }
}

// ✅ Test in previews
#Preview {
    ContentView()
        .environment(\.dynamicTypeSize, .accessibility3)
}
```

#### Color & Contrast

```swift
// ✅ Respond to accessibility settings
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.colorSchemeContrast) var contrast

// Don't rely solely on color for meaning
HStack {
    Circle().fill(transaction.isPositive ? .green : .red)
    Text(transaction.isPositive ? "+$5.00" : "-$5.00") // Also use text/icons
}

// ✅ Support Button Shapes
@Environment(\.accessibilityShowButtonShapes) var showButtonShapes

Button("Action") { }
    .background(showButtonShapes ? Color.gold.opacity(0.2) : .clear)
    .cornerRadius(showButtonShapes ? 8 : 0)
```

#### Accessibility Reading Order

```swift
// Control VoiceOver order with sort priority
VStack {
    Text("Welcome back!")
        .accessibilitySortPriority(2) // Read first

    Text("$47.50 USDT")
        .accessibilitySortPriority(1) // Read second
}
```

#### Voice Control

```swift
Button("Scan QR Code") { }
    .accessibilityInputLabels(["Scan", "QR", "Camera"]) // Max 4 labels
```

#### Accessibility Checklist

- VoiceOver support on all interactive elements
- Dynamic Type support
- High contrast mode support
- Minimum touch target size: 44x44pt
- Color-blind friendly (don't rely solely on color to convey information)

### 12.3 Feature Completion Checklist (For AI Agents)

**Before marking ANY feature as complete, verify:**

**Functionality:**
- [ ] Code compiles without errors or warnings
- [ ] Feature works as specified in Section 4
- [ ] No crashes or force-unwraps
- [ ] Conforms to `APIClientProtocol` pattern (mock-swappable)

**Architecture:**
- [ ] Follows MVVM pattern (View → ViewModel → Model)
- [ ] View contains zero business logic
- [ ] ViewModel uses `@MainActor` and `@Published`
- [ ] Model structs are `Codable`
- [ ] Uses `async/await` for API calls (Combine only for third-party SDK publishers)
- [ ] Dependencies injected via protocol (not hardcoded)

**UI/UX:**
- [ ] Loading state implemented (skeleton, not spinner)
- [ ] Empty state implemented (friendly, actionable)
- [ ] Error state implemented (clear message, retry option)
- [ ] Follows 8pt grid spacing guideline
- [ ] Gold accent used sparingly (<10% of screen)
- [ ] Animations are smooth (0.3s spring default)
- [ ] Reduce Motion alternative provided

**Accessibility & Quality:**
- [ ] All interactive elements have accessibility labels
- [ ] Supports Dynamic Type
- [ ] No retain cycles (`[weak self]` in closures)
- [ ] Uses `LazyVStack` for lists
- [ ] Uses system colors where appropriate
- [ ] Respects safe areas
- [ ] Minimum 44x44pt touch targets

**If any of these fail:** Fix before moving to the next feature.

### 12.4 When to Refactor vs Rebuild

**Rebuild the component from scratch when:**
- Architecture is wrong (not following MVVM or protocol patterns from this document)
- Multiple interconnected bugs suggest a flawed foundation
- Performance is fundamentally poor (wrong data structure, missing lazy loading)
- The component can't be made to conform to `APIClientProtocol` without major surgery

**Refactor incrementally when:**
- Small UI adjustments needed (spacing, colors, sizing)
- Missing a single state (loading, empty, error)
- Accessibility labels need adding
- A specific bug with a clear cause
- Polish pass (animations, haptics, transitions)

**Decision rule:** If fixing the issue requires changing more than 50% of the file, rebuild. Otherwise, refactor.

### 12.5 Testing Requirements

**Unit Tests (For ViewModels):**

Every ViewModel must have tests covering:
- `loadData()` success — data populates correctly
- `loadData()` failure — error state is set
- `isLoading` state transitions correctly

**Pattern:**

```swift
@MainActor
final class FeatureViewModelTests: XCTestCase {
    var viewModel: FeatureViewModel!
    var mockAPI: MockAPIClient!
    
    override func setUp() {
        mockAPI = MockAPIClient()
        viewModel = FeatureViewModel(apiClient: mockAPI)
    }
    
    func testLoadDataSuccess() async {
        mockAPI.shouldSucceed = true
        await viewModel.loadData()
        
        XCTAssertNotNil(viewModel.data)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testLoadDataFailure() async {
        mockAPI.shouldSucceed = false
        await viewModel.loadData()
        
        XCTAssertNil(viewModel.data)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.error)
    }
}
```

**UI Tests (For Critical Flows):**

Write XCUITest for these flows:
- Signup → lands on Scan & Wallet tab
- Login with valid credentials
- Scan QR code → see rich confirmation
- Add to cart → checkout flow
- Navigate between all 5 tabs

**Pattern:**

```swift
final class AuthenticationUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    func testSignupFlow() {
        let signupButton = app.buttons["Get Started"]
        signupButton.tap()
        
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("test@example.com")
        
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("password123")
        
        app.buttons["Create Account"].tap()
        
        XCTAssertTrue(app.tabBars["Main"].waitForExistence(timeout: 5))
    }
}
```

---

## 13. Battery & Resource Efficiency

### Push Notifications > Polling

**Always use APNs push notifications.** Never poll the server for updates.

- Push: ~0% battery drain (system-managed)
- Polling every 60s: ~8-12% daily battery drain

### Camera (QR Scanner) Lifecycle

```swift
.onAppear { viewModel.startSession() }
.onDisappear { viewModel.stopSession() }  // CRITICAL
.onChange(of: scenePhase) { phase in
    if phase == .background { viewModel.stopSession() }
    if phase == .active { viewModel.startSession() }
}
```

- Use `.medium` capture preset (not `.high`) unless quality-critical
- Only scan for `.qr` type (not all barcode types)
- Stop session immediately after successful scan

### WebSocket Keepalive

- **Chat:** 30-60 second ping interval
- **Live stream:** 20-30 seconds
- **Low Power Mode:** Increase to 120 seconds or disconnect
- Use exponential backoff for reconnection (2s, 4s, 8s, 16s, 32s)

### HLS Video Player

```swift
// Limit buffer to save memory and bandwidth
playerItem.preferredForwardBufferDuration = 10 // 10 seconds
playerItem.preferredPeakBitRate = 1_000_000 // 1 Mbps cap

// Clean up when view disappears
player.replaceCurrentItem(with: nil)

// In Low Power Mode: Force lower quality
playerItem.preferredPeakBitRate = 500_000
playerItem.preferredMaximumResolution = CGSize(width: 640, height: 360)
```

### Location (If Used for Scan Verification)

```swift
// ✅ Best: Single location request (auto-stops)
locationManager.requestLocation()

// ✅ Good: Significant change monitoring (cell towers)
locationManager.startMonitoringSignificantLocationChanges()

// ❌ Avoid: Continuous GPS tracking
locationManager.startUpdatingLocation() // High battery drain
```

---

## 14. Development Phases

**Note:** These phases are organized for efficient parallel execution. Phases with no dependencies between them can be built simultaneously by separate agents. No fixed timeline — move as fast as the work allows.

### Phase 1: Foundation (Must Be First)

- Xcode project setup per Section 8 (folder structure, dependencies, configurations, Info.plist)
- Design system (colors, typography, component library)
- `APIClientProtocol` + `MockAPIClient` + `MockData/` folder
- Warning banner component
- Age gate screen
- Tab bar navigation shell (5 tabs with center bubble)

**Why first:** Everything else depends on this foundation.

### Phase 2: Authentication

- Welcome/splash screen
- Signup flow (with birthdate 21+ validation)
- Login flow
- Forgot password
- Face ID / Touch ID integration
- Keychain JWT storage
- MetaMask Embedded Wallets SDK (wallet auto-creation on signup)

**Depends on:** Phase 1

### Phase 3: Scan & Wallet Tab

- Member card (tier, progress bar, Oobit card display)
- Scan circle button
- Scan modal (camera viewfinder, manual entry, rich confirmation)
- Wallet section (balance card, address, send/receive)
- Transaction history
- Scan history
- Comp vault

**Depends on:** Phase 1, Phase 2 (user must be authenticated)

### Phase 4: Insights Dashboard

- Insights menu (5 animated buttons)
- Overview sub-page (global scan counter, vitals, live feed, milestones)
- Treasury sub-page (crypto wallets, bank accounts, sparklines, reconciliation, payout ledger)
- Systems sub-page (budget health, pipeline, velocity, vault, tier distribution)
- Comps sub-page (prize tiers, milestones, trip comp, guarantees)
- Partners sub-page (affiliate metrics, wholesale, partner treasuries, partner feed)

**Depends on:** Phase 1 (can be built in parallel with Phases 2-3 using mock data)

### Phase 5: Shop & Checkout

- Streamlined product selection (flavor grid, strength, quantity)
- Cart
- Checkout (address, age verification, payment, review)
- Kintsugi tax calculation integration
- AgeChecker.net integration
- Order confirmation

**Depends on:** Phase 1, Phase 2 (can be built in parallel with Phases 3-4 using mock data)

### Phase 6: Oobit Card Integration

- Oobit Plug & Pay SDK setup
- Card activation flow in Scan & Wallet tab
- Apple Pay integration
- KYC flow (handled by Oobit widget)

**Depends on:** Phase 2 (MetaMask), Phase 3 (Scan & Wallet UI)

### Phase 7: Social Hub

- Discord-style channel list with categories
- Chat view (message feed, input, emoji)
- Socket.io real-time messaging (Socket.IO-Client-Swift)
- Live stream player (HLS via AVPlayer)
- Live stream chat
- Notification center

**Depends on:** Phase 1, Phase 2 (can be built in parallel with other phases using mock data)

### Phase 8: Profile & Settings

- Profile overview
- Account settings
- Affiliate dashboard (conditional)
- Order history
- Support (Intercom integration)
- Legal pages
- Logout

**Depends on:** Phase 1, Phase 2

### Phase 9: Polish & Launch Prep

- Animations and micro-interactions throughout
- All empty states finalized
- All loading states finalized
- All error states finalized
- Accessibility audit (VoiceOver, Dynamic Type, contrast)
- Performance optimization (Instruments profiling)
- Push notifications (native APNs — no Firebase on iOS)
- App Store assets (screenshots, description, privacy labels)
- TestFlight beta deployment

**Depends on:** All previous phases

**Parallel Execution Map:**

```
Phase 1 (Foundation) ──────────────────────────────────►
          │
          ├── Phase 2 (Auth) ──────────────────────────►
          │         │
          │         ├── Phase 3 (Scan & Wallet) ──────►
          │         │         │
          │         │         └── Phase 6 (Oobit) ────►
          │         │
          │         ├── Phase 8 (Profile) ────────────►
          │         │
          ├── Phase 4 (Insights) ─────────────────────► [parallel with mock data]
          │
          ├── Phase 5 (Shop) ─────────────────────────► [parallel with mock data]
          │
          ├── Phase 7 (Social) ───────────────────────► [parallel with mock data]
          │
          └─────────────────── Phase 9 (Polish) ─────► [after all features complete]
```

---

## 15. Design Deliverables

### What Should Be Created:

1. **SwiftUI Views** (all screens — Insights dashboard with 5 sub-pages, Scan & Wallet combined tab, Shop, Social, Profile)
2. **View Models** (all business logic)
3. **Models** (data structures)
4. **API Client** (networking layer with protocol pattern)
5. **Mock Data** (complete MockAPIClient and sample data)
6. **Third-party SDK Integrations** (MetaMask Embedded Wallets, Oobit, AgeChecker.net)
7. **Assets** (any custom icons, placeholder images, generative canvas patterns)
8. **Tests** (unit tests for ViewModels, UI tests for critical flows)
9. **README** (setup instructions, architecture overview)

### Design Documentation:

Create a design system document that includes:

- Color palette with hex codes
- Typography scale
- Component library (buttons, cards, inputs)
- Spacing system
- Icon guidelines

---

## 16. Inspiration & References

### Apps to Study (for UX patterns):

**For Premium Feel:**

- Apple Card app (clean, modern, premium)
- Calm app (sophisticated, calming)
- Stripe Dashboard app (polished, professional)

**For Social Features:**

- Discord (channel organization, chat UX)
- Twitch (live streaming, chat)
- Twitter/X (real-time feed)

**For E-Commerce:**

- Nike app (product display, checkout)
- Apple Store app (clean product pages)

**For Crypto Wallets:**

- Coinbase Wallet (simple, clear)
- MetaMask mobile (wallet management)
- Rainbow Wallet (beautiful design)

### Design Systems to Reference:

- Apple Human Interface Guidelines
- iOS 17 Design Kit (Figma)
- SF Symbols library

---

## 17. Quick Reference Cheat Sheet

### Spacing

```
Margins: 20pt | Card padding: 16-20pt | Section gap: 32-40pt
Grid gutter: 16pt | 8pt grid system | Min touch: 44x44pt
```

### Typography

```
Large Title: 34pt | Title: 28pt | Headline: 17pt Semi
Body: 17pt | Caption: 12pt | Min readable: 11pt
SF Pro: UI text | New York: Premium headlines | SF Mono: Wallet/amounts
```

### Colors

```
Gold: #D4AF37 (accent, <10%) | Background: systemBackground
Text: .primary → .secondary → .tertiary → .quaternary
Success: systemGreen | Error: systemRed | Warning: systemOrange
Dark mode gold (large elements): #C9A961
```

### Components

```
Button: 50pt height | Text field: 50pt | Card radius: 16pt
Tab icon: 25-30pt | Avatar (feed): 44pt | Badge: 20-24pt
Center scan button: 56-64pt
```

### Animation

```
Quick: 0.15-0.2s | Standard: 0.3-0.35s | Slow: 0.4-0.5s
Default spring: response 0.35, damping 0.85
Always support Reduce Motion
```

### Haptics

```
Button tap: .impact(.light) | Success: .success
Error: .error | Selection: .selection | Destructive: .warning
Tier level-up: .impact(.heavy) + .success
```

### Performance

```
Launch: <2s | Frame rate: 60fps | API: <1s perceived | Memory: <200MB
Use LazyVStack | Use .task | No force-unwraps | No retain cycles
async/await (default) | Combine (only for third-party SDK publishers)
```

---

## 18. Final Checklist

Before considering the app complete:

**Functionality:**

- [ ] All required features from Section 4 implemented
- [ ] All backend APIs integrated
- [ ] All third-party SDKs working
- [ ] Error handling comprehensive
- [ ] Offline behavior handled

**Design:**

- [ ] Consistent design system applied (Section 6)
- [ ] All screens designed
- [ ] Empty states designed (Section 6.14)
- [ ] Loading states designed (Section 6.13)
- [ ] Error states designed (Section 6.15)
- [ ] Animations smooth (Section 6.10)
- [ ] Haptic feedback mapped (Section 6.12)

**Quality:**

- [ ] No crashes
- [ ] No memory leaks
- [ ] 60fps performance
- [ ] < 200MB memory usage
- [ ] Accessibility support (Section 12.2)
- [ ] Dark mode works
- [ ] Works on small and large screens
- [ ] Reduce Motion supported

**Compliance:**

- [ ] Warning banner always visible
- [ ] Age gate on first launch
- [ ] AgeChecker.net at checkout
- [ ] Terms & Privacy links present

**Polish:**

- [ ] Haptic feedback on key actions
- [ ] Transitions smooth
- [ ] Icons consistent
- [ ] Copy/text reviewed
- [ ] App icon designed

**Resource Efficiency:**

- [ ] Camera lifecycle managed (Section 13)
- [ ] Socket.io keepalive configured (Section 13)
- [ ] HLS player optimized (Section 13)
- [ ] Push notifications (not polling)

**Testing:**

- [ ] Unit tests for all ViewModels
- [ ] UI tests for critical flows
- [ ] Tested on iPhone SE and iPhone 15 Pro Max
- [ ] Tested on iOS 16.0 minimum

---

## Mockup Reference

**Existing Mockup:** `/mnt/project/app-mockup.html`

**How to Use It:**

- ✅ Reference for feature list
- ✅ Inspiration for layout concepts
- ✅ Understanding required elements
- ❌ DO NOT copy visual design exactly
- ❌ DO NOT copy code/HTML
- ❌ It's a starting point, not a template

**Your Job:** Redesign everything from scratch in SwiftUI. Make it better, cleaner, more modern, and more intuitive than the mockup.

---

## Questions & Clarifications

If you need clarification on:

- **Backend APIs:** Assume RESTful JSON APIs, standard HTTP methods
- **Data structures:** Infer from context or ask
- **Third-party SDKs:** Refer to official documentation (MetaMask Embedded Wallets SDK docs, Oobit docs, etc.)
- **Business logic:** Make reasonable assumptions for MVP
- **Edge cases:** Handle gracefully with user-friendly messages

---

**Remember:** Premium. Intuitive. Fast. Delightful.

Now go build something incredible. 🚀

---

*End of BlakJaks iOS Master Strategy & Design Brief v5.0 (Unified + Xcode Implementation — Platform Alignment Update)*
