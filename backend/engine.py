import os
from dotenv import load_dotenv
load_dotenv()

import pandas as pd
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from typing import List, Dict, Any, Tuple
from supabase import create_client, Client

# Local Seed Data fallback if Supabase is not connected
SEED_EDUCATION_LEVELS = [
    {"id": 1, "level_name": "SMA / SMK Sederajat", "order_rank": 1},
    {"id": 2, "level_name": "Diploma 3 (D3)", "order_rank": 2},
    {"id": 3, "level_name": "Sarjana (S1)", "order_rank": 3},
    {"id": 4, "level_name": "Magister (S2)", "order_rank": 4},
    {"id": 5, "level_name": "Doktor (S3)", "order_rank": 5}
]

SEED_SKILLS = [
    {"id": 1, "skill_name": "Figma", "category": "Tech", "skill_type": "hard_skill"},
    {"id": 2, "skill_name": "Wireframing & Prototyping", "category": "Tech", "skill_type": "hard_skill"},
    {"id": 3, "skill_name": "User Research", "category": "Tech", "skill_type": "hard_skill"},
    {"id": 4, "skill_name": "HTML/CSS/JS", "category": "Tech", "skill_type": "hard_skill"},
    {"id": 5, "skill_name": "Python", "category": "Tech", "skill_type": "hard_skill"},
    {"id": 6, "skill_name": "SQL", "category": "Tech", "skill_type": "hard_skill"},
    {"id": 7, "skill_name": "Data Analysis", "category": "Tech", "skill_type": "hard_skill"},
    {"id": 8, "skill_name": "Machine Learning", "category": "Tech", "skill_type": "hard_skill"},
    {"id": 9, "skill_name": "React/Next.js", "category": "Tech", "skill_type": "hard_skill"},
    {"id": 10, "skill_name": "SEO/SEM", "category": "Creative", "skill_type": "hard_skill"},
    {"id": 11, "skill_name": "Copywriting", "category": "Creative", "skill_type": "hard_skill"},
    {"id": 12, "skill_name": "Content Marketing", "category": "Creative", "skill_type": "hard_skill"},
    {"id": 13, "skill_name": "Google Analytics", "category": "Creative", "skill_type": "hard_skill"},
    {"id": 14, "skill_name": "Graphic Design", "category": "Creative", "skill_type": "hard_skill"},
    {"id": 15, "skill_name": "Financial Modeling", "category": "Business", "skill_type": "hard_skill"},
    {"id": 16, "skill_name": "Corporate Finance", "category": "Business", "skill_type": "hard_skill"},
    {"id": 17, "skill_name": "Risk Management", "category": "Business", "skill_type": "hard_skill"},
    {"id": 18, "skill_name": "Excel / Google Sheets", "category": "Business", "skill_type": "hard_skill"},
    {"id": 19, "skill_name": "Project Management", "category": "Business", "skill_type": "hard_skill"},
    {"id": 20, "skill_name": "Communication", "category": "Interpersonal", "skill_type": "soft_skill"},
    {"id": 21, "skill_name": "Problem Solving", "category": "Interpersonal", "skill_type": "soft_skill"},
    {"id": 22, "skill_name": "Teamwork", "category": "Interpersonal", "skill_type": "soft_skill"},
    {"id": 23, "skill_name": "Critical Thinking", "category": "Interpersonal", "skill_type": "soft_skill"}
]

SEED_CAREERS = [
    {"id": 1, "career_name": "UI/UX Designer", "career_description": "Bertanggung jawab untuk merancang antarmuka pengguna yang mudah digunakan, menarik secara visual, serta membuat prototipe produk digital.", "min_education_id": 3, "target_city": "Jakarta", "salary_min": 8000000.0, "salary_max": 15000000.0},
    {"id": 2, "career_name": "Junior UI/UX Designer", "career_description": "Desainer tingkat pemula yang fokus pada pembuatan wireframe, komponen UI, serta membantu riset pengguna.", "min_education_id": 2, "target_city": "Bandung", "salary_min": 5000000.0, "salary_max": 8000000.0},
    {"id": 3, "career_name": "Digital Marketer", "career_description": "Merencanakan dan mengelola kampanye pemasaran online, strategi SEO/SEM, serta pemasaran konten untuk meningkatkan trafik dan interaksi.", "min_education_id": 3, "target_city": "Jakarta", "salary_min": 7000000.0, "salary_max": 14000000.0},
    {"id": 4, "career_name": "Digital Marketing Specialist", "career_description": "Mengelola anggaran periklanan, optimasi SEO, serta analisis performa kampanye guna meningkatkan ROI pemasaran digital.", "min_education_id": 3, "target_city": "Surabaya", "salary_min": 6000000.0, "salary_max": 12000000.0},
    {"id": 5, "career_name": "Financial Analyst", "career_description": "Menganalisis kinerja keuangan, menyusun model proyeksi keuangan, dan menyiapkan rekomendasi investasi.", "min_education_id": 3, "target_city": "Jakarta", "salary_min": 9000000.0, "salary_max": 18000000.0},
    {"id": 6, "career_name": "Software Engineer (Frontend)", "career_description": "Membangun aplikasi web yang responsif dan berkinerja tinggi menggunakan pustaka/kerangka kerja Javascript modern seperti React dan Next.js.", "min_education_id": 3, "target_city": "Bandung", "salary_min": 8000000.0, "salary_max": 16000000.0},
    {"id": 7, "career_name": "Data Scientist", "career_description": "Membangun model prediksi, memproses kumpulan data besar, dan melakukan analisis statistik mendalam untuk mendukung keputusan bisnis.", "min_education_id": 3, "target_city": "Jakarta", "salary_min": 12000000.0, "salary_max": 25000000.0}
]

