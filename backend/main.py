from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import uvicorn
from dotenv import load_dotenv

# Load env variables (e.g., GEMINI_API_KEY, OPENAI_API_KEY, SUPABASE_URL, SUPABASE_KEY)
load_dotenv()

from engine import run_hybrid_engine, get_supabase_client
from llm_service import extract_profile_from_chat, generate_journey_plan, generate_lesson_plan

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

@app.get("/api/health")
def health_check():
    return {"status": "healthy"}

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
        if not extracted.get("student_name") and request.current_params.student_name:
            extracted["student_name"] = request.current_params.student_name
        if not extracted.get("class_code") and request.current_params.class_code:
            extracted["class_code"] = request.current_params.class_code
        if not extracted.get("education") and request.current_params.education:
            extracted["education"] = request.current_params.education
        if not extracted.get("major") and request.current_params.major:
            extracted["major"] = request.current_params.major
        if not extracted.get("city") and request.current_params.city:
            extracted["city"] = request.current_params.city
        if (not extracted.get("min_salary") or extracted.get("min_salary") <= 0) and request.current_params.min_salary > 0:
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

    # If parameters are not fully gathered or the interviewer is still active-probing
    if not is_complete:
        return ChatJourneyResponse(
            is_complete=False,
            state=corrected_state,
            message=raw_message,
            suggested_skills=combined_suggested,
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
        
        # Add student name and class code context if available
        if request.student_name:
            record["student_name"] = request.student_name
        if request.class_code:
            record["class_code"] = request.class_code
        if request.major:
            record["major"] = request.major
        if request.cost_forecast:
            record["cost_forecast"] = request.cost_forecast
            
        try:
            res = client.table("user_journeys").insert(record).execute()
        except Exception as db_err:
            # Fallback in case columns do not exist yet on Supabase table schema
            fallback_record = record.copy()
            for col in ["student_name", "class_code", "cost_forecast", "major"]:
                if col in fallback_record:
                    del fallback_record[col]
            try:
                res = client.table("user_journeys").insert(fallback_record).execute()
            except Exception:
                # Raise original error if all retries fail
                raise db_err
        
        if not res.data:
            raise HTTPException(status_code=500, detail="Gagal menyimpan rencana karier ke database.")
            
        return {"status": "success", "inserted_id": res.data[0].get("id")}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Terjadi kesalahan koneksi saat menyimpan rencana karier: {str(e)}"
        )

class CreateClassRequest(BaseModel):
    class_name: str

@app.post("/api/teacher/classes")
def create_class(request: CreateClassRequest):
    """
    Registers a new class name and generates/saves a unique class code in Supabase 'classes' table.
    """
    client = get_supabase_client()
    if not client:
        raise HTTPException(
            status_code=503,
            detail="Koneksi database Supabase tidak tersedia."
        )
    
    import re
    import random
    import string
    
    class_name = request.class_name.strip()
    if not class_name:
        raise HTTPException(status_code=400, detail="Nama kelas tidak boleh kosong.")
        
    # Generate unique class code
    cleaned = re.sub(r'[^a-zA-Z0-9\s-]', '', class_name).strip().upper()
    slug = re.sub(r'[\s-]+', '-', cleaned)
    rand = ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))
    class_code = f"{slug}-{rand}" if slug else f"CLASS-{rand}"
    
    try:
        record = {
            "class_name": class_name,
            "class_code": class_code
        }
        res = client.table("classes").insert(record).execute()
        if not res.data:
            raise HTTPException(status_code=500, detail="Gagal menyimpan data kelas ke database.")
        return {"status": "success", "data": res.data[0]}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=(
                "Gagal menyimpan kelas. Pastikan tabel 'classes' sudah dibuat di database Supabase. "
                "Silakan jalankan file migration_classes_table.sql di SQL Editor Supabase Anda. "
                f"Error detail: {str(e)}"
            )
        )

@app.get("/api/teacher/classes")
def get_classes():
    """
    Returns list of all active registered classes from Supabase.
    """
    client = get_supabase_client()
    if not client:
        return {"classes": []}
        
    try:
        res = client.table("classes").select("*").order("created_at", desc=True).execute()
        return {"classes": res.data or []}
    except Exception as e:
        # Fallback to mock classes if database query fails (e.g. migration not run yet)
        return {
            "classes": [
                {"class_name": "XII RPL 1 (Mock)", "class_code": "XII-RPL-1-MOCK", "created_at": "2026-08-01T12:00:00Z"},
                {"class_name": "XII TKJ 2 (Mock)", "class_code": "XII-TKJ-2-MOCK", "created_at": "2026-08-01T12:00:00Z"}
            ],
            "warning": (
                "Tabel database 'classes' belum terdeteksi. Silakan jalankan script migration_classes_table.sql "
                "di SQL Editor Dashboard Supabase Anda."
            )
        }

