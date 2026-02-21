from fastapi import APIRouter

from app.api.routes import auth, feed, health, ideas, me, my_ideas, stats, swipes


api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(me.router, prefix="/me", tags=["me"])
api_router.include_router(my_ideas.router, prefix="/me/ideas", tags=["my-ideas"])
api_router.include_router(stats.router, prefix="/stats", tags=["stats"])
api_router.include_router(ideas.router, prefix="/ideas", tags=["ideas"])
api_router.include_router(feed.router, prefix="/feed", tags=["feed"])
api_router.include_router(swipes.router, prefix="/swipes", tags=["swipes"])
