import os
from dotenv import load_dotenv
load_dotenv()

import json
import logging
from typing import List, Dict, Any
import google.generativeai as genai
from openai import OpenAI

logger = logging.getLogger(__name__)

# Initialize clients lazily
_gemini_configured = False
_openai_client = None

def _get_openai_client():
    global _openai_client
    if _openai_client is None:
        api_key = os.environ.get("OPENAI_API_KEY")
        if api_key:
            _openai_client = OpenAI(api_key=api_key)
    return _openai_client

def _configure_gemini():
    global _gemini_configured
    if not _gemini_configured:
        api_key = os.environ.get("GEMINI_API_KEY")
        if api_key:
            genai.configure(api_key=api_key)
            _gemini_configured = True
    return _gemini_configured

def call_llm_json(prompt: str, system_instruction: str = "") -> str:
    """
    Calls the configured LLM API (Gemini or OpenAI) requesting a JSON response.
    If no API key is available, returns a clean mock JSON fallback.
    """
    # 1. Try Gemini
    if _configure_gemini():
        try:
            model = genai.GenerativeModel(
                model_name='gemini-1.5-flash',
                generation_config={"response_mime_type": "application/json"}
            )
            # Combine system instruction and prompt for Gemini if system_instruction is not supported as an arg
            # gemini-1.5-flash supports system_instruction in GenerativeModel constructor
            if system_instruction:
                model = genai.GenerativeModel(
                    model_name='gemini-1.5-flash',
                    system_instruction=system_instruction,
                    generation_config={"response_mime_type": "application/json"}
                )
            response = model.generate_content(prompt)
            return response.text
        except Exception as e:
            logger.warning(f"Gemini API call failed: {e}. Trying OpenAI fallback.")

    # 2. Try OpenAI
    openai_client = _get_openai_client()
    if openai_client:
        try:
            messages = []
            if system_instruction:
                messages.append({"role": "system", "content": system_instruction})
            messages.append({"role": "user", "content": prompt})
            
            response = openai_client.chat.completions.create(
                model="gpt-4o-mini",
                messages=messages,
                response_format={"type": "json_object"}
            )
            return response.choices[0].message.content
        except Exception as e:
            logger.warning(f"OpenAI API call failed: {e}. Falling back to mock generator.")

    # 3. Local Mock Fallback
    logger.info("Using local mock LLM fallback.")
    return generate_mock_fallback(prompt, system_instruction)

def parse_json_safely(raw: str) -> Dict[str, Any]:
    """
    Cleans up any potential markdown code blocks (e.g. ```json ... ```) from the LLM output
    and parses it into a Python dictionary.
    """
    if not raw:
        raise ValueError("Empty LLM response.")
    
    clean = raw.strip()
    # Remove markdown prefix if present
    if clean.startswith("```"):
        first_newline = clean.find("\n")
        if first_newline != -1:
            clean = clean[first_newline:].strip()
        else:
            clean = clean[3:].strip()
            
    # Remove markdown suffix if present
    if clean.endswith("```"):
        clean = clean[:-3].strip()
        
    return json.loads(clean)

