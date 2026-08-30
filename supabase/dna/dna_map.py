# Pemetaan 54 atribut Career DNA -> elemen O*NET.
# Kunci = kode atribut. Nilai = daftar (file, nama elemen).
# File: SIA=Specific Interest Areas, WA=Work Activities, ES=Essential Skills,
#       TS=Transferable Skills, AB=Abilities, WS=Work Styles, WC=Work Context

INTEREST = {
 "INT_TEKNOLOGI":   [("SIA","Information Technology"),("SIA","Engineering"),("SIA","Mechanics/Electronics"),
                     ("SIA","Construction/Woodwork"),("SIA","Transportation/Machine Operation"),("SIA","Physical/Manual Labor")],
 "INT_KESEHATAN":   [("SIA","Health Care Service"),("SIA","Medical Science"),("SIA","Athletics")],
 "INT_BISNIS":      [("SIA","Business Initiatives"),("SIA","Management/Administration"),("SIA","Sales"),
                     ("SIA","Marketing/Advertising"),("SIA","Public Speaking"),("SIA","Office Work")],
 "INT_PENDIDIKAN":  [("SIA","Teaching/Education")],
 "INT_KREATIVITAS": [("SIA","Visual Arts"),("SIA","Applied Arts and Design"),("SIA","Performing Arts"),
                     ("SIA","Music"),("SIA","Creative Writing"),("SIA","Media"),("SIA","Culinary Art")],
 "INT_KEUANGAN":    [("SIA","Finance"),("SIA","Accounting")],
 "INT_RISET":       [("SIA","Physical Science"),("SIA","Life Science"),("SIA","Mathematics/Statistics"),
                     ("SIA","Social Science"),("SIA","Humanities")],
 "INT_SOSIAL":      [("SIA","Social Service"),("SIA","Personal Service"),("SIA","Professional Advising"),
                     ("SIA","Human Resources"),("SIA","Religious Activities")],
 "INT_HUKUM":       [("SIA","Law"),("SIA","Politics"),("SIA","Protective Service")],
 "INT_LINGKUNGAN":  [("SIA","Nature/Outdoors"),("SIA","Agriculture"),("SIA","Animal Service")],
}

ACTIVITY = {
 "ACT_ANALISA":     [("WA","Analyzing Data or Information"),("WA","Getting Information"),
                     ("WA","Identifying Objects, Actions, and Events")],
 "ACT_PROBLEM":     [("WA","Making Decisions and Solving Problems"),
                     ("WA","Judging the Qualities of Objects, Services, or People")],
 "ACT_DESAIN":      [("WA","Thinking Creatively"),
                     ("WA","Drafting, Laying Out, and Specifying Technical Devices, Parts, and Equipment")],
 # Tiga GWA kerja fisik (Handling and Moving Objects, Performing General Physical
 # Activities, Operating Vehicles) SENGAJA tidak dipetakan: taksonomi Activity DNA
 # belum punya kategori kerja manual/lapangan. Kalau dipaksa masuk sini, profesi
 # knowledge work seperti Software Developer justru tenggelam. Lihat catatan gap.
 "ACT_MEMBANGUN":   [("WA","Working with Computers"),
                     ("WA","Drafting, Laying Out, and Specifying Technical Devices, Parts, and Equipment"),
                     ("WA","Repairing and Maintaining Electronic Equipment"),
                     ("WA","Repairing and Maintaining Mechanical Equipment"),
                     ("WA","Controlling Machines and Processes")],
 "ACT_MEMBANTU":    [("WA","Assisting and Caring for Others"),("WA","Performing for or Working Directly with the Public")],
 "ACT_MENGAJAR":    [("WA","Training and Teaching Others"),("WA","Coaching and Developing Others")],
 "ACT_KOMUNIKASI":  [("WA","Communicating with Supervisors, Peers, or Subordinates"),
                     ("WA","Communicating with People Outside the Organization"),
                     ("WA","Establishing and Maintaining Interpersonal Relationships"),
                     ("WA","Interpreting the Meaning of Information for Others")],
 "ACT_MEMIMPIN":    [("WA","Coordinating the Work and Activities of Others"),("WA","Developing and Building Teams"),
                     ("WA","Guiding, Directing, and Motivating Subordinates"),("WA","Staffing Organizational Units"),
                     ("WA","Monitoring and Controlling Resources"),("WA","Developing Objectives and Strategies")],
 "ACT_MENJUAL":     [("WA","Selling or Influencing Others"),("WA","Resolving Conflicts and Negotiating with Others"),
                     ("WA","Providing Consultation and Advice to Others")],
 "ACT_OPERASIONAL": [("WA","Processing Information"),("WA","Documenting/Recording Information"),
                     ("WA","Performing Administrative Activities"),("WA","Scheduling Work and Activities"),
                     ("WA","Organizing, Planning, and Prioritizing Work")],
 "ACT_RISET":       [("WA","Updating and Using Relevant Knowledge"),
                     ("WA","Estimating the Quantifiable Characteristics of Products, Events, or Information")],
 "ACT_QC":          [("WA","Inspecting Equipment, Structures, or Materials"),
                     ("WA","Monitoring Processes, Materials, or Surroundings"),
                     ("WA","Evaluating Information to Determine Compliance with Standards")],
}

