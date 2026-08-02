from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import uvicorn
from dotenv import load_dotenv

# Load env variables (e.g., GEMINI_API_KEY, OPENAI_API_KEY, SUPABASE_URL, SUPABASE_KEY)
load_dotenv()

from engine import run_hybrid_engine, get_supabase_client
from llm_service import extract_profile_from_chat, generate_journey_plan

app = FastAPI(title="CareerPath AI Core API Engine", version="1.0.0")

# Enable CORS for Next.js frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For production, restrict this to the frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatMessage(BaseModel):
    role: str  # 'user' or 'assistant'
    content: str

class ChatJourneyRequest(BaseModel):
    messages: List[ChatMessage]

class ExtractedParams(BaseModel):
    education: Optional[str] = None
    city: Optional[str] = None
    min_salary: float = 0.0
    skills: List[str] = []

class SkillItem(BaseModel):
    name: str
    weight: float

class CareerSkillsGroup(BaseModel):
    required: List[SkillItem]
    missing: List[SkillItem]
    acquired: List[SkillItem]

class CareerRecommendation(BaseModel):
    career_id: int
    career_name: str
    description: str
    target_city: str
    salary_min: float
    salary_max: float
    match_score: float
    skills: CareerSkillsGroup

class TimelineItem(BaseModel):
    period: str
    focus: str
    skills_to_acquire: List[str]
    action_steps: List[str]
    milestones: List[str]

class IndividualJourneyPlan(BaseModel):
    career_id: int
    career_name: str
    timeline: List[TimelineItem]
    budget_investment_guideline: str

class JourneyPlanResponse(BaseModel):
    opportunity_overview: str
    journey_plans: List[IndividualJourneyPlan]

class ChatJourneyResponse(BaseModel):
    extracted_params: ExtractedParams
    recommendations: List[CareerRecommendation]
    journey_plan: JourneyPlanResponse

class SaveJourneyRequest(BaseModel):
    education: Optional[str] = None
    city: Optional[str] = None
    min_salary: float = 0.0
    skills: List[str] = []
    opportunity_overview: str
    journey_plan: Dict[str, Any]

@app.get("/api/health")
def health_check():
    return {"status": "healthy"}

@app.post("/api/chat-journey", response_model=ChatJourneyResponse)
async def generate_chat_journey(request: ChatJourneyRequest):
    """
    Receives chat transcript, extracts parameters, runs math engine, runs LLM, and returns structured plan.
    """
    if not request.messages:
        raise HTTPException(status_code=400, detail="Message history cannot be empty.")
    
    # Convert Pydantic ChatMessages to standard dicts
    messages_list = [{"role": msg.role, "content": msg.content} for msg in request.messages]
    
    # Step 1: LLM Parameter Extraction
    try:
        extracted = extract_profile_from_chat(messages_list)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error extracting parameters: {str(e)}")
        
    # Step 2: KBF & CBF Math Engine Matching
    try:
        recommendations = run_hybrid_engine(
            user_skills=extracted.get("skills", []),
            user_education=extracted.get("education", ""),
            user_min_salary=extracted.get("min_salary", 0.0),
            user_city=extracted.get("city")
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error matching careers: {str(e)}")
        
    # If KBF filters out everything, let's retry with relaxed salary constraint (e.g. min_salary = 0)
    # to guarantee the user gets some recommendations instead of a blank screen
    if not recommendations and extracted.get("min_salary", 0.0) > 0:
        try:
            recommendations = run_hybrid_engine(
                user_skills=extracted.get("skills", []),
                user_education=extracted.get("education", ""),
                user_min_salary=0.0,
                user_city=extracted.get("city")
            )
        except Exception:
            pass

    # Step 3: LLM Multi-Year Journey Planner
    try:
        journey_plan = generate_journey_plan(recommendations, extracted)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating journey plan: {str(e)}")
        
    # Standardize results to match Response schema
    formatted_recommendations = []
    for rec in recommendations:
        formatted_recommendations.append(
            CareerRecommendation(
                career_id=rec["career_id"],
                career_name=rec["career_name"],
                description=rec["description"],
                target_city=rec["target_city"],
                salary_min=rec["salary_min"],
                salary_max=rec["salary_max"],
                match_score=rec["match_score"],
                skills=CareerSkillsGroup(
                    required=[SkillItem(name=s["name"], weight=s["weight"]) for s in rec["skills"]["required"]],
                    missing=[SkillItem(name=s["name"], weight=s["weight"]) for s in rec["skills"]["missing"]],
                    acquired=[SkillItem(name=s["name"], weight=s["weight"]) for s in rec["skills"]["acquired"]]
                )
            )
        )
        
    formatted_journey_plans = []
    for plan in journey_plan.get("journey_plans", []):
        timeline_items = []
        for tl in plan.get("timeline", []):
            timeline_items.append(
                TimelineItem(
                    period=tl.get("period", ""),
                    focus=tl.get("focus", ""),
                    skills_to_acquire=tl.get("skills_to_acquire", []),
                    action_steps=tl.get("action_steps", []),
                    milestones=tl.get("milestones", [])
                )
            )
        formatted_journey_plans.append(
            IndividualJourneyPlan(
                career_id=plan.get("career_id", 0),
                career_name=plan.get("career_name", ""),
                timeline=timeline_items,
                budget_investment_guideline=plan.get("budget_investment_guideline", "")
            )
        )
        
    formatted_response = ChatJourneyResponse(
        extracted_params=ExtractedParams(
            education=extracted.get("education"),
            city=extracted.get("city"),
            min_salary=extracted.get("min_salary", 0.0),
            skills=extracted.get("skills", [])
        ),
        recommendations=formatted_recommendations,
        journey_plan=JourneyPlanResponse(
            opportunity_overview=journey_plan.get("opportunity_overview", ""),
            journey_plans=formatted_journey_plans
        )
    )
    
    return formatted_response

@app.post("/api/save-journey")
async def save_journey(request: SaveJourneyRequest):
    """
    Saves the active user parameters, opportunity overview, and journey plan timeline to Supabase user_journeys table.
    """
    client = get_supabase_client()
    if not client:
        raise HTTPException(
            status_code=503,
            detail="Koneksi database Supabase tidak tersedia. Silakan lengkapi SUPABASE_URL dan SUPABASE_KEY di .env."
        )
        
    try:
        record = {
            "education": request.education,
            "city": request.city,
            "min_salary": request.min_salary,
            "skills": request.skills,
            "opportunity_overview": request.opportunity_overview,
            "journey_plan": request.journey_plan
        }
        
        res = client.table("user_journeys").insert(record).execute()
        
        if not res.data:
            raise HTTPException(status_code=500, detail="Gagal menyimpan rencana karier ke database.")
            
        return {"status": "success", "inserted_id": res.data[0].get("id")}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Terjadi kesalahan koneksi saat menyimpan rencana karier: {str(e)}"
        )

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
