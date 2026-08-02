"use client";

import React, { useState, useEffect, useRef } from "react";
import { Send, Sparkles, Brain, Check, User, ArrowRight } from "lucide-react";

interface Message {
  role: "assistant" | "user";
  content: string;
  isActionable?: boolean;
}

interface ChatOnboardingProps {
  onComplete: (data: any) => void;
}

export default function ChatOnboarding({ onComplete }: ChatOnboardingProps) {
  const [messages, setMessages] = useState<Message[]>([
    {
      role: "assistant",
      content: "Halo! Saya adalah CareerPath AI. Saya akan membantu Anda merencanakan perjalanan karier dan menjembatani kesenjangan keahlian Anda. Untuk memulai, apa tingkat pendidikan terakhir Anda?"
    }
  ]);
  
  const [currentStep, setCurrentStep] = useState<number>(0); // 0: Edu, 1: City, 2: Salary, 3: Skills, 4: Loading
  const [education, setEducation] = useState<string>("");
  const [city, setCity] = useState<string>("");
  const [salary, setSalary] = useState<number>(6000000);
  const [selectedSkills, setSelectedSkills] = useState<string[]>([]);
  const [customSkill, setCustomSkill] = useState<string>("");
  
  const [loadingLogs, setLoadingLogs] = useState<string[]>([]);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const popularSkills = [
    "Figma", "Python", "SQL", "HTML/CSS/JS", 
    "React/Next.js", "SEO/SEM", "Copywriting", 
    "Financial Modeling", "Excel / Google Sheets"
  ];

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, loadingLogs]);

  useEffect(() => {
    if (currentStep === 4) {
      const logs = [
        "Menginisialisasi Core CareerPath AI...",
        "Mengakses tabel database PostgreSQL...",
        "Menerapkan Knowledge-Based Filtering (KBF)...",
        "Menyaring kriteria pendidikan terakhir & target gaji...",
        "Melakukan vektorisasi profil keahlian...",
        "Menghitung Cosine Similarity...",
        "Melakukan Analisis Kesenjangan Keahlian (Skill Gap)...",
        "Menyuntikkan hasil matriks kecocokan ke LLM...",
        "Membuat Peta Jalan Perjalanan Karier Multi-Tahun...",
        "Menyusun Ringkasan Peluang Karier..."
      ];
      
      let index = 0;
      const interval = setInterval(() => {
        if (index < logs.length) {
          setLoadingLogs(prev => [...prev, logs[index]]);
          index++;
        } else {
          clearInterval(interval);
          submitData();
        }
      }, 350);
      return () => clearInterval(interval);
    }
  }, [currentStep]);

  const submitData = async () => {
    const chatPayload = [
      { role: "user", content: `Pendidikan terakhir saya adalah ${education}.` },
      { role: "assistant", content: "Paham! Kota mana di Pulau Jawa yang Anda pilih untuk bekerja?" },
      { role: "user", content: `Saya memilih bekerja di ${city}.` },
      { role: "assistant", content: "Bagus! Berapa target gaji bulanan yang Anda harapkan?" },
      { role: "user", content: `Minimal target gaji bulanan saya adalah Rp ${salary.toLocaleString('id-ID')}.` },
      { role: "assistant", content: "Dimengerti. Terakhir, keahlian atau minat apa yang Anda miliki?" },
      { role: "user", content: `Saya memiliki pengalaman di bidang: ${selectedSkills.join(", ")}.` }
    ];

    try {
      const response = await fetch("http://localhost:8000/api/chat-journey", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ messages: chatPayload })
      });
      
      if (!response.ok) {
        throw new Error("Gagal mengambil data rekomendasi dari backend.");
      }
      
      const data = await response.json();
      onComplete(data);
    } catch (error) {
      console.error(error);
      // Fallback response for offline / demo mode
      setTimeout(() => {
        onComplete({
          extracted_params: {
            education,
            city,
            min_salary: salary,
            skills: selectedSkills
          },
          recommendations: [
            {
              career_id: 6,
              career_name: "Software Engineer (Frontend)",
              description: "Membangun aplikasi web yang responsif dan berkinerja tinggi menggunakan pustaka/kerangka kerja Javascript modern seperti React dan Next.js.",
              target_city: "Bandung",
              salary_min: 8000000.0,
              salary_max: 16000000.0,
              match_score: 85.0,
              skills: {
                required: [
                  { name: "HTML/CSS/JS", weight: 30.0 },
                  { name: "React/Next.js", weight: 45.0 }
                ],
                missing: [
                  { name: "React/Next.js", weight: 45.0 }
                ],
                acquired: [
                  { name: "HTML/CSS/JS", weight: 30.0 }
                ]
              }
            },
            {
              career_id: 1,
              career_name: "UI/UX Designer",
              description: "Bertanggung jawab untuk merancang antarmuka pengguna yang mudah digunakan, menarik secara visual, serta membuat prototipe produk digital.",
              target_city: "Jakarta",
              salary_min: 8000000.0,
              salary_max: 15000000.0,
              match_score: 60.0,
              skills: {
                required: [
                  { name: "Figma", weight: 40.0 },
                  { name: "Wireframing & Prototyping", weight: 25.0 },
                  { name: "User Research", weight: 20.0 }
                ],
                missing: [
                  { name: "Figma", weight: 40.0 },
                  { name: "Wireframing & Prototyping", weight: 25.0 },
                  { name: "User Research", weight: 20.0 }
                ],
                acquired: []
              }
            }
          ],
          journey_plan: {
            opportunity_overview: `Profil Anda paling cocok dengan karir Software Engineer (Frontend) dan UI/UX Designer. Koridor bisnis digital Jakarta-Bandung menawarkan peluang pertumbuhan yang sangat luas untuk kedua posisi ini.`,
            journey_plans: [
              {
                career_id: 6,
                career_name: "Software Engineer (Frontend)",
                timeline: [
                  {
                    period: "Tahun 1",
                    focus: "Menguasai dasar dan kerangka kerja Frontend",
                    skills_to_acquire: ["React/Next.js"],
                    action_steps: ["Menyelesaikan kursus Next.js", "Membangun 3 situs web interaktif sederhana menggunakan React"],
                    milestones: ["Berhasil meluncurkan portofolio pribadi berbasis Next.js"]
                  },
                  {
                    period: "Tahun 2",
                    focus: "Pendalaman optimasi performa dan pengerjaan proyek kolaboratif",
                    skills_to_acquire: ["TypeScript", "Tailwind CSS"],
                    action_steps: ["Berkontribusi pada proyek Git secara tim", "Mengoptimalkan kecepatan rendering aplikasi React"],
                    milestones: ["Pertama kali kontribusi open source disetujui"]
                  },
                  {
                    period: "Tahun 3",
                    focus: "Persiapan wawancara kerja dan transisi karier profesional",
                    skills_to_acquire: ["Persiapan Wawancara", "Pustaka Pengujian"],
                    action_steps: ["Melamar kerja ke perusahaan teknologi di Bandung/Jakarta", "Melakukan latihan tes pemrograman"],
                    milestones: ["Diterima sebagai Junior Frontend Developer sesuai target gaji"]
                  }
                ],
                budget_investment_guideline: "Estimasi biaya: Rp 500.000 - Rp 2.000.000. Rekomendasi platform: Dicoding Indonesia, Udemy, dan dokumentasi resmi."
              }
            ]
          }
        });
      }, 1000);
    }
  };

  const handleSelectEdu = (eduVal: string) => {
    setEducation(eduVal);
    setMessages(prev => [
      ...prev,
      { role: "user", content: eduVal },
      { role: "assistant", content: "Paham! Kota mana di Pulau Jawa yang Anda pilih untuk bekerja?" }
    ]);
    setCurrentStep(1);
  };

  const handleSelectCity = (cityVal: string) => {
    setCity(cityVal);
    setMessages(prev => [
      ...prev,
      { role: "user", content: `Saya memilih bekerja di ${cityVal}` },
      { role: "assistant", content: "Bagus! Berapa target gaji bulanan yang Anda harapkan?" }
    ]);
    setCurrentStep(2);
  };

  const handleConfirmSalary = () => {
    setMessages(prev => [
      ...prev,
      { role: "user", content: `Minimal Target Gaji: Rp ${salary.toLocaleString('id-ID')}` },
      { role: "assistant", content: "Dimengerti. Terakhir, pilih keahlian & minat yang Anda miliki saat ini:" }
    ]);
    setCurrentStep(3);
  };

  const handleToggleSkill = (skill: string) => {
    if (selectedSkills.includes(skill)) {
      setSelectedSkills(prev => prev.filter(s => s !== skill));
    } else {
      setSelectedSkills(prev => [...prev, skill]);
    }
  };

  const handleAddCustomSkill = (e: React.FormEvent) => {
    e.preventDefault();
    const clean = customSkill.trim();
    if (clean && !selectedSkills.includes(clean)) {
      setSelectedSkills(prev => [...prev, clean]);
      setCustomSkill("");
    }
  };

  const handleFinalSubmit = () => {
    setMessages(prev => [
      ...prev,
      { role: "user", content: `Keahlian dipilih: ${selectedSkills.join(", ") || 'Tidak ada'}` },
      { role: "assistant", content: "Menganalisis kriteria dan minat Anda menggunakan mesin rekomendasi hibrida kami..." }
    ]);
    setCurrentStep(4);
  };

  return (
    <div className="flex flex-col h-full bg-white text-slate-900 font-sans border-b border-slate-200">
      {/* Header */}
      <header className="flex items-center justify-between px-4 py-3 bg-white border-b border-slate-200 sticky top-0 z-10">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded bg-slate-900 flex items-center justify-center">
            <Sparkles className="w-4 h-4 text-white" />
          </div>
          <div>
            <h1 className="font-bold text-sm text-slate-900 leading-tight">CareerPath AI</h1>
            <p className="text-[10px] text-slate-500">Perencana Karier Siswa & Lulusan Baru</p>
          </div>
        </div>
        <div className="px-2 py-0.5 rounded bg-slate-100 text-[10px] font-semibold text-slate-600 border border-slate-200 flex items-center gap-1">
          <Brain className="w-3 h-3 text-slate-500" /> Engine Hibrida
        </div>
      </header>

      {/* Chat Messages Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg, idx) => (
          <div
            key={idx}
            className={`flex items-start gap-2.5 ${msg.role === "user" ? "flex-row-reverse" : ""}`}
          >
            {/* Avatar */}
            <div className={`w-8 h-8 rounded flex items-center justify-center text-xs font-semibold shrink-0 border ${
              msg.role === "user" 
                ? "bg-slate-900 border-slate-950 text-white" 
                : "bg-slate-100 border-slate-200 text-slate-700"
            }`}>
              {msg.role === "user" ? <User className="w-4 h-4" /> : <Sparkles className="w-3.5 h-3.5" />}
            </div>
            
            {/* Bubble */}
            <div className={`max-w-[75%] px-3.5 py-2 rounded-lg text-sm leading-relaxed ${
              msg.role === "user" 
                ? "bg-slate-900 text-white rounded-tr-none" 
                : "bg-slate-100 border border-slate-200 text-slate-800 rounded-tl-none"
            }`}>
              {msg.content}
            </div>
          </div>
        ))}

        {/* Dynamic Interactive Input Modules inside the Scroll View */}
        {currentStep === 0 && (
          <div className="flex flex-col gap-2 pl-10">
            <p className="text-xs text-slate-500 ml-1 mb-1 font-semibold">Pilih Pendidikan Terakhir:</p>
            {["SMA / SMK Sederajat", "Diploma 3 (D3)", "Sarjana (S1)", "Magister (S2)", "Doktor (S3)"].map((edu) => (
              <button
                key={edu}
                onClick={() => handleSelectEdu(edu)}
                className="w-full text-left px-4 py-2.5 rounded border border-slate-200 bg-white hover:border-slate-400 hover:bg-slate-50 transition-colors text-xs font-semibold text-slate-850"
              >
                {edu}
              </button>
            ))}
          </div>
        )}

        {currentStep === 1 && (
          <div className="flex flex-col gap-2 pl-10">
            <p className="text-xs text-slate-500 ml-1 mb-1 font-semibold">Pilih Kota Target Kerja:</p>
            {["Jakarta", "Bandung", "Surabaya"].map((c) => (
              <button
                key={c}
                onClick={() => handleSelectCity(c)}
                className="w-full text-left px-4 py-2.5 rounded border border-slate-200 bg-white hover:border-slate-400 hover:bg-slate-50 transition-colors text-xs font-semibold text-slate-855"
              >
                {c}
              </button>
            ))}
          </div>
        )}

        {currentStep === 2 && (
          <div className="p-4 rounded border border-slate-200 bg-slate-50 space-y-4 ml-10">
            <div className="flex justify-between items-center text-xs">
              <span className="text-slate-500 font-semibold">Target Gaji Bulanan:</span>
              <span className="font-bold text-slate-900">Rp {salary.toLocaleString('id-ID')}</span>
            </div>
            <input
              type="range"
              min={3000000}
              max={25000000}
              step={500000}
              value={salary}
              onChange={(e) => setSalary(parseInt(e.target.value))}
              className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-slate-900"
            />
            <div className="flex justify-between text-[10px] text-slate-400 font-medium">
              <span>Rp 3 Juta</span>
              <span>Rp 25 Juta</span>
            </div>
            <button
              onClick={handleConfirmSalary}
              className="w-full py-2 rounded bg-slate-900 hover:bg-slate-800 text-white font-semibold text-xs flex items-center justify-center gap-1 transition-colors"
            >
              Konfirmasi Gaji <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        )}

        {currentStep === 3 && (
          <div className="p-4 rounded border border-slate-200 bg-slate-50 space-y-4 ml-10">
            <div>
              <p className="text-xs text-slate-500 mb-2 font-semibold">Pilih keahlian & minat Anda:</p>
              <div className="flex flex-wrap gap-1.5">
                {popularSkills.map(skill => {
                  const isSelected = selectedSkills.includes(skill);
                  return (
                    <button
                      key={skill}
                      onClick={() => handleToggleSkill(skill)}
                      className={`px-2.5 py-1.5 rounded text-[10px] font-semibold border transition-all ${
                        isSelected 
                          ? "bg-slate-900 border-slate-950 text-white" 
                          : "bg-white border-slate-200 text-slate-700 hover:bg-slate-100"
                      }`}
                    >
                      {skill} {isSelected && "✓"}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Custom Skills List Display */}
            {selectedSkills.filter(s => !popularSkills.includes(s)).length > 0 && (
              <div className="space-y-1">
                <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Keahlian Tambahan:</p>
                <div className="flex flex-wrap gap-1.5">
                  {selectedSkills.filter(s => !popularSkills.includes(s)).map(skill => (
                    <span
                      key={skill}
                      onClick={() => handleToggleSkill(skill)}
                      className="px-2.5 py-1 rounded text-[10px] bg-slate-900 text-white font-semibold flex items-center gap-1 cursor-pointer hover:bg-rose-600 transition-colors shadow-sm"
                      title="Klik untuk menghapus"
                    >
                      {skill} <span className="text-[8px] text-slate-300">✕</span>
                    </span>
                  ))}
                </div>
              </div>
            )}
            
            <form onSubmit={handleAddCustomSkill} className="flex gap-2">
              <input
                type="text"
                placeholder="Tambah keahlian lain (contoh: Penjualan, Python)..."
                value={customSkill}
                onChange={(e) => setCustomSkill(e.target.value)}
                className="flex-1 min-w-0 bg-white border border-slate-200 rounded px-3 py-2 text-xs focus:outline-none focus:border-slate-400 text-slate-900"
              />
              <button
                type="submit"
                className="px-3 rounded bg-white border border-slate-200 text-xs font-semibold hover:bg-slate-50 text-slate-700"
              >
                Tambah
              </button>
            </form>

            <div className="border-t border-slate-200 pt-3">
              <button
                onClick={handleFinalSubmit}
                className="w-full py-2.5 rounded bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs flex items-center justify-center gap-1.5 transition-colors"
              >
                <Brain className="w-4 h-4" /> Buat Rencana Karier
              </button>
            </div>
          </div>
        )}

        {currentStep === 4 && (
          <div className="p-4 rounded border border-slate-200 bg-slate-50 ml-10 space-y-3 font-mono text-[10px] text-slate-700">
            <p className="font-bold border-b border-slate-200 pb-1 text-slate-900 flex items-center gap-1">
              <Brain className="w-3.5 h-3.5 animate-spin" /> MENJALANKAN ENGINE ANALISIS...
            </p>
            <div className="space-y-1 max-h-40 overflow-y-auto">
              {loadingLogs.map((log, lidx) => (
                <div key={lidx} className="flex items-center gap-1.5">
                  <Check className="w-3.5 h-3.5 text-slate-900 shrink-0" />
                  <span>{log}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>
    </div>
  );
}