SEED_CAREER_SKILLS = [
    # UI/UX Designer (1)
    {"career_id": 1, "skill_id": 1, "weight_pct": 40.0, "is_required": True},
    {"career_id": 1, "skill_id": 2, "weight_pct": 25.0, "is_required": True},
    {"career_id": 1, "skill_id": 3, "weight_pct": 20.0, "is_required": True},
    {"career_id": 1, "skill_id": 20, "weight_pct": 10.0, "is_required": False},
    {"career_id": 1, "skill_id": 21, "weight_pct": 5.0, "is_required": False},
    # Junior UI/UX Designer (2)
    {"career_id": 2, "skill_id": 1, "weight_pct": 50.0, "is_required": True},
    {"career_id": 2, "skill_id": 2, "weight_pct": 30.0, "is_required": True},
    {"career_id": 2, "skill_id": 14, "weight_pct": 10.0, "is_required": False},
    {"career_id": 2, "skill_id": 22, "weight_pct": 10.0, "is_required": False},
    # Digital Marketer (3)
    {"career_id": 3, "skill_id": 10, "weight_pct": 30.0, "is_required": True},
    {"career_id": 3, "skill_id": 11, "weight_pct": 20.0, "is_required": True},
    {"career_id": 3, "skill_id": 12, "weight_pct": 20.0, "is_required": True},
    {"career_id": 3, "skill_id": 13, "weight_pct": 20.0, "is_required": True},
    {"career_id": 3, "skill_id": 20, "weight_pct": 10.0, "is_required": False},
    # Digital Marketing Specialist (4)
    {"career_id": 4, "skill_id": 10, "weight_pct": 35.0, "is_required": True},
    {"career_id": 4, "skill_id": 13, "weight_pct": 25.0, "is_required": True},
    {"career_id": 4, "skill_id": 12, "weight_pct": 20.0, "is_required": True},
    {"career_id": 4, "skill_id": 18, "weight_pct": 10.0, "is_required": False},
    {"career_id": 4, "skill_id": 21, "weight_pct": 10.0, "is_required": False},
    # Financial Analyst (5)
    {"career_id": 5, "skill_id": 15, "weight_pct": 35.0, "is_required": True},
    {"career_id": 5, "skill_id": 16, "weight_pct": 25.0, "is_required": True},
    {"career_id": 5, "skill_id": 18, "weight_pct": 20.0, "is_required": True},
    {"career_id": 5, "skill_id": 17, "weight_pct": 10.0, "is_required": True},
    {"career_id": 5, "skill_id": 23, "weight_pct": 10.0, "is_required": False},
    # Software Engineer (Frontend) (6)
    {"career_id": 6, "skill_id": 4, "weight_pct": 30.0, "is_required": True},
    {"career_id": 6, "skill_id": 9, "weight_pct": 45.0, "is_required": True},
    {"career_id": 6, "skill_id": 1, "weight_pct": 10.0, "is_required": False},
    {"career_id": 6, "skill_id": 21, "weight_pct": 10.0, "is_required": False},
    {"career_id": 6, "skill_id": 22, "weight_pct": 5.0, "is_required": False},
    # Data Scientist (7)
    {"career_id": 7, "skill_id": 5, "weight_pct": 30.0, "is_required": True},
    {"career_id": 7, "skill_id": 6, "weight_pct": 20.0, "is_required": True},
    {"career_id": 7, "skill_id": 7, "weight_pct": 20.0, "is_required": True},
    {"career_id": 7, "skill_id": 8, "weight_pct": 20.0, "is_required": True},
    {"career_id": 7, "skill_id": 23, "weight_pct": 10.0, "is_required": False}
]