def extract_profile_from_chat(messages: List[Dict[str, str]]) -> Dict[str, Any]:
    """
    Analyzes chat history to extract education, target city, min salary, and current skills.
    """
    system_instruction = (
        "You are an expert profile extraction bot for CareerPath AI. Your job is to extract user constraints "
        "and parameters from the conversational transcript.\n\n"
        "Extract exactly these keys:\n"
        "- 'education': user's highest education level. Must align to one of: "
        "'High School / Equivalent (SMA/SMK)', 'Associate Degree (D3)', 'Bachelor's Degree (S1)', 'Master's Degree (S2)', 'Doctorate Degree (S3)'.\n"
        "- 'city': preferred target city in Java. Must map to: 'Jakarta', 'Bandung', or 'Surabaya'.\n"
        "- 'min_salary': minimum salary expectations in IDR (integer).\n"
        "- 'skills': a JSON list of strings containing skills, technical abilities, or topics of interest.\n\n"
        "VAGUE INTEREST MAPPING RULE:\n"
        "If the user provides vague interests, you MUST map them to one or more of these concrete database skills:\n"
        "- Drawing/Designing/Interface interests -> 'Figma', 'Wireframing & Prototyping', 'User Research', 'Graphic Design'\n"
        "- Frontend/Website interests -> 'HTML/CSS/JS', 'React/Next.js'\n"
        "- Data/Backend/Statistics interests -> 'Python', 'SQL', 'Data Analysis', 'Machine Learning'\n"
        "- Marketing/Social media/Ad writing -> 'SEO/SEM', 'Copywriting', 'Content Marketing', 'Google Analytics'\n"
        "- Business/Spreadsheet/Finance interests -> 'Financial Modeling', 'Corporate Finance', 'Risk Management', 'Excel / Google Sheets'\n"
        "- Organizing/Managing projects -> 'Project Management'\n"
        "- Soft skills -> 'Communication', 'Problem Solving', 'Teamwork', 'Critical Thinking'\n\n"
        "Your response MUST be a strict raw JSON string. Do NOT wrap it in markdown code blocks. No explanations outside JSON.\n"
        "JSON Schema:\n"
        "{\n"
        "  \"education\": string or null,\n"
        "  \"city\": string or null,\n"
        "  \"min_salary\": number or null,\n"
        "  \"skills\": [string]\n"
        "}"
    )
    
    prompt = f"Chat transcript:\n{json.dumps(messages, indent=2)}"
    
    try:
        raw_response = call_llm_json(prompt, system_instruction)
        data = parse_json_safely(raw_response)
        
        return {
            "education": data.get("education"),
            "city": data.get("city"),
            "min_salary": float(data.get("min_salary")) if data.get("min_salary") else 0.0,
            "skills": list(data.get("skills", []))
        }
    except Exception as e:
        logger.error(f"Failed to parse profile from LLM response: {e}. Raw response was: {raw_response if 'raw_response' in locals() else 'None'}")
        return {
            "education": "Bachelor's Degree (S1)",
            "city": "Jakarta",
            "min_salary": 6000000.0,
            "skills": []
        }

def generate_journey_plan(math_results: List[Dict[str, Any]], user_profile: Dict[str, Any]) -> Dict[str, Any]:
    """
    Injects mathematical filtering results into LLM context to build a personalized multi-year career path.
    """
    system_instruction = (
        "You are CareerPath AI, an expert multi-year journey planner.\n"
        "Your task is to take the mathematically recommended careers and skill gap analysis, "
        "and generate a personalized Multi-Year Journey Planner and Opportunity Overview.\n\n"
        "STRICT LOCALIZATION RULE:\n"
        "ALL RESPONSES, including job titles, journey phases, timeline periods (e.g. 'Tahun 1', 'Tahun 2', 'Tahun 3'), "
        "focus, checklist items, and descriptions, MUST be generated in natural and professional Bahasa Indonesia.\n\n"
        "STRICT NON-PSYCHOLOGICAL RULE:\n"
        "DO NOT provide psychological diagnosis, personality labeling, or mental health advice. "
        "This system is strictly technical and professional. Focus ONLY on actionable, practical steps: "
        "courses/schools to attend, technical or business skills to learn, portfolio projects to build, and job applications.\n\n"
        "CRITICAL RECOMMENDATIONS RULE:\n"
        "You must ONLY reference the matched careers and their details (description, target city, salary range, missing required skills) "
        "from the provided engine results. Do not suggest or create timelines for any other careers.\n\n"
        "Your response MUST be a strict raw JSON string. Do NOT wrap it in markdown code blocks. No explanations outside JSON.\n"
        "JSON Schema:\n"
        "{\n"
        "  \"opportunity_overview\": \"Ringkasan tingkat tinggi mengenai karir yang cocok dan mengapa karir tersebut sesuai dengan kriteria pengguna, disertai tren pasar kerja spesifik di Indonesia.\",\n"
        "  \"journey_plans\": [\n"
        "    {\n"
        "      \"career_id\": number,\n"
        "      \"career_name\": \"string\",\n"
        "      \"timeline\": [\n"
        "        {\n"
        "          \"period\": \"Tahun 1 (atau Tahun 2, Tahun 3)\",\n"
        "          \"focus\": \"Fokus utama untuk tahun ini\",\n"
        "          \"skills_to_acquire\": [\"Daftar keahlian untuk dipelajari\"],\n"
        "          \"action_steps\": [\"Langkah nyata 1\", \"Langkah nyata 2\"],\n"
        "          \"milestones\": [\"Pencapaian utama di akhir tahun\"]\n"
        "        }\n"
        "      ],\n"
        "      \"budget_investment_guideline\": \"Saran tempat belajar keahlian ini (kursus, bootcamp, sumber gratis) beserta panduan anggaran biaya di Indonesia.\"\n"
        "    }\n"
        "  ]\n"
        "}"
    )
    
    prompt = f"Engine Recommendations:\n{json.dumps(math_results, indent=2)}\n\nUser Profile:\n{json.dumps(user_profile, indent=2)}"
    
    try:
        raw_response = call_llm_json(prompt, system_instruction)
        return parse_json_safely(raw_response)
    except Exception as e:
        logger.error(f"Failed to generate structured journey plan: {e}. Raw response was: {raw_response if 'raw_response' in locals() else 'None'}")
        return build_fallback_journey_payload(math_results, user_profile)

