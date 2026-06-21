import os
import json
import time
import random
import logging
from pathlib import Path
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
from typing import Optional
from instagrapi import Client
from instagrapi.exceptions import (
    LoginRequired, BadPassword, ClientNotFoundError,
    RateLimitError, ReloginAttemptExceeded, ChallengeRequired as InstaChallenge,
    PleaseWaitFewMinutes, FeedbackRequired,
    TwoFactorRequired as Insta2FA,
)
from app.exceptions import (
    AppError, LoginFailed, ChallengeRequired, RateLimited,
    UserNotFound, SessionExpired, TwoFactorRequired,
)

logger = logging.getLogger("instacheck")


class InstagramClient:
    _instance: Optional['InstagramClient'] = None
    _client: Optional[Client] = None
    _last_login: float = 0
    _login_interval: float = 300

    def __init__(self):
        self.username = os.getenv("INSTAGRAM_USERNAME", "")
        self.password = os.getenv("INSTAGRAM_PASSWORD", "")
        self.session_path = Path(os.getenv(
            "INSTAGRAM_SESSION_FILE",
            str(Path(__file__).resolve().parents[2] / ".instagrapi-session.json")
        ))
        if not self.username or not self.password:
            raise ValueError(
                "INSTAGRAM_USERNAME and INSTAGRAM_PASSWORD must be set in .env "
                "(create backend/.env from backend/.env.example)"
            )
        logger.info(f"InstagramClient initialized for @{self.username}")

    @classmethod
    def get_instance(cls) -> 'InstagramClient':
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def _new_client(self) -> Client:
        client = Client()
        client.delay_range = [0.5, 1.0]
        return client

    def _session_exists(self) -> bool:
        return self.session_path.exists() and self.session_path.stat().st_size > 0

    def _save_session(self):
        if self._client is None:
            return
        try:
            self.session_path.parent.mkdir(parents=True, exist_ok=True)
            settings = self._client.get_settings()
            with open(self.session_path, "w", encoding="utf-8") as f:
                json.dump(settings, f, ensure_ascii=False)
            logger.info(f"Session saved to {self.session_path}")
        except Exception as e:
            logger.warning(f"Failed to save session: {e}")

    def _load_session(self) -> bool:
        if not self._session_exists():
            return False
        try:
            client = self._new_client()
            with open(self.session_path, "r", encoding="utf-8") as f:
                settings = json.load(f)
            client.set_settings(settings)
            client.login(self.username, self.password)
            client.get_timeline_feed()
            self._client = client
            self._last_login = time.time()
            logger.info(f"Session restored from {self.session_path}")
            return True
        except Exception as e:
            logger.warning(f"Failed to restore session: {e}")
            return False

    def _ensure_logged_in(self, max_retries: int = 3):
        now = time.time()
        for attempt in range(max_retries):
            try:
                if self._client is None:
                    if self._load_session():
                        return
                    self._login()
                    return

                if (now - self._last_login) > self._login_interval:
                    self._client.get_timeline_feed()
                    self._last_login = now
                return
            except (LoginRequired, ReloginAttemptExceeded):
                logger.warning(f"Session invalid (attempt {attempt+1}/{max_retries})")
                if attempt < max_retries - 1 and self._load_session():
                    return
                self._client = self._new_client()
                self._login()
                return
            except InstaChallenge:
                logger.warning(f"Instagram challenge (attempt {attempt+1}/{max_retries})")
                if attempt < max_retries - 1:
                    delay = (2 ** attempt) + random.random()
                    logger.info(f"Waiting {delay:.1f}s before retry...")
                    time.sleep(delay)
                    if self._load_session():
                        return
                    continue
                raise ChallengeRequired()
            except RateLimitError as e:
                logger.warning(f"Rate limited (attempt {attempt+1}/{max_retries})")
                retry_after = int(getattr(e, "retry_after", 60))
                delay = max(retry_after, (2 ** attempt) * 5)
                raise RateLimited(retry_after=int(delay))
            except PleaseWaitFewMinutes:
                logger.warning(f"Please wait (attempt {attempt+1}/{max_retries})")
                delay = (2 ** attempt) * 30 + random.random() * 10
                if attempt < max_retries - 1:
                    time.sleep(delay)
                    continue
                raise RateLimited(retry_after=int(delay))
            except Insta2FA:
                raise TwoFactorRequired()
            except FeedbackRequired as e:
                raise AppError(f"Instagram action blocked: {e}", code="FEEDBACK_REQUIRED")

    def _login(self):
        logger.info("Logging in...")
        self._client = self._new_client()
        try:
            self._client.login(self.username, self.password)
            self._last_login = time.time()
            self._save_session()
            try:
                my_id = self._client.user_id
                self._client.user_followers(my_id, amount=5)
            except Exception:
                pass
            logger.info("Login successful")
        except Insta2FA:
            raise TwoFactorRequired()
        except InstaChallenge:
            raise ChallengeRequired()
        except BadPassword:
            raise LoginFailed("Wrong Instagram username or password")
        except FeedbackRequired as e:
            raise AppError(f"Instagram action blocked: {e}", code="FEEDBACK_REQUIRED")
        except PleaseWaitFewMinutes:
            raise RateLimited(retry_after=120)
        except Exception as e:
            raise LoginFailed(str(e))

    def _api_call(self, fn, *args, max_retries: int = 2, **kwargs):
        last_error = None
        for attempt in range(max_retries):
            try:
                self._ensure_logged_in()
                result = fn(*args, **kwargs)
                self._save_session()
                return result
            except (LoginRequired, ReloginAttemptExceeded) as e:
                logger.warning(f"LoginRequired during API call (attempt {attempt+1})")
                last_error = e
                self._client = None
                continue
            except RateLimitError as e:
                retry_after = int(getattr(e, "retry_after", 30))
                logger.warning(f"Rate limited, waiting {retry_after}s...")
                time.sleep(retry_after)
                last_error = e
                continue
            except InstaChallenge:
                logger.warning("Challenge during API call")
                last_error = ChallengeRequired()
                continue
        raise last_error or AppError("API call failed after retries", code="API_FAILED")

    def get_profile(self, username: str) -> dict:
        logger.info(f"Fetching profile: @{username}")
        try:
            user = self._api_call(
                lambda: self._client.user_info_by_username(username)
            )
            profile_pic = str(user.profile_pic_url_hd or user.profile_pic_url or "")
            is_private = bool(user.is_private)
            followers = user.follower_count or 0
            following = user.following_count or 0
            posts = user.media_count or 0
            if not is_private:
                try:
                    test = self._client.user_followers(user.pk, amount=1)
                    if not test:
                        is_private = True
                except Exception:
                    is_private = True
            return {
                "username": user.username or username,
                "fullName": user.full_name or "",
                "biography": user.biography or "",
                "profilePicUrl": profile_pic,
                "followersCount": followers,
                "followingCount": following,
                "postsCount": posts,
                "isPrivate": is_private,
                "isVerified": bool(user.is_verified),
                "externalUrl": getattr(user, "external_url", None) or "",
                "businessCategory": getattr(user, "business_category_name", None)
                                    or getattr(user, "business_category", None),
            }
        except ClientNotFoundError:
            raise UserNotFound(username)
        except AppError:
            raise
        except Exception as e:
            logger.exception(f"Failed to fetch profile @{username}")
            raise AppError(f"Failed to fetch profile @{username}: {e}", code="PROFILE_FETCH_FAILED")

    def get_follow_analysis(self, username: str, amount: int = 300) -> dict:
        logger.info(f"Fetching follow analysis: @{username} (amount={amount})")
        try:
            user_info = self._api_call(
                lambda: self._client.user_info_by_username(username)
            )
            if user_info.is_private:
                raise AppError(
                    f"Account @{username} is private. Follow analysis is "
                    "not available for private accounts.",
                    code="PRIVATE_ACCOUNT",
                )
            user_id = user_info.pk
            compare_amount = min(max(amount * 3, 300), 5000)
            logger.info(f"Using compare_amount={compare_amount} for @{username}")

            def _fetch_followers():
                return self._api_call(
                    lambda: self._client.user_followers(user_id, amount=compare_amount)
                )

            def _fetch_following():
                return self._api_call(
                    lambda: self._client.user_following(user_id, amount=compare_amount)
                )

            with ThreadPoolExecutor(max_workers=2) as pool:
                f_followers = pool.submit(_fetch_followers)
                f_following = pool.submit(_fetch_following)
                followers = f_followers.result()
                following = f_following.result()

            if not followers and not following:
                raise AppError(
                    f"Account @{username} is private or inaccessible. "
                    "Follow analysis is not available.",
                    code="PRIVATE_ACCOUNT",
                )

            follower_ids = list(followers.keys())
            following_ids = list(following.keys())
            follower_set = set(follower_ids)
            following_set = set(following_ids)

            mutual_ids = follower_set & following_set
            limited_follower_set = set(follower_ids[:amount])
            limited_following_set = set(following_ids[:amount])

            not_following_back_ids = [uid for uid in following_ids[:amount] if uid not in follower_set]
            not_followed_by_user_ids = [uid for uid in follower_ids[:amount] if uid not in following_set]
            mutual_ranked_ids = [
                uid for uid in follower_ids
                if uid in mutual_ids and (uid in limited_follower_set or uid in limited_following_set)
            ]
            if len(mutual_ranked_ids) < amount:
                extra_mutual_ids = [uid for uid in following_ids if uid in mutual_ids and uid not in mutual_ranked_ids]
                for uid in extra_mutual_ids:
                    mutual_ranked_ids.append(uid)
                    if len(mutual_ranked_ids) >= amount:
                        break

            all_users = {**followers, **following}

            def _to_item(uid: int) -> dict:
                u = all_users[uid]
                return {
                    "username": u.username,
                    "fullName": u.full_name,
                    "profilePicUrl": str(u.profile_pic_url or ""),
                    "isVerified": u.is_verified,
                }

            total_seen = max(len(follower_ids), len(following_ids))
            is_approximate = total_seen < compare_amount

            return {
                "notFollowingBack": [_to_item(uid) for uid in not_following_back_ids],
                "notFollowedByUser": [_to_item(uid) for uid in not_followed_by_user_ids],
                "mutualFollowers": [_to_item(uid) for uid in mutual_ranked_ids[:amount]],
                "analyzedAt": datetime.utcnow().isoformat(),
                "metadata": {
                    "sampled": amount,
                    "totalAvailable": total_seen,
                    "isApproximate": is_approximate,
                },
            }
        except ClientNotFoundError:
            raise UserNotFound(username)
        except AppError:
            raise
        except Exception as e:
            logger.exception(f"Failed to analyze @{username}")
            raise AppError(f"Failed to analyze @{username}: {e}", code="ANALYSIS_FAILED")

    def get_user_media(self, username: str, amount: int = 30) -> dict:
        logger.info(f"Fetching media: @{username} (amount={amount})")
        try:
            user_id = self._api_call(
                lambda: self._client.user_id_from_username(username)
            )
            medias = self._api_call(
                lambda: self._client.user_medias(user_id, amount=amount)
            )
            media_list = []
            thumb_cache = {}

            def _download_thumb(m):
                if m.media_type != 1:
                    return str(m.id), None
                try:
                    import base64
                    import tempfile
                    with tempfile.TemporaryDirectory() as tmpdir:
                        path = self._client.photo_download(m.id, folder=tmpdir)
                        if path and path.exists():
                            with open(path, 'rb') as f:
                                b64 = base64.b64encode(f.read()).decode()
                            return str(m.id), f"data:image/jpeg;base64,{b64}"
                except Exception:
                    pass
                return str(m.id), None

            with ThreadPoolExecutor(max_workers=5) as pool:
                for mid, b64data in pool.map(_download_thumb, medias):
                    thumb_cache[mid] = b64data

            for m in medias:
                thumb_data = thumb_cache.get(str(m.id))
                item = {
                    "id": str(m.id),
                    "mediaType": m.media_type,
                    "caption": m.caption_text if m.caption_text else None,
                    "likeCount": m.like_count or 0,
                    "commentCount": m.comment_count or 0,
                    "thumbnailUrl": thumb_data or (str(m.thumbnail_url) if m.thumbnail_url else None),
                    "mediaUrl": str(m.media_url) if hasattr(m, "media_url") and m.media_url else str(m.video_url) if hasattr(m, "video_url") and m.video_url else None,
                    "takenAt": m.taken_at.isoformat() if m.taken_at else None,
                    "videoDuration": m.video_duration if hasattr(m, "video_duration") else None,
                    "productType": m.product_type if hasattr(m, "product_type") else None,
                }
                media_list.append(item)
            return {"username": username, "media": media_list, "total": len(media_list)}
        except ClientNotFoundError:
            raise UserNotFound(username)
        except AppError:
            raise
        except Exception as e:
            logger.exception(f"Failed to fetch media for @{username}")
            raise AppError(f"Failed to fetch media for @{username}: {e}", code="MEDIA_FETCH_FAILED")
