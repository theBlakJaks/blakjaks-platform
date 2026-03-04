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
    target_tiers: list[str] = Field(min_length=1)
    options: list[VoteOption] = Field(min_length=2, max_length=20)
    end_date: datetime


class VoteResult(BaseModel):
    option_id: str
    label: str
    count: int
    percentage: float


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


class BallotCast(BaseModel):
    option_id: str = Field(min_length=1, max_length=50)
