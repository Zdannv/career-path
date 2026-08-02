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
    Calls the Groq API requesting a JSON response using llama3-70b-8192.
    """
    client = _get_groq_client()
    
    messages = []
    if system_instruction:
        messages.append({"role": "system", "content": system_instruction})
    messages.append({"role": "user", "content": prompt})
    
    try:
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages,
            response_format={"type": "json_object"}
        )
        return response.choices[0].message.content
    except Exception as e:
        logger.error(f"Groq API call failed: {e}")
        raise e

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
    
    raw_response = call_llm_json(prompt, system_instruction)
    data = parse_json_safely(raw_response)
    
    return {
        "education": data.get("education"),
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
    
    raw_response = call_llm_json(prompt, system_instruction)
    return parse_json_safely(raw_response)
