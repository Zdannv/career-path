-- =============================================
-- MIGRATION: Education Majors & Suggested Skills
-- Run in Supabase SQL Editor
-- =============================================

-- Create table for education majors and suggested skills
CREATE TABLE IF NOT EXISTS education_majors (
  id SERIAL PRIMARY KEY,
  education_level TEXT NOT NULL,
  major_name TEXT NOT NULL,
  suggested_skills TEXT[] NOT NULL
);

-- Seed data for SMA/SMK Sederajat
INSERT INTO education_majors (education_level, major_name, suggested_skills) VALUES
  ('SMA/SMK Sederajat', 'SMA - MIPA (IPA)', ARRAY['Python', 'SQL', 'Data Analysis', 'Excel / Google Sheets']),
  ('SMA/SMK Sederajat', 'SMA - IPS', ARRAY['Excel / Google Sheets', 'Data Analysis', 'Digital Marketing', 'SEO / SEM']),
  ('SMA/SMK Sederajat', 'SMA - Bahasa & Sastra', ARRAY['Copywriting', 'Technical Writing', 'Content Strategy']),
  ('SMA/SMK Sederajat', 'SMK - Rekayasa Perangkat Lunak (RPL)', ARRAY['HTML/CSS', 'JavaScript', 'PHP', 'SQL', 'React.js', 'Laravel']),
  ('SMA/SMK Sederajat', 'SMK - Teknik Komputer & Jaringan (TKJ)', ARRAY['Linux / Unix Administration', 'Network Security', 'Computer Networks']),
  ('SMA/SMK Sederajat', 'SMK - Sistem Informatika, Jaringan & Aplikasi (SIJA)', ARRAY['Linux / Unix Administration', 'Docker', 'Network Security', 'CI/CD (Jenkins, GitHub Actions, GitLab CI)']),
  ('SMA/SMK Sederajat', 'SMK - Multimedia / Desain Komunikasi Visual (DKV)', ARRAY['UI/UX Design', 'Figma', 'Adobe Photoshop']),
  ('SMA/SMK Sederajat', 'SMK - Animasi', ARRAY['Blender', 'Adobe After Effects', '3D Modeling']),
  ('SMA/SMK Sederajat', 'SMK - Otomasi & Robotika Industri', ARRAY['Arduino / Microcontroller Programming', 'Raspberry Pi', 'Python', 'C/C++']),
  ('SMA/SMK Sederajat', 'SMK - Elektronika', ARRAY['Arduino / Microcontroller Programming', 'PCB Design (KiCad / Altium)', 'C/C++']),
  ('SMA/SMK Sederajat', 'SMK - Bisnis Daring & Pemasaran', ARRAY['Digital Marketing', 'SEO / SEM', 'Social Media Management', 'Copywriting']),
  ('SMA/SMK Sederajat', 'SMK - Akuntansi & Keuangan', ARRAY['Excel / Google Sheets', 'SQL', 'Power BI']),
  ('SMA/SMK Sederajat', 'SMK - Lainnya', ARRAY['Python', 'SQL', 'Excel / Google Sheets']),
  ('SMA/SMK Sederajat', 'SMA - Lainnya', ARRAY['Python', 'SQL', 'Excel / Google Sheets']);

-- Seed data for Diploma 3 (D3)
INSERT INTO education_majors (education_level, major_name, suggested_skills) VALUES
  ('Diploma 3 (D3)', 'D3 - Teknik Informatika', ARRAY['HTML/CSS', 'JavaScript', 'PHP', 'SQL', 'React.js', 'Laravel', 'Java']),
  ('Diploma 3 (D3)', 'D3 - Sistem Informasi', ARRAY['SQL', 'Python', 'Excel / Google Sheets', 'Power BI', 'Data Analysis']),
  ('Diploma 3 (D3)', 'D3 - Manajemen Informatika', ARRAY['SQL', 'Excel / Google Sheets', 'Power BI', 'Data Analysis', 'Project Management']),
  ('Diploma 3 (D3)', 'D3 - Teknik Komputer', ARRAY['C/C++', 'Python', 'Embedded Systems', 'Arduino', 'Linux / Unix Administration']),
  ('Diploma 3 (D3)', 'D3 - Jaringan Komputer', ARRAY['Linux / Unix Administration', 'Network Security', 'Computer Networks', 'Docker']),
  ('Diploma 3 (D3)', 'D3 - Keamanan Siber', ARRAY['Network Security', 'Penetration Testing', 'Web Application Security (OWASP)', 'Linux / Unix Administration']),
  ('Diploma 3 (D3)', 'D3 - Multimedia', ARRAY['UI/UX Design', 'Figma', 'Adobe Photoshop', 'Adobe After Effects']),
  ('Diploma 3 (D3)', 'D3 - Akuntansi', ARRAY['Excel / Google Sheets', 'SQL', 'Power BI']),
  ('Diploma 3 (D3)', 'D3 - Teknik Elektro', ARRAY['MATLAB', 'Embedded Systems', 'Arduino', 'PLC Programming']),
  ('Diploma 3 (D3)', 'D3 - Statistika', ARRAY['R', 'Python', 'SQL', 'Excel / Google Sheets', 'Data Analysis']),
  ('Diploma 3 (D3)', 'D3 - Lainnya', ARRAY['Python', 'SQL', 'Excel / Google Sheets']);

