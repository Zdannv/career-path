import logging
import os
from typing import Any, Dict, List, Optional

import uvicorn
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

load_dotenv()

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s %(levelname)-8s %(name)s %(message)s",
)
logger = logging.getLogger("careerpath.api")

from auth import AuthenticatedUser, optional_user, require_user  # noqa: E402
from engine import get_supabase_client, run_hybrid_engine  # noqa: E402
from llm_service import extract_profile_from_chat, generate_journey_plan  # noqa: E402

app = FastAPI(title="CareerPath Engine API", version="2.0.0")

# Browser origins allowed to call this service. Never "*": that plus
# credentials is what lets any site read a signed-in user's data.
_origins = [
    o.strip()
    for o in os.getenv("CORS_ALLOWED_ORIGINS", "http://localhost:3000").split(",")
    if o.strip()
]
if "*" in _origins:
    logger.warning("CORS_ALLOWED_ORIGINS contains '*'. Set real origins before deploying.")
logger.info("CORS allowed origins: %s", _origins)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)


class ChatMessage(BaseModel):
    role: str  # 'user' or 'assistant'
    content: str

class ExtractedParams(BaseModel):
    student_name: Optional[str] = None
    class_code: Optional[str] = None
    education: Optional[str] = None
    major: Optional[str] = None
    city: Optional[str] = None
    min_salary: float = 0.0
    skills: List[str] = []

class ChatJourneyRequest(BaseModel):
    messages: List[ChatMessage]
    current_params: Optional[ExtractedParams] = None

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
    is_complete: bool
    state: str
    message: Optional[str] = None
    suggested_skills: Optional[List[str]] = []
    suggested_options: Optional[List[str]] = []
    extracted_params: Optional[ExtractedParams] = None
    recommendations: Optional[List[CareerRecommendation]] = None
    journey_plan: Optional[JourneyPlanResponse] = None

class SaveJourneyRequest(BaseModel):
    student_name: Optional[str] = None
    class_code: Optional[str] = None
    education: Optional[str] = None
    major: Optional[str] = None
    city: Optional[str] = None
    min_salary: float = 0.0
    skills: List[str] = []
    opportunity_overview: str
    journey_plan: Dict[str, Any]
    cost_forecast: Optional[Dict[str, Any]] = None
    csat_rating: Optional[int] = None

@app.get("/api/health")
def health_check():
    return {"status": "healthy"}


@app.get("/api/me")
def whoami(user: AuthenticatedUser = Depends(require_user)):
    """Echoes the verified caller. Use this to check that auth is wired up."""
    return {"id": user.id, "email": user.email, "role": user.role}

def validate_and_correct_state(message: str, current_state: str) -> str:
    import re
    # Split into clauses/sentences
    parts = [p.strip() for p in re.split(r'[.?!]', message) if p.strip()]
    if not parts:
        return current_state
        
    # Look at the last 2 parts of the message (which contain the active question)
    question_parts = parts[-2:] if len(parts) >= 2 else parts
    question_text = " ".join(question_parts).lower()
    
    if "gaji" in question_text or "target gaji" in question_text or "gaji minimal" in question_text:
        return "min_salary"
    if "jurusan" in question_text or "program studi" in question_text:
        return "major"
    if "pendidikan terakhir" in question_text or "tingkat pendidikan" in question_text or "lulusan" in question_text or "sekolah" in question_text:
        return "education"
    if "kota" in question_text or "tempat bekerja" in question_text or "lokasi" in question_text:
        return "city"
    if "apakah ada keahlian lain" in question_text or "sudah cukup" in question_text or "apakah profil" in question_text or "apakah data" in question_text or "apakah seluruh keahlian" in question_text:
        return "confirmation"
    if "keahlian" in question_text or "skill" in question_text or "pengalaman" in question_text or "teknologi" in question_text or "minat dalam" in question_text or "bahasa pemrograman" in question_text or "pemrograman" in question_text or "bidang it" in question_text:
        return "skills"
        
    return current_state

