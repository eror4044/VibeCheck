from fastapi import APIRouter


router = APIRouter()


@router.get("/healthz", tags=["health"])
def healthz() -> dict:
    return {"status": "ok"}
