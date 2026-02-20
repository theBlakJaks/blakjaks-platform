"""Celery application instance with Redis broker and 5 beat schedule entries.

Beat schedule:
  - treasury_snapshot:     hourly
  - teller_sync:           every 6 hours
  - affiliate_payout:      Sunday 3AM UTC
  - guaranteed_comps:      1st of month 2AM UTC
  - leaderboard_reconcile: daily midnight UTC
"""

from celery import Celery
from celery.schedules import crontab

from app.core.config import settings

celery_app = Celery(
    "blakjaks",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=[
        "app.tasks.treasury",
        "app.tasks.teller",
        "app.tasks.affiliate",
        "app.tasks.comps",
    ],
)

celery_app.conf.update(
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    timezone="UTC",
    enable_utc=True,
    worker_prefetch_multiplier=1,
    task_acks_late=True,
)

celery_app.conf.beat_schedule = {
    # Treasury snapshot — runs every hour on the hour
    "treasury-snapshot-hourly": {
        "task": "app.tasks.treasury.take_treasury_snapshot",
        "schedule": crontab(minute=0),
    },
    # Teller bank sync — every 6 hours
    "teller-sync-6h": {
        "task": "app.tasks.teller.sync_teller_balances",
        "schedule": crontab(minute=0, hour="*/6"),
    },
    # Weekly affiliate payout — Sunday 3:00 AM UTC
    "affiliate-payout-weekly": {
        "task": "app.tasks.affiliate.run_weekly_affiliate_payout",
        "schedule": crontab(minute=0, hour=3, day_of_week="sunday"),
    },
    # Monthly guaranteed comps — 1st of month 2:00 AM UTC
    "guaranteed-comps-monthly": {
        "task": "app.tasks.comps.run_monthly_guaranteed_comps",
        "schedule": crontab(minute=0, hour=2, day_of_month=1),
    },
    # Leaderboard reconciliation — daily midnight UTC
    "leaderboard-reconcile-daily": {
        "task": "app.tasks.treasury.reconcile_leaderboard",
        "schedule": crontab(minute=0, hour=0),
    },
}
