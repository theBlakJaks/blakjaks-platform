# Governance to Social Hub Transition — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the standalone governance page and existing chat rooms with a tier-based channel system where governance (polls/voting) lives inside dedicated governance rooms in the social hub.

**Architecture:** New migration deletes all existing channels and inserts 11 new ones across 4 tier categories (Standard, VIP, High Roller, Whale). A `room_type` column on channels drives frontend behavior (chat/announcements/governance). Votes gain a `target_tiers` JSONB column replacing `vote_type`/`min_tier_required`. The frontend social page conditionally renders chat input, announcement reactions, or poll cards based on room type. The standalone governance page and proposal system are deleted.

**Tech Stack:** Python/FastAPI/SQLAlchemy (backend), Next.js/React/TypeScript (web-app), React/Vite (admin)

---

## Task 1: Database Migration — Channel Restructure + Vote Schema Changes

**Files:**
- Create: `backend/alembic/versions/028_restructure_channels_and_votes.py`
- Modify: `backend/app/models/channel.py`
- Modify: `backend/app/models/vote.py`

**Step 1: Add `room_type` column to Channel model**

In `backend/app/models/channel.py`, add after `sort_order`:

```python
room_type: Mapped[str] = mapped_column(String(20), server_default=text("'chat'"), nullable=False)
```

**Step 2: Modify Vote model — add `target_tiers`, drop old columns**

In `backend/app/models/vote.py`:
- Replace `vote_type` and `min_tier_required` with:
```python
target_tiers: Mapped[list] = mapped_column(JSONB, nullable=False)
```
- Remove `proposal_id` column and `proposal` relationship (proposals are being removed).
- Keep `vote_type` column for now as nullable (will be dropped in migration, but keeping model in sync).

Updated model:
```python
class Vote(UUIDPrimaryKey, UpdateTimestampMixin, Base):
    __tablename__ = "votes"

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str] = mapped_column(String(2000), nullable=False)
    target_tiers: Mapped[list] = mapped_column(JSONB, nullable=False)
    options_json: Mapped[dict | list] = mapped_column(JSONB, nullable=False)
    status: Mapped[str] = mapped_column(
        String(20), server_default=text("'draft'"), nullable=False, index=True
    )
    start_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )

    creator = relationship("User", foreign_keys=[created_by])
    ballots = relationship("VoteBallot", back_populates="vote", cascade="all, delete-orphan")
```

**Step 3: Write the migration**

Create `backend/alembic/versions/028_restructure_channels_and_votes.py`:

```python
"""Restructure channels into tier categories + update votes schema.

Revision ID: k1l2m3n4o5p6
Revises: <previous_revision>
"""
from typing import Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB, UUID

revision: str = "k1l2m3n4o5p6"
down_revision: Union[str, None] = "<previous_revision>"  # chain from 027


def upgrade() -> None:
    conn = op.get_bind()

    # ── 1. Add room_type column to channels ──
    op.add_column("channels", sa.Column("room_type", sa.String(20), server_default=sa.text("'chat'"), nullable=False))

    # ── 2. Delete all existing channels ──
    conn.execute(sa.text("DELETE FROM messages"))  # FK cascade
    conn.execute(sa.text("DELETE FROM channel_tier_access"))
    conn.execute(sa.text("DELETE FROM channels"))

    # ── 3. Look up tier IDs ──
    tiers = conn.execute(sa.text("SELECT id, name FROM tiers")).fetchall()
    tier_map = {name: str(tid) for tid, name in tiers}
    vip_id = tier_map.get("VIP")
    high_roller_id = tier_map.get("High Roller")
    whale_id = tier_map.get("Whale")

    # ── 4. Insert new channels ──
    # (name, description, category, tier_required_id, is_locked, sort_order, room_type)
    channels = [
        # Standard (no tier required)
        ("general-chat", "General community chat", "Standard", None, False, 0, "chat"),
        ("announcements", "Official BlakJaks announcements", "Standard", None, True, 1, "announcements"),
        # VIP
        ("general-chat", "VIP community chat", "VIP", vip_id, False, 0, "chat"),
        ("announcements", "VIP announcements", "VIP", vip_id, True, 1, "announcements"),
        ("governance", "VIP governance polls", "VIP", vip_id, True, 2, "governance"),
        # High Roller
        ("general-chat", "High Roller community chat", "High Roller", high_roller_id, False, 0, "chat"),
        ("announcements", "High Roller announcements", "High Roller", high_roller_id, True, 1, "announcements"),
        ("governance", "High Roller governance polls", "High Roller", high_roller_id, True, 2, "governance"),
        # Whale
        ("general-chat", "Whale exclusive chat", "Whale", whale_id, False, 0, "chat"),
        ("announcements", "Whale announcements", "Whale", whale_id, True, 1, "announcements"),
        ("governance", "Whale governance polls", "Whale", whale_id, True, 2, "governance"),
    ]

    for name, desc, category, tier_id, is_locked, sort, room_type in channels:
        if tier_id:
            conn.execute(
                sa.text(
                    "INSERT INTO channels (id, name, description, category, tier_required_id, is_locked, sort_order, room_type, created_at) "
                    "VALUES (gen_random_uuid(), :name, :desc, :category, :tier_id, :locked, :sort, :room_type, now())"
                ),
                {"name": name, "desc": desc, "category": category, "tier_id": tier_id, "locked": is_locked, "sort": sort, "room_type": room_type},
            )
        else:
            conn.execute(
                sa.text(
                    "INSERT INTO channels (id, name, description, category, is_locked, sort_order, room_type, created_at) "
                    "VALUES (gen_random_uuid(), :name, :desc, :category, :locked, :sort, :room_type, now())"
                ),
                {"name": name, "desc": desc, "category": category, "locked": is_locked, "sort": sort, "room_type": room_type},
            )

    # ── 5. Modify votes table ──
    # Add target_tiers column
    op.add_column("votes", sa.Column("target_tiers", JSONB, nullable=True))

    # Migrate existing vote_type to target_tiers
    type_to_tiers = {
        "flavor": '["VIP", "High Roller", "Whale"]',
        "product": '["High Roller", "Whale"]',
        "loyalty": '["High Roller", "Whale"]',
        "corporate": '["Whale"]',
    }
    for vtype, tiers_json in type_to_tiers.items():
        conn.execute(
            sa.text("UPDATE votes SET target_tiers = :tiers::jsonb WHERE vote_type = :vtype"),
            {"tiers": tiers_json, "vtype": vtype},
        )
    # Default any remaining
    conn.execute(sa.text("UPDATE votes SET target_tiers = '[\"VIP\", \"High Roller\", \"Whale\"]'::jsonb WHERE target_tiers IS NULL"))

    # Make target_tiers NOT NULL
    op.alter_column("votes", "target_tiers", nullable=False)

    # Drop old columns
    op.drop_column("votes", "vote_type")
    op.drop_column("votes", "min_tier_required")

    # Drop proposal_id FK and column
    op.drop_constraint("votes_proposal_id_fkey", "votes", type_="foreignkey")
    op.drop_column("votes", "proposal_id")

    # ── 6. Drop governance_proposals table ──
    op.drop_table("governance_proposals")


def downgrade() -> None:
    # This is a destructive migration — downgrade is not fully reversible
    # Re-create governance_proposals table
    op.create_table(
        "governance_proposals",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.String(2000), nullable=False),
        sa.Column("proposed_vote_type", sa.String(20), nullable=False),
        sa.Column("proposed_options_json", JSONB, nullable=True),
        sa.Column("status", sa.String(30), server_default=sa.text("'pending'"), nullable=False),
        sa.Column("admin_notes", sa.String(500), nullable=True),
        sa.Column("reviewed_by", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    # Re-add vote columns
    op.add_column("votes", sa.Column("proposal_id", UUID(as_uuid=True), sa.ForeignKey("governance_proposals.id"), nullable=True))
    op.add_column("votes", sa.Column("vote_type", sa.String(20), nullable=True))
    op.add_column("votes", sa.Column("min_tier_required", sa.String(50), nullable=True))
    op.drop_column("votes", "target_tiers")

    # Drop room_type from channels
    op.drop_column("channels", "room_type")
```

**Step 4: Run migration locally to verify**

Run: `cd backend && alembic upgrade head`
Expected: Migration applies cleanly, 11 new channels created.

**Step 5: Commit**

```bash
git add backend/alembic/versions/028_restructure_channels_and_votes.py backend/app/models/channel.py backend/app/models/vote.py
git commit -m "feat: restructure channels into tier categories + update votes schema"
```

---

## Task 2: Backend — Update Services and API for New Schema