class LessonPlanRequest(BaseModel):
    topic: str
    grade_level: str

@app.get("/api/teacher/summary")
def get_teacher_summary(class_code: Optional[str] = None):
    """
    Returns aggregated analytics for Guidance Counselors (Guru BK) based on saved user journeys.
    Can be filtered by class_code.
    """
    client = get_supabase_client()
    if not client:
        return {
            "total_journeys": 0,
            "top_careers": [],
            "average_cost": 0.0,
            "students": []
        }
        
    try:
        # Fetch filtered or all records
        if class_code:
            res = client.table("user_journeys").select("*").eq("class_code", class_code).execute()
        else:
            res = client.table("user_journeys").select("*").execute()
            
        data = res.data or []
        
        total_journeys = len(data)
        career_counts = {}
        cost_sum = 0.0
        cost_count = 0
        students_list = []
        
        for item in data:
            sname = item.get("student_name") or "Anonim"
            plan = item.get("journey_plan") or {}
            cname = plan.get("career_name") or "Belum Ditentukan"
            
            # Add to student table info
            students_list.append({
                "student_name": sname,
                "career_name": cname,
                "class_code": item.get("class_code") or "-"
            })
            
            # Aggregate matched careers
            if cname and cname != "Belum Ditentukan":
                career_counts[cname] = career_counts.get(cname, 0) + 1
                
            # Aggregate cost forecasts
            cf = item.get("cost_forecast") or {}
            total_cost = cf.get("total_cost")
            if total_cost is not None:
                try:
                    cost_sum += float(total_cost)
                    cost_count += 1
                except (ValueError, TypeError):
                    pass
                    
        sorted_careers = sorted(career_counts.items(), key=lambda x: x[1], reverse=True)
        top_careers = [{"career_name": k, "count": v} for k, v in sorted_careers[:5]]
        avg_cost = cost_sum / cost_count if cost_count > 0 else 0.0
        
        # If no entries are present yet (and no filter is active), return a helpful default mock state so counselors can visualize immediately
        if total_journeys == 0 and not class_code:
            return {
                "total_journeys": 15,
                "top_careers": [
                    {"career_name": "Frontend Developer", "count": 6},
                    {"career_name": "DevOps Engineer", "count": 4},
                    {"career_name": "Data Analyst", "count": 3},
                    {"career_name": "Mobile Developer", "count": 2}
                ],
                "average_cost": 54000000.0,
                "students": [
                    {"student_name": "Budi", "career_name": "Frontend Developer", "class_code": "SMK-BISA-26"},
                    {"student_name": "Siti", "career_name": "DevOps Engineer", "class_code": "SMK-BISA-26"},
                    {"student_name": "Andi", "career_name": "Data Analyst", "class_code": "SMK-BISA-26"}
                ]
            }
            
        return {
            "total_journeys": total_journeys,
            "top_careers": top_careers,
            "average_cost": avg_cost,
            "students": students_list
        }
    except Exception as e:
        # Fallback to mock dashboard stats if Supabase request hits any connection or format error
        return {
            "total_journeys": 15,
            "top_careers": [
                {"career_name": "Frontend Developer (Mock)", "count": 6},
                {"career_name": "DevOps Engineer (Mock)", "count": 4},
                {"career_name": "Data Analyst (Mock)", "count": 3},
                {"career_name": "Mobile Developer (Mock)", "count": 2}
            ],
            "average_cost": 54000000.0,
            "students": [
                {"student_name": "Budi (Mock)", "career_name": "Frontend Developer", "class_code": "SMK-BISA-26"},
                {"student_name": "Siti (Mock)", "career_name": "DevOps Engineer", "class_code": "SMK-BISA-26"},
                {"student_name": "Andi (Mock)", "career_name": "Data Analyst", "class_code": "SMK-BISA-26"}
            ]
        }

@app.post("/api/teacher/lesson-plan")
def get_lesson_plan(request: LessonPlanRequest):
    """
    Generates a structured lesson plan for counselors using LLM orientation capabilities.
    """
    try:
        plan = generate_lesson_plan(request.topic, request.grade_level)
        return {"lesson_plan": plan}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Terjadi kesalahan saat memproses materi pembelajaran: {str(e)}"
        )

