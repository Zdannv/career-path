"use client";

import React, { useState, useEffect, useRef } from "react";
import { Send, Sparkles, Brain, Check, User, ArrowRight, RefreshCw, MapPin, Landmark, GraduationCap, Hash, X, CheckCircle2 } from "lucide-react";

interface Message {
  role: "assistant" | "user";
  content: string;
  isActionable?: boolean;
}

interface ExtractedParams {
  student_name: string | null;
  class_code: string | null;
  education: string | null;
  major: string | null;
  city: string | null;
  min_salary: number;
  skills: string[];
}

interface ChatOnboardingProps {
  onComplete: (data: any) => void;
}

export default function ChatOnboarding({ onComplete }: ChatOnboardingProps) {
  // ── Class-code quick-fill banner state ─────────────────────────────────
  const [showClassBanner, setShowClassBanner] = useState(false);
  const [bannerName, setBannerName] = useState("");
  const [bannerCode, setBannerCode] = useState("");
  const [bannerError, setBannerError] = useState("");
  const [bannerValidating, setBannerValidating] = useState(false);
  const [bannerSubmitted, setBannerSubmitted] = useState(false);

  // Permanent ref for banner-locked identity — never overwritten by LLM
  const bannerParamsRef = useRef<{ student_name: string | null; class_code: string | null }>({
    student_name: null,
    class_code: null
  });

  const [extractedParams, setExtractedParams] = useState<ExtractedParams>({
    student_name: null,
    class_code: null,
    education: null,
    major: null,
    city: null,
    min_salary: 0,
    skills: []
  });

  // Sync ref with extractedParams to avoid stale closures in setTimeout
  const extractedParamsRef = useRef<ExtractedParams>(extractedParams);
  useEffect(() => {
    extractedParamsRef.current = extractedParams;
  }, [extractedParams]);

  const handleBannerSubmit = async () => {
    if (!bannerName.trim() || !bannerCode.trim()) return;
    setBannerError("");
    setBannerValidating(true);
    try {
      const res = await fetch(
        `http://localhost:8000/api/classes/validate?code=${encodeURIComponent(bannerCode.trim().toUpperCase())}`
      );
      if (res.ok) {
        const json = await res.json();
        if (!json.valid) {
          setBannerError("Kode kelas tidak ditemukan. Periksa kembali kode dari Guru BK Anda.");
          setBannerValidating(false);
          return;
        }
      }
    } catch {
      // Network error — allow continue without blocking
    } finally {
      setBannerValidating(false);
    }

    const freshParams = {
      student_name: bannerName.trim(),
      class_code: bannerCode.trim().toUpperCase(),
      education: null,
      major: null,
      city: null,
      min_salary: 0,
      skills: []
    };

    // Lock name + class code permanently — also into bannerParamsRef (never overwritten by LLM)
    bannerParamsRef.current = {
      student_name: bannerName.trim(),
      class_code: bannerCode.trim().toUpperCase()
    };

    // Lock into extractedParams state & ref immediately
    setExtractedParams(freshParams);
    extractedParamsRef.current = freshParams;

    // Inject a natural opening into the chat so AI knows
    const joinMsg = `Nama saya ${bannerName.trim()} dan kode kelas saya adalah ${bannerCode.trim().toUpperCase()}`;
    const newMsg: Message = { role: "user", content: joinMsg };
    const updated = [...messages, newMsg];
    setMessages(updated);
    sendMessageToBackend(updated, freshParams);
    setBannerSubmitted(true);
    setShowClassBanner(false);
  };

  const [messages, setMessages] = useState<Message[]>([
    {
      role: "assistant",
      content: "Halo! Saya adalah CareerPath AI 👋 Saya akan membantu memetakan karir IT terbaik untuk Anda.\n\nJika Anda memiliki kode kelas dari Guru BK, klik tombol **\"Punya Kode Kelas\"** di atas. Jika tidak, langsung ceritakan saja nama panggilan Anda!"
    }
  ]);

  const [inputText, setInputText] = useState<string>("");
  const [isWaiting, setIsWaiting] = useState<boolean>(false);
  const [currentStep, setCurrentStep] = useState<number>(0); // 0: Chatting, 1: Loading Logs
  // Slider or inline widgets state
  const [salaryInput, setSalaryInput] = useState<number>(6000000);
  const [loadingLogs, setLoadingLogs] = useState<string[]>([]);
  const [suggestedSkills, setSuggestedSkills] = useState<string[]>([]);
  const [suggestedOptions, setSuggestedOptions] = useState<string[]>([]);


  const [selectedSkills, setSelectedSkills] = useState<string[]>([]);
  const [customSkill, setCustomSkill] = useState<string>("");
  const [activeState, setActiveState] = useState<string>("name_code");
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const popularSkills = [
    "Figma", "Python", "SQL", "HTML/CSS/JS", 
    "React/Next.js", "SEO/SEM", "Copywriting", 
    "Financial Modeling", "Excel / Google Sheets",
    "Docker", "Kubernetes (K8s)", "CI/CD (Jenkins, GitHub Actions, GitLab CI)",
    "Linux / Unix Administration", "Network Security", "Penetration Testing"
  ];

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, loadingLogs, isWaiting]);

  useEffect(() => {
    if (currentStep === 1) {
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
          // submit data will run final completion
        }
      }, 350);
      return () => clearInterval(interval);
    }
  }, [currentStep]);

  const sendMessageToBackend = async (nextMessages: Message[], overrideParams?: ExtractedParams) => {
    setIsWaiting(true);
    try {
      const response = await fetch("http://localhost:8000/api/chat-journey", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          messages: nextMessages
            .filter(m => !m.content.includes("Maaf, terjadi kesalahan:") && !m.content.includes("Gagal terhubung"))
            .map(m => ({ role: m.role, content: m.content })),
          current_params: overrideParams || extractedParamsRef.current
        })
      });

      if (!response.ok) {
        throw new Error("Gagal terhubung ke server CareerPath AI.");
      }

      const data = await response.json();
      
      if (data.extracted_params) {
        setExtractedParams(prev => {
          const isNullOrEmpty = (val: any) => {
            if (val === null || val === undefined) return true;
            const s = String(val).trim().toLowerCase();
            return s === "" || s === "null" || s === "none" || s === "tidak ada" || s === "undefined";
          };
          
          return {
            student_name: !isNullOrEmpty(data.extracted_params.student_name) ? data.extracted_params.student_name : prev.student_name,
            class_code: !isNullOrEmpty(data.extracted_params.class_code) ? data.extracted_params.class_code : prev.class_code,
            education: !isNullOrEmpty(data.extracted_params.education) ? data.extracted_params.education : prev.education,
            major: !isNullOrEmpty(data.extracted_params.major) ? data.extracted_params.major : prev.major,
            city: !isNullOrEmpty(data.extracted_params.city) ? data.extracted_params.city : prev.city,
            min_salary: (data.extracted_params.min_salary && data.extracted_params.min_salary > 0) ? data.extracted_params.min_salary : prev.min_salary,
            skills: data.extracted_params.skills && data.extracted_params.skills.length > 0
              ? data.extracted_params.skills
              : prev.skills
          };
        });
      }

      if (data.suggested_skills) {
        setSuggestedSkills(data.suggested_skills);
      } else {
        setSuggestedSkills([]);
      }

      if (data.suggested_options) {
        setSuggestedOptions(data.suggested_options);
      } else {
        setSuggestedOptions([]);
      }

      if (data.state) {
        setActiveState(data.state);
      }

      if (data.is_complete) {
        // Chat is finished, trigger the loading animation step and pass output
        setMessages(prev => [
          ...prev,
          { role: "assistant", content: data.message || "Analisis lengkap. Memproses rekomendasi..." }
        ]);
        setCurrentStep(1);
        setTimeout(async () => {
          const isNullOrEmpty = (val: any) => {
            if (val === null || val === undefined) return true;
            const s = String(val).trim().toLowerCase();
            return s === "" || s === "null" || s === "none" || s === "tidak ada" || s === "undefined";
          };

          // bannerParamsRef always wins for student_name + class_code
          const lockedName = bannerParamsRef.current.student_name
            || (!isNullOrEmpty(data.extracted_params?.student_name) ? data.extracted_params.student_name : null)
            || extractedParamsRef.current.student_name;

          const lockedCode = bannerParamsRef.current.class_code
            || (!isNullOrEmpty(data.extracted_params?.class_code) ? data.extracted_params.class_code : null)
            || extractedParamsRef.current.class_code;

          console.log("[ChatOnboarding] finalData student_name:", lockedName, "class_code:", lockedCode);

          const finalExtracted = {
            student_name: lockedName,
            class_code: lockedCode,
            education: !isNullOrEmpty(data.extracted_params?.education) ? data.extracted_params.education : extractedParamsRef.current.education,
            major: !isNullOrEmpty(data.extracted_params?.major) ? data.extracted_params.major : extractedParamsRef.current.major,
            city: !isNullOrEmpty(data.extracted_params?.city) ? data.extracted_params.city : extractedParamsRef.current.city,
            min_salary: (data.extracted_params?.min_salary && data.extracted_params.min_salary > 0) ? data.extracted_params.min_salary : extractedParamsRef.current.min_salary,
            skills: (data.extracted_params?.skills && data.extracted_params.skills.length > 0)
              ? data.extracted_params.skills
              : extractedParamsRef.current.skills
          };

          // ── Auto-save directly from ChatOnboarding when class code is present ──
          // This bypasses the Dashboard auto-save to avoid stale state issues.
          let preSavedId: string | null = null;
          if (lockedCode && data.journey_plan?.journey_plans?.length > 0) {
            const primaryPlan = data.journey_plan.journey_plans[0];
            const savePayload = {
              student_name: lockedName,
              class_code: lockedCode,
              education: finalExtracted.education,
              major: finalExtracted.major,
              city: finalExtracted.city,
              min_salary: finalExtracted.min_salary,
              skills: finalExtracted.skills,
              opportunity_overview: data.journey_plan.opportunity_overview || "",
              journey_plan: primaryPlan,
            };
            console.log("[ChatOnboarding] Saving with payload:", JSON.stringify(savePayload).slice(0, 300));
            try {
              const saveRes = await fetch("http://localhost:8000/api/save-journey", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(savePayload)
              });
              if (saveRes.ok) {
                const saveData = await saveRes.json();
                preSavedId = saveData.inserted_id ? String(saveData.inserted_id) : null;
                console.log("[ChatOnboarding] Pre-save SUCCESS, id:", preSavedId);
              } else {
                console.error("[ChatOnboarding] Pre-save FAILED status:", saveRes.status);
              }
            } catch (saveErr) {
              console.error("[ChatOnboarding] Pre-save ERROR:", saveErr);
            }
          }
          
          const finalData = {
            ...data,
            pre_saved_id: preSavedId,
            extracted_params: finalExtracted
          };
          onComplete(finalData);
        }, 3600);
      } else {
        // Chat is ongoing, show follow up question
        setMessages(prev => [
          ...prev,
          { role: "assistant", content: data.message || "Tolong berikan informasi lebih lanjut." }
        ]);
      }
    } catch (err: any) {
      setMessages(prev => [
        ...prev,
        { role: "assistant", content: `Maaf, terjadi kesalahan: ${err.message}. Silakan kirim ulang pesan Anda.` }
      ]);
    } finally {
      setIsWaiting(false);
    }
  };

  const handleSendText = (textToSend?: string) => {
    const text = textToSend || inputText;
    const clean = text.trim();
    if (!clean || isWaiting) return;

    const newMsg: Message = { role: "user", content: clean };
    const updated = [...messages, newMsg];
    setMessages(updated);
    setInputText("");
    sendMessageToBackend(updated);
  };

  const handleKeyPress = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      handleSendText();
    }
  };

  const handleToggleSkill = (skill: string) => {
    if (selectedSkills.includes(skill)) {
      setSelectedSkills(prev => prev.filter(s => s !== skill));
    } else {
      setSelectedSkills(prev => [...prev, skill]);
    }
  };

  const handleSendSelectedSkills = () => {
    if (selectedSkills.length === 0) return;
    const sentence = `Saya memiliki keahlian: ${selectedSkills.join(", ")}`;
    handleSendText(sentence);
    setSelectedSkills([]); // reset selection
  };

  // Helper selectors to make the chat experience interactive and fast
  const renderHelpers = () => {
    if (isWaiting || currentStep === 1) return null;

    if (activeState === "name_code") {
      return (
        <div className="p-4 bg-slate-50 border-t border-slate-200 space-y-3">
          <p className="text-xs text-slate-650 font-bold">Langkah Awal: Masukkan nama panggilan & kode kelas BK (jika ada) di kolom chat bawah.</p>
          <div className="flex gap-2">
            <button
              onClick={() => handleSendText("Nama saya Budi. Lewati kode kelas.")}
              className="flex-1 py-2 rounded bg-white hover:bg-slate-50 border border-slate-300 text-slate-700 font-bold text-xs flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
            >
              Gunakan Sesi Tamu (Mulai Cepat)
            </button>
          </div>
        </div>
      );
    }

    if (activeState === "education") {
      const options = suggestedOptions.length > 0 ? suggestedOptions : ["SMA/SMK Sederajat", "Diploma 3 (D3)", "Sarjana (S1)", "Magister (S2)", "Doktor (S3)"];
      return (
        <div className="flex flex-wrap gap-2 p-3 bg-slate-50 border-t border-slate-200">
          {options.map((edu) => (
            <button
              key={edu}
              onClick={() => handleSendText(edu)}
              className="px-3 py-1.5 rounded-full border border-slate-350 bg-white hover:border-slate-800 text-xs font-semibold text-slate-800 transition-colors cursor-pointer"
            >
              {edu}
            </button>
          ))}
        </div>
      );
    }

    if (activeState === "major") {
      const options = suggestedOptions.length > 0 ? suggestedOptions : ["Teknik Informatika", "Sistem Informasi", "Rekayasa Perangkat Lunak (RPL)", "Multimedia", "Teknik Elektro", "Sistem Komputer"];
      return (
        <div className="flex flex-wrap gap-2 p-3 bg-slate-50 border-t border-slate-200">
          {options.map((maj) => (
            <button
              key={maj}
              onClick={() => handleSendText(maj)}
              className="px-3 py-1.5 rounded-full border border-slate-350 bg-white hover:border-slate-800 text-xs font-semibold text-slate-800 transition-colors cursor-pointer"
            >
              {maj}
            </button>
          ))}
        </div>
      );
    }

    if (activeState === "city") {
      const options = suggestedOptions.length > 0 ? suggestedOptions : ["Jakarta", "Bandung", "Surabaya"];
      return (
        <div className="flex flex-wrap gap-2 p-3 bg-slate-50 border-t border-slate-200">
          {options.map((c) => (
            <button
              key={c}
              onClick={() => handleSendText(c)}
              className="px-3 py-1.5 rounded-full border border-slate-350 bg-white hover:border-slate-800 text-xs font-semibold text-slate-800 transition-colors cursor-pointer"
            >
              {c}
            </button>
          ))}
        </div>
      );
    }

    if (activeState === "min_salary") {
      return (
        <div className="p-4 bg-slate-50 border-t border-slate-200 space-y-3">
          <div className="flex justify-between items-center text-xs">
            <span className="text-slate-500 font-semibold">Tarik slider untuk mengatur gaji:</span>
            <span className="font-bold text-slate-900">Rp {salaryInput.toLocaleString('id-ID')}</span>
          </div>
          <input
            type="range"
            min={3000000}
            max={25000000}
            step={500000}
            value={salaryInput}
            onChange={(e) => setSalaryInput(parseInt(e.target.value))}
            className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-slate-900"
          />
          <div className="flex justify-between text-[10px] text-slate-400 font-medium">
            <span>Rp 3 Juta</span>
            <span>Rp 25 Juta</span>
          </div>
          <div className="flex gap-2">
            {[5000000, 8000000, 12000000].map(s => (
              <button
                key={s}
                onClick={() => setSalaryInput(s)}
                className="flex-1 py-1 rounded border border-slate-200 bg-white text-[10px] font-bold hover:bg-slate-50"
              >
                Rp {(s/1000000)} Jt
              </button>
            ))}
          </div>
          <button
            onClick={() => handleSendText(`Gaji minimal Rp ${salaryInput.toLocaleString('id-ID')}`)}
            className="w-full py-2 rounded bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs flex items-center justify-center gap-1 transition-colors cursor-pointer"
          >
            Konfirmasi Target Gaji <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>
      );
    }

    if (activeState === "confirmation") {
      return (
        <div className="p-4 bg-slate-50 border-t border-slate-200 space-y-3">
          <p className="text-xs text-slate-700 font-bold text-center">Apakah seluruh keahlian dan profil Anda di atas sudah cukup?</p>
          <div className="flex gap-3">
            <button
              onClick={() => handleSendText("Ya, cukup. Mulai analisis sekarang.")}
              className="flex-1 py-2.5 rounded bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
            >
              <Brain className="w-4 h-4" /> Ya, Mulai Analisis
            </button>
            <button
              onClick={() => handleSendText("Saya ingin menambahkan keahlian lain.")}
              className="flex-1 py-2.5 rounded border border-slate-350 bg-white hover:bg-slate-50 text-slate-700 font-bold text-xs flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
            >
              Tambah Keahlian Lain
            </button>
          </div>
        </div>
      );
    }

    // Default: Probing for skills (activeState === "skills")
    const displaySkills = suggestedSkills.length > 0 ? suggestedSkills : popularSkills;
    const titleText = suggestedSkills.length > 0 
      ? "Rekomendasi pilihan keahlian spesifik berdasarkan minat Anda (Pilih beberapa):"
      : "Pilih keahlian & minat Anda saat ini (Pilih beberapa):";

    return (
      <div className="p-4 bg-slate-50 border-t border-slate-200 space-y-4">
        <div>
          <p className="text-xs text-slate-500 font-semibold mb-2">{titleText}</p>
          <div className="flex flex-wrap gap-1.5 max-h-28 overflow-y-auto pb-1">
            {displaySkills.map(skill => {
              const hasConfirmed = extractedParams.skills.some(s => s.toLowerCase() === skill.toLowerCase());
              const isSelected = selectedSkills.includes(skill);
              return (
                <button
                  key={skill}
                  disabled={hasConfirmed}
                  onClick={() => handleToggleSkill(skill)}
                  className={`px-2.5 py-1.5 rounded-full text-[10px] font-semibold border transition-all cursor-pointer ${
                    hasConfirmed
                      ? "bg-slate-200 border-slate-300 text-slate-400 cursor-not-allowed"
                      : isSelected 
                      ? "bg-slate-900 border-slate-950 text-white" 
                      : "bg-white border-slate-200 text-slate-700 hover:bg-slate-100"
                  }`}
                >
                  {skill} {hasConfirmed ? "✓" : isSelected ? "✓" : ""}
                </button>
              );
            })}
          </div>
        </div>

        {/* Custom skills list display if any selected */}
        {selectedSkills.filter(s => !displaySkills.includes(s)).length > 0 && (
          <div className="space-y-1">
            <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Keahlian Tambahan Pilihan Anda:</p>
            <div className="flex flex-wrap gap-1.5">
              {selectedSkills.filter(s => !displaySkills.includes(s)).map(skill => (
                <span
                  key={skill}
                  onClick={() => handleToggleSkill(skill)}
                  className="px-2.5 py-1 rounded-full text-[10px] bg-slate-900 text-white font-semibold flex items-center gap-1 cursor-pointer hover:bg-rose-600 transition-colors shadow-sm"
                  title="Klik untuk menghapus"
                >
                  {skill} <span className="text-[8px] text-slate-300">✕</span>
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Add custom skill input */}
        <div className="flex gap-2">
          <input
            type="text"
            placeholder="Tambah keahlian lain (contoh: Figma, SQL)..."
            value={customSkill}
            onChange={(e) => setCustomSkill(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                e.preventDefault();
                const clean = String(customSkill).trim();
                if (clean && !selectedSkills.includes(clean)) {
                  setSelectedSkills(prev => [...prev, clean]);
                  setCustomSkill("");
                }
              }
            }}
            className="flex-1 bg-white border border-slate-200 rounded px-3 py-1.5 text-xs focus:outline-none focus:border-slate-400 text-slate-900"
          />
          <button
            onClick={() => {
              const clean = String(customSkill).trim();
              if (clean && !selectedSkills.includes(clean)) {
                setSelectedSkills(prev => [...prev, clean]);
                setCustomSkill("");
              }
            }}
            className="px-3 py-1.5 rounded bg-white border border-slate-200 text-xs font-semibold hover:bg-slate-50 text-slate-700 cursor-pointer"
          >
            Tambah
          </button>
        </div>

        {/* Confirm submit buttons */}
        <div className="flex gap-3 border-t border-slate-200 pt-3">
          <button
            onClick={handleSendSelectedSkills}
            disabled={selectedSkills.length === 0}
            className="flex-1 py-2.5 rounded bg-slate-900 hover:bg-slate-800 disabled:opacity-50 text-white font-bold text-xs flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
            title="Kirim keahlian yang baru Anda pilih di atas"
          >
            <Brain className="w-4 h-4" /> Kirim Keahlian Pilihan ({selectedSkills.length})
          </button>
          
          <button
            onClick={() => handleSendText("Sudah cukup, mulai analisis sekarang.")}
            className="flex-1 py-2.5 rounded border border-slate-350 bg-white hover:bg-slate-50 text-slate-700 font-bold text-xs flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
            title="Selesai menyebutkan keahlian dan langsung mulai analisis"
          >
            Ya, Cukup & Mulai Analisis
          </button>
        </div>
      </div>
    );
  };

  // Calculate completion progress
  const getProgressPct = () => {
    let pts = 0;
    if (extractedParams.education) pts += 20;

    const needsMajor = extractedParams.education && 
      (extractedParams.education.toLowerCase().includes("smk") || 
       extractedParams.education.toLowerCase().includes("d3") || 
       extractedParams.education.toLowerCase().includes("s1") || 
       extractedParams.education.toLowerCase().includes("s2") || 
       extractedParams.education.toLowerCase().includes("s3") || 
       extractedParams.education.toLowerCase().includes("sarjana") || 
       extractedParams.education.toLowerCase().includes("diploma") || 
       extractedParams.education.toLowerCase().includes("magister") || 
       extractedParams.education.toLowerCase().includes("doktor"));

    if (!needsMajor || extractedParams.major) pts += 20;
    if (extractedParams.city) pts += 20;
    if (extractedParams.min_salary > 0) pts += 20;
    if (extractedParams.skills.length > 0) pts += 20;

    return pts;
  };

  const progressPct = getProgressPct();


  return (
    <div className="flex-1 flex bg-white h-full overflow-hidden w-full">
      {/* Left Pane: Conversational Chat */}
      <div className="flex-1 flex flex-col h-full overflow-hidden relative">
        {/* Header */}
        <header className="flex items-center justify-between px-4 py-3 bg-white border-b border-slate-200 sticky top-0 z-10">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded bg-slate-900 flex items-center justify-center">
              <Sparkles className="w-4 h-4 text-white" />
            </div>
            <div>
              <h1 className="font-bold text-sm text-slate-900 leading-tight">CareerPath AI</h1>
              <p className="text-[10px] text-slate-500">Konseling Karier IT & Analisis Celah Keahlian</p>
            </div>
          </div>
          <div className="px-2 py-0.5 rounded bg-slate-100 text-[10px] font-semibold text-slate-600 border border-slate-200 flex items-center gap-1">
            <Brain className="w-3 h-3 text-slate-500" /> Active Interviewer
          </div>
        </header>

        {/* Class Code Quick-Fill Banner */}
        {!bannerSubmitted && (
          <div className="border-b border-slate-100 bg-gradient-to-r from-slate-50 to-white">
            {!showClassBanner ? (
              <div className="flex items-center justify-between px-4 py-2">
                <p className="text-[10px] text-slate-500 font-medium">
                  Siswa kelas Guru BK?
                </p>
                <button
                  onClick={() => setShowClassBanner(true)}
                  className="flex items-center gap-1.5 px-2.5 py-1 bg-slate-900 hover:bg-slate-800 text-white rounded text-[10px] font-bold transition-all cursor-pointer shadow-sm"
                >
                  <Hash className="w-3 h-3" />
                  Punya Kode Kelas
                </button>
              </div>
            ) : (
              <div className="px-4 py-3 space-y-2">
                <div className="flex items-center justify-between">
                  <p className="text-xs font-bold text-slate-700">Masukkan nama & kode kelas Anda</p>
                  <button onClick={() => { setShowClassBanner(false); setBannerError(""); }} className="text-slate-400 hover:text-slate-600 cursor-pointer">
                    <X className="w-3.5 h-3.5" />
                  </button>
                </div>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={bannerName}
                    onChange={e => setBannerName(e.target.value)}
                    placeholder="Nama panggilan"
                    className="flex-1 border border-slate-200 rounded px-2.5 py-1.5 text-xs font-medium text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-slate-900 transition-all"
                  />
                  <input
                    type="text"
                    value={bannerCode}
                    onChange={e => { setBannerCode(e.target.value.toUpperCase()); setBannerError(""); }}
                    placeholder="Kode kelas (mis. XII-A-6-XXXX)"
                    className="flex-1 border border-slate-200 rounded px-2.5 py-1.5 text-xs font-bold text-slate-900 placeholder:text-slate-400 placeholder:font-normal focus:outline-none focus:ring-2 focus:ring-slate-900 transition-all tracking-widest uppercase"
                  />
                  <button
                    onClick={handleBannerSubmit}
                    disabled={!bannerName.trim() || !bannerCode.trim() || bannerValidating}
                    className="px-3 py-1.5 bg-slate-900 hover:bg-slate-800 text-white rounded text-[10px] font-bold disabled:opacity-40 disabled:cursor-not-allowed transition-all cursor-pointer whitespace-nowrap"
                  >
                    {bannerValidating ? "Memvalidasi..." : "Konfirmasi"}
                  </button>
                </div>
                {bannerError && (
                  <p className="text-[10px] text-rose-600 font-semibold flex items-center gap-1">⚠️ {bannerError}</p>
                )}
              </div>
            )}
          </div>
        )}
        {bannerSubmitted && (
          <div className="flex items-center gap-2 px-4 py-2 bg-emerald-50 border-b border-emerald-100">
            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
            <p className="text-[10px] font-bold text-emerald-700">
              Kelas terdaftar! Data Anda akan otomatis tersimpan ke dashboard Guru BK.
            </p>
          </div>
        )}

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
                  : "bg-slate-100 border border-slate-200 text-slate-800 rounded-tl-none whitespace-pre-line"
              }`}>
                {msg.content}
              </div>
            </div>
          ))}

          {/* Typing indicator */}
          {isWaiting && (
            <div className="flex items-start gap-2.5">
              <div className="w-8 h-8 rounded flex items-center justify-center bg-slate-100 border border-slate-200 text-slate-700 shrink-0">
                <RefreshCw className="w-3.5 h-3.5 animate-spin" />
              </div>
              <div className="bg-slate-100 border border-slate-200 text-slate-500 rounded-lg rounded-tl-none px-3.5 py-2 text-xs italic">
                CareerPath AI sedang memikirkan pertanyaan berikutnya...
              </div>
            </div>
          )}

          {/* Loading Logs panel for calculation progress */}
          {currentStep === 1 && (
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

        {/* Helper Suggestion Buttons depending on context */}
        {renderHelpers()}

        {/* Input Form at the bottom */}
        {currentStep === 0 && (
          <div className="p-3 border-t border-slate-200 bg-white flex gap-2">
            <input
              type="text"
              disabled={isWaiting}
              placeholder={
                isWaiting 
                  ? "Mohon tunggu..." 
                  : "Ketik jawaban atau keahlian Anda di sini..."
              }
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              onKeyDown={handleKeyPress}
              className="flex-1 bg-white border border-slate-200 rounded px-3 py-2 text-xs focus:outline-none focus:border-slate-400 text-slate-900 disabled:bg-slate-50 disabled:text-slate-400"
            />
            <button
              onClick={() => handleSendText()}
              disabled={isWaiting || !inputText.trim()}
              className="px-4 rounded bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs flex items-center justify-center gap-1.5 transition-colors disabled:opacity-50 cursor-pointer shrink-0"
            >
              <Send className="w-3 h-3" /> Kirim
            </button>
          </div>
        )}
      </div>

      {/* Right Pane: Live Profile Summary Sidebar (Desktop Only) */}
      <div className="hidden lg:flex w-80 bg-slate-50 flex-col p-5 overflow-y-auto shrink-0 justify-between border-l border-slate-200">
        <div className="space-y-6">
          {/* Header */}
          <div className="border-b border-slate-200 pb-3">
            <h3 className="font-bold text-xs text-slate-400 uppercase tracking-wider">Ringkasan Profil Anda</h3>
            <p className="text-[10px] text-slate-500 font-medium">Data terekstraksi oleh AI dalam percakapan</p>
          </div>

          {/* Progress Bar */}
          <div className="space-y-1.5 bg-white p-3 rounded-lg border border-slate-200 shadow-sm">
            <div className="flex justify-between items-center text-[10px] font-bold text-slate-650">
              <span>Kelengkapan Asesmen</span>
              <span>{progressPct}%</span>
            </div>
            <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden border border-slate-200/60 shadow-inner">
              <div 
                className="h-full bg-slate-900 transition-all duration-550 ease-out rounded-full"
                style={{ width: `${progressPct}%` }}
              />
            </div>
          </div>

          {/* Parameters Grid */}
          <div className="space-y-3.5">
            {/* Education */}
            <div className="space-y-1">
              <span className="text-[9px] font-bold text-slate-400 uppercase tracking-wide">Pendidikan</span>
              <div className="text-xs font-bold text-slate-800 bg-white p-2.5 rounded-lg border border-slate-200 shadow-sm flex items-center gap-1.5 min-h-[36px]">
                <GraduationCap className="w-4 h-4 text-slate-500 shrink-0" />
                <span className="truncate">
                  {extractedParams.education || <span className="text-slate-400 font-medium italic">Belum diinput...</span>}
                  {extractedParams.major ? ` - ${extractedParams.major}` : ""}
                </span>
              </div>
            </div>

            {/* City */}
            <div className="space-y-1">
              <span className="text-[9px] font-bold text-slate-400 uppercase tracking-wide">Kota Kerja</span>
              <div className="text-xs font-bold text-slate-800 bg-white p-2.5 rounded-lg border border-slate-200 shadow-sm flex items-center gap-1.5 min-h-[36px]">
                <MapPin className="w-4 h-4 text-slate-500 shrink-0" />
                <span className="truncate">
                  {extractedParams.city || <span className="text-slate-400 font-medium italic">Belum diinput...</span>}
                </span>
              </div>
            </div>

            {/* Salary */}
            <div className="space-y-1">
              <span className="text-[9px] font-bold text-slate-400 uppercase tracking-wide">Target Gaji</span>
              <div className="text-xs font-bold text-slate-800 bg-white p-2.5 rounded-lg border border-slate-200 shadow-sm flex items-center gap-1.5 min-h-[36px]">
                <Landmark className="w-4 h-4 text-slate-500 shrink-0" />
                <span className="truncate">
                  {extractedParams.min_salary > 0 
                    ? `Rp ${extractedParams.min_salary.toLocaleString('id-ID')}` 
                    : <span className="text-slate-400 font-medium italic">Belum diinput...</span>
                  }
                </span>
              </div>
            </div>

            {/* Skills */}
            <div className="space-y-1">
              <span className="text-[9px] font-bold text-slate-400 uppercase tracking-wide">Keahlian ({extractedParams.skills.length})</span>
              <div className="bg-white p-2.5 rounded-lg border border-slate-200 shadow-sm flex flex-wrap gap-1 min-h-[60px] max-h-48 overflow-y-auto">
                {extractedParams.skills.length > 0 ? (
                  extractedParams.skills.map((s, idx) => (
                    <span 
                      key={idx}
                      className="px-2 py-0.5 rounded-full text-[9px] bg-slate-100 text-slate-700 border border-slate-200 font-bold transition-all hover:bg-slate-200"
                    >
                      {s}
                    </span>
                  ))
                ) : (
                  <span className="text-[10px] text-slate-400 font-medium italic p-0.5">Belum diinput...</span>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Footer info card */}
        <div className="mt-6 p-3 rounded-lg bg-white border border-slate-200 shadow-sm space-y-1">
          <p className="text-[10px] font-bold text-slate-900 flex items-center gap-1.5">
            <Sparkles className="w-3.5 h-3.5 text-slate-900" />
            Persona Wali Murid
          </p>
          <p className="text-[9px] text-slate-500 leading-normal font-medium">
            Sistem memproyeksikan target karier IT anak beserta kalkulator biaya perkuliahan secara detail.
          </p>
        </div>
      </div>
    </div>
  );
}