**Files:**
- Modify: `backend/app/services/governance_service.py`
- Modify: `backend/app/services/chat_service.py`
- Modify: `backend/app/api/schemas/governance.py`
- Modify: `backend/app/api/admin/governance.py`
- Modify: `backend/app/api/governance.py`
- Modify: `backend/app/api/router.py`
- Delete: `backend/app/models/governance_proposal.py`
- Modify: `backend/app/models/__init__.py`

**Step 1: Delete governance_proposal.py**

Remove the file entirely. It's no longer needed.

**Step 2: Remove GovernanceProposal from `__init__.py`**

Remove the import and `__all__` entry for `GovernanceProposal`.

**Step 3: Update governance schemas**

Replace `backend/app/api/schemas/governance.py`:
- Remove `ProposalCreate`, `ProposalOut`, `ProposalReview`
- Update `VoteCreate` to use `target_tiers: list[str]` instead of `vote_type`
- Update `VoteOut` to return `target_tiers` instead of `vote_type`

```python
class VoteCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str = Field(min_length=1, max_length=2000)
    target_tiers: list[str] = Field(min_length=1, max_length=3)
    options: list[VoteOption] = Field(min_length=2, max_length=20)
    end_date: datetime

class VoteOut(BaseModel):
    id: uuid.UUID
    title: str
    description: str
    target_tiers: list[str]
    options: list[VoteOption]
    status: str
    start_date: datetime
    end_date: datetime
    total_votes: int = 0
    results: list[VoteResult] = []
    user_has_voted: bool = False
    user_selected_option: str | None = None
    created_at: datetime
    model_config = {"from_attributes": True}
```

**Step 4: Update governance_service.py**

- Remove all proposal functions (`submit_proposal`, `get_proposals`, `get_user_proposals`, `review_proposal`)
- Remove `VOTE_TYPE_MIN_TIER`, `TIER_VOTE_ELIGIBILITY`, `_user_can_vote`
- Update `create_vote()` to accept `target_tiers: list[str]` and `end_date: datetime` instead of `vote_type` and `duration_days`
- Update `get_active_votes()` to filter by user's tier being in `vote.target_tiers`
- Update `cast_ballot()` tier check to use `target_tiers`
- Update `_vote_to_dict()` to use `target_tiers`
- Add new function: `get_votes_for_tier(db, tier_name)` — returns active votes where `tier_name` is in `target_tiers`
- Update `_post_vote_results_to_announcements` — post to all announcement channels

**Step 5: Update admin governance API**

In `backend/app/api/admin/governance.py`:
- Remove proposal endpoints (`admin_list_proposals`, `admin_review_proposal`)
- Update `admin_create_vote` to use new schema (target_tiers + end_date)
- Remove imports for proposal-related schemas and services

**Step 6: Update user governance API**

In `backend/app/api/governance.py`:
- Remove proposal endpoints (`create_proposal`, `my_proposals`)
- Remove proposal imports
- Add new endpoint: `GET /governance/votes/tier/{tier_name}` — returns active votes for a specific tier (used by governance room)

**Step 7: Update chat_service.py**

In `get_channels()`, add `room_type` to the returned dict:
```python
accessible.append({
    "id": ch.id,
    "name": ch.name,
    "description": ch.description,
    "category": ch.category,
    "tier_required": tier_name,
    "view_only": access_level == "view_only",
    "room_type": ch.room_type,
    "unread_count": 0,
    "member_count": 0,
})
```

**Step 8: Update router.py**

No changes needed — governance router stays, just has fewer endpoints.

**Step 9: Commit**

```bash
git add -A
git commit -m "feat: update backend services for tier-based governance"
```

---

## Task 3: Backend — Visibility Model Change (All Rooms Visible with Lock)

**Files:**
- Modify: `backend/app/services/chat_service.py`

Currently `get_channels()` skips channels where `access_level == "hidden"`. The new design shows all channels to everyone, with locked ones displaying a lock icon but not allowing entry.

**Step 1: Update get_channels() to return all channels**

Change the logic to:
- Always include every channel in the response
- Add `"locked": True/False` based on whether user has access
- Remove the `if access_level == "hidden": continue` skip

