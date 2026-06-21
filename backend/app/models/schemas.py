from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ProfileResponse(BaseModel):
    username: str
    fullName: str
    biography: Optional[str] = None
    profilePicUrl: Optional[str] = None
    followersCount: int
    followingCount: int
    postsCount: int
    isPrivate: bool
    isVerified: bool
    externalUrl: Optional[str] = None
    businessCategory: Optional[str] = None


class FollowerItem(BaseModel):
    username: str
    fullName: Optional[str] = None
    profilePicUrl: Optional[str] = None
    isVerified: bool = False
    followedAt: Optional[datetime] = None


class AnalysisMetadata(BaseModel):
    sampled: int
    totalAvailable: int = 0
    isApproximate: bool = False


class FollowAnalysisResponse(BaseModel):
    notFollowingBack: list[FollowerItem]
    notFollowedByUser: list[FollowerItem]
    mutualFollowers: list[FollowerItem]
    analyzedAt: datetime
    metadata: AnalysisMetadata | None = None


class MediaItem(BaseModel):
    id: str
    mediaType: int
    caption: Optional[str] = None
    likeCount: int = 0
    commentCount: int = 0
    thumbnailUrl: Optional[str] = None
    mediaUrl: Optional[str] = None
    takenAt: Optional[datetime] = None
    videoDuration: Optional[float] = None
    productType: Optional[str] = None


class MediaResponse(BaseModel):
    username: str
    media: list[MediaItem]
    total: int


class ErrorResponse(BaseModel):
    detail: str
