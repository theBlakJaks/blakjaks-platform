"""Pydantic v2 schemas for the Governance & Voting system."""

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class VoteOption(BaseModel):
    id: str
    label: str


class VoteCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str = Field(min_length=1, max_length=2000)
    vote_type: str = Field(pattern="^(flavor|product|loyalty|corporate)$")
    options: list[VoteOption] = Field(min_length=2, max_length=20)
    duration_days: int = Field(default=7, ge=1, le=90)


class VoteResult(BaseModel):
    option_id: str
    label: str
    count: int
    percentage: float


class VoteOut(BaseModel):
    id: uuid.UUID
    title: str
    description: str
    vote_type: str
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


class BallotCast(BaseModel):
    option_id: str = Field(min_length=1, max_length=50)


class VoteHistoryItem(BaseModel):
    vote_id: uuid.UUID
    title: str
    vote_type: str
    user_option: str | None = None
    status: str
    created_at: datetime


class VoteHistoryList(BaseModel):
    items: list[VoteHistoryItem]
    total: int
    page: int
    per_page: int


class ProposalCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str = Field(min_length=1, max_length=2000)
    proposed_vote_type: str = Field(pattern="^(flavor|product|loyalty|corporate)$")
    proposed_options: list[VoteOption] | None = None


class ProposalOut(BaseModel):
    id: uuid.UUID
    title: str
    description: str
    proposed_vote_type: str
    status: str
    admin_notes: str | None = None
    created_at: datetime
    reviewed_at: datetime | None = None

    model_config = {"from_attributes": True}


class ProposalReview(BaseModel):
    action: str = Field(pattern="^(approve|reject|changes_requested)$")
    admin_notes: str | None = Field(None, max_length=500)
