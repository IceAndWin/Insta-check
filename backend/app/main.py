import os
import sys
import logging
from pathlib import Path
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from dotenv import load_dotenv

# Загружаем .env из папки бэкенда (на случай если запуск из другой директории)
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
from app.models.schemas import ProfileResponse, FollowAnalysisResponse, MediaResponse, ErrorResponse

app = FastAPI(
    title="InstaCheck API",
    description="Backend for Instagram profile analysis",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    creds_set = bool(os.getenv("INSTAGRAM_USERNAME")) and bool(os.getenv("INSTAGRAM_PASSWORD"))
    return {
        "status": "ok",
        "credentials_set": creds_set,
        "dotenv_path": str(dotenv_path),
    }


@app.get(
    "/api/profile/{username}",
    response_model=ProfileResponse,
    responses={400: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
)
def get_profile(username: str):
    try:
        client = InstagramClient.get_instance()
        data = client.get_profile(username)
        return ProfileResponse(**data)
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        logger.error(f"Error fetching profile @{username}: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@app.get(
    "/api/media/{username}",
    response_model=MediaResponse,
    responses={400: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
)
def get_user_media(username: str, amount: int = 30):
    try:
        client = InstagramClient.get_instance()
        data = client.get_user_media(username, amount=min(amount, 100))
        return MediaResponse(**data)
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        logger.error(f"Error fetching media @{username}: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@app.get(
    "/api/follow-analysis/{username}",
    response_model=FollowAnalysisResponse,
    responses={400: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
)
def get_follow_analysis(username: str, amount: int = 300):
    try:
        client = InstagramClient.get_instance()
        data = client.get_follow_analysis(username, amount=min(amount, 5000))
        return FollowAnalysisResponse(**data)
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        logger.error(f"Error analyzing @{username}: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/api/proxy-image")
def proxy_image(url: str = Query(...)):
    try:
        client = InstagramClient.get_instance()
        client._ensure_logged_in()
        session = client._client.private
        resp = session.get(url, timeout=30)
        return Response(
            content=resp.content,
            media_type=resp.headers.get("content-type", "image/jpeg"),
        )
    except Exception as e:
        logger.error(f"Image proxy failed: {e}")
        raise HTTPException(status_code=400, detail="Failed to load image")


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
