import os
from dotenv import load_dotenv
load_dotenv()

import pandas as pd
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from typing import List, Dict, Any, Tuple
from supabase import create_client, Client

# ─────────────────────────────────────────────────────────────────────────────
# LOCAL SEED DATA  (fallback when Supabase is unreachable)
# Generated from: knowledge_base_profesi_IT.xlsx (LinkedIn scraping 2025)
# This mirrors exactly the rows inserted via migration_linkedin_kb.sql
# ─────────────────────────────────────────────────────────────────────────────

SEED_EDUCATION_LEVELS = [
    {"id": 1, "level_name": "SMA/MA/SMK",           "order_rank": 1},
    {"id": 2, "level_name": "Diploma 1/2 (D1/D2)",  "order_rank": 2},
    {"id": 3, "level_name": "Diploma 3 (D3)",        "order_rank": 3},
    {"id": 4, "level_name": "Sarjana / D4 (S1/D4)", "order_rank": 4},
    {"id": 5, "level_name": "Magister (S2)",         "order_rank": 5},
    {"id": 6, "level_name": "Doktor (S3)",           "order_rank": 6},
]

# Skills (id = row order in the SQL INSERT, matching the migration script)
SEED_SKILLS = [
    {"id": 1,  "skill_name": "Python",                                   "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 2,  "skill_name": "JavaScript",                               "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 3,  "skill_name": "TypeScript",                               "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 4,  "skill_name": "Java",                                     "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 5,  "skill_name": "Kotlin",                                   "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 6,  "skill_name": "Swift",                                    "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 7,  "skill_name": "C#",                                       "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 8,  "skill_name": "C/C++",                                    "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 9,  "skill_name": "Go (Golang)",                              "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 10, "skill_name": "PHP",                                      "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 11, "skill_name": "Dart",                                     "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 12, "skill_name": "R",                                        "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 13, "skill_name": "Scala",                                    "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 14, "skill_name": "Rust",                                     "category": "Programming Language", "skill_type": "hard_skill"},
    {"id": 15, "skill_name": "SQL",                                      "category": "Database",             "skill_type": "hard_skill"},
    {"id": 16, "skill_name": "React.js",                                 "category": "Frontend Framework",  "skill_type": "hard_skill"},
    {"id": 17, "skill_name": "Vue.js",                                   "category": "Frontend Framework",  "skill_type": "hard_skill"},
    {"id": 18, "skill_name": "Angular",                                  "category": "Frontend Framework",  "skill_type": "hard_skill"},
    {"id": 19, "skill_name": "Next.js",                                  "category": "Frontend Framework",  "skill_type": "hard_skill"},
    {"id": 20, "skill_name": "Nuxt.js",                                  "category": "Frontend Framework",  "skill_type": "hard_skill"},
    {"id": 21, "skill_name": "HTML/CSS",                                 "category": "Frontend",             "skill_type": "hard_skill"},
    {"id": 22, "skill_name": "Tailwind CSS",                             "category": "Frontend",             "skill_type": "hard_skill"},
    {"id": 23, "skill_name": "Bootstrap",                                "category": "Frontend",             "skill_type": "hard_skill"},
    {"id": 24, "skill_name": "Node.js",                                  "category": "Backend Framework",   "skill_type": "hard_skill"},
    {"id": 25, "skill_name": "Laravel",                                  "category": "Backend Framework",   "skill_type": "hard_skill"},
    {"id": 26, "skill_name": "Django",                                   "category": "Backend Framework",   "skill_type": "hard_skill"},
    {"id": 27, "skill_name": "FastAPI",                                  "category": "Backend Framework",   "skill_type": "hard_skill"},
    {"id": 28, "skill_name": "Spring Boot",                              "category": "Backend Framework",   "skill_type": "hard_skill"},
    {"id": 29, "skill_name": "Express.js",                               "category": "Backend Framework",   "skill_type": "hard_skill"},
    {"id": 30, "skill_name": "NestJS",                                   "category": "Backend Framework",   "skill_type": "hard_skill"},
    {"id": 31, "skill_name": "PostgreSQL",                               "category": "Database",             "skill_type": "hard_skill"},
    {"id": 32, "skill_name": "MySQL",                                    "category": "Database",             "skill_type": "hard_skill"},
    {"id": 33, "skill_name": "MongoDB",                                  "category": "Database",             "skill_type": "hard_skill"},
    {"id": 34, "skill_name": "Redis",                                    "category": "Database",             "skill_type": "hard_skill"},
    {"id": 35, "skill_name": "Firebase",                                 "category": "Database",             "skill_type": "hard_skill"},
    {"id": 36, "skill_name": "BigQuery",                                 "category": "Database",             "skill_type": "hard_skill"},
    {"id": 37, "skill_name": "Snowflake",                                "category": "Database",             "skill_type": "hard_skill"},
    {"id": 38, "skill_name": "Elasticsearch",                            "category": "Database",             "skill_type": "hard_skill"},
    {"id": 39, "skill_name": "AWS",                                      "category": "Cloud Platform",       "skill_type": "hard_skill"},
    {"id": 40, "skill_name": "Google Cloud Platform (GCP)",              "category": "Cloud Platform",       "skill_type": "hard_skill"},
    {"id": 41, "skill_name": "Microsoft Azure",                          "category": "Cloud Platform",       "skill_type": "hard_skill"},
    {"id": 42, "skill_name": "Docker",                                   "category": "DevOps",               "skill_type": "hard_skill"},
    {"id": 43, "skill_name": "Kubernetes (K8s)",                        "category": "DevOps",               "skill_type": "hard_skill"},
    {"id": 44, "skill_name": "Terraform",                                "category": "DevOps",               "skill_type": "hard_skill"},
    {"id": 45, "skill_name": "CI/CD (Jenkins, GitHub Actions, GitLab CI)", "category": "DevOps",           "skill_type": "hard_skill"},
    {"id": 46, "skill_name": "Linux / Unix Administration",              "category": "Infrastructure",       "skill_type": "hard_skill"},
    {"id": 47, "skill_name": "Nginx / Apache",                          "category": "Infrastructure",       "skill_type": "hard_skill"},
    {"id": 48, "skill_name": "Apache Airflow",                           "category": "Data Engineering",    "skill_type": "hard_skill"},
    {"id": 49, "skill_name": "Apache Spark",                             "category": "Data Engineering",    "skill_type": "hard_skill"},
    {"id": 50, "skill_name": "Apache Kafka",                             "category": "Data Engineering",    "skill_type": "hard_skill"},
    {"id": 51, "skill_name": "dbt (Data Build Tool)",                   "category": "Data Engineering",    "skill_type": "hard_skill"},
    {"id": 52, "skill_name": "ETL/ELT Processes",                       "category": "Data Engineering",    "skill_type": "hard_skill"},
    {"id": 53, "skill_name": "Data Warehousing Concepts",               "category": "Data Engineering",    "skill_type": "hard_skill"},
    {"id": 54, "skill_name": "Tableau",                                  "category": "Data Visualization",  "skill_type": "hard_skill"},
    {"id": 55, "skill_name": "Power BI",                                 "category": "Data Visualization",  "skill_type": "hard_skill"},
    {"id": 56, "skill_name": "Looker / Looker Studio",                  "category": "Data Visualization",  "skill_type": "hard_skill"},
    {"id": 57, "skill_name": "Metabase",                                 "category": "Data Visualization",  "skill_type": "hard_skill"},
    {"id": 58, "skill_name": "Pandas",                                   "category": "Data Science Library","skill_type": "hard_skill"},
    {"id": 59, "skill_name": "NumPy",                                    "category": "Data Science Library","skill_type": "hard_skill"},
    {"id": 60, "skill_name": "Scikit-learn",                             "category": "Data Science Library","skill_type": "hard_skill"},
    {"id": 61, "skill_name": "TensorFlow",                               "category": "ML Framework",        "skill_type": "hard_skill"},
    {"id": 62, "skill_name": "PyTorch",                                  "category": "ML Framework",        "skill_type": "hard_skill"},
    {"id": 63, "skill_name": "Hugging Face",                             "category": "ML Framework",        "skill_type": "hard_skill"},
    {"id": 64, "skill_name": "LangChain",                                "category": "AI Framework",        "skill_type": "hard_skill"},
    {"id": 65, "skill_name": "OpenAI API",                               "category": "AI Framework",        "skill_type": "hard_skill"},
    {"id": 66, "skill_name": "NVIDIA CUDA / GPU Computing",              "category": "ML Infrastructure",   "skill_type": "hard_skill"},
    {"id": 67, "skill_name": "Computer Vision (OpenCV)",                 "category": "ML Specialization",   "skill_type": "hard_skill"},
    {"id": 68, "skill_name": "RAG (Retrieval-Augmented Generation)",     "category": "AI Technique",        "skill_type": "hard_skill"},
    {"id": 69, "skill_name": "Vector Database (Pinecone, Weaviate)",    "category": "AI Infrastructure",   "skill_type": "hard_skill"},
    {"id": 70, "skill_name": "Git",                                      "category": "Version Control",     "skill_type": "hard_skill"},
    {"id": 71, "skill_name": "GitHub / GitLab",                         "category": "Version Control",     "skill_type": "hard_skill"},
    {"id": 72, "skill_name": "Network Security",                         "category": "Cybersecurity",       "skill_type": "hard_skill"},
    {"id": 73, "skill_name": "Web Application Security (OWASP)",        "category": "Cybersecurity",       "skill_type": "hard_skill"},
    {"id": 74, "skill_name": "Penetration Testing",                      "category": "Cybersecurity",       "skill_type": "hard_skill"},
    {"id": 75, "skill_name": "SIEM Tools",                               "category": "Cybersecurity",       "skill_type": "hard_skill"},
    {"id": 76, "skill_name": "Cryptography & PKI",                      "category": "Cybersecurity",       "skill_type": "hard_skill"},
    {"id": 77, "skill_name": "Figma",                                    "category": "Design Tool",         "skill_type": "hard_skill"},
    {"id": 78, "skill_name": "Adobe XD / Photoshop / Illustrator",      "category": "Design Tool",         "skill_type": "hard_skill"},
    {"id": 79, "skill_name": "Agile / Scrum",                           "category": "Methodology",         "skill_type": "hard_skill"},
    {"id": 80, "skill_name": "REST API Design",                          "category": "Backend",             "skill_type": "hard_skill"},
    {"id": 81, "skill_name": "GraphQL",                                  "category": "Backend",             "skill_type": "hard_skill"},
    {"id": 82, "skill_name": "Microservices Architecture",               "category": "Architecture",        "skill_type": "hard_skill"},
    {"id": 83, "skill_name": "System Design",                            "category": "Architecture",        "skill_type": "hard_skill"},
    {"id": 84, "skill_name": "Power Query",                              "category": "Data Tool",           "skill_type": "hard_skill"},
    {"id": 85, "skill_name": "Microsoft Excel (Advanced)",               "category": "Data Tool",           "skill_type": "hard_skill"},
    {"id": 86, "skill_name": "IBM DataStage",                            "category": "Data Engineering",    "skill_type": "hard_skill"},
    {"id": 87, "skill_name": "Apache Hadoop",                            "category": "Data Engineering",    "skill_type": "hard_skill"},
    {"id": 88, "skill_name": "A/B Testing",                             "category": "Analytics",           "skill_type": "hard_skill"},
    {"id": 89, "skill_name": "Problem Solving",                          "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 90, "skill_name": "Communication",                            "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 91, "skill_name": "Teamwork & Collaboration",                "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 92, "skill_name": "Analytical Thinking",                      "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 93, "skill_name": "Adaptability",                             "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 94, "skill_name": "Time Management",                          "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 95, "skill_name": "Critical Thinking",                        "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 96, "skill_name": "Leadership",                               "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 97, "skill_name": "Creativity & Innovation",                 "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 98, "skill_name": "Attention to Detail",                     "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 99, "skill_name": "English Proficiency",                      "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 100,"skill_name": "Project Management",                       "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 101,"skill_name": "Stakeholder Management",                   "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 102,"skill_name": "Self-Learning",                            "category": "Soft Skill",          "skill_type": "soft_skill"},
    {"id": 103,"skill_name": "Data Storytelling",                        "category": "Soft Skill",          "skill_type": "soft_skill"},
]

# Careers — id = row order (1-based) matching SQL migration
SEED_CAREERS = [
    {"id": 1,  "career_name": "Frontend Developer",                    "career_description": "Mengembangkan tampilan dan interaksi antarmuka pengguna berbasis web.",                                   "min_education_rank": 3, "location_bias": "Jakarta, Surabaya, Bandung",        "salary_min": 5000000.0,  "salary_max": 12000000.0},
    {"id": 2,  "career_name": "Backend Developer",                     "career_description": "Merancang dan membangun logika bisnis, API, serta manajemen database sisi server.",                       "min_education_rank": 3, "location_bias": "Jakarta, Surabaya, Bandung",        "salary_min": 6000000.0,  "salary_max": 15000000.0},
    {"id": 3,  "career_name": "Fullstack Developer",                   "career_description": "Menangani pengembangan sisi frontend dan backend secara menyeluruh dalam satu proyek.",                  "min_education_rank": 4, "location_bias": "Jakarta, Surabaya, Bandung",        "salary_min": 8000000.0,  "salary_max": 18000000.0},
    {"id": 4,  "career_name": "Mobile Developer (Android)",            "career_description": "Mengembangkan aplikasi native Android menggunakan Kotlin atau Java.",                                    "min_education_rank": 3, "location_bias": "Jakarta, Bandung",                  "salary_min": 5500000.0,  "salary_max": 13000000.0},
    {"id": 5,  "career_name": "Mobile Developer (iOS)",               "career_description": "Mengembangkan aplikasi native iOS menggunakan Swift atau Objective-C.",                                  "min_education_rank": 4, "location_bias": "Jakarta, Bali",                     "salary_min": 6000000.0,  "salary_max": 15000000.0},
    {"id": 6,  "career_name": "Mobile Developer (Flutter/React Native)","career_description": "Membangun aplikasi mobile cross-platform menggunakan Flutter atau React Native.",                      "min_education_rank": 3, "location_bias": "Jakarta, Surabaya, Bandung",        "salary_min": 6000000.0,  "salary_max": 15000000.0},
    {"id": 7,  "career_name": "Data Analyst",                          "career_description": "Menganalisis data bisnis untuk menghasilkan insight, laporan, dan visualisasi data yang mendukung pengambilan keputusan.", "min_education_rank": 3, "location_bias": "Jakarta, Surabaya, Bandung", "salary_min": 5000000.0, "salary_max": 15000000.0},
    {"id": 8,  "career_name": "Business Intelligence Developer",       "career_description": "Membangun pipeline data, dashboard BI, dan sistem pelaporan untuk keperluan analitik bisnis.",          "min_education_rank": 4, "location_bias": "Jakarta, Surabaya",                 "salary_min": 7000000.0,  "salary_max": 15000000.0},
    {"id": 9,  "career_name": "Data Engineer",                         "career_description": "Membangun dan mengelola pipeline data, data lake, dan infrastruktur pemrosesan data skala besar.",       "min_education_rank": 4, "location_bias": "Jakarta, Surabaya, Bandung",        "salary_min": 9000000.0,  "salary_max": 20000000.0},
    {"id": 10, "career_name": "Data Scientist",                        "career_description": "Membangun model prediksi statistik dan machine learning untuk mendukung keputusan bisnis berbasis data.", "min_education_rank": 4, "location_bias": "Jakarta, Bandung",                  "salary_min": 10000000.0, "salary_max": 25000000.0},
    {"id": 11, "career_name": "Machine Learning Engineer",             "career_description": "Merancang, melatih, dan men-deploy model machine learning ke lingkungan produksi.",                       "min_education_rank": 4, "location_bias": "Jakarta, Bandung",                  "salary_min": 12000000.0, "salary_max": 28000000.0},
    {"id": 12, "career_name": "AI Engineer",                           "career_description": "Mengembangkan sistem kecerdasan buatan dan solusi berbasis LLM/Generative AI untuk aplikasi produksi.",  "min_education_rank": 4, "location_bias": "Jakarta",                           "salary_min": 12000000.0, "salary_max": 30000000.0},
    {"id": 13, "career_name": "Computer Vision Engineer",              "career_description": "Membangun sistem pengenalan gambar/video menggunakan deep learning untuk berbagai aplikasi industri.",   "min_education_rank": 4, "location_bias": "Jakarta, Surabaya",                 "salary_min": 12000000.0, "salary_max": 25000000.0},
    {"id": 14, "career_name": "NLP Engineer",                          "career_description": "Mengembangkan sistem pemrosesan bahasa alami (NLP) untuk chatbot, analisis sentimen, dan text mining.",  "min_education_rank": 4, "location_bias": "Jakarta, Bandung",                  "salary_min": 11000000.0, "salary_max": 25000000.0},
    {"id": 15, "career_name": "DevOps Engineer",                       "career_description": "Merancang dan mengelola pipeline CI/CD, mengotomatiskan infrastruktur dengan Docker & Kubernetes, serta memastikan keandalan sistem produksi.", "min_education_rank": 3, "location_bias": "Jakarta, Surabaya, Bandung", "salary_min": 7000000.0, "salary_max": 18000000.0},
    {"id": 16, "career_name": "Cloud Engineer",                        "career_description": "Merancang dan mengelola infrastruktur cloud di AWS, GCP, atau Azure untuk mendukung aplikasi berskala tinggi.", "min_education_rank": 4, "location_bias": "Jakarta, Surabaya",             "salary_min": 9000000.0,  "salary_max": 20000000.0},
    {"id": 17, "career_name": "Site Reliability Engineer (SRE)",       "career_description": "Memastikan keandalan, performa, dan skalabilitas layanan produksi melalui otomatisasi dan manajemen insiden.", "min_education_rank": 4, "location_bias": "Jakarta",                       "salary_min": 15000000.0, "salary_max": 30000000.0},
    {"id": 18, "career_name": "Cybersecurity Analyst",                 "career_description": "Melindungi aset digital organisasi dari ancaman siber melalui pemantauan keamanan dan analisis kerentanan.", "min_education_rank": 3, "location_bias": "Jakarta, Surabaya",               "salary_min": 6000000.0,  "salary_max": 15000000.0},
    {"id": 19, "career_name": "Penetration Tester",                    "career_description": "Melakukan simulasi serangan siber (ethical hacking) untuk menemukan dan melaporkan celah keamanan sistem.", "min_education_rank": 4, "location_bias": "Jakarta, Bandung",                 "salary_min": 8000000.0,  "salary_max": 20000000.0},
    {"id": 20, "career_name": "UI/UX Designer",                        "career_description": "Merancang antarmuka pengguna yang intuitif dan pengalaman pengguna yang memuaskan untuk produk digital.",  "min_education_rank": 3, "location_bias": "Jakarta, Bandung, Bali, Yogyakarta", "salary_min": 4500000.0,  "salary_max": 12000000.0},
    {"id": 21, "career_name": "Product Manager",                       "career_description": "Mengelola siklus hidup produk digital dari ideasi hingga peluncuran, berkoordinasi antara tim teknis dan bisnis.", "min_education_rank": 4, "location_bias": "Jakarta",                      "salary_min": 12000000.0, "salary_max": 30000000.0},
    {"id": 22, "career_name": "QA Engineer / Software Tester",         "career_description": "Memastikan kualitas perangkat lunak melalui pengujian manual dan otomatis.",                              "min_education_rank": 3, "location_bias": "Jakarta, Surabaya",                 "salary_min": 5000000.0,  "salary_max": 12000000.0},
    {"id": 23, "career_name": "IT Project Manager",                    "career_description": "Merencanakan, mengelola, dan memastikan keberhasilan proyek IT dalam batasan waktu, biaya, dan kualitas.", "min_education_rank": 4, "location_bias": "Jakarta, Surabaya",                 "salary_min": 15000000.0, "salary_max": 35000000.0},
    {"id": 24, "career_name": "IT Support / Helpdesk",                 "career_description": "Memberikan dukungan teknis kepada pengguna akhir, troubleshooting perangkat keras dan lunak.",            "min_education_rank": 1, "location_bias": "Semua kota besar Indonesia",        "salary_min": 3500000.0,  "salary_max": 7000000.0},
    {"id": 25, "career_name": "System Administrator",                  "career_description": "Mengelola, mengkonfigurasi, dan memelihara server serta infrastruktur jaringan organisasi.",              "min_education_rank": 3, "location_bias": "Jakarta, Surabaya, Bandung",        "salary_min": 5000000.0,  "salary_max": 12000000.0},
    {"id": 26, "career_name": "Network Engineer",                      "career_description": "Merancang, mengimplementasikan, dan memelihara infrastruktur jaringan komputer organisasi.",              "min_education_rank": 3, "location_bias": "Jakarta, Surabaya, Bandung",        "salary_min": 6000000.0,  "salary_max": 14000000.0},
    {"id": 27, "career_name": "Database Administrator",                "career_description": "Mengelola, mengoptimalkan, dan mengamankan sistem database relasional dan non-relasional.",               "min_education_rank": 3, "location_bias": "Jakarta, Surabaya",                 "salary_min": 6000000.0,  "salary_max": 15000000.0},
    {"id": 28, "career_name": "Scrum Master / Agile Coach",            "career_description": "Memfasilitasi proses Agile/Scrum, membantu tim pengembang bekerja lebih efektif dan kolaboratif.",       "min_education_rank": 4, "location_bias": "Jakarta",                           "salary_min": 10000000.0, "salary_max": 22000000.0},
    {"id": 29, "career_name": "Digital Marketing Analyst",             "career_description": "Menganalisis performa kampanye digital, SEO/SEM, serta strategi pemasaran online berbasis data.",         "min_education_rank": 3, "location_bias": "Jakarta, Surabaya, Bali",           "salary_min": 4500000.0,  "salary_max": 10000000.0},
    {"id": 30, "career_name": "Game Developer",                        "career_description": "Merancang dan mengembangkan game untuk platform mobile, PC, atau konsol.",                                "min_education_rank": 3, "location_bias": "Jakarta, Bandung, Yogyakarta",      "salary_min": 5000000.0,  "salary_max": 15000000.0},
    {"id": 31, "career_name": "IT Business Analyst",                   "career_description": "Menjembatani kebutuhan bisnis dan solusi teknologi melalui analisis proses dan spesifikasi kebutuhan sistem.", "min_education_rank": 4, "location_bias": "Jakarta, Surabaya",              "salary_min": 7000000.0,  "salary_max": 16000000.0},
    {"id": 32, "career_name": "ERP Consultant / Developer",            "career_description": "Mengimplementasikan dan mengkustomisasi sistem ERP (SAP, Oracle, Odoo) sesuai kebutuhan bisnis.",          "min_education_rank": 4, "location_bias": "Jakarta, Surabaya",                 "salary_min": 10000000.0, "salary_max": 25000000.0},
    {"id": 33, "career_name": "Blockchain Developer",                  "career_description": "Mengembangkan aplikasi terdesentralisasi (dApps) dan smart contract di atas platform blockchain.",        "min_education_rank": 4, "location_bias": "Jakarta",                           "salary_min": 12000000.0, "salary_max": 30000000.0},
    {"id": 34, "career_name": "IoT Engineer",                          "career_description": "Merancang dan mengembangkan sistem Internet of Things, mulai dari perangkat keras hingga software backend.", "min_education_rank": 3, "location_bias": "Surabaya, Jakarta, Bandung",       "salary_min": 7000000.0,  "salary_max": 16000000.0},
    {"id": 35, "career_name": "Technical Writer",                      "career_description": "Membuat dokumentasi teknis yang jelas, akurat, dan mudah dipahami untuk produk atau API.",               "min_education_rank": 3, "location_bias": "Jakarta, Remote",                  "salary_min": 4000000.0,  "salary_max": 9000000.0},
]

# career_skills — matching the SQL migration row-order exactly
SEED_CAREER_SKILLS = [
    # Frontend Developer (1)
    {"career_id":1,"skill_id":16,"weight_pct":15.0,"is_required":True},
    {"career_id":1,"skill_id":17,"weight_pct":8.0,"is_required":False},
    {"career_id":1,"skill_id":19,"weight_pct":8.0,"is_required":False},
    {"career_id":1,"skill_id":2,"weight_pct":12.0,"is_required":True},
    {"career_id":1,"skill_id":3,"weight_pct":8.0,"is_required":False},
    {"career_id":1,"skill_id":21,"weight_pct":10.0,"is_required":True},
    {"career_id":1,"skill_id":22,"weight_pct":5.0,"is_required":False},
    {"career_id":1,"skill_id":80,"weight_pct":10.0,"is_required":True},
    {"career_id":1,"skill_id":70,"weight_pct":8.0,"is_required":True},
    {"career_id":1,"skill_id":77,"weight_pct":5.0,"is_required":False},
    # Backend Developer (2)
    {"career_id":2,"skill_id":1,"weight_pct":15.0,"is_required":True},
    {"career_id":2,"skill_id":24,"weight_pct":12.0,"is_required":True},
    {"career_id":2,"skill_id":26,"weight_pct":10.0,"is_required":False},
    {"career_id":2,"skill_id":27,"weight_pct":8.0,"is_required":False},
    {"career_id":2,"skill_id":15,"weight_pct":12.0,"is_required":True},
    {"career_id":2,"skill_id":80,"weight_pct":12.0,"is_required":True},
    {"career_id":2,"skill_id":31,"weight_pct":8.0,"is_required":False},
    {"career_id":2,"skill_id":42,"weight_pct":8.0,"is_required":False},
    {"career_id":2,"skill_id":70,"weight_pct":8.0,"is_required":True},
    {"career_id":2,"skill_id":82,"weight_pct":7.0,"is_required":False},
    # Fullstack Developer (3)
    {"career_id":3,"skill_id":2,"weight_pct":12.0,"is_required":True},
    {"career_id":3,"skill_id":1,"weight_pct":12.0,"is_required":True},
    {"career_id":3,"skill_id":16,"weight_pct":10.0,"is_required":True},
    {"career_id":3,"skill_id":24,"weight_pct":10.0,"is_required":True},
    {"career_id":3,"skill_id":15,"weight_pct":10.0,"is_required":True},
    {"career_id":3,"skill_id":42,"weight_pct":8.0,"is_required":False},
    {"career_id":3,"skill_id":80,"weight_pct":8.0,"is_required":True},
    {"career_id":3,"skill_id":70,"weight_pct":5.0,"is_required":True},
    # Mobile Developer Android (4)
    {"career_id":4,"skill_id":5,"weight_pct":40.0,"is_required":True},
    {"career_id":4,"skill_id":4,"weight_pct":20.0,"is_required":True},
    {"career_id":4,"skill_id":80,"weight_pct":15.0,"is_required":True},
    {"career_id":4,"skill_id":70,"weight_pct":10.0,"is_required":True},
    {"career_id":4,"skill_id":35,"weight_pct":15.0,"is_required":False},
    # Mobile Developer iOS (5)
    {"career_id":5,"skill_id":6,"weight_pct":45.0,"is_required":True},
    {"career_id":5,"skill_id":80,"weight_pct":15.0,"is_required":True},
    {"career_id":5,"skill_id":70,"weight_pct":10.0,"is_required":True},
    {"career_id":5,"skill_id":35,"weight_pct":15.0,"is_required":False},
    {"career_id":5,"skill_id":83,"weight_pct":15.0,"is_required":False},
    # Mobile Developer Flutter (6)
    {"career_id":6,"skill_id":11,"weight_pct":35.0,"is_required":True},
    {"career_id":6,"skill_id":80,"weight_pct":12.0,"is_required":True},
    {"career_id":6,"skill_id":70,"weight_pct":10.0,"is_required":True},
    {"career_id":6,"skill_id":35,"weight_pct":12.0,"is_required":False},
    # Data Analyst (7)
    {"career_id":7,"skill_id":1,"weight_pct":20.0,"is_required":True},
    {"career_id":7,"skill_id":15,"weight_pct":20.0,"is_required":True},
    {"career_id":7,"skill_id":55,"weight_pct":15.0,"is_required":True},
    {"career_id":7,"skill_id":54,"weight_pct":10.0,"is_required":False},
    {"career_id":7,"skill_id":85,"weight_pct":10.0,"is_required":True},
    {"career_id":7,"skill_id":92,"weight_pct":10.0,"is_required":False},
    {"career_id":7,"skill_id":103,"weight_pct":10.0,"is_required":False},
    {"career_id":7,"skill_id":58,"weight_pct":5.0,"is_required":False},
    # BI Developer (8)
    {"career_id":8,"skill_id":15,"weight_pct":20.0,"is_required":True},
    {"career_id":8,"skill_id":55,"weight_pct":25.0,"is_required":True},
    {"career_id":8,"skill_id":54,"weight_pct":15.0,"is_required":True},
    {"career_id":8,"skill_id":36,"weight_pct":15.0,"is_required":False},
    {"career_id":8,"skill_id":84,"weight_pct":10.0,"is_required":False},
    {"career_id":8,"skill_id":92,"weight_pct":10.0,"is_required":False},
    {"career_id":8,"skill_id":103,"weight_pct":5.0,"is_required":False},
    # Data Engineer (9)
    {"career_id":9,"skill_id":1,"weight_pct":20.0,"is_required":True},
    {"career_id":9,"skill_id":15,"weight_pct":15.0,"is_required":True},
    {"career_id":9,"skill_id":49,"weight_pct":15.0,"is_required":True},
    {"career_id":9,"skill_id":48,"weight_pct":10.0,"is_required":True},
    {"career_id":9,"skill_id":50,"weight_pct":10.0,"is_required":False},
    {"career_id":9,"skill_id":53,"weight_pct":10.0,"is_required":True},
    {"career_id":9,"skill_id":42,"weight_pct":10.0,"is_required":False},
    {"career_id":9,"skill_id":51,"weight_pct":10.0,"is_required":False},
    # Data Scientist (10)
    {"career_id":10,"skill_id":1,"weight_pct":20.0,"is_required":True},
    {"career_id":10,"skill_id":15,"weight_pct":15.0,"is_required":True},
    {"career_id":10,"skill_id":58,"weight_pct":10.0,"is_required":True},
    {"career_id":10,"skill_id":60,"weight_pct":15.0,"is_required":True},
    {"career_id":10,"skill_id":59,"weight_pct":10.0,"is_required":False},
    {"career_id":10,"skill_id":92,"weight_pct":15.0,"is_required":True},
    {"career_id":10,"skill_id":103,"weight_pct":10.0,"is_required":False},
    {"career_id":10,"skill_id":61,"weight_pct":5.0,"is_required":False},
    # ML Engineer (11)
    {"career_id":11,"skill_id":1,"weight_pct":20.0,"is_required":True},
    {"career_id":11,"skill_id":61,"weight_pct":15.0,"is_required":True},
    {"career_id":11,"skill_id":62,"weight_pct":15.0,"is_required":True},
    {"career_id":11,"skill_id":60,"weight_pct":15.0,"is_required":True},
    {"career_id":11,"skill_id":42,"weight_pct":10.0,"is_required":False},
    {"career_id":11,"skill_id":43,"weight_pct":10.0,"is_required":False},
    {"career_id":11,"skill_id":66,"weight_pct":10.0,"is_required":False},
    {"career_id":11,"skill_id":82,"weight_pct":5.0,"is_required":False},
    # AI Engineer (12)
    {"career_id":12,"skill_id":1,"weight_pct":15.0,"is_required":True},
    {"career_id":12,"skill_id":64,"weight_pct":20.0,"is_required":True},
    {"career_id":12,"skill_id":65,"weight_pct":15.0,"is_required":True},
    {"career_id":12,"skill_id":68,"weight_pct":15.0,"is_required":True},
    {"career_id":12,"skill_id":69,"weight_pct":10.0,"is_required":False},
    {"career_id":12,"skill_id":62,"weight_pct":10.0,"is_required":False},
    {"career_id":12,"skill_id":61,"weight_pct":10.0,"is_required":False},
    {"career_id":12,"skill_id":66,"weight_pct":5.0,"is_required":False},
    # Computer Vision Engineer (13)
    {"career_id":13,"skill_id":1,"weight_pct":20.0,"is_required":True},
    {"career_id":13,"skill_id":67,"weight_pct":30.0,"is_required":True},
    {"career_id":13,"skill_id":62,"weight_pct":20.0,"is_required":True},
    {"career_id":13,"skill_id":66,"weight_pct":15.0,"is_required":False},
    {"career_id":13,"skill_id":60,"weight_pct":15.0,"is_required":False},
    # NLP Engineer (14)
    {"career_id":14,"skill_id":1,"weight_pct":20.0,"is_required":True},
    {"career_id":14,"skill_id":63,"weight_pct":25.0,"is_required":True},
    {"career_id":14,"skill_id":68,"weight_pct":20.0,"is_required":True},
    {"career_id":14,"skill_id":64,"weight_pct":15.0,"is_required":False},
    {"career_id":14,"skill_id":62,"weight_pct":15.0,"is_required":False},
    {"career_id":14,"skill_id":69,"weight_pct":5.0,"is_required":False},
    # DevOps Engineer (15)
    {"career_id":15,"skill_id":42,"weight_pct":20.0,"is_required":True},
    {"career_id":15,"skill_id":43,"weight_pct":20.0,"is_required":True},
    {"career_id":15,"skill_id":45,"weight_pct":20.0,"is_required":True},
    {"career_id":15,"skill_id":46,"weight_pct":10.0,"is_required":True},
    {"career_id":15,"skill_id":44,"weight_pct":10.0,"is_required":False},
    {"career_id":15,"skill_id":39,"weight_pct":10.0,"is_required":False},
    {"career_id":15,"skill_id":70,"weight_pct":10.0,"is_required":True},
    # Cloud Engineer (16)
    {"career_id":16,"skill_id":39,"weight_pct":30.0,"is_required":True},
    {"career_id":16,"skill_id":40,"weight_pct":20.0,"is_required":False},
    {"career_id":16,"skill_id":41,"weight_pct":15.0,"is_required":False},
    {"career_id":16,"skill_id":44,"weight_pct":15.0,"is_required":True},
    {"career_id":16,"skill_id":43,"weight_pct":10.0,"is_required":False},
    {"career_id":16,"skill_id":46,"weight_pct":10.0,"is_required":False},
    # SRE (17)
    {"career_id":17,"skill_id":42,"weight_pct":15.0,"is_required":True},
    {"career_id":17,"skill_id":43,"weight_pct":15.0,"is_required":True},
    {"career_id":17,"skill_id":45,"weight_pct":15.0,"is_required":True},
    {"career_id":17,"skill_id":39,"weight_pct":15.0,"is_required":True},
    {"career_id":17,"skill_id":46,"weight_pct":15.0,"is_required":True},
    {"career_id":17,"skill_id":44,"weight_pct":10.0,"is_required":False},
    {"career_id":17,"skill_id":1,"weight_pct":15.0,"is_required":False},
    # Cybersecurity Analyst (18)
    {"career_id":18,"skill_id":72,"weight_pct":25.0,"is_required":True},
    {"career_id":18,"skill_id":73,"weight_pct":20.0,"is_required":True},
    {"career_id":18,"skill_id":75,"weight_pct":15.0,"is_required":True},
    {"career_id":18,"skill_id":46,"weight_pct":15.0,"is_required":True},
    {"career_id":18,"skill_id":74,"weight_pct":15.0,"is_required":False},
    {"career_id":18,"skill_id":76,"weight_pct":10.0,"is_required":False},
    # Penetration Tester (19)
    {"career_id":19,"skill_id":74,"weight_pct":35.0,"is_required":True},
    {"career_id":19,"skill_id":73,"weight_pct":25.0,"is_required":True},
    {"career_id":19,"skill_id":72,"weight_pct":20.0,"is_required":True},
    {"career_id":19,"skill_id":46,"weight_pct":10.0,"is_required":False},
    {"career_id":19,"skill_id":76,"weight_pct":10.0,"is_required":False},
    # UI/UX Designer (20)
    {"career_id":20,"skill_id":77,"weight_pct":35.0,"is_required":True},
    {"career_id":20,"skill_id":78,"weight_pct":20.0,"is_required":False},
    {"career_id":20,"skill_id":21,"weight_pct":15.0,"is_required":False},
    {"career_id":20,"skill_id":90,"weight_pct":15.0,"is_required":False},
    {"career_id":20,"skill_id":89,"weight_pct":15.0,"is_required":False},
    # Product Manager (21)
    {"career_id":21,"skill_id":79,"weight_pct":20.0,"is_required":True},
    {"career_id":21,"skill_id":90,"weight_pct":20.0,"is_required":True},
    {"career_id":21,"skill_id":100,"weight_pct":20.0,"is_required":True},
    {"career_id":21,"skill_id":92,"weight_pct":15.0,"is_required":True},
    {"career_id":21,"skill_id":101,"weight_pct":15.0,"is_required":False},
    {"career_id":21,"skill_id":97,"weight_pct":10.0,"is_required":False},
    # QA Engineer (22)
    {"career_id":22,"skill_id":79,"weight_pct":20.0,"is_required":True},
    {"career_id":22,"skill_id":98,"weight_pct":20.0,"is_required":True},
    {"career_id":22,"skill_id":15,"weight_pct":15.0,"is_required":False},
    {"career_id":22,"skill_id":92,"weight_pct":15.0,"is_required":True},
    {"career_id":22,"skill_id":70,"weight_pct":15.0,"is_required":True},
    {"career_id":22,"skill_id":89,"weight_pct":15.0,"is_required":False},
    # IT Project Manager (23)
    {"career_id":23,"skill_id":100,"weight_pct":25.0,"is_required":True},
    {"career_id":23,"skill_id":79,"weight_pct":20.0,"is_required":True},
    {"career_id":23,"skill_id":101,"weight_pct":20.0,"is_required":True},
    {"career_id":23,"skill_id":90,"weight_pct":15.0,"is_required":True},
    {"career_id":23,"skill_id":96,"weight_pct":10.0,"is_required":False},
    {"career_id":23,"skill_id":94,"weight_pct":10.0,"is_required":False},
    # IT Support (24)
    {"career_id":24,"skill_id":46,"weight_pct":25.0,"is_required":True},
    {"career_id":24,"skill_id":90,"weight_pct":25.0,"is_required":True},
    {"career_id":24,"skill_id":89,"weight_pct":20.0,"is_required":True},
    {"career_id":24,"skill_id":94,"weight_pct":15.0,"is_required":True},
    {"career_id":24,"skill_id":91,"weight_pct":15.0,"is_required":False},
    # System Administrator (25)
    {"career_id":25,"skill_id":46,"weight_pct":30.0,"is_required":True},
    {"career_id":25,"skill_id":42,"weight_pct":20.0,"is_required":False},
    {"career_id":25,"skill_id":47,"weight_pct":15.0,"is_required":False},
    {"career_id":25,"skill_id":89,"weight_pct":15.0,"is_required":True},
    {"career_id":25,"skill_id":72,"weight_pct":20.0,"is_required":False},
    # Network Engineer (26)
    {"career_id":26,"skill_id":72,"weight_pct":30.0,"is_required":True},
    {"career_id":26,"skill_id":46,"weight_pct":25.0,"is_required":True},
    {"career_id":26,"skill_id":47,"weight_pct":20.0,"is_required":False},
    {"career_id":26,"skill_id":89,"weight_pct":10.0,"is_required":False},
    {"career_id":26,"skill_id":98,"weight_pct":15.0,"is_required":False},
    # Database Administrator (27)
    {"career_id":27,"skill_id":15,"weight_pct":30.0,"is_required":True},
    {"career_id":27,"skill_id":31,"weight_pct":20.0,"is_required":True},
    {"career_id":27,"skill_id":32,"weight_pct":15.0,"is_required":False},
    {"career_id":27,"skill_id":38,"weight_pct":15.0,"is_required":False},
    {"career_id":27,"skill_id":46,"weight_pct":10.0,"is_required":False},
    {"career_id":27,"skill_id":42,"weight_pct":10.0,"is_required":False},
]


# ─────────────────────────────────────────────────────────────────────────────
# SUPABASE CLIENT
# ─────────────────────────────────────────────────────────────────────────────

def get_supabase_client() -> Client:
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_KEY")
    if url and key:
        url = url.strip()
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


# ─────────────────────────────────────────────────────────────────────────────
# DATA FETCHING  (Supabase → fallback to seed)
# ─────────────────────────────────────────────────────────────────────────────

def fetch_data() -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """
    Returns (df_edu, df_skills, df_careers, df_cs).
    Columns in df_careers must include: id, career_name, career_description,
    min_education_rank (int), location_bias (str), salary_min, salary_max.
    Columns in df_cs must include: career_id, skill_id, weight_pct, is_required.
    """
    client = get_supabase_client()
    if client:
        try:
            edu_res     = client.table("education_levels").select("*").execute()
            skills_res  = client.table("skills").select("*").execute()
            careers_res = client.table("careers").select("*").execute()
            cs_res      = client.table("career_skills").select("*").execute()

            df_edu     = pd.DataFrame(edu_res.data)
            df_skills  = pd.DataFrame(skills_res.data)
            df_careers = pd.DataFrame(careers_res.data)
            df_cs      = pd.DataFrame(cs_res.data)

            if not (df_edu.empty or df_skills.empty or df_careers.empty or df_cs.empty):
                print(f"[engine] Supabase OK — {len(df_careers)} careers, {len(df_skills)} skills")
                return df_edu, df_skills, df_careers, df_cs
        except Exception as e:
            print(f"[engine] Supabase fetch failed: {e}. Using seed data.")

    print("[engine] Using local seed data.")
    return (
        pd.DataFrame(SEED_EDUCATION_LEVELS),
        pd.DataFrame(SEED_SKILLS),
        pd.DataFrame(SEED_CAREERS),
        pd.DataFrame(SEED_CAREER_SKILLS),
    )


# ─────────────────────────────────────────────────────────────────────────────
# HELPER: Map user education string → numeric rank
# ─────────────────────────────────────────────────────────────────────────────

def map_user_education_rank(user_edu_str: str, df_edu: pd.DataFrame) -> int:
    """
    Petakan jenjang pendidikan user ke order_rank.

    PENTING: skala berubah di migration 0005 dari 6 jenjang menjadi 10.
    SMA dan SMK sekarang terpisah (rank sama, 2), D1-D4 terpisah, dan SMP
    ditambahkan. Angka di bawah HARUS sama dengan education_levels.order_rank --
    kalau meleset, filter KBF akan menyaring profesi yang salah.

        SMP 1 | SMA 2 | SMK 2 | D1 3 | D2 4 | D3 5 | D4 6 | S1 6 | S2 7 | S3 8
    """
    if not user_edu_str:
        return 6  # default: sarjana

    clean = user_edu_str.lower().strip()

    # Kode jenjang dari onboarding baru ('SMK', 'S1', ...) -- paling akurat,
    # dicek lebih dulu sebelum pencocokan teks bebas.
    codes = {
        "smp": 1, "sma": 2, "smk": 2,
        "d1": 3, "d2": 4, "d3": 5, "d4": 6,
        "s1": 6, "s2": 7, "s3": 8,
    }
    if clean in codes:
        return codes[clean]

    # Nama jenjang dari tabel education_levels
    col = "level_name" if "level_name" in df_edu.columns else df_edu.columns[1]
    if "code" in df_edu.columns:
        for _, row in df_edu.iterrows():
            if str(row["code"]).lower() == clean:
                return int(row["order_rank"])
    for _, row in df_edu.iterrows():
        lvl = str(row[col]).lower()
        if clean in lvl or lvl in clean:
            return int(row["order_rank"])

    # Pencocokan kata kunci. Urutannya penting: yang lebih spesifik dulu,
    # supaya "diploma 3" tidak tertangkap oleh "diploma".
    shortcuts = [
        ("smp", 1), ("mts", 1), ("junior high", 1),
        ("smk", 2), ("mak", 2), ("vocational", 2),
        ("sma", 2), ("ma ", 2), ("high school", 2),
        ("diploma 1", 3), ("d1", 3),
        ("diploma 2", 4), ("d2", 4),
        ("diploma 3", 5), ("d3", 5),
        ("diploma 4", 6), ("d4", 6), ("sarjana terapan", 6),
        ("s1", 6), ("bachelor", 6), ("sarjana", 6),
        ("diploma", 5),
        ("s2", 7), ("master", 7), ("magister", 7),
        ("s3", 8), ("doctor", 8), ("doktor", 8), ("phd", 8), ("doctorate", 8),
    ]
    for kw, rank in shortcuts:
        if kw in clean:
            return rank
    return 6


# ─────────────────────────────────────────────────────────────────────────────
# HELPER: Map user skill strings → skill IDs (fuzzy)
# ─────────────────────────────────────────────────────────────────────────────

def map_user_skills(user_input_skills: List[str], df_skills: pd.DataFrame) -> List[int]:
    """
    Maps user-typed skill strings to skill IDs using:
    1. Exact case-insensitive match
    2. Substring match (either direction)
    3. Word-level prefix matching
    """
    mapped_ids = []
    skill_col = "skill_name" if "skill_name" in df_skills.columns else df_skills.columns[1]
    all_skills_norm = {
        str(row[skill_col]).lower().strip(): int(row["id"])
        for _, row in df_skills.iterrows()
    }

    def tokenize(s: str) -> List[str]:
        return [w for w in s.replace("&", " ").replace("/", " ").replace("-", " ").replace("(", " ").replace(")", " ").split() if len(w) > 2]

    for input_skill in user_input_skills:
        clean = input_skill.lower().strip()

        # 1. Exact
        if clean in all_skills_norm:
            mapped_ids.append(all_skills_norm[clean])
            continue

        # 2. Substring (only if both strings are >= 4 chars to avoid "R" matching "Docker")
        found = False
        if len(clean) >= 4:
            for db_name, db_id in all_skills_norm.items():
                if len(db_name) >= 4 and (clean in db_name or db_name in clean):
                    mapped_ids.append(db_id)
                    found = True
                    break
        if found:
            continue

        # 3. Word-level prefix
        input_words = tokenize(clean)
        for db_name, db_id in all_skills_norm.items():
            db_words = tokenize(db_name)
            for iw in input_words:
                for sw in db_words:
                    if sw.startswith(iw) or iw.startswith(sw[:max(3, len(sw) - 2)]):
                        mapped_ids.append(db_id)
                        found = True
                        break
                if found:
                    break
            if found:
                break

    return list(set(mapped_ids))


# ─────────────────────────────────────────────────────────────────────────────
# HELPER: City matching for multi-value location_bias
# ─────────────────────────────────────────────────────────────────────────────

def city_matches(location_bias: str, user_city: str) -> bool:
    """
    Returns True if user_city appears anywhere inside location_bias
    (case-insensitive, comma-separated).
    e.g. "Jakarta, Surabaya, Bandung" matches "surabaya"
    """
    if not user_city or not location_bias:
        return True  # no filter if either is empty
    cities = [c.strip().lower() for c in str(location_bias).split(",")]
    uc = user_city.lower().strip()
    return any(uc in c or c in uc for c in cities)


# ─────────────────────────────────────────────────────────────────────────────
# MAIN ENGINE
# ─────────────────────────────────────────────────────────────────────────────

def run_hybrid_engine(
    user_skills: List[str],
    user_education: str,
    user_min_salary: float,
    user_city: str = None,
) -> List[Dict[str, Any]]:
    """
    Hybrid Knowledge-Based + Content-Based recommendation engine.

    1. KBF: Filter by education rank, min salary, and city (multi-value).
    2. CBF: Cosine Similarity between user skill vector and career skill vectors.
    3. Gap Analysis: Required skills acquired vs. missing per career.
    """
    df_edu, df_skills, df_careers, df_cs = fetch_data()

    # Normalise column names from Supabase (may differ from seed dict keys)
    # education_levels: expect 'order_rank'
    # careers: expect 'min_education_rank', 'location_bias', 'salary_min', 'salary_max'
    # Rename legacy columns if they exist (backward-compat)
    if "min_education_id" in df_careers.columns and "min_education_rank" not in df_careers.columns:
        # Old schema: join with edu to get order_rank
        edu_rank_map = df_edu.set_index("id")["order_rank"].to_dict()
        df_careers = df_careers.copy()
        df_careers["min_education_rank"] = df_careers["min_education_id"].map(edu_rank_map).fillna(3).astype(int)

    if "target_city" in df_careers.columns and "location_bias" not in df_careers.columns:
        df_careers = df_careers.rename(columns={"target_city": "location_bias"})

    # Map user inputs
    mapped_skill_ids = map_user_skills(user_skills, df_skills)
    user_edu_rank    = map_user_education_rank(user_education, df_edu)

    print(f"[engine] User edu rank: {user_edu_rank}, mapped skills: {mapped_skill_ids}")

    # ── 1. Knowledge-Based Filtering ────────────────────────────────────────
    # Relax education filter: treat SMA/SMK/Diploma students (rank <= 3) as S1-equivalent (rank 4) 
    # to allow them to discover and plan roadmaps for D3/S1 level careers.
    effective_edu_rank = max(user_edu_rank, 4)
    kbf_mask = df_careers["min_education_rank"].astype(int) <= effective_edu_rank
    kbf_mask = kbf_mask & (df_careers["salary_max"].astype(float) >= user_min_salary)

    if user_city:
        city_mask = df_careers["location_bias"].apply(lambda lb: city_matches(lb, user_city))
        # Apply city filter only if it doesn't empty the result
        if (kbf_mask & city_mask).any():
            kbf_mask = kbf_mask & city_mask

    filtered_careers = df_careers[kbf_mask].copy()
    print(f"[engine] KBF passed: {len(filtered_careers)} careers")

    if filtered_careers.empty:
        return []

    # ── 2. Content-Based Filtering (Cosine Similarity) ──────────────────────
    all_skill_ids = df_skills["id"].astype(int).tolist()

    # Pivot: rows = career_id, columns = skill_id, values = weight_pct
    df_cs_typed = df_cs.copy()
    df_cs_typed["career_id"] = df_cs_typed["career_id"].astype(int)
    df_cs_typed["skill_id"]  = df_cs_typed["skill_id"].astype(int)
    df_cs_typed["weight_pct"] = df_cs_typed["weight_pct"].astype(float)

    pivot_cs = df_cs_typed.pivot_table(
        index="career_id", columns="skill_id", values="weight_pct", aggfunc="max"
    ).fillna(0.0)

    for sid in all_skill_ids:
        if sid not in pivot_cs.columns:
            pivot_cs[sid] = 0.0
    pivot_cs = pivot_cs[all_skill_ids]

    kbf_ids = filtered_careers["id"].astype(int).tolist()
    pivot_filtered = pivot_cs.loc[pivot_cs.index.isin(kbf_ids)]

    if pivot_filtered.empty:
        return []

    # Build user vector
    user_vector = np.zeros((1, len(all_skill_ids)))
    for sid in mapped_skill_ids:
        if sid in all_skill_ids:
            user_vector[0, all_skill_ids.index(sid)] = 1.0

    similarities = cosine_similarity(user_vector, pivot_filtered.to_numpy())[0]
    career_scores = {pivot_filtered.index[i]: float(similarities[i]) for i in range(len(similarities))}

    filtered_careers["match_score"] = filtered_careers["id"].astype(int).map(career_scores)
    ranked_careers = filtered_careers.sort_values(by="match_score", ascending=False)

    # ── 3. Gap Analysis ─────────────────────────────────────────────────────
    results = []
    for _, career_row in ranked_careers.iterrows():
        c_id      = int(career_row["id"])
        c_name    = career_row["career_name"]
        c_desc    = career_row.get("career_description", "")
        c_loc     = career_row.get("location_bias", career_row.get("target_city", ""))
        c_sal_min = float(career_row["salary_min"])
        c_sal_max = float(career_row["salary_max"])
        score     = float(career_row["match_score"])

        cs_sub    = df_cs_typed[df_cs_typed["career_id"] == c_id]
        cs_detail = cs_sub.merge(df_skills, left_on="skill_id", right_on="id")

        skill_col = "skill_name" if "skill_name" in cs_detail.columns else cs_detail.columns[2]
        required, missing, acquired = [], [], []

        for _, sr in cs_detail.iterrows():
            s_id     = int(sr["skill_id"])
            s_name   = str(sr[skill_col])
            s_req    = bool(sr["is_required"])
            s_weight = float(sr["weight_pct"])

            if s_req:
                required.append({"name": s_name, "weight": s_weight})
                if s_id not in mapped_skill_ids:
                    missing.append({"name": s_name, "weight": s_weight})
                else:
                    acquired.append({"name": s_name, "weight": s_weight})

        results.append({
            "career_id":    c_id,
            "career_name":  c_name,
            "description":  c_desc,
            "target_city":  c_loc,
            "salary_min":   c_sal_min,
            "salary_max":   c_sal_max,
            "match_score":  round(score * 100, 2),
            "skills": {
                "required": required,
                "missing":  missing,
                "acquired": acquired,
            },
        })

    return results[:3]