def generate_mock_fallback(prompt: str, system_instruction: str) -> str:
    """
    Generates realistic JSON responses if no LLM APIs are configured or if they fail.
    """
    if "extract" in system_instruction.lower():
        prompt_lower = prompt.lower()
        edu = "Sarjana (S1)"
        if "sma" in prompt_lower or "smk" in prompt_lower:
            edu = "SMA / SMK Sederajat"
        elif "d3" in prompt_lower or "diploma" in prompt_lower:
            edu = "Diploma 3 (D3)"
        elif "s2" in prompt_lower or "master" in prompt_lower:
            edu = "Magister (S2)"
            
        city = "Jakarta"
        if "bandung" in prompt_lower:
            city = "Bandung"
        elif "surabaya" in prompt_lower:
            city = "Surabaya"
            
        min_salary = 6000000.0
        if "8" in prompt_lower or "8jt" in prompt_lower or "8.000.000" in prompt_lower:
            min_salary = 8000000.0
        elif "10" in prompt_lower or "10jt" in prompt_lower:
            min_salary = 10000000.0
            
        skills = []
        if "figma" in prompt_lower:
            skills.append("Figma")
        if "python" in prompt_lower:
            skills.append("Python")
        if "design" in prompt_lower:
            skills.append("Figma")
            skills.append("Wireframing & Prototyping")
        if "code" in prompt_lower or "js" in prompt_lower or "react" in prompt_lower:
            skills.append("HTML/CSS/JS")
            skills.append("React/Next.js")
            
        if not skills:
            skills = ["HTML/CSS/JS"]
            
        return json.dumps({
            "education": edu,
            "city": city,
            "min_salary": min_salary,
            "skills": skills
        })
    else:
        try:
            start_idx = prompt.find("Engine Recommendations:")
            if start_idx != -1:
                json_str = prompt[start_idx + len("Engine Recommendations:"):].strip()
                end_idx = json_str.find("User Profile:")
                if end_idx != -1:
                    json_str = json_str[:end_idx].strip()
                math_results = json.loads(json_str)
            else:
                math_results = []
        except Exception:
            math_results = []
            
        if not math_results:
            math_results = [{
                "career_id": 6,
                "career_name": "Software Engineer (Frontend)",
                "description": "Membangun aplikasi web.",
                "target_city": "Bandung",
                "salary_min": 8000000.0,
                "salary_max": 16000000.0,
                "match_score": 85.0,
                "skills": {
                    "required": [{"name": "HTML/CSS/JS", "weight": 30.0}, {"name": "React/Next.js", "weight": 45.0}],
                    "missing": [{"name": "React/Next.js", "weight": 45.0}],
                    "acquired": [{"name": "HTML/CSS/JS", "weight": 30.0}]
                }
            }]
            
        user_profile = {"education": "Sarjana (S1)", "city": "Bandung", "min_salary": 8000000.0, "skills": ["HTML/CSS/JS"]}
        return json.dumps(build_fallback_journey_payload(math_results, user_profile))