def get_supabase_client() -> Client:
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_KEY")
    if url and key:
        url = url.strip()
        # Auto-clean trailing PostgREST suffixes often copied from Supabase API configs
        if url.endswith("/rest/v1/"):
            url = url[:-9]
        elif url.endswith("/rest/v1"):
            url = url[:-8]
        url = url.rstrip("/")
        try:
            return create_client(url, key)
        except Exception:
            return None
    return None

def fetch_data() -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """
    Fetches the necessary tables from Supabase. Falls back to local seed data if unavailable.
    """
    client = get_supabase_client()
    if client:
        try:
            edu_res = client.table("education_levels").select("*").execute()
            skills_res = client.table("skills").select("*").execute()
            careers_res = client.table("careers").select("*").execute()
            cs_res = client.table("career_skills").select("*").execute()
            
            df_edu = pd.DataFrame(edu_res.data)
            df_skills = pd.DataFrame(skills_res.data)
            df_careers = pd.DataFrame(careers_res.data)
            df_cs = pd.DataFrame(cs_res.data)
            
            if not (df_edu.empty or df_skills.empty or df_careers.empty or df_cs.empty):
                return df_edu, df_skills, df_careers, df_cs
        except Exception as e:
            print(f"Failed to fetch data from Supabase: {e}. Falling back to seed data.")
            
    # Fallback to local seed data
    return (
        pd.DataFrame(SEED_EDUCATION_LEVELS),
        pd.DataFrame(SEED_SKILLS),
        pd.DataFrame(SEED_CAREERS),
        pd.DataFrame(SEED_CAREER_SKILLS)
    )

def map_user_skills(user_input_skills: List[str], df_skills: pd.DataFrame) -> List[int]:
    """
    Map user input skills (strings) to skill IDs in the database using case-insensitive matches,
    substring matches, and word-level prefix matching (e.g. "wireframe" matching "Wireframing").
    """
    mapped_ids = []
    all_skills_normalized = {row['skill_name'].lower().strip(): row['id'] for _, row in df_skills.iterrows()}
    
    for input_skill in user_input_skills:
        clean_input = input_skill.lower().strip()
        # Direct exact match
        if clean_input in all_skills_normalized:
            mapped_ids.append(all_skills_normalized[clean_input])
            continue
            
        # Try substring match
        found = False
        for skill_name_norm, skill_id in all_skills_normalized.items():
            if clean_input in skill_name_norm or skill_name_norm in clean_input:
                mapped_ids.append(skill_id)
                found = True
                break
        if found:
            continue
            
        # Try word-level prefix matching
        input_words = [w for w in clean_input.replace("&", " ").replace("/", " ").replace("-", " ").split() if len(w) > 2]
        for skill_name_norm, skill_id in all_skills_normalized.items():
            skill_words = skill_name_norm.replace("&", " ").replace("/", " ").replace("-", " ").split()
            for iw in input_words:
                for sw in skill_words:
                    if sw.startswith(iw) or iw.startswith(sw[:max(3, len(sw)-3)]):
                        mapped_ids.append(skill_id)
                        found = True
                        break
                if found:
                    break
            if found:
                break
    return list(set(mapped_ids))

def map_user_education_rank(user_edu_str: str, df_edu: pd.DataFrame) -> int:
    """
    Map user's education string to its rank, defaulting to Rank 3 (Bachelor's S1) if not clear.
    """
    if not user_edu_str:
        return 3
    
    clean_edu = user_edu_str.lower().strip()
    
    # Try direct mapping
    for _, row in df_edu.iterrows():
        lvl_name = row['level_name'].lower()
        if clean_edu in lvl_name or lvl_name in clean_edu:
            return int(row['order_rank'])
            
    # Common short names mapping
    short_names = {
        "sma": 1, "smk": 1, "high school": 1,
        "d3": 2, "diploma": 2, "associate": 2,
        "s1": 3, "bachelor": 3, "sarjana": 3,
        "s2": 4, "master": 4, "magister": 4,
        "s3": 5, "doctor": 5, "phd": 5
    }
    
    for key, val in short_names.items():
        if key in clean_edu:
            return val
            
    return 3

