from typing import List, Optional
from app.core.supabase_client import get_supabase
from app.db.schemas.plan import Plan, AgentStep

class LegacyPlanService:
    def __init__(self, db_session=None):
        # We don't use db_session anymore, but keeping init for compatibility
        self.supabase = get_supabase()

    def save_plan(self, user_id: str, plan: Plan) -> Plan:
        steps_payload = [step.model_dump(mode="json") for step in plan.steps]
        
        # Check if plan exists
        existing = self.supabase.table("plans").select("id").eq("id", plan.id).execute()
        
        data = {
            "id": plan.id,
            "user_id": user_id,
            "goal": plan.goal,
            "status": plan.status,
            "steps": steps_payload,
            # updated_at can be handled by DB trigger or here
        }

        if existing.data:
            self.supabase.table("plans").update(data).eq("id", plan.id).execute()
        else:
            self.supabase.table("plans").insert(data).execute()
            
        return plan

    def get_plan(self, user_id: str, plan_id: str) -> Optional[Plan]:
        res = self.supabase.table("plans").select("*").eq("id", plan_id).eq("user_id", user_id).single().execute()
        if not res.data:
            return None
        
        record = res.data
        steps = []
        if record.get("steps"):
            steps = [AgentStep.model_validate(item) for item in record["steps"]]
            
        return Plan(
            id=record["id"],
            goal=record["goal"],
            steps=steps,
            status=record["status"]
        )

    def list_plans(self, user_id: str, limit: int = 20) -> List[Plan]:
        res = self.supabase.table("plans").select("*").eq("user_id", user_id).limit(limit).execute()
        
        plans = []
        for record in res.data:
            steps = []
            if record.get("steps"):
                steps = [AgentStep.model_validate(item) for item in record["steps"]]
            plans.append(Plan(
                id=record["id"],
                goal=record["goal"],
                steps=steps,
                status=record["status"]
            ))
        return plans