@app.post("/api/chat-journey", response_model=ChatJourneyResponse)
async def generate_chat_journey(request: ChatJourneyRequest):
    """
    Receives chat transcript, extracts parameters, runs math engine, runs LLM, and returns structured plan.
    """
    if not request.messages:
        raise HTTPException(status_code=400, detail="Message history cannot be empty.")
    
    # Convert Pydantic ChatMessages to standard dicts
    messages_list = [{"role": msg.role, "content": msg.content} for msg in request.messages]
    
    # Step 1: LLM Parameter Extraction / Active Probing
    try:
        extracted = extract_profile_from_chat(messages_list)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error extracting parameters: {str(e)}")
        
    # Merge with current_params from frontend to prevent LLM from forgetting earlier extracted details
    if request.current_params:
        def is_empty(val):
            if val is None:
                return True
            s = str(val).strip().lower()
            return s in ["", "null", "none", "tidak ada", "undefined"]

        if is_empty(extracted.get("student_name")) and not is_empty(request.current_params.student_name):
            extracted["student_name"] = request.current_params.student_name
        if is_empty(extracted.get("class_code")) and not is_empty(request.current_params.class_code):
            extracted["class_code"] = request.current_params.class_code
        if is_empty(extracted.get("education")) and not is_empty(request.current_params.education):
            extracted["education"] = request.current_params.education
        if is_empty(extracted.get("major")) and not is_empty(request.current_params.major):
            extracted["major"] = request.current_params.major
        if is_empty(extracted.get("city")) and not is_empty(request.current_params.city):
            extracted["city"] = request.current_params.city
        if (is_empty(extracted.get("min_salary")) or float(extracted.get("min_salary") or 0.0) <= 0) and request.current_params.min_salary > 0:
            extracted["min_salary"] = request.current_params.min_salary
        if request.current_params.skills:
            combined_skills = list(set(extracted.get("skills", []) + request.current_params.skills))
            extracted["skills"] = combined_skills
            
    is_complete = extracted.get("is_complete", False)
    
    # Programmatic completion override if user sent a confirmation/finish message
    latest_user_content = ""
    for msg in reversed(messages_list):
        if msg["role"] == "user":
            latest_user_content = msg["content"].lower()
            break
            
    finish_keywords = ["sudah cukup", "mulai analisis", "selesai", "cukup", "lanjutkan analisis", "mulai sekarang", "ya, cukup"]
    if any(kw in latest_user_content for kw in finish_keywords):
        if extracted.get("education") and extracted.get("city") and extracted.get("skills"):
            is_complete = True
            
    raw_message = extracted.get("message", "Bisa tolong ceritakan lebih lanjut?")
    
    corrected_state = validate_and_correct_state(raw_message, extracted.get("state", "skills"))
    
    # Programmatic Standardized Skills injection
    injected_skills = []
    latest_user_msg = ""
    for msg in reversed(messages_list):
        if msg["role"] == "user":
            latest_user_msg = msg["content"].lower()
            break
            
    STANDARDIZED_MAPPING = {
        "frontend": [
            "React.js", "TypeScript", "JavaScript", "Next.js", "HTML/CSS", 
            "Tailwind CSS", "Vue.js", "Bootstrap", "Angular"
        ],
        "backend": [
            "Node.js", "Laravel", "FastAPI", "Django", "Go (Golang)", "Python", 
            "PHP", "REST API Design", "GraphQL", "PostgreSQL", "MySQL", 
            "MongoDB", "Redis", "Java", "Spring Boot"
        ],
        "mobile": [
            "Kotlin", "Swift", "Dart", "Firebase", "JavaScript", "TypeScript"
        ],
        "devops": [
            "Docker", "Kubernetes (K8s)", "Terraform", "CI/CD (Jenkins, GitHub Actions, GitLab CI)", 
            "AWS", "Google Cloud Platform (GCP)", "Microsoft Azure", "Linux / Unix Administration"
        ],
        "cloud": [
            "AWS", "Google Cloud Platform (GCP)", "Microsoft Azure", "Docker", "Kubernetes (K8s)"
        ],
        "data": [
            "SQL", "Python", "Pandas", "NumPy", "Tableau", "Power BI", "Looker / Looker Studio",
            "ETL/ELT Processes", "Apache Spark", "Apache Kafka", "Data Warehousing Concepts"
        ],
        "ai": [
            "Python", "TensorFlow", "PyTorch", "Hugging Face", "LangChain", "OpenAI API",
            "RAG (Retrieval-Augmented Generation)", "Vector Database (Pinecone, Weaviate)"
        ],
        "machine learning": [
            "Python", "Scikit-learn", "TensorFlow", "PyTorch", "Hugging Face"
        ],
        "cyber": [
            "Network Security", "Web Application Security (OWASP)", "Penetration Testing",
            "SIEM Tools", "Cryptography & PKI"
        ],
        "design": [
            "Figma", "Adobe XD / Photoshop / Illustrator"
        ],
        "ui/ux": [
            "Figma", "Adobe XD / Photoshop / Illustrator"
        ]
    }
    
    for key, skills in STANDARDIZED_MAPPING.items():
        if key in latest_user_msg:
            injected_skills.extend(skills)
            
    seen = set()
    unique_injected = []
    for s in injected_skills:
        if s not in seen:
            seen.add(s)
            unique_injected.append(s)
            
    # Combine with any skills returned by the LLM
    llm_suggested = extracted.get("suggested_skills", [])
    combined_suggested = unique_injected
    for s in llm_suggested:
        if s not in seen:
            seen.add(s)
            combined_suggested.append(s)
            
    # Programmatic State Correction & Fallback
    if combined_suggested:
        corrected_state = "skills"
    elif not is_complete:
        # Fallback to prevent LLM from getting stuck on name_code or empty state
        if extracted.get("student_name"):
            if corrected_state == "name_code":
                if not extracted.get("education"):
                    corrected_state = "education"
                elif not extracted.get("major") and (extracted.get("education") and any(k in extracted.get("education").lower() for k in ["smk", "d3", "s1", "s2", "s3", "diploma", "sarjana", "magister", "doktor"])):
                    corrected_state = "major"
                elif not extracted.get("city"):
                    corrected_state = "city"
                elif not extracted.get("min_salary") or extracted.get("min_salary") <= 0:
                    corrected_state = "min_salary"
                else:
                    corrected_state = "skills"
        
        # Ensure we don't confirm if there are no skills
        if not extracted.get("skills") and corrected_state == "confirmation":
            corrected_state = "skills"

    # Calculate suggested options based on active state
    suggested_options = []
    if not is_complete:
        if corrected_state == "education":
            suggested_options = ["SMA/SMK Sederajat", "Diploma 3 (D3)", "Sarjana (S1/D4)", "Magister (S2)", "Doktor (S3)"]
        elif corrected_state == "major":
            edu = extracted.get("education") or ""
            match_level = None
            if any(k in edu.lower() for k in ["sma", "smk", "sederajat"]):
                match_level = "SMA/SMK Sederajat"
            elif any(k in edu.lower() for k in ["d3", "diploma 3"]):
                match_level = "Diploma 3 (D3)"
            elif any(k in edu.lower() for k in ["s1", "sarjana", "d4", "diploma 4"]):
                match_level = "Sarjana (S1/D4)"
            elif any(k in edu.lower() for k in ["s2", "magister"]):
                match_level = "Magister (S2)"
            elif any(k in edu.lower() for k in ["s3", "doktor", "phd"]):
                match_level = "Doktor (S3)"
                
            if match_level:
                client = get_supabase_client()
                if client:
                    try:
                        res = client.table("education_majors").select("major_name").eq("education_level", match_level).execute()
                        suggested_options = [r["major_name"] for r in res.data]
                    except Exception:
                        pass
                
                # Fallback if no database options found
                if not suggested_options:
                    if match_level == "SMA/SMK Sederajat":
                        suggested_options = [
                            "SMA - MIPA (IPA)", "SMA - IPS", 
                            "SMK - Rekayasa Perangkat Lunak (RPL)", 
                            "SMK - Teknik Komputer & Jaringan (TKJ)",
                            "SMK - Sistem Informatika, Jaringan & Aplikasi (SIJA)",
                            "SMK - Multimedia / Desain Komunikasi Visual (DKV)"
                        ]
                    elif match_level == "Diploma 3 (D3)":
                        suggested_options = ["D3 - Teknik Informatika", "D3 - Sistem Informasi", "D3 - Teknik Komputer"]
                    else:
                        suggested_options = ["S1 - Teknik Informatika", "S1 - Ilmu Komputer", "S1 - Sistem Informasi", "S1 - Sains Data / Data Science", "S1 - Kecerdasan Buatan / AI"]
        elif corrected_state == "city":
            suggested_options = ["Jakarta", "Bandung", "Surabaya"]
        elif corrected_state == "skills":
            user_major = extracted.get("major")
            if user_major:
                client = get_supabase_client()
                if client:
                    try:
                        res = client.table("education_majors").select("suggested_skills").eq("major_name", user_major).execute()
                        if res.data:
                            db_skills = res.data[0].get("suggested_skills") or []
                            combined_suggested = list(set(combined_suggested + db_skills))
                    except Exception:
                        pass

    # If parameters are not fully gathered or the interviewer is still active-probing
    if not is_complete:
        return ChatJourneyResponse(
            is_complete=False,
            state=corrected_state,
            message=raw_message,
            suggested_skills=combined_suggested,
            suggested_options=suggested_options,
            extracted_params=ExtractedParams(
                student_name=extracted.get("student_name"),
                class_code=extracted.get("class_code"),
                education=extracted.get("education"),
                major=extracted.get("major"),
                city=extracted.get("city"),
                min_salary=extracted.get("min_salary", 0.0),
                skills=extracted.get("skills", [])
            ),
            recommendations=None,
            journey_plan=None
        )
        
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
        is_complete=True,
        state="complete",
        message="Analisis selesai. Berikut adalah rekomendasi karier Anda!",
        suggested_skills=[],
        suggested_options=[],
        extracted_params=ExtractedParams(
            student_name=extracted.get("student_name"),
            class_code=extracted.get("class_code"),
            education=extracted.get("education"),
            major=extracted.get("major"),
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
async def save_journey(
    request: SaveJourneyRequest,
    user: Optional[AuthenticatedUser] = Depends(optional_user),
):
    """
    Saves the active user parameters, opportunity overview, and journey plan timeline to Supabase user_journeys table.
    """
    # TODO(fase-2): switch to `require_user` and stamp user_id on the row
    # once student accounts exist. Anonymous saves are legacy behaviour.
    if user is None:
        logger.info("save-journey called anonymously (legacy flow)")

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
        
        # Add student name and class code context if available
        if request.student_name:
            record["student_name"] = request.student_name
        if request.class_code:
            record["class_code"] = request.class_code
        if request.major:
            record["major"] = request.major
        if request.cost_forecast:
            record["cost_forecast"] = request.cost_forecast
        if request.csat_rating is not None:
            record["csat_rating"] = request.csat_rating
            
        try:
            res = client.table("user_journeys").insert(record).execute()
            if not res.data:
                raise HTTPException(status_code=500, detail="Gagal menyimpan rencana karier ke database.")
            return {"status": "success", "inserted_id": res.data[0].get("id")}
        except Exception as db_err:
            fallback_record = record.copy()
            # student_name and class_code columns exist, so we only remove potentially missing ones
            for col in ["cost_forecast", "major", "csat_rating"]:
                if col in fallback_record:
                    del fallback_record[col]
                        
            try:
                res = client.table("user_journeys").insert(fallback_record).execute()
            except Exception:
                # Absolute fallback: save only guaranteed baseline columns
                baseline_cols = ["education", "city", "min_salary", "skills", "opportunity_overview", "journey_plan"]
                absolute_fallback = {k: v for k, v in record.items() if k in baseline_cols}
                try:
                    res = client.table("user_journeys").insert(absolute_fallback).execute()
                except Exception:
                    raise db_err
        
        if not res.data:
            raise HTTPException(status_code=500, detail="Gagal menyimpan rencana karier ke database.")
            
        return {"status": "success", "inserted_id": res.data[0].get("id")}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Terjadi kesalahan koneksi saat menyimpan rencana karier: {str(e)}"
        )

class RateJourneyRequest(BaseModel):
    rating: int

@app.post("/api/journey/{journey_id}/rate")
def rate_journey(journey_id: str, request: RateJourneyRequest):
    """
    Updates the CSAT rating score of a saved student journey.
    """
    client = get_supabase_client()
    if not client:
        raise HTTPException(status_code=503, detail="Koneksi database Supabase tidak tersedia.")
        
    try:
        res = client.table("user_journeys").update({"csat_rating": request.rating}).eq("id", journey_id).execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="Rencana karier tidak ditemukan.")
        return {"status": "success", "data": res.data[0]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gagal menyimpan penilaian kepuasan: {str(e)}")

@app.get("/api/journey/{journey_id}")
def get_journey(journey_id: str):
    """
    Retrieves a single saved student journey by its database UUID.
    """
    client = get_supabase_client()
    if not client:
        raise HTTPException(
            status_code=503,
            detail="Koneksi database Supabase tidak tersedia."
        )
        
    try:
        res = client.table("user_journeys").select("*").eq("id", journey_id).execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="Rencana karier tidak ditemukan.")
        return res.data[0]
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Terjadi kesalahan saat memuat rencana karier: {str(e)}"
        )

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