def run_hybrid_engine(
    user_skills: List[str],
    user_education: str,
    user_min_salary: float,
    user_city: str = None
) -> List[Dict[str, Any]]:
    """
    Runs the Knowledge-Based and Content-Based filtering algorithms.
    
    1. KBF: Hard-filters careers based on user's education rank and min salary target.
    2. CBF: Vectorizes career profiles and user profile to compute Cosine Similarity.
    3. Gap Analysis: For the top matches, returns missing required skills.
    """
    df_edu, df_skills, df_careers, df_cs = fetch_data()
    
    # Map user inputs
    mapped_skill_ids = map_user_skills(user_skills, df_skills)
    user_edu_rank = map_user_education_rank(user_education, df_edu)
    
    # 1. Knowledge-Based Filtering (KBF)
    # Join careers with min education rank for filtering
    df_careers_joined = df_careers.merge(df_edu, left_on='min_education_id', right_on='id', suffixes=('', '_edu'))
    
    # Filter: Min education order_rank <= user education rank
    kbf_mask = df_careers_joined['order_rank'] <= user_edu_rank
    
    # Filter: Career salary_max >= user_min_salary
    kbf_mask = kbf_mask & (df_careers_joined['salary_max'] >= user_min_salary)
    
    # Filter: Optional City Filter (case-insensitive)
    if user_city:
        city_mask = df_careers_joined['target_city'].str.lower().str.strip() == user_city.lower().strip()
        # If we have matches after applying city filter, apply it. Otherwise, ignore it to prevent empty results.
        if (kbf_mask & city_mask).any():
            kbf_mask = kbf_mask & city_mask

    filtered_careers = df_careers_joined[kbf_mask]
    
    if filtered_careers.empty:
        return []
        
    # 2. Content-Based Filtering (CBF) using Cosine Similarity
    # Build pivot table of career skills
    # Pivot rows: career_id, columns: skill_id, values: weight_pct
    all_skill_ids = df_skills['id'].tolist()
    
    # Pivot the career skills. Fill missing skills with 0.0
    pivot_cs = df_cs.pivot(index='career_id', columns='skill_id', values='weight_pct').fillna(0.0)
    
    # Ensure all skills exist as columns in the pivot dataframe
    for skill_id in all_skill_ids:
        if skill_id not in pivot_cs.columns:
            pivot_cs[skill_id] = 0.0
            
    # Keep only columns for skills in the database
    pivot_cs = pivot_cs[all_skill_ids]
    
    # Filter pivot table for only KBF-passed careers
    kbf_career_ids = filtered_careers['id'].tolist()
    pivot_cs_filtered = pivot_cs.loc[pivot_cs.index.isin(kbf_career_ids)]
    
    if pivot_cs_filtered.empty:
        return []
        
    # Build User Profile vector (1 if user has skill, 0 otherwise)
    user_vector = np.zeros((1, len(all_skill_ids)))
    for skill_id in mapped_skill_ids:
        if skill_id in all_skill_ids:
            idx = all_skill_ids.index(skill_id)
            user_vector[0, idx] = 1.0
            
    # Compute Cosine Similarity between user vector and each career vector
    career_matrices = pivot_cs_filtered.to_numpy()
    similarities = cosine_similarity(user_vector, career_matrices)[0]
    
    # Map similarities back to career IDs
    career_scores = {pivot_cs_filtered.index[i]: float(similarities[i]) for i in range(len(similarities))}
    
    # Add similarity score to filtered careers
    filtered_careers = filtered_careers.copy()
    filtered_careers['match_score'] = filtered_careers['id'].map(career_scores)
    
    # Sort careers by score descending
    ranked_careers = filtered_careers.sort_values(by='match_score', ascending=False)
    
    # 3. Gap Analysis
    results = []
    for _, career_row in ranked_careers.iterrows():
        c_id = int(career_row['id'])
        c_name = career_row['career_name']
        c_desc = career_row['career_description']
        c_city = career_row['target_city']
        c_sal_min = float(career_row['salary_min'])
        c_sal_max = float(career_row['salary_max'])
        score = float(career_row['match_score'])
        
        # Get required and optional skills for this career
        career_skills_subset = df_cs[df_cs['career_id'] == c_id]
        
        # Merge with skill names
        career_skills_detailed = career_skills_subset.merge(df_skills, left_on='skill_id', right_on='id')
        
        required_skills = []
        missing_required = []
        acquired_required = []
        
        for _, skill_row in career_skills_detailed.iterrows():
            s_id = int(skill_row['skill_id'])
            s_name = skill_row['skill_name']
            s_req = bool(skill_row['is_required'])
            s_weight = float(skill_row['weight_pct'])
            
            if s_req:
                required_skills.append({"name": s_name, "weight": s_weight})
                if s_id not in mapped_skill_ids:
                    missing_required.append({"name": s_name, "weight": s_weight})
                else:
                    acquired_required.append({"name": s_name, "weight": s_weight})
                    
        results.append({
            "career_id": c_id,
            "career_name": c_name,
            "description": c_desc,
            "target_city": c_city,
            "salary_min": c_sal_min,
            "salary_max": c_sal_max,
            "match_score": round(score * 100, 2), # percentage
            "skills": {
                "required": required_skills,
                "missing": missing_required,
                "acquired": acquired_required
            }
        })
        
    return results[:3] # Return top 3 matched careers
