"""
API routes for scheduled deployment management and background scheduler.
"""

import os
import json
import uuid
import logging
import asyncio
from datetime import datetime, time
from typing import Literal
from pathlib import Path
from pydantic import BaseModel
from fastapi import APIRouter, HTTPException, BackgroundTasks

from models.node import NodeResponse
from routes.nodes import get_node_by_id
from routes.deployment import _run_deployment, deployment_results

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/schedule", tags=["schedule"])

SCHEDULE_FILE = Path(__file__).parent.parent.parent / "data" / "settings" / "schedules.json"

class ScheduleCreateRequest(BaseModel):
    activity_name: str
    schedule_type: Literal["onetime", "recurring"]
    date: str  # YYYY-MM-DD (for one-time)
    time: str  # HH:MM
    repeat_mode: Literal["daily", "weekly", "monthly"] | None = None
    repeat_day: str | None = None  # day name or day-of-month
    node_ids: list[str]
    commands: list[str]
    execution_method: Literal["standard", "broadcast"] = "broadcast"

class ScheduleEntry(BaseModel):
    id: str
    activity_name: str
    schedule_type: Literal["onetime", "recurring"]
    date: str
    time: str
    repeat_mode: Literal["daily", "weekly", "monthly"] | None = None
    repeat_day: str | None = None
    node_ids: list[str]
    commands: list[str]
    execution_method: Literal["standard", "broadcast"] = "broadcast"
    created_at: str
    status: Literal["waiting", "running", "success", "failed", "cancelled"]


def load_schedules() -> list[ScheduleEntry]:
    """Load schedules from JSON file."""
    if not SCHEDULE_FILE.exists():
        return []
    try:
        with open(SCHEDULE_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            return [ScheduleEntry(**item) for item in data]
    except Exception as e:
        logger.error("Failed to load schedules: %s", e)
        return []


def save_schedules(schedules: list[ScheduleEntry]):
    """Save schedules to JSON file."""
    try:
        SCHEDULE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(SCHEDULE_FILE, "w", encoding="utf-8") as f:
            json.dump([s.model_dump() for s in schedules], f, indent=4)
    except Exception as e:
        logger.error("Failed to save schedules: %s", e)


@router.get("", response_model=list[ScheduleEntry])
async def list_schedules():
    """List all scheduled deployments."""
    return load_schedules()


@router.post("", response_model=ScheduleEntry)
async def create_schedule(request: ScheduleCreateRequest):
    """Create a new scheduled deployment."""
    if not request.node_ids:
        raise HTTPException(status_code=400, detail="No nodes selected")
    if not request.commands or all(not c.strip() for c in request.commands):
        raise HTTPException(status_code=400, detail="Commands list is empty")
    
    # Simple formatting validations
    try:
        datetime.strptime(request.time, "%H:%M")
        if request.schedule_type == "onetime":
            datetime.strptime(request.date, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date or time format. Expected YYYY-MM-DD and HH:MM.")

    schedules = load_schedules()
    
    new_entry = ScheduleEntry(
        id=str(uuid.uuid4())[:8],  # short ID
        activity_name=request.activity_name,
        schedule_type=request.schedule_type,
        date=request.date,
        time=request.time,
        repeat_mode=request.repeat_mode,
        repeat_day=request.repeat_day,
        node_ids=request.node_ids,
        commands=[c.strip() for c in request.commands if c.strip()],
        execution_method=request.execution_method,
        created_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        status="waiting",
    )
    
    schedules.append(new_entry)
    save_schedules(schedules)
    
    return new_entry


@router.delete("/{schedule_id}", response_model=dict)
async def cancel_schedule(schedule_id: str):
    """Cancel/remove a scheduled deployment."""
    schedules = load_schedules()
    updated_schedules = []
    found = False
    
    for s in schedules:
        if s.id == schedule_id:
            s.status = "cancelled"
            found = True
        updated_schedules.append(s)
        
    if not found:
        raise HTTPException(status_code=404, detail=f"Schedule {schedule_id} not found")
        
    save_schedules(updated_schedules)
    return {"status": "success", "message": f"Schedule {schedule_id} cancelled"}


# --- Background Scheduler Loop ---
async def start_background_scheduler():
    """Background loop checking and executing schedules."""
    logger.info("Starting background scheduler loop...")
    while True:
        try:
            await check_and_run_schedules()
        except Exception as e:
            logger.error("Error in scheduler loop: %s", e)
        await asyncio.sleep(15)  # check every 15 seconds


async def check_and_run_schedules():
    """Check all schedules and run the ones that match current time."""
    schedules = load_schedules()
    now = datetime.now()
    now_time_str = now.strftime("%H:%M")
    now_date_str = now.strftime("%Y-%m-%d")
    
    changed = False
    
    for s in schedules:
        if s.status != "waiting":
            continue
            
        should_run = False
        
        # Check time match (simple minute-level check)
        if s.time == now_time_str:
            if s.schedule_type == "onetime":
                if s.date == now_date_str:
                    should_run = True
            elif s.schedule_type == "recurring":
                if s.repeat_mode == "daily":
                    should_run = True
                elif s.repeat_mode == "weekly":
                    weekday_now = now.strftime("%a")  # e.g., "Mon"
                    if s.repeat_day and s.repeat_day.startswith(weekday_now):
                        should_run = True
                elif s.repeat_mode == "monthly":
                    day_now = str(now.day)
                    if s.repeat_day == day_now:
                        should_run = True
                        
        if should_run:
            logger.info("Executing scheduled deployment: %s (%s)", s.activity_name, s.id)
            s.status = "running"
            changed = True
            
            # Spawn background deployment task
            session_id = f"sched-{s.id}"
            
            # Initialize session result in deployment results
            deployment_results[session_id] = {
                "session_id": session_id,
                "status": "started",
                "message": f"Scheduled deployment started for {s.activity_name}",
                "results": [],
            }
            
            # Run deployment in background
            asyncio.create_task(run_scheduled_deployment(s, session_id))
            
    if changed:
        save_schedules(schedules)


async def run_scheduled_deployment(schedule: ScheduleEntry, session_id: str):
    """Execute scheduled deployment and update status."""
    try:
        await _run_deployment(
            session_id=session_id,
            node_ids=schedule.node_ids,
            commands=schedule.commands,
            execution_method=schedule.execution_method,
        )
        
        # Check overall status from results
        res = deployment_results.get(session_id, {})
        status = res.get("status", "completed")
        
        # Update schedule status
        schedules = load_schedules()
        for s in schedules:
            if s.id == schedule.id:
                s.status = "success" if status == "completed" else "failed"
        save_schedules(schedules)
        logger.info("Scheduled deployment %s finished with status: %s", schedule.id, status)
        
    except Exception as e:
        logger.error("Scheduled deployment %s failed: %s", schedule.id, e)
        schedules = load_schedules()
        for s in schedules:
            if s.id == schedule.id:
                s.status = "failed"
        save_schedules(schedules)
