"use client";

import React, { useState } from "react";
import { BookOpen, Users, GraduationCap, ChevronRight, ChevronLeft, CheckCircle, Hash, Sparkles } from "lucide-react";
import { API_URL } from "@/config/api";

// ─────────────────────────────────────────────────────────────────────────────
// DATA: Standardized education levels
// ─────────────────────────────────────────────────────────────────────────────
export const EDUCATION_LEVELS = [
  { value: "SMA/SMK Sederajat", label: "SMA / SMK Sederajat", icon: "🏫", sublabel: "Termasuk MA, MAK" },
  { value: "Diploma 3 (D3)", label: "Diploma 3 (D3)", icon: "📋", sublabel: "Ahli Madya" },
  { value: "Sarjana (S1/D4)", label: "Sarjana / D4 (S1/D4)", icon: "🎓", sublabel: "Strata 1 / Diploma 4" },
  { value: "Magister (S2)", label: "Magister (S2)", icon: "📚", sublabel: "Strata 2" },
  { value: "Doktor (S3)", label: "Doktor (S3)", icon: "🔬", sublabel: "Strata 3 / PhD" },
];

// ─────────────────────────────────────────────────────────────────────────────
// DATA: Standardized major tags per education level
// ─────────────────────────────────────────────────────────────────────────────
export const MAJOR_MAP: Record<string, { value: string; label: string; tags?: string[] }[]> = {
  "SMA/SMK Sederajat": [
    // SMA streams
    { value: "SMA - MIPA (IPA)", label: "SMA – MIPA (IPA)" },
    { value: "SMA - IPS", label: "SMA – IPS" },
    { value: "SMA - Bahasa & Sastra", label: "SMA – Bahasa & Sastra" },
    // SMK popular IT programs
    { value: "SMK - Rekayasa Perangkat Lunak (RPL)", label: "SMK – Rekayasa Perangkat Lunak (RPL)" },
    { value: "SMK - Teknik Komputer & Jaringan (TKJ)", label: "SMK – Teknik Komputer & Jaringan (TKJ)" },
    { value: "SMK - Sistem Informatika, Jaringan & Aplikasi (SIJA)", label: "SMK – Sistem Informatika, Jaringan & Aplikasi (SIJA)" },
    { value: "SMK - Multimedia / Desain Komunikasi Visual (DKV)", label: "SMK – Multimedia / DKV" },
    { value: "SMK - Animasi", label: "SMK – Animasi" },
    { value: "SMK - Otomasi & Robotika Industri", label: "SMK – Otomasi & Robotika" },
    { value: "SMK - Elektronika", label: "SMK – Elektronika" },
    { value: "SMK - Bisnis Daring & Pemasaran", label: "SMK – Bisnis Daring & Pemasaran" },
    { value: "SMK - Akuntansi & Keuangan", label: "SMK – Akuntansi & Keuangan" },
    { value: "SMK - Lainnya", label: "SMK – Jurusan Lainnya" },
    { value: "SMA - Lainnya", label: "SMA – Program Lainnya" },
  ],
  "Diploma 3 (D3)": [
    { value: "D3 - Teknik Informatika", label: "Teknik Informatika" },
    { value: "D3 - Sistem Informasi", label: "Sistem Informasi" },
    { value: "D3 - Manajemen Informatika", label: "Manajemen Informatika" },
    { value: "D3 - Teknik Komputer", label: "Teknik Komputer" },
    { value: "D3 - Jaringan Komputer", label: "Jaringan Komputer" },
    { value: "D3 - Keamanan Siber", label: "Keamanan Siber" },
    { value: "D3 - Multimedia", label: "Multimedia" },
    { value: "D3 - Akuntansi", label: "Akuntansi" },
    { value: "D3 - Teknik Elektro", label: "Teknik Elektro" },
    { value: "D3 - Statistika", label: "Statistika" },
    { value: "D3 - Lainnya", label: "Jurusan Lainnya" },
  ],
  "Sarjana (S1/D4)": [
    { value: "S1 - Teknik Informatika", label: "Teknik Informatika" },
    { value: "S1 - Ilmu Komputer", label: "Ilmu Komputer" },
    { value: "S1 - Sistem Informasi", label: "Sistem Informasi" },
    { value: "S1 - Teknik Elektro", label: "Teknik Elektro" },
    { value: "S1 - Teknik Komputer", label: "Teknik Komputer" },
    { value: "S1 - Sains Data / Data Science", label: "Sains Data / Data Science" },
    { value: "S1 - Kecerdasan Buatan / AI", label: "Kecerdasan Buatan / AI" },
    { value: "S1 - Rekayasa Perangkat Lunak", label: "Rekayasa Perangkat Lunak" },
    { value: "S1 - Keamanan Siber / Cybersecurity", label: "Keamanan Siber / Cybersecurity" },
    { value: "S1 - Teknik Telekomunikasi", label: "Teknik Telekomunikasi" },
    { value: "S1 - Matematika", label: "Matematika" },
    { value: "S1 - Statistika", label: "Statistika" },
    { value: "S1 - Manajemen / Bisnis Digital", label: "Manajemen / Bisnis Digital" },
    { value: "S1 - Ekonomi / Akuntansi", label: "Ekonomi / Akuntansi" },
    { value: "S1 - Desain Komunikasi Visual (DKV)", label: "Desain Komunikasi Visual (DKV)" },
    { value: "S1 - Fisika", label: "Fisika" },
    { value: "S1 - Lainnya", label: "Jurusan Lainnya" },
  ],
  "Magister (S2)": [
    { value: "S2 - Teknik Informatika", label: "Teknik Informatika" },
    { value: "S2 - Ilmu Komputer", label: "Ilmu Komputer" },
    { value: "S2 - Kecerdasan Buatan / AI", label: "Kecerdasan Buatan / AI" },
    { value: "S2 - Sains Data / Data Science", label: "Sains Data / Data Science" },
    { value: "S2 - Keamanan Siber", label: "Keamanan Siber" },
    { value: "S2 - Sistem Informasi", label: "Sistem Informasi" },
    { value: "S2 - Teknik Elektro", label: "Teknik Elektro" },
    { value: "S2 - Manajemen Teknologi Informasi (MTI)", label: "Manajemen Teknologi Informasi (MTI)" },
    { value: "S2 - Machine Learning / Data Analytics", label: "Machine Learning / Data Analytics" },
    { value: "S2 - Bisnis / MBA Tech", label: "Bisnis / MBA Tech" },
    { value: "S2 - Lainnya", label: "Jurusan Lainnya" },
  ],
  "Doktor (S3)": [
    { value: "S3 - Teknik Informatika / Ilmu Komputer", label: "Teknik Informatika / Ilmu Komputer" },
    { value: "S3 - Kecerdasan Buatan / Machine Learning", label: "Kecerdasan Buatan / Machine Learning" },
    { value: "S3 - Sains Data / Komputasi", label: "Sains Data / Komputasi" },
    { value: "S3 - Keamanan Siber", label: "Keamanan Siber" },
    { value: "S3 - Sistem Terbenam / IoT", label: "Sistem Terbenam / IoT" },
    { value: "S3 - Jaringan & Komputasi Terdistribusi", label: "Jaringan & Komputasi Terdistribusi" },
    { value: "S3 - Lainnya", label: "Jurusan Lainnya" },
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// DATA: Standardized skill recommendations per major (rich list)
// ─────────────────────────────────────────────────────────────────────────────
export const MAJOR_SKILLS_MAP: Record<string, string[]> = {
  // ── SMA ──────────────────────────────────────────────────────────────────
  "SMA - MIPA (IPA)": [
    "Python", "SQL", "Mathematics & Statistics", "R", "Pandas", "NumPy",
    "Scikit-learn", "Data Analysis", "Machine Learning", "Excel / Google Sheets",
    "Tableau", "Power BI", "Git", "GitHub / GitLab", "Linux / Unix Administration",
    "JavaScript", "Arduino / IoT Basics", "Physics Simulation", "Matlab",
  ],
  "SMA - IPS": [
    "Excel / Google Sheets", "SQL", "Data Analysis", "Python", "Power BI",
    "Tableau", "Financial Modeling", "Business Analytics", "Digital Marketing",
    "Google Analytics", "SEO / SEM", "Copywriting", "Content Strategy",
    "Social Media Management", "Communication", "Project Management",
    "Microsoft 365 Suite", "CRM Tools", "Market Research",
  ],
  "SMA - Bahasa & Sastra": [
    "Copywriting", "Technical Writing", "Content Strategy", "SEO / SEM",
    "Social Media Management", "Communication", "UX Writing", "Localization",
    "Translation Tools", "WordPress", "Content Management Systems (CMS)",
    "Email Marketing", "Adobe Acrobat", "Notion / Obsidian", "Figma (basic)",
    "Podcast & Video Scripting", "Journalism Tools",
  ],
  "SMA - Lainnya": [
    "Python", "SQL", "HTML/CSS", "JavaScript", "Excel / Google Sheets",
    "Git", "GitHub / GitLab", "Digital Marketing", "Communication",
  ],

  // ── SMK IT ──────────────────────────────────────────────────────────────
  "SMK - Rekayasa Perangkat Lunak (RPL)": [
    "HTML/CSS", "JavaScript", "TypeScript", "PHP", "Python", "Java",
    "React.js", "Vue.js", "Next.js", "Node.js", "Laravel", "CodeIgniter",
    "Express.js", "FastAPI", "Django", "SQL", "MySQL", "PostgreSQL", "MongoDB",
    "RESTful API Design", "Git", "GitHub / GitLab", "Docker (basic)", "Postman",
    "Unit Testing", "Bootstrap", "Tailwind CSS", "Figma (basic)", "Linux (basic)",
  ],
  "SMK - Teknik Komputer & Jaringan (TKJ)": [
    "Linux / Unix Administration", "Cisco CCNA / Networking", "Network Security",
    "Mikrotik RouterOS", "Wireshark", "TCP/IP Protocols", "VLAN & Subnetting",
    "Server Administration", "Active Directory", "Windows Server", "Firewall Configuration",
    "VPN Configuration", "Hardware Troubleshooting", "Nginx / Apache",
    "Docker (basic)", "Virtualization (VMware / VirtualBox)", "Cloud Basics (AWS / GCP)",
    "Python Scripting", "Bash Scripting", "Penetration Testing (basic)",
  ],
  "SMK - Sistem Informatika, Jaringan & Aplikasi (SIJA)": [
    "Linux / Unix Administration", "Docker", "Kubernetes (K8s) (basic)",
    "Network Security", "Python Scripting", "Bash Scripting",
    "CI/CD (Jenkins, GitHub Actions, GitLab CI)", "Cloud Basics (AWS / GCP / Azure)",
    "MySQL", "PostgreSQL", "RESTful API Design", "Git", "GitHub / GitLab",
    "Server Administration", "Mikrotik RouterOS", "Firewall Configuration",
    "Nginx / Apache", "Monitoring Tools (Grafana / Prometheus)", "Virtualization",
  ],
  "SMK - Multimedia / Desain Komunikasi Visual (DKV)": [
    "Figma", "Adobe Photoshop", "Adobe Illustrator", "Adobe Premiere Pro",
    "Adobe After Effects", "Canva", "UI/UX Design", "Wireframing & Prototyping",
    "InDesign", "Cinema 4D (basic)", "Blender (basic)", "Color Theory",
    "Typography", "Branding & Visual Identity", "Motion Graphics",
    "HTML/CSS (basic)", "WordPress", "Social Media Design", "Print Design",
  ],
  "SMK - Animasi": [
    "Adobe Animate", "Blender", "Maya (basic)", "Adobe After Effects",
    "Cinema 4D", "Storyboarding", "2D Animation", "3D Modeling",
    "Rigging & Skinning", "Compositing", "Adobe Premiere Pro",
    "Unity (basic)", "Unreal Engine (basic)", "VFX Basics",
    "Concept Art", "Figma", "Adobe Photoshop",
  ],
  "SMK - Otomasi & Robotika Industri": [
    "Arduino / Microcontroller Programming", "Raspberry Pi",
    "Python Scripting", "C/C++", "PLC Programming",
    "Embedded Systems", "SCADA Systems", "CAD (AutoCAD / SolidWorks)",
    "IoT Protocols (MQTT, Modbus)", "Industrial Networking",
    "Sensor & Actuator Programming", "ROS (Robot Operating System) (basic)",
    "PCB Design (basic)", "Matlab / Simulink",
  ],
  "SMK - Elektronika": [
    "Arduino / Microcontroller Programming", "C/C++", "Raspberry Pi",
    "PCB Design (KiCad / Altium)", "Embedded Systems", "VHDL / FPGA Programming",
    "Analog & Digital Circuit Design", "Oscilloscope & Signal Analysis",
    "Python Scripting", "Matlab", "IoT Basics", "Sensor Integration",
    "3D Printing / Fabrication", "Soldering & Assembly",
  ],
  "SMK - Bisnis Daring & Pemasaran": [
    "Digital Marketing", "SEO / SEM", "Google Analytics", "Facebook Ads / Meta Ads",
    "TikTok Ads", "Shopee / Tokopedia Marketplace Management", "Copywriting",
    "Content Creation", "Social Media Management", "Email Marketing",
    "E-commerce Operations", "Canva", "Excel / Google Sheets",
    "Customer Relationship Management (CRM)", "Market Research",
    "Data Analysis (basic)", "Microsoft 365 Suite",
  ],
  "SMK - Akuntansi & Keuangan": [
    "Excel / Google Sheets", "SQL (basic)", "Power BI", "Accurate Online",
    "MYOB / Jurnal", "SAP (basic)", "Financial Modeling",
    "Payroll Management", "Tax Compliance", "Microsoft 365 Suite",
    "Data Analysis (basic)", "Python (basic)", "Business Analytics",
    "ERPNext (basic)", "Odoo (basic)",
  ],
  "SMK - Lainnya": [
    "Python", "SQL", "Excel / Google Sheets", "Git", "Digital Marketing",
    "HTML/CSS (basic)", "Communication", "Microsoft 365 Suite",
  ],

  // ── D3 ───────────────────────────────────────────────────────────────────
  "D3 - Teknik Informatika": [
    "Python", "Java", "PHP", "JavaScript", "HTML/CSS", "React.js", "Laravel",
    "MySQL", "PostgreSQL", "SQL", "Git", "GitHub / GitLab", "RESTful API Design",
    "Docker (basic)", "Linux / Unix Administration", "Figma", "Unit Testing",
    "Node.js", "Bootstrap", "Tailwind CSS",
  ],
  "D3 - Sistem Informasi": [
    "SQL", "MySQL", "Python", "PHP", "Laravel", "JavaScript", "HTML/CSS",
    "Excel / Google Sheets", "Power BI", "Tableau", "Data Analysis",
    "ERPNext / Odoo (basic)", "SAP (basic)", "Business Process Modeling",
    "Git", "RESTful API Design", "Figma", "Agile / Scrum",
  ],
  "D3 - Manajemen Informatika": [
    "SQL", "Excel / Google Sheets", "Python", "PHP", "HTML/CSS",
    "Power BI", "Tableau", "Data Analysis", "Business Analytics",
    "Project Management", "Figma", "RESTful API Design", "Laravel",
    "SAP (basic)", "Microsoft 365 Suite", "Git",
  ],
  "D3 - Teknik Komputer": [
    "C/C++", "Python", "Embedded Systems", "Arduino", "Raspberry Pi",
    "Linux / Unix Administration", "Git", "Docker (basic)",
    "Computer Architecture", "Assembly Language", "Hardware Troubleshooting",
    "PCB Design (basic)", "IoT Basics", "Networking Basics",
  ],
  "D3 - Jaringan Komputer": [
    "Cisco CCNA / Networking", "Linux / Unix Administration", "Python Scripting",
    "Network Security", "Firewall Configuration", "VPN Configuration",
    "Wireshark", "TCP/IP Protocols", "Docker", "Server Administration",
    "Nginx / Apache", "Bash Scripting", "Cloud Basics (AWS / GCP)",
    "Mikrotik RouterOS", "Monitoring (Grafana / Prometheus)",
  ],
  "D3 - Keamanan Siber": [
    "Network Security", "Penetration Testing", "Web Application Security (OWASP)",
    "Python Scripting", "Linux / Unix Administration", "Wireshark",
    "Metasploit", "Nmap / Nessus", "Burp Suite", "Cryptography",
    "Bash Scripting", "Docker (basic)", "Forensics Tools", "SIEM Basics",
    "Ethical Hacking Methodology", "CTF (Capture The Flag) Skills",
  ],
  "D3 - Multimedia": [
    "Figma", "Adobe Photoshop", "Adobe Illustrator", "Adobe Premiere Pro",
    "Adobe After Effects", "HTML/CSS", "JavaScript (basic)", "UI/UX Design",
    "Motion Graphics", "Video Production", "Blender (basic)", "WordPress",
  ],
  "D3 - Akuntansi": [
    "Excel / Google Sheets", "SQL (basic)", "Power BI", "SAP (basic)",
    "Accurate Online", "MYOB", "Financial Modeling", "Payroll Management",
    "Tax Compliance", "Python (basic)", "Odoo (basic)", "Microsoft 365 Suite",
  ],
  "D3 - Teknik Elektro": [
    "Python", "MATLAB", "Embedded Systems", "Arduino", "PLC Programming",
    "AutoCAD Electrical", "PCB Design", "IoT Protocols", "C/C++",
    "Power Systems Analysis", "SCADA", "Industrial Networking",
  ],
  "D3 - Statistika": [
    "R", "Python", "SQL", "SPSS", "Pandas", "NumPy", "Scikit-learn",
    "Excel / Google Sheets", "Tableau", "Power BI", "Data Analysis",
    "Statistical Modeling", "Machine Learning (basic)", "Git",
  ],
  "D3 - Lainnya": [
    "Python", "SQL", "Excel / Google Sheets", "Git", "JavaScript",
    "Data Analysis", "Linux (basic)", "Communication",
  ],

  // ── S1 ───────────────────────────────────────────────────────────────────
  "S1 - Teknik Informatika": [
    "Python", "JavaScript", "TypeScript", "Java", "Go (Golang)", "C/C++", "SQL",
    "React.js", "Vue.js", "Next.js", "Node.js", "FastAPI", "Django", "Spring Boot",
    "PostgreSQL", "MongoDB", "Redis", "Docker", "Kubernetes (K8s)",
    "CI/CD (Jenkins, GitHub Actions, GitLab CI)", "Linux / Unix Administration",
    "AWS", "Google Cloud Platform (GCP)", "Git", "GitHub / GitLab",
    "Agile / Scrum", "Microservices Architecture", "GraphQL",
    "Unit Testing & TDD", "RESTful API Design", "System Design",
  ],
  "S1 - Ilmu Komputer": [
    "Python", "C/C++", "Java", "Algorithms & Data Structures", "Go (Golang)",
    "Machine Learning", "Scikit-learn", "TensorFlow", "PyTorch",
    "SQL", "PostgreSQL", "MongoDB", "Git", "Docker", "Linux / Unix Administration",
    "Computer Networks", "Operating Systems Internals", "Compiler Design",
    "Cryptography", "Parallel Computing", "Distributed Systems",
    "Research Methodology", "LaTeX", "Matlab",
  ],
  "S1 - Sistem Informasi": [
    "SQL", "Python", "PHP", "JavaScript", "Java", "Laravel", "React.js",
    "Power BI", "Tableau", "Data Analysis", "ERPNext / Odoo", "SAP (basic)",
    "Business Process Modeling (BPMN)", "Agile / Scrum", "Project Management",
    "IT Service Management (ITIL)", "Git", "Docker (basic)", "Figma",
    "UX Research", "Digital Transformation Strategy", "Excel / Google Sheets",
  ],
  "S1 - Rekayasa Perangkat Lunak": [
    "Python", "JavaScript", "TypeScript", "Java", "Go (Golang)", "Kotlin",
    "React.js", "Vue.js", "Next.js", "NestJS", "Node.js", "FastAPI",
    "Spring Boot", "Laravel", "SQL", "PostgreSQL", "MongoDB", "Redis",
    "Docker", "Kubernetes (K8s)", "CI/CD (Jenkins, GitHub Actions, GitLab CI)",
    "Git", "GitHub / GitLab", "Unit Testing & TDD", "Microservices Architecture",
    "System Design", "Agile / Scrum", "Code Review Best Practices",
  ],
  "S1 - Sains Data / Data Science": [
    "Python", "R", "SQL", "Pandas", "NumPy", "Scikit-learn",
    "TensorFlow", "PyTorch", "Hugging Face", "XGBoost / LightGBM",
    "Tableau", "Power BI", "Looker / Looker Studio", "BigQuery",
    "Apache Spark", "Apache Airflow", "dbt (Data Build Tool)",
    "Snowflake", "Elasticsearch", "Git", "Docker (basic)",
    "Machine Learning", "Statistical Modeling", "A/B Testing",
    "Feature Engineering", "Data Visualization", "MLflow",
  ],
  "S1 - Kecerdasan Buatan / AI": [
    "Python", "TensorFlow", "PyTorch", "Hugging Face", "LangChain",
    "OpenAI API", "RAG (Retrieval-Augmented Generation)",
    "Vector Database (Pinecone, Weaviate)", "Computer Vision (OpenCV)",
    "NVIDIA CUDA / GPU Computing", "Scikit-learn", "SQL", "Pandas",
    "Git", "Docker", "Kubernetes (K8s)", "MLflow", "Kubeflow",
    "Reinforcement Learning", "NLP / LLM Fine-tuning",
    "Knowledge Graphs", "Prompt Engineering",
  ],
  "S1 - Keamanan Siber / Cybersecurity": [
    "Network Security", "Web Application Security (OWASP)",
    "Penetration Testing", "Python Scripting", "Linux / Unix Administration",
    "Wireshark", "Metasploit", "Burp Suite", "Nmap / Nessus",
    "Cryptography", "Bash Scripting", "SIEM (Splunk, ELK Stack)",
    "Digital Forensics", "Incident Response", "Threat Hunting",
    "Kubernetes Security", "AWS Security", "Zero Trust Architecture",
    "Ethical Hacking Methodology", "CTF Skills", "Docker Security",
    "Identity & Access Management (IAM)", "SOC Analyst Skills",
  ],
  "S1 - Teknik Elektro": [
    "Python", "MATLAB", "Embedded Systems", "C/C++", "Arduino",
    "Raspberry Pi", "PLC Programming", "FPGA / VHDL",
    "AutoCAD Electrical", "PCB Design (Altium / KiCad)",
    "Power Systems Analysis", "SCADA", "Industrial Networking",
    "IoT Protocols (MQTT, Modbus)", "Signal Processing",
    "LabVIEW", "Simulink", "Linux (basic)",
  ],
  "S1 - Teknik Komputer": [
    "C/C++", "Python", "Embedded Systems", "Linux / Unix Administration",
    "Computer Architecture", "Assembly Language", "FPGA / VHDL",
    "Docker", "Git", "Arduino", "Raspberry Pi",
    "PCB Design", "IoT Basics", "Networking Basics",
    "Parallel Computing", "Operating Systems Internals", "RTOS",
  ],
  "S1 - Teknik Telekomunikasi": [
    "Python", "MATLAB / Simulink", "Signal Processing",
    "5G / LTE / Network Protocols", "GNU Radio", "Networking",
    "Cisco CCNA / Networking", "Software Defined Networking (SDN)",
    "Linux / Unix Administration", "Embedded Systems",
    "Antenna & RF Design", "Wireshark", "VoIP", "IoT Protocols",
  ],
  "S1 - Matematika": [
    "Python", "R", "MATLAB", "NumPy", "SciPy", "Pandas",
    "Machine Learning", "Scikit-learn", "SQL", "Excel / Google Sheets",
    "Statistical Modeling", "Optimization Algorithms",
    "LaTeX", "Git", "Tableau", "Power BI", "Mathematical Programming",
  ],
  "S1 - Statistika": [
    "R", "Python", "SPSS / SAS", "SQL", "Pandas", "NumPy",
    "Scikit-learn", "Excel / Google Sheets", "Tableau", "Power BI",
    "Machine Learning", "Statistical Modeling", "A/B Testing",
    "Time Series Analysis", "Bayesian Statistics", "Data Visualization",
    "BigQuery", "Git", "LaTeX",
  ],
  "S1 - Desain Komunikasi Visual (DKV)": [
    "Figma", "Adobe XD", "Adobe Photoshop", "Adobe Illustrator",
    "Adobe Premiere Pro", "Adobe After Effects", "InDesign",
    "Blender (basic)", "Cinema 4D", "UI/UX Design",
    "Wireframing & Prototyping", "Motion Graphics",
    "Branding & Visual Identity", "HTML/CSS (basic)", "User Research",
    "Accessibility Design", "Typography", "Color Theory",
  ],
  "S1 - Manajemen / Bisnis Digital": [
    "Data Analysis", "Excel / Google Sheets", "Power BI", "Tableau",
    "Python (basic)", "SQL (basic)", "Digital Marketing", "SEO / SEM",
    "Google Analytics", "CRM Tools (HubSpot, Salesforce)", "Project Management",
    "Agile / Scrum", "Business Process Modeling (BPMN)",
    "Financial Modeling", "Product Management", "OKR Frameworks",
    "E-commerce Strategy", "Content Strategy",
  ],
  "S1 - Ekonomi / Akuntansi": [
    "Excel / Google Sheets", "SQL", "Python", "Power BI", "Tableau",
    "SAP / Oracle", "Financial Modeling", "Business Analytics",
    "Statistical Modeling", "R (basic)", "ERPNext / Odoo",
    "Tax Compliance", "Payroll Management", "Audit & Internal Control",
    "Bloomberg Terminal (basic)", "Data Analysis", "Microsoft 365 Suite",
  ],
  "S1 - Fisika": [
    "Python", "MATLAB", "R", "C/C++", "NumPy", "SciPy",
    "Machine Learning", "Signal Processing", "Embedded Systems",
    "Arduino", "FPGA (basic)", "Data Visualization",
    "LaTeX", "Git", "Research Methodology", "Simulation Tools",
  ],
  "S1 - Lainnya": [
    "Python", "SQL", "Git", "Excel / Google Sheets", "JavaScript",
    "Linux (basic)", "Data Analysis", "Communication", "Project Management",
  ],

  // ── S2 ───────────────────────────────────────────────────────────────────
  "S2 - Teknik Informatika": [
    "Python", "Go (Golang)", "Rust", "Distributed Systems",
    "Microservices Architecture", "Kubernetes (K8s)", "Docker",
    "System Design", "Machine Learning", "TensorFlow", "PyTorch",
    "Kafka", "Redis", "PostgreSQL", "Cloud Architecture (AWS / GCP / Azure)",
    "Terraform", "CI/CD (Jenkins, GitHub Actions, GitLab CI)",
    "Research Methodology", "LaTeX", "Linux / Unix Administration",
  ],
  "S2 - Ilmu Komputer": [
    "Python", "C/C++", "Algorithms & Data Structures", "Machine Learning",
    "Deep Learning", "TensorFlow", "PyTorch", "Hugging Face",
    "Distributed Systems", "Parallel Computing", "Cryptography",
    "Formal Methods", "Computer Vision (OpenCV)", "NLP / LLM Fine-tuning",
    "Research Methodology", "LaTeX", "Git", "Docker",
  ],
  "S2 - Kecerdasan Buatan / AI": [
    "Python", "TensorFlow", "PyTorch", "Hugging Face", "LangChain",
    "OpenAI API", "RAG (Retrieval-Augmented Generation)",
    "Vector Database (Pinecone, Weaviate)", "NVIDIA CUDA / GPU Computing",
    "Computer Vision (OpenCV)", "NLP / LLM Fine-tuning",
    "Reinforcement Learning", "Knowledge Graphs", "MLflow",
    "Kubeflow", "Research Methodology", "LaTeX", "Prompt Engineering",
    "Multimodal AI", "Agentic AI Systems",
  ],
  "S2 - Sains Data / Data Science": [
    "Python", "R", "SQL", "Pandas", "NumPy", "Scikit-learn",
    "TensorFlow", "PyTorch", "XGBoost / LightGBM",
    "Apache Spark", "Apache Airflow", "Apache Kafka",
    "dbt (Data Build Tool)", "BigQuery", "Snowflake",
    "Tableau", "Looker / Looker Studio", "MLflow",
    "A/B Testing", "Causal Inference", "Bayesian Statistics",
    "Feature Engineering", "Research Methodology", "LaTeX",
  ],
  "S2 - Keamanan Siber": [
    "Penetration Testing", "Reverse Engineering", "Malware Analysis",
    "Network Security", "Web Application Security (OWASP)",
    "Cryptography", "Digital Forensics", "Incident Response",
    "Threat Hunting", "SIEM (Splunk, ELK Stack)", "Zero Trust Architecture",
    "Kubernetes Security", "AWS Security", "SOC Analyst Skills",
    "Python Scripting", "Bash Scripting", "Metasploit", "Burp Suite",
    "Research Methodology",
  ],
  "S2 - Sistem Informasi": [
    "SQL", "Python", "Power BI", "Tableau", "SAP Advanced",
    "Business Process Modeling (BPMN)", "Enterprise Architecture",
    "IT Governance (COBIT / ITIL)", "ERP Systems", "Data Warehousing",
    "Project Management", "Agile / Scrum", "Digital Transformation Strategy",
    "Cloud Computing", "Research Methodology",
  ],
  "S2 - Teknik Elektro": [
    "Python", "MATLAB / Simulink", "FPGA / VHDL",
    "Power Systems Analysis", "Embedded Systems", "Signal Processing",
    "IoT Protocols", "SCADA Systems", "Renewable Energy Systems",
    "PCB Design (Altium)", "LabVIEW", "Research Methodology", "LaTeX",
  ],
  "S2 - Manajemen Teknologi Informasi (MTI)": [
    "Data Analysis", "Power BI", "Tableau", "Python (basic)", "SQL",
    "IT Governance (COBIT / ITIL)", "Enterprise Architecture",
    "Digital Transformation Strategy", "Agile / Scrum",
    "Product Management", "Cloud Strategy", "Business Analytics",
    "Project Management", "OKR Frameworks", "Research Methodology",
  ],
  "S2 - Machine Learning / Data Analytics": [
    "Python", "R", "TensorFlow", "PyTorch", "Scikit-learn",
    "Hugging Face", "MLflow", "Kubeflow", "Apache Spark",
    "Feature Engineering", "A/B Testing", "Causal Inference",
    "Bayesian Statistics", "NLP / LLM Fine-tuning",
    "Computer Vision (OpenCV)", "SQL", "BigQuery",
    "Research Methodology", "LaTeX",
  ],
  "S2 - Bisnis / MBA Tech": [
    "Data Analysis", "Excel / Google Sheets", "Power BI", "SQL (basic)",
    "Python (basic)", "Product Management", "OKR Frameworks",
    "Digital Marketing", "Financial Modeling", "Business Analytics",
    "Agile / Scrum", "Project Management", "CRM Tools",
    "Digital Transformation Strategy", "Research Methodology",
  ],
  "S2 - Lainnya": [
    "Python", "SQL", "Data Analysis", "Git", "Research Methodology",
    "Project Management", "LaTeX", "Communication",
  ],

  // ── S3 ───────────────────────────────────────────────────────────────────
  "S3 - Teknik Informatika / Ilmu Komputer": [
    "Python", "C/C++", "Rust", "Go (Golang)", "Research Methodology",
    "Distributed Systems", "Parallel Computing", "Formal Methods",
    "Algorithms & Data Structures", "Compiler Design",
    "Operating Systems Internals", "TensorFlow", "PyTorch",
    "Docker", "Kubernetes (K8s)", "LaTeX", "Git", "Academic Writing",
  ],
  "S3 - Kecerdasan Buatan / Machine Learning": [
    "Python", "TensorFlow", "PyTorch", "Hugging Face", "LangChain",
    "NVIDIA CUDA / GPU Computing", "Reinforcement Learning",
    "Multimodal AI", "Agentic AI Systems", "NLP / LLM Fine-tuning",
    "Computer Vision (OpenCV)", "RAG (Retrieval-Augmented Generation)",
    "Vector Database (Pinecone, Weaviate)", "MLflow", "Kubeflow",
    "Research Methodology", "LaTeX", "Academic Writing",
    "Knowledge Graphs", "Causal Inference",
  ],
  "S3 - Sains Data / Komputasi": [
    "Python", "R", "Julia", "MATLAB", "Apache Spark", "Apache Kafka",
    "dbt (Data Build Tool)", "BigQuery", "Snowflake",
    "Bayesian Statistics", "Causal Inference", "Feature Engineering",
    "Statistical Modeling", "Simulation Tools", "LaTeX",
    "Research Methodology", "Academic Writing",
  ],
  "S3 - Keamanan Siber": [
    "Penetration Testing", "Reverse Engineering", "Malware Analysis",
    "Cryptography", "Zero Trust Architecture", "Formal Security Proofs",
    "Network Security", "Vulnerability Research", "Digital Forensics",
    "Python Scripting", "Bash Scripting", "C/C++", "Assembly Language",
    "Research Methodology", "LaTeX", "Academic Writing",
  ],
  "S3 - Sistem Terbenam / IoT": [
    "C/C++", "Python", "Embedded Systems", "FPGA / VHDL",
    "RTOS", "IoT Protocols (MQTT, Modbus)", "Sensor Integration",
    "Arduino", "Raspberry Pi", "Linux / Unix Administration",
    "Signal Processing", "Edge Computing", "Research Methodology", "LaTeX",
  ],
  "S3 - Jaringan & Komputasi Terdistribusi": [
    "Distributed Systems", "Kubernetes (K8s)", "Docker", "Kafka",
    "gRPC / Protocol Buffers", "Software Defined Networking (SDN)",
    "Network Security", "Rust", "Go (Golang)", "Python",
    "Cloud Architecture (AWS / GCP / Azure)", "Consensus Algorithms",
    "Blockchain Fundamentals", "Research Methodology", "LaTeX",
  ],
  "S3 - Lainnya": [
    "Python", "R", "Research Methodology", "LaTeX", "Statistical Modeling",
    "Data Analysis", "Academic Writing", "Git", "Docker",
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// PROPS INTERFACE
// ─────────────────────────────────────────────────────────────────────────────
interface PreChatFormProps {
  onComplete: (params: {
    student_name: string;
    class_code: string | null;
    education: string;
    major: string;
    skills: string[];
  }) => void;
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT
// ─────────────────────────────────────────────────────────────────────────────
export default function PreChatForm({ onComplete }: PreChatFormProps) {
  const [step, setStep] = useState<1 | 2 | 3>(1);

  // Step 1 state
  const [studentName, setStudentName] = useState("");
  const [hasClassCode, setHasClassCode] = useState(false);
  const [classCode, setClassCode] = useState("");
  const [classCodeError, setClassCodeError] = useState("");
  const [validatingCode, setValidatingCode] = useState(false);

  // Step 2 state
  const [education, setEducation] = useState("");
  const [major, setMajor] = useState("");
  const [customMajor, setCustomMajor] = useState("");

  // Step 3 state — selected skills
  const [selectedSkills, setSelectedSkills] = useState<string[]>([]);
  const [customSkill, setCustomSkill] = useState("");

  const nameIsValid = studentName.trim().length >= 2;
  const classCodeIsValid = !hasClassCode || classCode.trim().length >= 3;
  const majorValue = major === "custom" ? customMajor.trim() : major;

  const recommendedSkills: string[] =
    major && MAJOR_SKILLS_MAP[major] ? MAJOR_SKILLS_MAP[major] : [];

  const toggleSkill = (skill: string) => {
    setSelectedSkills(prev =>
      prev.includes(skill) ? prev.filter(s => s !== skill) : [...prev, skill]
    );
  };

  const addCustomSkill = () => {
    const trimmed = customSkill.trim();
    if (trimmed && !selectedSkills.includes(trimmed)) {
      setSelectedSkills(prev => [...prev, trimmed]);
      setCustomSkill("");
    }
  };

  const handleStep1Next = async () => {
    if (!nameIsValid) return;

    if (hasClassCode && classCode.trim()) {
      // Quick validate class code against backend
      setValidatingCode(true);
      setClassCodeError("");
      try {
        const res = await fetch(`${API_URL}/api/classes/validate?code=${encodeURIComponent(classCode.trim())}`);
        if (res.ok) {
          const json = await res.json();
          if (!json.valid) {
            setClassCodeError("Kode kelas tidak ditemukan. Pastikan kode yang dimasukkan benar.");
            setValidatingCode(false);
            return;
          }
        }
      } catch {
        // Network error — allow continue without blocking
      } finally {
        setValidatingCode(false);
      }
    }

    setStep(2);
  };

  const handleStep2Next = () => {
    if (!education || !majorValue) return;
    // Pre-select recommended skills for the chosen major
    if (recommendedSkills.length > 0 && selectedSkills.length === 0) {
      // Pre-check first 8 skills as defaults, rest are available to toggle
      setSelectedSkills(recommendedSkills.slice(0, 8));
    }
    setStep(3);
  };

  const handleFinish = () => {
    onComplete({
      student_name: studentName.trim(),
      class_code: hasClassCode && classCode.trim() ? classCode.trim() : null,
      education,
      major: majorValue,
      skills: selectedSkills,
    });
  };

  return (
    <div className="flex flex-col h-full justify-center items-center p-6 gap-0 bg-gradient-to-br from-slate-50 to-slate-100 overflow-y-auto">
      
      {/* Header */}
      <div className="text-center mb-6 max-w-md">
        <div className="inline-flex items-center gap-2 bg-slate-900 text-white px-4 py-2 rounded-full text-xs font-bold mb-4 shadow-md">
          <Sparkles className="w-3.5 h-3.5" />
          CareerPath AI
        </div>
        <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Mulai Perjalanan Karier IT-mu</h1>
        <p className="text-sm text-slate-500 mt-1 font-medium">Isi data berikut sebelum sesi konseling AI dimulai</p>
      </div>

      {/* Progress Steps Indicator */}
      <div className="flex items-center gap-2 mb-6">
        {[1, 2, 3].map((s) => (
          <React.Fragment key={s}>
            <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition-all duration-300 ${
              step === s ? "bg-slate-900 text-white shadow-md scale-110" :
              step > s ? "bg-emerald-500 text-white" :
              "bg-slate-200 text-slate-500"
            }`}>
              {step > s ? <CheckCircle className="w-4 h-4" /> : s}
            </div>
            {s < 3 && <div className={`w-12 h-0.5 transition-all duration-500 ${step > s ? "bg-emerald-400" : "bg-slate-200"}`} />}
          </React.Fragment>
        ))}
      </div>

      {/* Card */}
      <div className="w-full max-w-md bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">

        {/* ── STEP 1: Identitas ─────────────────────────────────────────── */}
        {step === 1 && (
          <div className="p-6 space-y-5">
            <div className="flex items-center gap-2 border-b border-slate-100 pb-4">
              <div className="w-8 h-8 rounded-full bg-slate-900 flex items-center justify-center">
                <Users className="w-4 h-4 text-white" />
              </div>
              <div>
                <h2 className="font-bold text-slate-900 text-sm">Identitas Siswa</h2>
                <p className="text-[10px] text-slate-400 font-semibold">Langkah 1 dari 3</p>
              </div>
            </div>

            {/* Name */}
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1.5">
                Nama Panggilan <span className="text-rose-500">*</span>
              </label>
              <input
                type="text"
                value={studentName}
                onChange={e => setStudentName(e.target.value)}
                placeholder="Contoh: Zaidan"
                className="w-full border border-slate-200 rounded-lg px-3 py-2.5 text-sm font-medium text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-slate-900 focus:border-slate-900 transition-all"
              />
            </div>

            {/* Class code toggle */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="text-xs font-bold text-slate-700">Saya memiliki Kode Kelas dari Guru BK</label>
                <button
                  onClick={() => { setHasClassCode(!hasClassCode); setClassCode(""); setClassCodeError(""); }}
                  className={`relative inline-flex h-5 w-9 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                    hasClassCode ? "bg-slate-900" : "bg-slate-200"
                  }`}
                >
                  <span className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${hasClassCode ? "translate-x-4" : "translate-x-0"}`} />
                </button>
              </div>

              {hasClassCode && (
                <div>
                  <div className="flex gap-2">
                    <div className="relative flex-1">
                      <Hash className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-400" />
                      <input
                        type="text"
                        value={classCode}
                        onChange={e => { setClassCode(e.target.value.toUpperCase()); setClassCodeError(""); }}
                        placeholder="XII-A-6-XXXX"
                        className="w-full border border-slate-200 rounded-lg pl-9 pr-3 py-2.5 text-sm font-bold text-slate-900 placeholder:text-slate-400 placeholder:font-normal focus:outline-none focus:ring-2 focus:ring-slate-900 focus:border-slate-900 transition-all tracking-widest uppercase"
                      />
                    </div>
                  </div>
                  {classCodeError && (
                    <p className="text-rose-500 text-[10px] font-semibold mt-1 flex items-center gap-1">⚠️ {classCodeError}</p>
                  )}
                  <p className="text-[10px] text-slate-400 mt-1">Kode kelas terdiri dari huruf kapital, angka, dan tanda hubung.</p>
                </div>
              )}
            </div>

            <button
              onClick={handleStep1Next}
              disabled={!nameIsValid || !classCodeIsValid || validatingCode}
              className="w-full bg-slate-900 hover:bg-slate-800 text-white font-bold py-2.5 rounded-lg text-sm flex items-center justify-center gap-2 transition-all disabled:opacity-40 disabled:cursor-not-allowed shadow-sm"
            >
              {validatingCode ? "Memvalidasi kode..." : "Lanjut"}
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* ── STEP 2: Pendidikan & Jurusan ──────────────────────────────── */}
        {step === 2 && (
          <div className="p-6 space-y-5">
            <div className="flex items-center gap-2 border-b border-slate-100 pb-4">
              <div className="w-8 h-8 rounded-full bg-slate-900 flex items-center justify-center">
                <GraduationCap className="w-4 h-4 text-white" />
              </div>
              <div>
                <h2 className="font-bold text-slate-900 text-sm">Latar Belakang Pendidikan</h2>
                <p className="text-[10px] text-slate-400 font-semibold">Langkah 2 dari 3</p>
              </div>
            </div>

            {/* Education Level */}
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-2">
                Jenjang Pendidikan Saat Ini <span className="text-rose-500">*</span>
              </label>
              <div className="grid grid-cols-1 gap-1.5">
                {EDUCATION_LEVELS.map(lvl => (
                  <button
                    key={lvl.value}
                    onClick={() => { setEducation(lvl.value); setMajor(""); }}
                    className={`flex items-center gap-3 px-3 py-2 rounded-lg border text-left transition-all text-sm font-semibold ${
                      education === lvl.value
                        ? "border-slate-900 bg-slate-900 text-white"
                        : "border-slate-200 bg-white text-slate-700 hover:border-slate-400 hover:bg-slate-50"
                    }`}
                  >
                    <span className="text-base">{lvl.icon}</span>
                    <span className="flex-1">{lvl.label}</span>
                    {education === lvl.value && <CheckCircle className="w-4 h-4 shrink-0" />}
                  </button>
                ))}
              </div>
            </div>

            {/* Major tags based on education */}
            {education && MAJOR_MAP[education] && (
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-2">
                  Jurusan / Program Studi <span className="text-rose-500">*</span>
                </label>
                <div className="flex flex-wrap gap-2 max-h-44 overflow-y-auto pr-1">
                  {MAJOR_MAP[education].map(m => (
                    <button
                      key={m.value}
                      onClick={() => setMajor(m.value)}
                      className={`px-3 py-1.5 rounded-full border text-xs font-bold transition-all ${
                        major === m.value
                          ? "bg-slate-900 border-slate-900 text-white"
                          : "bg-white border-slate-200 text-slate-600 hover:border-slate-400 hover:bg-slate-50"
                      }`}
                    >
                      {m.label}
                    </button>
                  ))}
                  <button
                    onClick={() => setMajor("custom")}
                    className={`px-3 py-1.5 rounded-full border text-xs font-bold transition-all ${
                      major === "custom"
                        ? "bg-slate-900 border-slate-900 text-white"
                        : "bg-white border-dashed border-slate-300 text-slate-500 hover:border-slate-400"
                    }`}
                  >
                    + Lainnya (ketik manual)
                  </button>
                </div>
                {major === "custom" && (
                  <input
                    type="text"
                    value={customMajor}
                    onChange={e => setCustomMajor(e.target.value)}
                    placeholder="Ketik jurusan Anda..."
                    className="mt-2 w-full border border-slate-200 rounded-lg px-3 py-2 text-sm font-medium text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-slate-900 transition-all"
                  />
                )}
              </div>
            )}

            <div className="flex gap-3">
              <button
                onClick={() => setStep(1)}
                className="flex items-center gap-1 px-4 py-2.5 rounded-lg border border-slate-200 text-slate-600 font-bold text-sm hover:bg-slate-50 transition-all"
              >
                <ChevronLeft className="w-4 h-4" />
                Kembali
              </button>
              <button
                onClick={handleStep2Next}
                disabled={!education || !majorValue}
                className="flex-1 bg-slate-900 hover:bg-slate-800 text-white font-bold py-2.5 rounded-lg text-sm flex items-center justify-center gap-2 transition-all disabled:opacity-40 disabled:cursor-not-allowed shadow-sm"
              >
                Lanjut
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* ── STEP 3: Pilih / Konfirmasi Keahlian ──────────────────────── */}
        {step === 3 && (
          <div className="p-6 space-y-5">
            <div className="flex items-center gap-2 border-b border-slate-100 pb-4">
              <div className="w-8 h-8 rounded-full bg-slate-900 flex items-center justify-center">
                <BookOpen className="w-4 h-4 text-white" />
              </div>
              <div>
                <h2 className="font-bold text-slate-900 text-sm">Keahlian & Minat Teknologi</h2>
                <p className="text-[10px] text-slate-400 font-semibold">Langkah 3 dari 3 — pilih yang sudah dikuasai atau ingin dipelajari</p>
              </div>
            </div>

            {/* Summary mini recap */}
            <div className="bg-slate-50 rounded-lg px-3 py-2 text-[10px] font-semibold text-slate-600 flex flex-wrap gap-2">
              <span>👤 <span className="text-slate-900">{studentName}</span></span>
              {hasClassCode && classCode && <span>🏷️ <span className="text-slate-900">{classCode}</span></span>}
              <span>🎓 <span className="text-slate-900">{education}</span></span>
              <span>📖 <span className="text-slate-900">{majorValue}</span></span>
            </div>

            {/* Recommended skills from major */}
            {recommendedSkills.length > 0 && (
              <div>
                <p className="text-xs font-bold text-slate-700 mb-2">
                  Rekomendasi skill cocok untuk jurusan <span className="text-emerald-600">{majorValue}</span>:
                </p>
                <div className="flex flex-wrap gap-1.5 max-h-52 overflow-y-auto pr-1">
                  {recommendedSkills.map(skill => (
                    <button
                      key={skill}
                      onClick={() => toggleSkill(skill)}
                      className={`px-2.5 py-1 rounded-full border text-[10px] font-bold transition-all ${
                        selectedSkills.includes(skill)
                          ? "bg-slate-900 border-slate-900 text-white"
                          : "bg-white border-slate-200 text-slate-600 hover:border-slate-400 hover:bg-slate-50"
                      }`}
                    >
                      {selectedSkills.includes(skill) ? "✓ " : ""}{skill}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Custom skill input */}
            <div>
              <p className="text-xs font-bold text-slate-700 mb-2">Tambah keahlian lain (opsional):</p>
              <div className="flex gap-2">
                <input
                  type="text"
                  value={customSkill}
                  onChange={e => setCustomSkill(e.target.value)}
                  onKeyDown={e => { if (e.key === "Enter") { e.preventDefault(); addCustomSkill(); }}}
                  placeholder="Ketik nama keahlian, tekan Enter..."
                  className="flex-1 border border-slate-200 rounded-lg px-3 py-2 text-xs font-medium text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-slate-900 transition-all"
                />
                <button
                  onClick={addCustomSkill}
                  className="px-3 py-2 bg-slate-100 hover:bg-slate-200 border border-slate-200 rounded-lg text-xs font-bold text-slate-700 transition-all"
                >
                  +
                </button>
              </div>
            </div>

            {/* Selected skills recap */}
            {selectedSkills.length > 0 && (
              <div className="bg-emerald-50 border border-emerald-100 rounded-lg p-3">
                <p className="text-[10px] font-bold text-emerald-700 mb-2">✅ {selectedSkills.length} keahlian dipilih:</p>
                <div className="flex flex-wrap gap-1">
                  {selectedSkills.map(s => (
                    <span
                      key={s}
                      onClick={() => toggleSkill(s)}
                      className="cursor-pointer px-2 py-0.5 bg-emerald-100 border border-emerald-200 rounded-full text-[10px] font-bold text-emerald-800 hover:bg-rose-100 hover:border-rose-200 hover:text-rose-700 transition-all"
                      title="Klik untuk hapus"
                    >
                      {s} ✕
                    </span>
                  ))}
                </div>
              </div>
            )}

            <div className="flex gap-3">
              <button
                onClick={() => setStep(2)}
                className="flex items-center gap-1 px-4 py-2.5 rounded-lg border border-slate-200 text-slate-600 font-bold text-sm hover:bg-slate-50 transition-all"
              >
                <ChevronLeft className="w-4 h-4" />
                Kembali
              </button>
              <button
                onClick={handleFinish}
                className="flex-1 bg-slate-900 hover:bg-slate-800 text-white font-bold py-2.5 rounded-lg text-sm flex items-center justify-center gap-2 transition-all shadow-sm"
              >
                <Sparkles className="w-4 h-4" />
                Mulai Konseling AI
              </button>
            </div>
          </div>
        )}
      </div>

      <p className="text-[10px] text-slate-400 mt-4 font-medium text-center max-w-xs">
        Data Anda digunakan secara lokal untuk mempersonalisasi rekomendasi karier IT. Tidak digunakan untuk keperluan lain.
      </p>
    </div>
  );
}