def build_fallback_journey_payload(math_results: List[Dict[str, Any]], user_profile: Dict[str, Any]) -> Dict[str, Any]:
    """
    Constructs a deterministic journey planner payload when LLM generation fails or is offline.
    """
    journey_plans = []
    
    for item in math_results:
        c_id = item.get("career_id", 1)
        c_name = item.get("career_name", "Software Engineer")
        missing_skills = [skill["name"] for skill in item.get("skills", {}).get("missing", [])]
        
        timeline = []
        year_1_skills = missing_skills[:2] if missing_skills else ["Keahlian Dasar"]
        timeline.append({
            "period": "Tahun 1",
            "focus": f"Membangun fondasi kuat dan mempelajari keahlian utama yang dibutuhkan untuk posisi {c_name}.",
            "skills_to_acquire": year_1_skills,
            "action_steps": [
                f"Mengikuti kursus sertifikasi online yang mencakup {', '.join(year_1_skills)}.",
                "Membangun 3-5 proyek mandiri kecil untuk mempraktikkan keahlian.",
                "Membuat repositori GitHub personal atau portofolio untuk memajang hasil karya."
            ],
            "milestones": [
                f"Berhasil menyelesaikan pelatihan dasar untuk {', '.join(year_1_skills)}."
            ]
        })
        
        year_2_skills = missing_skills[2:] if len(missing_skills) > 2 else ["Proyek Lanjutan", "Kerja Kolaboratif"]
        timeline.append({
            "period": "Tahun 2",
            "focus": f"Meningkatkan kompetensi ke tingkat lanjut dan mulai berkontribusi pada proyek nyata secara kolaboratif.",
            "skills_to_acquire": year_2_skills,
            "action_steps": [
                f"Mendalami pemahaman mendalam tentang {', '.join(year_2_skills)}.",
                "Berkontribusi pada proyek open-source atau ikut serta dalam hackathon lokal.",
                "Menyiapkan resume profesional yang disesuaikan untuk melamar posisi junior."
            ],
            "milestones": [
                "Menyelesaikan proyek capstone komprehensif yang sesuai standar industri."
            ]
        })
        
        timeline.append({
            "period": "Tahun 3",
            "focus": f"Melakukan transisi karir penuh ke peran profesional {c_name} di kota {item.get('target_city', 'Jakarta')}.",
            "skills_to_acquire": ["Persiapan Wawancara", "Desain Sistem / Praktik Terbaik Profesional"],
            "action_steps": [
                "Melamar pekerjaan magang atau posisi tingkat pemula (entry-level).",
                "Berlatih wawancara teknis dan kepribadian (mock interview).",
                "Membangun jejaring dengan profesional di LinkedIn yang bekerja di kota target."
            ],
            "milestones": [
                f"Mendapatkan tawaran pekerjaan sebagai junior {c_name} dengan gaji awal memenuhi target."
            ]
        })
        
        journey_plans.append({
            "career_id": c_id,
            "career_name": c_name,
            "timeline": timeline,
            "budget_investment_guideline": (
                "Sangat disarankan menggunakan platform belajar gratis dan terjangkau seperti Coursera, Udemy, dan Dicoding Indonesia. "
                "Estimasi investasi: Rp 500.000 - Rp 2.000.000 untuk sertifikasi online standar."
            )
        })
        
    return {
        "opportunity_overview": (
            f"Berdasarkan profil Anda, kami mencocokkan Anda dengan {len(math_results)} jalur karir. "
            "Pekerjaan ini memenuhi kriteria gaji dan pendidikan Anda, serta selaras dengan keahlian/minat Anda. "
            "Pusat bisnis digital utama di Jawa (Jakarta, Bandung, Surabaya) menawarkan prospek pertumbuhan yang luar biasa untuk peran ini."
        ),
        "journey_plans": journey_plans
    }