SKILL = {
 "SKL_KOMUNIKASI":  [("ES","Speaking"),("ES","Active Listening"),("ES","Writing"),("AB","Oral Expression")],
 "SKL_LOGIKA":      [("TS","Systems Analysis"),("TS","Operations Analysis"),("AB","Deductive Reasoning"),("AB","Inductive Reasoning")],
 "SKL_KREATIVITAS": [("AB","Fluency of Ideas"),("AB","Originality"),("TS","Technology Design"),("WS","Innovation")],
 "SKL_EMPATI":      [("TS","Social Perceptiveness"),("TS","Service Orientation"),("WS","Empathy")],
 "SKL_PERENCANAAN": [("TS","Time Management"),("TS","Management of Material Resources"),("TS","Management of Personnel Resources")],
 "SKL_KEPEMIMPINAN":[("TS","Management of Personnel Resources"),("TS","Coordination"),("WS","Leadership Orientation")],
 "SKL_KETELITIAN":  [("WS","Attention to Detail"),("TS","Quality Control Analysis"),("AB","Perceptual Speed")],
 "SKL_NUMERIK":     [("ES","Mathematics"),("AB","Mathematical Reasoning"),("AB","Number Facility")],
 "SKL_KOLABORASI":  [("TS","Coordination"),("WS","Cooperation"),("WS","Social Orientation")],
 "SKL_ADAPTABILITAS":[("WS","Adaptability"),("AB","Category Flexibility"),("WS","Tolerance for Ambiguity")],
 "SKL_KEPUTUSAN":   [("TS","Judgment and Decision Making"),("AB","Deductive Reasoning")],
 "SKL_CRITICAL":    [("ES","Critical Thinking"),("TS","Complex Problem Solving")],
 "SKL_BELAJAR":     [("ES","Active Learning"),("ES","Learning Strategies"),("WS","Intellectual Curiosity")],
 "SKL_NEGOSIASI":   [("TS","Negotiation"),("TS","Persuasion")],
 "SKL_PRESENTASI":  [("ES","Speaking"),("WC","Public Speaking"),("AB","Oral Expression")],
 "SKL_WAKTU":       [("TS","Time Management"),("WS","Dependability")],
}

ENVIRONMENT = {
 # Hanya sinyal yang MEMBEDAKAN. Elemen yang dimiliki hampir semua profesi
 # (Face-to-Face Discussions, Importance of Being Exact) sengaja dibuang:
 # kehadirannya menaikkan semua lingkungan sekaligus, jadi tidak informatif.
 "ENV_KANTOR":    [("WC","Indoors, Environmentally Controlled"),("WC","Spend Time Sitting"),("WC","E-Mail")],
 "ENV_ONSITE":    [("WC","Outdoors, Exposed to All Weather Conditions"),("WC","Indoors, Not Environmentally Controlled"),
                   ("WC","Spend Time Standing"),("WC","Spend Time Walking or Running")],
 "ENV_LAB":       [("ES","Science"),("WC","Exposed to Radiation"),("WC","Exposed to Contaminants")],
 "ENV_RS":        [("WC","Exposed to Disease or Infections"),("WA","Assisting and Caring for Others")],
 "ENV_SEKOLAH":   [("WA","Training and Teaching Others"),("WC","Public Speaking")],
 "ENV_PABRIK":    [("WC","Exposed to Hazardous Equipment"),("WC","Exposed to Sounds, Noise Levels that are Distracting or Uncomfortable"),
                   ("WA","Controlling Machines and Processes"),("WC","Pace Determined by Speed of Equipment"),
                   ("WC","Spend Time Making Repetitive Motions")],
 # ENV_REMOTE dan ENV_HYBRID tidak ada di O*NET -- dihitung lewat aturan, lihat derive2.py
}

WORKSTYLE = {
 "WSY_MANDIRI":     [("WS","Initiative"),("WS","Self-Confidence")],
 "WSY_KOLABORATIF": [("WS","Cooperation"),("WS","Social Orientation")],
 "WSY_TERSTRUKTUR": [("WS","Dependability"),("WS","Attention to Detail"),("WS","Cautiousness")],
 "WSY_DINAMIS":     [("WS","Innovation"),("WS","Tolerance for Ambiguity")],
 "WSY_BERUBAH":     [("WS","Adaptability"),("WS","Stress Tolerance")],
 "WSY_DETAIL":      [("WS","Attention to Detail")],
 "WSY_TARGET":      [("WS","Achievement Orientation"),("WS","Perseverance")],
 "WSY_PELAYANAN":   [("WS","Empathy"),("WS","Sincerity")],
}
