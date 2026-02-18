from fastapi import APIRouter

from app.api.auth import router as auth_router
from app.api.users import router as users_router
from app.api.scans import router as scans_router
from app.api.admin.qr_codes import router as admin_qr_router
from app.api.wallet import router as wallet_router

api_router = APIRouter(prefix="/api")
api_router.include_router(auth_router)
api_router.include_router(users_router)
api_router.include_router(scans_router)
api_router.include_router(admin_qr_router)
api_router.include_router(wallet_router)
