"""Tests for Celery infrastructure — celery_app, beat schedule, and task imports."""

import pytest


def test_celery_app_imports():
    """celery_app module imports cleanly."""
    from app.celery_app import celery_app
    assert celery_app is not None
    assert celery_app.main == "blakjaks"


def test_celery_beat_schedule_has_five_entries():
    from app.celery_app import celery_app
    schedule = celery_app.conf.beat_schedule
    assert len(schedule) == 5


def test_celery_beat_schedule_task_names():
    from app.celery_app import celery_app
    task_names = {v["task"] for v in celery_app.conf.beat_schedule.values()}
    assert "app.tasks.treasury.take_treasury_snapshot" in task_names
    assert "app.tasks.treasury.reconcile_leaderboard" in task_names
    assert "app.tasks.teller.sync_teller_balances" in task_names
    assert "app.tasks.affiliate.run_weekly_affiliate_payout" in task_names
    assert "app.tasks.comps.run_monthly_guaranteed_comps" in task_names


def test_treasury_tasks_import():
    from app.tasks.treasury import take_treasury_snapshot, reconcile_leaderboard
    assert callable(take_treasury_snapshot)
    assert callable(reconcile_leaderboard)


def test_teller_task_imports():
    from app.tasks.teller import sync_teller_balances
    assert callable(sync_teller_balances)


def test_affiliate_task_imports():
    from app.tasks.affiliate import run_weekly_affiliate_payout
    assert callable(run_weekly_affiliate_payout)


def test_comps_task_imports():
    from app.tasks.comps import run_monthly_guaranteed_comps
    assert callable(run_monthly_guaranteed_comps)


def test_task_stubs_return_status_dict():
    """All stub tasks return a dict with status='stub'."""
    from app.tasks.treasury import take_treasury_snapshot, reconcile_leaderboard
    from app.tasks.teller import sync_teller_balances
    from app.tasks.affiliate import run_weekly_affiliate_payout
    from app.tasks.comps import run_monthly_guaranteed_comps

    # Call the underlying function directly (bypasses Celery broker)
    for task_fn in [
        take_treasury_snapshot,
        reconcile_leaderboard,
        sync_teller_balances,
        run_weekly_affiliate_payout,
        run_monthly_guaranteed_comps,
    ]:
        result = task_fn.run()
        assert result["status"] == "stub"
        assert "task" in result
        assert "message" in result
