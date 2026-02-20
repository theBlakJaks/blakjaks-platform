from fastapi import APIRouter

from app.api.auth import router as auth_router
from app.api.users import router as users_router
from app.api.scans import router as scans_router
from app.api.admin.qr_codes import router as admin_qr_router
from app.api.wallet import router as wallet_router
from app.api.treasury import router as treasury_router
from app.api.shop import router as shop_router
from app.api.notifications import router as notifications_router
from app.api.social import router as social_router
from app.api.admin.social import router as admin_social_router
from app.api.affiliate import router as affiliate_router
from app.api.admin.affiliate import router as admin_affiliate_router
from app.api.governance import router as governance_router
from app.api.admin.governance import router as admin_governance_router
from app.api.admin.treasury import router as admin_treasury_router
from app.api.streams import router as streams_router
from app.api.wholesale import router as wholesale_router
from app.api.oobit import router as oobit_router
from app.api.giphy import router as giphy_router
from app.api.insights import router as insights_router

api_router = APIRouter(prefix="/api")
api_router.include_router(auth_router)
api_router.include_router(users_router)
api_router.include_router(scans_router)
api_router.include_router(admin_qr_router)
api_router.include_router(wallet_router)
api_router.include_router(treasury_router)
api_router.include_router(shop_router)
api_router.include_router(notifications_router)
api_router.include_router(social_router)
api_router.include_router(admin_social_router)
api_router.include_router(affiliate_router)
api_router.include_router(admin_affiliate_router)
api_router.include_router(governance_router)
api_router.include_router(admin_governance_router)
api_router.include_router(admin_treasury_router)
api_router.include_router(streams_router)
api_router.include_router(wholesale_router)
api_router.include_router(oobit_router)
api_router.include_router(giphy_router)
api_router.include_router(insights_router)
