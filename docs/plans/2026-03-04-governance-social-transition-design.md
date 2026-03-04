# Governance to Social Hub Transition

## Summary

Replace the standalone governance page and existing chat room structure with a tier-based channel system. Governance functionality (polls/voting) moves into dedicated governance rooms within the social hub. Proposal submission is removed.

## New Channel Structure

| Category | Rooms | Access |
|----------|-------|--------|
| Standard | general-chat, announcements | All members |
| VIP | general-chat, announcements, governance | VIP+ |
| High Roller | general-chat, announcements, governance | High Roller+ |
| Whale | general-chat, announcements, governance | Whale only |

11 rooms total. All rooms visible to every member in the sidebar. Rooms the user cannot access show a lock icon. Clicking a locked room does not enter it — entry is fully blocked.

## Room Types

### general-chat
Normal chat room. Full message input bar with text, emotes, and GIFs.

### announcements
Admin-only posting. The chat input bar is hidden for non-admin members. Admins see a normal input bar and can post text messages. Members can add/remove emoji reactions on announcements but cannot send messages, emotes, or GIFs.

### governance
Polls only. No chat input bar. No messages. The room displays a scrollable list of poll cards (newest first). Members vote inline on each poll.

## Poll System

### Admin Poll Creation (Admin Panel)
When creating a poll, admin selects:
- Title and description
- Options (minimum 2)
- End date/time
- Target tiers (multi-select: VIP, High Roller, Whale)

### Tier Routing
A poll's `target_tiers` determines which governance rooms display it:
- Poll targeting [VIP, High Roller] appears in both VIP and High Roller governance rooms
- Poll targeting [VIP, High Roller, Whale] appears in all three governance rooms

### One Vote Per Poll, Globally
A member gets exactly one vote per poll regardless of how many governance rooms display it. The existing `VoteBallot` unique constraint on `(vote_id, user_id)` enforces this. A Whale who votes in the High Roller governance room cannot vote again in the Whale governance room. Both rooms reflect the vote immediately.

### Poll Card UI
Each poll renders as a card within the governance room:
- Title, description
- Options as clickable buttons
- Live vote counts and percentages
- Countdown timer to deadline
- Once voted: selected option highlighted, buttons disabled
- Expired polls: final results with winner highlighted

### Real-Time Updates
When a vote is cast, broadcast via WebSocket to all governance rooms that contain that poll. All rooms update live.

## Database Changes

### Channels
- Delete all existing channel rows
- Insert 11 new channels with `category`, `name`, `tier_required`
- Add `room_type` column to channels: `chat` | `announcements` | `governance`

### Votes Table
- Add `target_tiers` column (JSONB array of tier strings)
- Drop `min_tier_required` and `vote_type` columns
- Keep `VoteBallot` table unchanged (unique constraint on vote_id + user_id already correct)

### Removed
- `GovernanceProposal` model and all proposal endpoints — proposal submission is removed

## Frontend Changes

### Social Page
- Sidebar: group channels by tier category with collapsible headers
- Lock icon on inaccessible rooms, block entry on click
- Main area renders conditionally based on `room_type`:
  - `chat`: current behavior (full input bar)
  - `announcements`: hide input bar for non-admins, keep reaction buttons on messages
  - `governance`: no input bar, render poll cards fetched from governance API

### Deleted
- `/governance` page and all associated components
- Governance nav link from sidebar/navigation

### Admin Panel
- Update "Create Vote" form: replace vote_type dropdown with multi-select tier picker (VIP, High Roller, Whale)
- Remove Proposals tab entirely