```python
async def get_channels(db: AsyncSession, user_id: uuid.UUID) -> list[dict]:
    result = await db.execute(
        select(Channel).order_by(Channel.category, Channel.sort_order)
    )
    channels = result.scalars().all()

    all_channels = []
    for ch in channels:
        access_level = await _get_channel_access_level(db, user_id, ch)

        tier_name = None
        if ch.tier_required_id is not None:
            tier_result = await db.execute(select(Tier).where(Tier.id == ch.tier_required_id))
            tier = tier_result.scalar_one_or_none()
            tier_name = tier.name if tier else None

        all_channels.append({
            "id": ch.id,
            "name": ch.name,
            "description": ch.description,
            "category": ch.category,
            "tier_required": tier_name,
            "locked": access_level == "hidden",
            "view_only": access_level == "view_only",
            "room_type": ch.room_type,
            "unread_count": 0,
            "member_count": 0,
        })

    return all_channels
```

**Step 2: Commit**

```bash
git add backend/app/services/chat_service.py
git commit -m "feat: return all channels with locked status instead of hiding"
```

---

## Task 4: Frontend — Update Types and API Client

**Files:**
- Modify: `web-app/src/lib/types.ts`
- Modify: `web-app/src/lib/api.ts`

**Step 1: Update Channel type**

Add `roomType` and `locked` to Channel interface:
```typescript
export interface Channel {
  id: string
  name: string
  category: string
  description: string
  tierRequired: Tier
  unreadCount: number
  icon: string
  viewOnly?: boolean
  roomType: 'chat' | 'announcements' | 'governance'
  locked: boolean
}
```

**Step 2: Update getChannels() in api.ts**

Map `room_type` and `locked` from backend response:
```typescript
roomType: (c.room_type ?? 'chat') as Channel['roomType'],
locked: Boolean(c.locked),
```

**Step 3: Add governance API calls to api.ts**

Add to the governance namespace (or create one if the old one is removed):
```typescript
governance: {
  async getVotesForTier(tierName: string): Promise<VoteOut[]> {
    return fetchAPI<VoteOut[]>(`/governance/votes/tier/${encodeURIComponent(tierName)}`)
  },
  async castVote(voteId: string, optionId: string): Promise<void> {
    await fetchAPI(`/governance/votes/${voteId}/cast`, {
      method: 'POST',
      body: JSON.stringify({ option_id: optionId }),
    })
  },
  async getVoteDetail(voteId: string): Promise<VoteOut> {
    return fetchAPI<VoteOut>(`/governance/votes/${voteId}`)
  },
}
```

**Step 4: Update Vote types**

Replace old Vote/Proposal types with:
```typescript
export interface VoteOption {
  id: string
  label: string
}

export interface VoteResult {
  option_id: string
  label: string
  count: number
  percentage: number
}

export interface VoteOut {
  id: string
  title: string
  description: string
  target_tiers: string[]
  options: VoteOption[]
  status: string
  start_date: string
  end_date: string
  total_votes: number
  results: VoteResult[]
  user_has_voted: boolean
  user_selected_option: string | null
  created_at: string
}
```

Remove `VoteStatus`, `ProposalStatus`, `Proposal` types.

**Step 5: Commit**

```bash
git add web-app/src/lib/types.ts web-app/src/lib/api.ts
git commit -m "feat: update frontend types and API client for new channel/vote schema"
```

---

## Task 5: Frontend — Social Page Sidebar + Room Type Rendering

**Files:**
- Modify: `web-app/src/app/(app)/social/page.tsx`

This is the largest frontend task. The social page needs to:

**Step 1: Update sidebar channel rendering**

The sidebar already groups by category and shows lock icons. Update it to:
- Use `ch.locked` instead of computing `TIER_RANK[ch.tierRequired] > userRank`
- Blocked channels (`ch.locked`) cannot be clicked (already works with `disabled={isLocked}`)

**Step 2: Conditionally render main area based on room type**

After the message list, before the input bar, check `currentChannel?.roomType`:

- **`chat`** — current behavior, full input bar
- **`announcements`** — show messages like chat, but:
  - Hide the entire input bar section for non-admins
  - Keep emoji reaction buttons on messages (already exist)
  - Hide emote picker, GIF picker, and text input for non-admins
  - Show input bar for admins only (check `user?.isAdmin`)
- **`governance`** — completely different rendering:
  - Instead of messages, show poll cards
  - No input bar at all
  - Fetch polls from `api.governance.getVotesForTier(tierName)` where tierName comes from the channel's category
  - Render each poll as a card with title, description, options, results, countdown

**Step 3: Create GovernancePollCard component inline or as separate component**

The poll card renders:
- Title and description
- Options as buttons (disabled if already voted or poll expired)
- Vote counts and percentage bars
- User's selected option highlighted
- Countdown timer to deadline
- "Closed" badge for expired polls

**Step 4: Commit**

