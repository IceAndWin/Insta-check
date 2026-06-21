import os
import logging
from pathlib import Path
from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv

backend_dir = Path(__file__).resolve().parent.parent
dotenv_path = backend_dir / ".env"
load_dotenv(dotenv_path)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("instacheck")

if not os.getenv("INSTAGRAM_USERNAME") or not os.getenv("INSTAGRAM_PASSWORD"):
    logger.warning(
        "INSTAGRAM_USERNAME or INSTAGRAM_PASSWORD not set in .env. "
        f"Looking for: {dotenv_path}"
    )

from app.instagram.client import InstagramClient
from app.models.schemas import ProfileResponse, FollowAnalysisResponse, MediaResponse
from app.exceptions import AppError

app = FastAPI(
    title="InstaCheck API",
    description="Backend for Instagram profile analysis",
    version="1.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(AppError)
async def app_error_handler(request, exc: AppError):
    body = {"detail": exc.message, "code": exc.code}
    if exc.retry_after is not None:
        body["retryAfter"] = exc.retry_after
    status = 429 if exc.code == "RATE_LIMITED" else 400
    return JSONResponse(status_code=status, content=body)


@app.get("/health")
def health():
    creds_set = bool(os.getenv("INSTAGRAM_USERNAME")) and bool(os.getenv("INSTAGRAM_PASSWORD"))
    return {
        "status": "ok",
        "credentials_set": creds_set,
        "dotenv_path": str(dotenv_path),
    }


@app.get("/api/profile/{username}", response_model=ProfileResponse)
def get_profile(username: str):
    try:
        client = InstagramClient.get_instance()
        data = client.get_profile(username)
        return ProfileResponse(**data)
    except ValueError as e:
        return JSONResponse(status_code=500, content={"detail": str(e), "code": "CONFIG_ERROR"})
    except AppError:
        raise
    except Exception as e:
        logger.error(f"Error fetching profile @{username}: {e}")
        return JSONResponse(status_code=500, content={"detail": "Internal server error", "code": "INTERNAL"})


@app.get("/api/media/{username}", response_model=MediaResponse)
def get_user_media(username: str, amount: int = 30):
    try:
        client = InstagramClient.get_instance()
        data = client.get_user_media(username, amount=min(amount, 100))
        return MediaResponse(**data)
    except ValueError as e:
        return JSONResponse(status_code=500, content={"detail": str(e), "code": "CONFIG_ERROR"})
    except AppError:
        raise
    except Exception as e:
        logger.error(f"Error fetching media @{username}: {e}")
        return JSONResponse(status_code=500, content={"detail": "Internal server error", "code": "INTERNAL"})


@app.get("/api/follow-analysis/{username}", response_model=FollowAnalysisResponse)
def get_follow_analysis(username: str, amount: int = 300):
    try:
        client = InstagramClient.get_instance()
        data = client.get_follow_analysis(username, amount=min(amount, 5000))
        return FollowAnalysisResponse(**data)
    except ValueError as e:
        return JSONResponse(status_code=500, content={"detail": str(e), "code": "CONFIG_ERROR"})
    except AppError:
        raise
    except Exception as e:
        logger.error(f"Error analyzing @{username}: {e}")
        return JSONResponse(status_code=500, content={"detail": "Internal server error", "code": "INTERNAL"})


@app.get("/api/proxy-image")
def proxy_image(url: str = Query(...)):
    try:
        client = InstagramClient.get_instance()
        client._ensure_logged_in()
        session = client._client.private
        resp = session.get(url, timeout=30)
        return JSONResponse(
            content=resp.content,
            media_type=resp.headers.get("content-type", "image/jpeg"),
        )
    except AppError:
        raise
    except Exception as e:
        logger.error(f"Image proxy failed: {e}")
        return JSONResponse(status_code=400, content={"detail": "Failed to load image", "code": "PROXY_FAILED"})


if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(
        "app.main:app",
        host=host,
        port=port,
        reload=True,
        timeout_keep_alive=120,
    )
