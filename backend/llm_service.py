import os
from dotenv import load_dotenv
load_dotenv()

import json
import logging
from typing import List, Dict, Any
from groq import Groq

logger = logging.getLogger(__name__)

# Initialize Groq client
_groq_client = None

def _get_groq_client() -> Groq:
    global _groq_client
    if _groq_client is None:
        api_key = os.environ.get("GROQ_API_KEY")
        if not api_key:
            raise ValueError("GROQ_API_KEY environment variable is not set. Please add it to your .env file.")
        _groq_client = Groq(api_key=api_key)
    return _groq_client

def call_llm_json(prompt: str, system_instruction: str = "") -> str:
    """
    Calls the Groq API requesting a JSON response, with automatic fallback
    to smaller models if rate limits (429) or token limits are hit.
    """
    client = _get_groq_client()
    
    messages = []
    if system_instruction:
        messages.append({"role": "system", "content": system_instruction})
    messages.append({"role": "user", "content": prompt})
    
    # Try models in order, falling back on 429 or general errors
    models_to_try = [
        "llama-3.3-70b-versatile",
        "llama-3.1-8b-instant"
    ]
    
    last_err = None
    for model_name in models_to_try:
        try:
            print(f"[llm_service] Requesting chat completion using model: {model_name}")
            response = client.chat.completions.create(
                model=model_name,
                messages=messages,
                response_format={"type": "json_object"}
            )
            return response.choices[0].message.content
        except Exception as e:
            print(f"[llm_service] Model {model_name} failed: {e}")
            last_err = e
            continue
            
    logger.error(f"Groq API call failed for all models. Last error: {last_err}")
    raise last_err

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
    Analyzes chat history to actively interview the user, probing for specific skills and extracting parameters.
    """
    system_instruction = (
        "You are CareerPath AI, a friendly, conversational career counseling bot.\n"
        "Your task is to conduct an interactive interview with the user to gather these parameters:\n"
        "1. 'student_name': Nama panggilan atau nama depan siswa (wajib ditanyakan di awal chat/percakapan secara santai).\n"
        "2. 'class_code': Kode kelas dari Guru BK jika ada (bersifat opsional/nullable, tanyakan bersamaan dengan nama panggilan).\n"
        "3. 'education': Tingkat pendidikan terakhir. Harus selaras dengan salah satu dari: "
        "'SMA/SMK Sederajat', 'Diploma 3 (D3)', 'Sarjana (S1)', 'Magister (S2)', 'Doktor (S3)'.\n"
        "4. 'major': Jurusan atau Program Studi. Wajib ditanyakan jika tingkat pendidikan terakhirnya adalah SMK atau Kuliah (D3, S1, S2, S3).\n"
        "5. 'city': Kota target tempat bekerja di Pulau Jawa. Harus selaras dengan salah satu dari: 'Jakarta', 'Bandung', atau 'Surabaya'.\n"
        "6. 'min_salary': Target gaji bulanan minimum (dalam Rupiah, integer).\n"
        "7. 'skills': Daftar skill teknis spesifik dari 113 database IT skills kami.\n\n"
        "ACTIVE INTERVIEW & PROBING RULES:\n"
        "- Lakukan percakapan dalam Bahasa Indonesia dengan nada santun, profesional, dan bersahabat.\n"
        "- Di pesan pertama atau awal chat, tanyakan nama panggilan mereka dan apakah mereka memiliki kode kelas dari Guru BK.\n"
        "- Ajukan pertanyaan satu per satu secara bertahap secara alami. Jangan menanyakan semua parameter sekaligus dalam satu pesan.\n"
        "- Jika ada parameter yang belum diketahui, tanyakanlah secara percakapan.\n"
        "- ATURAN 1 (PENTING): Jika pengguna memberikan bidang IT yang luas atau tidak spesifik (seperti 'Saya suka frontend', 'Saya belajar backend', 'Saya tertarik data', 'Saya mau cyber security', 'Saya anak DevOps/Cloud'), Anda HARUS menetapkan 'is_complete' menjadi false.\n"
        "- ATURAN 2 (PENTING): Ketika pengguna menggunakan istilah luas tersebut, Anda WAJIB membalas dengan menyarankan 3-5 skill spesifik dari daftar database kami dalam pesan Anda agar mereka bisa memilih/mengonfirmasinya. Contoh saran:\n"
        "  * Frontend -> React.js, HTML/CSS, JavaScript, Next.js, Vue.js.\n"
        "  * Backend -> Python, Go (Golang), Node.js, PHP, API Design & REST, Laravel.\n"
        "  * Data/AI -> Python, SQL, Pandas, Tableau, Machine Learning, Data Analysis.\n"
        "  * DevOps/Cloud -> Docker, Kubernetes (K8s), CI/CD, AWS, Terraform.\n"
        "  * Cybersecurity -> Network Security, Web Application Security (OWASP), Penetration Testing.\n"
        "  Tanyakan kepada pengguna manakah dari skill spesifik tersebut yang sudah mereka kuasai atau ingin dipelajari.\n"
        "- ATURAN 3: Kumpulkan semua parameter secara spesifik.\n"
        "- ATURAN 4 (KONFIRMASI AKHIR): JANGAN langsung menetapkan 'is_complete' menjadi true saat pertama kali keahlian terkumpul. Anda WAJIB mengonfirmasi data yang terkumpul secara ramah, dan menanyakan apakah pengguna ingin menambahkan keahlian lain atau sudah cukup.\n"
        "- ATURAN 5 (SUBMIT HANYA SAAT DISETUJUI): Tetapkan 'is_complete' menjadi true HANYA jika pengguna secara eksplisit mengkonfirmasi bahwa data sudah cukup / selesai (misal mengirimkan pesan 'sudah cukup', 'cukup', 'selesai', 'mulai analisis', 'lanjut', atau konfirmasi sejenis).\n\n"
        "STRICT NON-PSYCHOLOGICAL RULE:\n"
        "JANGAN memberikan saran psikologis, tes kepribadian, diagnosa mental, atau nasihat medis. Fokus murni pada pemetaan profil karier IT teknis.\n\n"
        "Your response MUST be a strict raw JSON string. Do NOT wrap it in markdown code blocks. No explanations outside JSON.\n"
        "Crucial: Ensure every key is enclosed in double quotes (e.g. \"is_complete\": false). Do NOT output keys without quotes like \"is_complete:false\".\n"
        "JSON Schema:\n"
        "{\n"
        "  \"is_complete\": boolean,\n"
        "  \"state\": \"Tentukan tahap berdasarkan pertanyaan terakhir Anda (asisten) di 'message': 'name_code' (menanyakan nama/kode kelas), 'education' (menanyakan pendidikan), 'major' (menanyakan jurusan), 'city' (menanyakan kota), 'min_salary' (menanyakan target gaji), 'skills' (menanyakan/probing keahlian/minat IT), 'confirmation' (mengonfirmasi profil dan bertanya apakah sudah cukup).\",\n"
        "  \"message\": \"Conversational reply to the user in Bahasa Indonesia. Ask for nickname/class_code first if not set.\",\n"
        "  \"suggested_skills\": [\"string\"],\n"
        "  \"student_name\": \"string or null\",\n"
        "  \"class_code\": \"string or null\",\n"
        "  \"education\": \"string or null\",\n"
        "  \"major\": \"string or null\",\n"
        "  \"city\": \"string or null\",\n"
        "  \"min_salary\": number or null,\n"
        "  \"skills\": [\"string\"]\n"
        "}"
    )
    
    prompt = f"Chat transcript:\n{json.dumps(messages, indent=2)}"
    
    raw_response = call_llm_json(prompt, system_instruction)
    data = parse_json_safely(raw_response)
    
    return {
        "is_complete": bool(data.get("is_complete", False)),
        "state": str(data.get("state", "skills")),
        "message": data.get("message", ""),
        "suggested_skills": list(data.get("suggested_skills", [])),
        "student_name": data.get("student_name"),
        "class_code": data.get("class_code"),
        "education": data.get("education"),
        "major": data.get("major"),
        "city": data.get("city"),
        "min_salary": float(data.get("min_salary")) if data.get("min_salary") else 0.0,
        "skills": list(data.get("skills", []))
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
        "from the provided engine results. Do not suggest or create timelines for any other careers.\n"
        "You MUST generate exactly one journey plan for EACH of the recommended careers in the input list. "
        "Do not skip any careers. For example, if the engine returns 3 careers, 'journey_plans' MUST contain exactly 3 objects. "
        "Each object's 'career_id' and 'career_name' MUST match the corresponding inputs exactly.\n\n"
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
    
    raw_response = call_llm_json(prompt, system_instruction)
    return parse_json_safely(raw_response)