-- Seed data for Sarjana (S1/D4)
INSERT INTO education_majors (education_level, major_name, suggested_skills) VALUES
  ('Sarjana (S1/D4)', 'S1 - Teknik Informatika', ARRAY['Python', 'JavaScript', 'TypeScript', 'Java', 'Go (Golang)', 'SQL', 'React.js', 'Node.js', 'PostgreSQL', 'Docker']),
  ('Sarjana (S1/D4)', 'S1 - Ilmu Komputer', ARRAY['Python', 'C/C++', 'Java', 'Machine Learning', 'SQL', 'Git', 'Linux / Unix Administration']),
  ('Sarjana (S1/D4)', 'S1 - Sistem Informasi', ARRAY['SQL', 'Python', 'Power BI', 'Tableau', 'Data Analysis', 'Project Management', 'Figma']),
  ('Sarjana (S1/D4)', 'S1 - Teknik Elektro', ARRAY['Python', 'MATLAB', 'Embedded Systems', 'C/C++', 'Arduino', 'PCB Design (Altium / KiCad)']),
  ('Sarjana (S1/D4)', 'S1 - Teknik Komputer', ARRAY['C/C++', 'Python', 'Embedded Systems', 'Linux / Unix Administration', 'Arduino', 'Raspberry Pi']),
  ('Sarjana (S1/D4)', 'S1 - Sains Data / Data Science', ARRAY['Python', 'R', 'SQL', 'Pandas', 'NumPy', 'Scikit-learn', 'Tableau', 'Power BI']),
  ('Sarjana (S1/D4)', 'S1 - Kecerdasan Buatan / AI', ARRAY['Python', 'TensorFlow', 'PyTorch', 'Hugging Face', 'LangChain', 'OpenAI API', 'RAG (Retrieval-Augmented Generation)']),
  ('Sarjana (S1/D4)', 'S1 - Rekayasa Perangkat Lunak', ARRAY['JavaScript', 'TypeScript', 'Node.js', 'React.js', 'SQL', 'PostgreSQL', 'Docker', 'Git']),
  ('Sarjana (S1/D4)', 'S1 - Keamanan Siber / Cybersecurity', ARRAY['Network Security', 'Web Application Security (OWASP)', 'Penetration Testing', 'Linux / Unix Administration', 'Wireshark']),
  ('Sarjana (S1/D4)', 'S1 - Teknik Telekomunikasi', ARRAY['Python', 'MATLAB', 'Signal Processing', 'Networking', 'Wireshark']),
  ('Sarjana (S1/D4)', 'S1 - Matematika', ARRAY['Python', 'R', 'MATLAB', 'Pandas', 'Scikit-learn', 'Statistical Modeling']),
  ('Sarjana (S1/D4)', 'S1 - Statistika', ARRAY['R', 'Python', 'SQL', 'Excel / Google Sheets', 'Tableau', 'Power BI', 'Statistical Modeling']),
  ('Sarjana (S1/D4)', 'S1 - Manajemen / Bisnis Digital', ARRAY['Data Analysis', 'Excel / Google Sheets', 'Power BI', 'SEO / SEM', 'Google Analytics']),
  ('Sarjana (S1/D4)', 'S1 - Ekonomi / Akuntansi', ARRAY['Excel / Google Sheets', 'SQL', 'Python', 'Power BI', 'Financial Modeling']),
  ('Sarjana (S1/D4)', 'S1 - Desain Komunikasi Visual (DKV)', ARRAY['Figma', 'UI/UX Design', 'Adobe Photoshop', 'Adobe Illustrator']),
  ('Sarjana (S1/D4)', 'S1 - Fisika', ARRAY['Python', 'MATLAB', 'NumPy', 'SciPy', 'Data Visualization']),
  ('Sarjana (S1/D4)', 'S1 - Lainnya', ARRAY['Python', 'SQL', 'Excel / Google Sheets']);

