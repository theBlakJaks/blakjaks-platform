from pydantic import BaseModel, Field


class SavedEmoteCreate(BaseModel):
    emote_id: str = Field(min_length=1, max_length=64)
    emote_name: str = Field(min_length=1, max_length=128)
    animated: bool = False
    zero_width: bool = False


class SavedEmoteOut(BaseModel):
    emote_id: str
    emote_name: str
    animated: bool
    zero_width: bool
    sort_order: int

    model_config = {"from_attributes": True}


class SavedEmoteReorder(BaseModel):
    """Full ordered list of emote IDs — server replaces sort_order for all."""
    emote_ids: list[str] = Field(min_length=1)