```bash
git add web-app/src/app/\(app\)/social/page.tsx
git commit -m "feat: render announcements and governance rooms in social hub"
```

---

## Task 6: Frontend — Delete Governance Page + Nav Links

**Files:**
- Delete: `web-app/src/app/(app)/governance/page.tsx`
- Modify: `web-app/src/app/(app)/layout.tsx`

**Step 1: Delete the governance page**

Remove the entire file/directory.

**Step 2: Remove governance from navigation**

In `layout.tsx`:
- Remove `Vote` from lucide-react import
- Remove governance entry from `mainNav`
- Remove governance entry from `mobileNav`

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: remove standalone governance page and nav links"
```

---

## Task 7: Admin — Update Governance Page for New Schema

**Files:**
- Modify: `admin/src/pages/Governance.tsx`
- Modify: `admin/src/api/governance.ts`
- Modify: `admin/src/types/index.ts`

**Step 1: Update admin types**

In `admin/src/types/index.ts`:
- Update `Vote` interface: replace `vote_type` and `min_tier_required` with `target_tiers: string[]`
- Remove `Proposal` interface

**Step 2: Update admin governance API**

In `admin/src/api/governance.ts`:
- Update `createVote()` to send `target_tiers` and `end_date` instead of `vote_type` and `duration_days`
- Remove all proposal functions (`getProposals`, `reviewProposal`)
- Update mock data if present

**Step 3: Update admin Governance page**

In `admin/src/pages/Governance.tsx`:
- Remove the "Proposals" tab entirely
- Update "Create Vote" modal:
  - Replace vote_type dropdown with multi-select checkboxes for tiers: VIP, High Roller, Whale
  - Replace duration_days with end_date datetime picker
  - Send `target_tiers` array
- Update vote list table: replace "Type" and "Min Tier" columns with "Target Tiers" showing badges
- Keep vote results view and close vote functionality

**Step 4: Commit**

```bash
git add admin/src/pages/Governance.tsx admin/src/api/governance.ts admin/src/types/index.ts
git commit -m "feat: update admin governance for tier-based poll targeting"
```

---

## Task 8: Cleanup — Remove Dead Code

**Files:**
- Delete: `backend/app/models/governance_proposal.py` (if not already deleted in Task 2)
- Verify: `backend/app/api/router.py` — governance routes still work
- Verify: `backend/app/models/__init__.py` — no broken imports
- Remove old governance API calls from `web-app/src/lib/api.ts` if any remain
- Remove `ProposalStatus`, `VoteStatus` from `web-app/src/lib/types.ts` if any remain

**Step 1: Run backend tests**

Run: `cd backend && pytest -x`
Expected: All tests pass (some governance tests may need updating or removal)

**Step 2: Run frontend type check**

Run: `cd web-app && npx tsc --noEmit`
Expected: No type errors

**Step 3: Run admin type check**

Run: `cd admin && npx tsc --noEmit`
Expected: No type errors

**Step 4: Commit any cleanup**

```bash
git add -A
git commit -m "chore: remove dead governance code and fix type errors"
```

---

## Task 9: Deploy + Migrate Staging

**Step 1: Push to staging**

```bash
git push origin main:staging
```

**Step 2: Wait for CI to pass**

Check: `gh run list --branch staging --limit 1`

**Step 3: Run migration on staging**

```bash
gcloud container clusters get-credentials blakjaks-staging --zone us-central1-a --project blakjaks-production
kubectl exec -n staging deployment/backend -- alembic upgrade head
```

**Step 4: Verify**

- Open staging site → Social Hub → should see 4 tier categories with 11 rooms
- Standard user sees all rooms, locked ones show lock icon
- Click locked room → nothing happens
- General chat rooms work as before
- Announcement rooms show no input bar (unless admin)
- Governance rooms show poll cards (empty if no polls created yet)
- Admin panel → Governance → Create poll with tier targeting → appears in correct governance rooms

---

## Implementation Order

Tasks 1-3 (backend) can be done sequentially first, then Tasks 4-6 (frontend) depend on backend being done. Task 7 (admin) is independent of frontend. Task 8 (cleanup) runs last. Task 9 (deploy) after everything passes.

```
Task 1 (migration) → Task 2 (backend services) → Task 3 (visibility) → Task 4 (frontend types) → Task 5 (social page) → Task 6 (delete governance page) → Task 7 (admin) → Task 8 (cleanup) → Task 9 (deploy)
```