MOCK_GIGS = [
    {
        "title": "Freelance UI/UX Designer untuk Landing Page UMKM",
        "type": "Gigs / Freelance",
        "city": "Surabaya",
        "salary_range": "Rp 2.000.000 - Rp 5.000.000 /proyek",
        "skills": ["Figma", "Web Design", "Wireframing"]
    },
    {
        "title": "Part-time React & Next.js Developer",
        "type": "Gigs / Freelance",
        "city": "Bandung",
        "salary_range": "Rp 4.000.000 - Rp 7.000.000 /bulan",
        "skills": ["React.js", "Next.js", "TypeScript"]
    },
    {
        "title": "Jasa Migrasi Database PostgreSQL & Security Audit",
        "type": "Gigs / Freelance",
        "city": "Jakarta",
        "salary_range": "Rp 5.000.000 - Rp 10.000.000 /proyek",
        "skills": ["PostgreSQL", "Database Security", "SQL"]
    },
    {
        "title": "Pembuatan Aplikasi Mobile Flutter (E-Commerce Lokal)",
        "type": "Gigs / Freelance",
        "city": "Yogyakarta",
        "salary_range": "Rp 8.000.000 - Rp 15.000.000 /proyek",
        "skills": ["Flutter", "Dart", "REST API Design"]
    },
    {
        "title": "Setup Pipeline CI/CD Docker & AWS (Kontrak 2 Bulan)",
        "type": "Gigs / Freelance",
        "city": "Jakarta",
        "salary_range": "Rp 6.000.000 - Rp 12.000.000 /bulan",
        "skills": ["Docker", "AWS", "CI/CD (Jenkins, GitHub Actions, GitLab CI)"]
    },
    {
        "title": "Freelance Penulis Konten & Edukasi IT BK",
        "type": "Gigs / Freelance",
        "city": "Malang",
        "salary_range": "Rp 1.500.000 - Rp 3.000.000 /proyek",
        "skills": ["Communication", "English Proficiency", "Agile / Scrum"]
    }
]

@app.get("/api/jobs/trends")
def get_jobs_trends():
    """
    Returns full-time career listings combined with mock freelance gig opportunities.
    """
    try:
        from engine import fetch_data
        df_edu, df_skills, df_careers, df_cs = fetch_data()
        
        jobs_list = []
        for _, row in df_careers.iterrows():
            career_id = int(row["id"])
            cname = row["career_name"]
            
            # target_city or location_bias mapping
            city = row.get("target_city") or row.get("location_bias") or "Jakarta"
            
            # clean city format (e.g. list or string)
            if isinstance(city, str):
                main_city = [c.strip() for c in city.split(",")][0]
            else:
                main_city = "Jakarta"
                
            salary_min = float(row.get("salary_min", 4000000.0))
            salary_max = float(row.get("salary_max", 12000000.0))
            
            # Find related skills sorted by weight_pct
            cs_filtered = df_cs[df_cs["career_id"] == career_id].sort_values(by="weight_pct", ascending=False)
            top_skills = []
            for _, cs_row in cs_filtered.head(3).iterrows():
                sid = int(cs_row["skill_id"])
                skill_matches = df_skills[df_skills["id"] == sid]
                if not skill_matches.empty:
                    top_skills.append(skill_matches.iloc[0]["skill_name"])
                    
            if not top_skills:
                top_skills = ["Python", "JavaScript", "HTML/CSS"]
                
            jobs_list.append({
                "title": cname,
                "type": "Full-time",
                "city": main_city,
                "salary_min": salary_min,
                "salary_max": salary_max,
                "skills": top_skills
            })
            
        return {
            "full_time_jobs": jobs_list,
            "freelance_gigs": MOCK_GIGS
        }
    except Exception as e:
        logger.error(f"Error fetching jobs trends: {e}")
        return {
            "full_time_jobs": [
                {
                    "title": "Frontend Developer",
                    "type": "Full-time",
                    "city": "Jakarta",
                    "salary_min": 5000000.0,
                    "salary_max": 12000000.0,
                    "skills": ["React.js", "TypeScript", "HTML/CSS"]
                },
                {
                    "title": "Backend Developer",
                    "type": "Full-time",
                    "city": "Bandung",
                    "salary_min": 6000000.0,
                    "salary_max": 15000000.0,
                    "skills": ["Node.js", "FastAPI", "PostgreSQL"]
                }
            ],
            "freelance_gigs": MOCK_GIGS
        }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