-- Seed data for Magister (S2)
INSERT INTO education_majors (education_level, major_name, suggested_skills) VALUES
  ('Magister (S2)', 'S2 - Teknik Informatika', ARRAY['Python', 'Go (Golang)', 'Distributed Systems', 'Kubernetes (K8s)', 'Docker', 'Cloud Architecture (AWS / GCP / Azure)']),
  ('Magister (S2)', 'S2 - Ilmu Komputer', ARRAY['Python', 'C/C++', 'Machine Learning', 'Deep Learning', 'Distributed Systems']),
  ('Magister (S2)', 'S2 - Kecerdasan Buatan / AI', ARRAY['Python', 'TensorFlow', 'PyTorch', 'LangChain', 'OpenAI API', 'RAG (Retrieval-Augmented Generation)', 'Vector Database (Pinecone, Weaviate)']),
  ('Magister (S2)', 'S2 - Sains Data / Data Science', ARRAY['Python', 'R', 'SQL', 'Pandas', 'Apache Spark', 'Tableau', 'Power BI']),
  ('Magister (S2)', 'S2 - Keamanan Siber', ARRAY['Penetration Testing', 'Reverse Engineering', 'Malware Analysis', 'Network Security', 'Cryptography']),
  ('Magister (S2)', 'S2 - Sistem Informasi', ARRAY['SQL', 'Power BI', 'Tableau', 'IT Governance (COBIT / ITIL)', 'Project Management']),
  ('Magister (S2)', 'S2 - Teknik Elektro', ARRAY['Python', 'MATLAB', 'Embedded Systems', 'IoT Protocols']),
  ('Magister (S2)', 'S2 - Manajemen Teknologi Informasi (MTI)', ARRAY['IT Governance (COBIT / ITIL)', 'Enterprise Architecture', 'Project Management', 'Agile / Scrum']),
  ('Magister (S2)', 'S2 - Machine Learning / Data Analytics', ARRAY['Python', 'TensorFlow', 'PyTorch', 'Scikit-learn', 'Feature Engineering']),
  ('Magister (S2)', 'S2 - Bisnis / MBA Tech', ARRAY['Data Analysis', 'Power BI', 'Product Management', 'OKR Frameworks']),
  ('Magister (S2)', 'S2 - Lainnya', ARRAY['Python', 'SQL', 'Data Analysis']);

-- Seed data for Doktor (S3)
INSERT INTO education_majors (education_level, major_name, suggested_skills) VALUES
  ('Doktor (S3)', 'S3 - Teknik Informatika / Ilmu Komputer', ARRAY['Python', 'C/C++', 'Distributed Systems', 'Parallel Computing', 'Research Methodology']),
  ('Doktor (S3)', 'S3 - Kecerdasan Buatan / Machine Learning', ARRAY['Python', 'TensorFlow', 'PyTorch', 'Reinforcement Learning', 'NLP / LLM Fine-tuning']),
  ('Doktor (S3)', 'S3 - Sains Data / Komputasi', ARRAY['Python', 'R', 'Julia', 'Statistical Modeling', 'Research Methodology']),
  ('Doktor (S3)', 'S3 - Keamanan Siber', ARRAY['Cryptography', 'Zero Trust Architecture', 'Vulnerability Research']),
  ('Doktor (S3)', 'S3 - Sistem Terbenam / IoT', ARRAY['C/C++', 'Embedded Systems', 'IoT Protocols', 'Edge Computing']),
  ('Doktor (S3)', 'S3 - Jaringan & Komputasi Terdistribusi', ARRAY['Distributed Systems', 'Kubernetes (K8s)', 'gRPC / Protocol Buffers', 'Blockchain Fundamentals']),
  ('Doktor (S3)', 'S3 - Lainnya', ARRAY['Python', 'Research Methodology', 'LaTeX']);
