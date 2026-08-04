"use client";

import React, { useState, useEffect } from "react";
import { GraduationCap, MapPin, Landmark, Hammer, ArrowLeft, RefreshCw, Save, Star, Printer, Copy } from "lucide-react";
import OpportunityOverview from "./OpportunityOverview";
import JourneyTimeline from "./JourneyTimeline";
import CostForecaster from "./CostForecaster";

interface SkillItem {
  name: string;
  weight: number;
}

interface CareerRecommendation {
  career_id: number;
  career_name: string;
  description: string;
  target_city: string;
  salary_min: number;
  salary_max: number;
  match_score: number;
  skills: {
    required: SkillItem[];
    missing: SkillItem[];
    acquired: SkillItem[];
  };
}

interface TimelineItem {
  period: string;
  focus: string;
  skills_to_acquire: string[];
  action_steps: string[];
  milestones: string[];
}

interface IndividualJourneyPlan {
  career_id: number;
  career_name: string;
  timeline: TimelineItem[];
  budget_investment_guideline: string;
}

interface DashboardProps {
  data: {
    extracted_params: {
      student_name?: string;
      class_code?: string;
      education: string;
      major?: string;
      city: string;
      min_salary: number;
      skills: string[];
    };
    recommendations: CareerRecommendation[];
    journey_plan: {
      opportunity_overview: string;
      journey_plans: IndividualJourneyPlan[];
    };
  };
  onRestart: () => void;
  isReadOnly?: boolean;
}

export default function Dashboard({ data, onRestart, isReadOnly = false }: DashboardProps) {
  const { extracted_params, recommendations, journey_plan } = data;
  
  const defaultCareerId = recommendations.length > 0 ? recommendations[0].career_id : 0;
  const [selectedCareerId, setSelectedCareerId] = useState<number>(defaultCareerId);
   const [saving, setSaving] = useState<boolean>(false);
  const [savedId, setSavedId] = useState<string | null>(null);
  const [hasAutoSaved, setHasAutoSaved] = useState<boolean>(false);
  const [toast, setToast] = useState<{ show: boolean; title: string; message: string; type: "success" | "error" } | null>(null);
  const [costForecast, setCostForecast] = useState<{
    tuition_annual: number;
    housing_monthly: number;
    living_monthly: number;
    duration_years: number;
    total_cost: number;
  } | null>(null);

  // CSAT Rating State
  const [csatRating, setCsatRating] = useState<number | null>(null);
  const [hoveredRating, setHoveredRating] = useState<number | null>(null);
  const [csatSubmitted, setCsatSubmitted] = useState<boolean>(false);

  const handleCsatSubmit = async (score: number) => {
    setCsatRating(score);
    setCsatSubmitted(true);
    // Track via PostHog if available
    try {
      if (typeof window !== "undefined") {
        const posthogLib = require("posthog-js").default;
        posthogLib.capture("csat_rating_submitted", {
          score: score,
          student_name: extracted_params.student_name,
          education: extracted_params.education,
          major: extracted_params.major
        });
      }
    } catch (e) {
      console.warn("PostHog tracking failed:", e);
    }

    if (savedId) {
      try {
        await fetch(`http://localhost:8000/api/journey/${savedId}/rate`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ rating: score })
        });
      } catch (err) {
        console.error("Failed to save CSAT rating score to database:", err);
      }
    }
  };

  const getEduDuration = (edu?: string) => {
    if (!edu) return 4;
    const lower = edu.toLowerCase();
    if (lower.includes("s3") || lower.includes("doktor")) return 3;
    if (lower.includes("s2") || lower.includes("magister")) return 2;
    if (lower.includes("s1") || lower.includes("sarjana") || lower.includes("d4")) return 4;
    if (lower.includes("d3") || lower.includes("diploma 3")) return 3;
    if (lower.includes("d1") || lower.includes("d2") || lower.includes("diploma 1") || lower.includes("diploma 2")) return 2;
    if (lower.includes("smk") || lower.includes("sma") || lower.includes("sederajat")) return 3;
    return 4;
  };

  const activePlan = journey_plan.journey_plans.find(
    (p) => p.career_id === selectedCareerId
  );

  // Auto-dismiss toast banner after 4 seconds
  useEffect(() => {
    if (toast && toast.show) {
      const timer = setTimeout(() => {
        setToast(null);
      }, 4000);
      return () => clearTimeout(timer);
    }
  }, [toast]);

  // Auto-save journey plan to database on dashboard mount ONLY if student has entered a class code
  useEffect(() => {
    const hasClassCode = extracted_params?.class_code && 
      String(extracted_params.class_code).trim().toLowerCase() !== "null" &&
      String(extracted_params.class_code).trim() !== "";

    if (!isReadOnly && !savedId && activePlan && !hasAutoSaved && !saving && hasClassCode) {
      setHasAutoSaved(true);
      handleSaveJourney();
    }
  }, [isReadOnly, savedId, activePlan, hasAutoSaved, saving, extracted_params?.class_code]);

  const handleSaveJourney = async () => {
    if (!activePlan) return;
    setSaving(true);
    setToast(null);

    const defaultCostForecast = costForecast || {
      tuition_annual: 12000000,
      housing_monthly: 1000000,
      living_monthly: 1500000,
      duration_years: activePlan.timeline?.length || 4,
      total_cost: (12000000 + (1000000 * 12) + (1500000 * 12)) * (activePlan.timeline?.length || 4)
    };

    const payload = {
      student_name: extracted_params.student_name,
      class_code: extracted_params.class_code,
      education: extracted_params.education,
      major: extracted_params.major,
      city: extracted_params.city,
      min_salary: extracted_params.min_salary,
      skills: extracted_params.skills,
      opportunity_overview: journey_plan.opportunity_overview,
      journey_plan: activePlan,
      cost_forecast: defaultCostForecast,
      csat_rating: csatRating
    };

    try {
      const response = await fetch("http://localhost:8000/api/save-journey", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || "Gagal menyimpan rencana karier ke database.");
      }

      const data = await response.json();
      setSavedId(data.inserted_id);

      setToast({
        show: true,
        title: "Berhasil Disimpan!",
        message: "Rencana Karier Anda telah tersimpan. Gunakan link bagikan di atas dasbor.",
        type: "success"
      });
    } catch (error: any) {
      setToast({
        show: true,
        title: "Gagal Menyimpan",
        message: error.message || "Koneksi database terputus. Rencana tidak dapat disimpan.",
        type: "error"
      });
    } finally {
      setSaving(false);
    }
  };

  const formatIDR = (num: number) => {
    return new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      maximumFractionDigits: 0
    }).format(num);
  };

  return (
    <div className="flex flex-col h-full bg-white text-slate-900 overflow-y-auto border-b border-slate-200 relative">
      
      {/* Toast Alert Banner */}
      {toast && toast.show && (
        <div className={`fixed top-4 right-4 z-50 p-4 rounded-lg shadow-lg border text-sm max-w-sm transition-all duration-300 ${
          toast.type === "success" 
            ? "bg-emerald-50 border-emerald-200 text-emerald-800" 
            : "bg-rose-50 border-rose-200 text-rose-800"
        }`}>
          <div className="flex justify-between items-start gap-4">
            <div>
              <p className="font-bold">{toast.title}</p>
              <p className="text-xs mt-0.5">{toast.message}</p>
            </div>
            <button 
              onClick={() => setToast(null)} 
              className="text-xs font-semibold hover:opacity-75 focus:outline-none cursor-pointer"
            >
              ✕
            </button>
          </div>
        </div>
      )}

      {/* Mini Profile Banner */}
      <div className="px-4 py-4 bg-slate-50 border-b border-slate-200 space-y-3">
        <div className="flex justify-between items-center max-w-7xl mx-auto w-full">
          <div>
            <h1 className="font-bold text-base md:text-lg text-slate-900 tracking-tight">Dasbor Perjalanan Karier Anda</h1>
            <p className="text-[10px] text-slate-500 font-semibold">Hasil Pencocokan & Peta Jalan Karier Multi-Tahun</p>
          </div>
          <div className="flex items-center gap-2">
            {activePlan && !isReadOnly && (
              <button
                onClick={savedId ? () => {
                  navigator.clipboard.writeText(`${window.location.origin}/student/journey/${savedId}`);
                  setToast({ show: true, title: "Link Disalin!", message: "Link perjalanan karier berhasil disalin ke clipboard.", type: "success" });
                } : handleSaveJourney}
                disabled={saving}
                className="px-3 py-1.5 rounded border border-slate-900 bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs flex items-center gap-1 transition-colors shadow-sm disabled:opacity-50 cursor-pointer"
              >
                {savedId ? (
                  <>
                    <Copy className="w-3.5 h-3.5" />
                    {"Bagikan Link"}
                  </>
                ) : (
                  <>
                    <Save className="w-3.5 h-3.5" />
                    {saving ? "Menyimpan otomatis..." : "Simpan & Bagikan"}
                  </>
                )}
              </button>
            )}
            <button
              onClick={() => window.print()}
              className="p-2 rounded border border-slate-200 bg-white hover:bg-slate-50 hover:border-slate-300 text-slate-500 hover:text-slate-800 transition-colors cursor-pointer flex items-center justify-center shadow-sm"
              title="Cetak Rencana"
            >
              <Printer className="w-3.5 h-3.5" />
            </button>
            <button
              onClick={onRestart}
              className="p-2 rounded border border-slate-200 bg-white hover:bg-slate-50 hover:border-slate-300 text-slate-500 hover:text-slate-800 transition-colors cursor-pointer flex items-center justify-center shadow-sm"
              title="Ulangi Asesmen"
            >
              <RefreshCw className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        {/* Profile Info Tags */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-2 text-[10px] font-bold text-slate-700 max-w-7xl mx-auto w-full">
          <div className="px-3 py-2 rounded bg-white border border-slate-200 flex items-center gap-1.5 shadow-sm">
            <GraduationCap className="w-3.5 h-3.5 text-slate-500 shrink-0" />
            <span className="truncate">
              {extracted_params.education || "Sarjana (S1)"}
              {extracted_params.major ? ` - ${extracted_params.major}` : ""}
            </span>
          </div>
          <div className="px-3 py-2 rounded bg-white border border-slate-200 flex items-center gap-1.5 shadow-sm">
            <MapPin className="w-3.5 h-3.5 text-slate-500 shrink-0" />
            <span className="truncate">{extracted_params.city || "Jakarta"}</span>
          </div>
          <div className="px-3 py-2 rounded bg-white border border-slate-200 flex items-center gap-1.5 shadow-sm">
            <Landmark className="w-3.5 h-3.5 text-slate-500 shrink-0" />
            <span className="truncate">Min. {extracted_params.min_salary ? formatIDR(extracted_params.min_salary) : "Rp 0"}</span>
          </div>
          <div className="px-3 py-2 rounded bg-white border border-slate-200 flex items-center gap-1.5 shadow-sm">
            <Hammer className="w-3.5 h-3.5 text-slate-500 shrink-0" />
            <span className="truncate">{extracted_params.skills.length > 0 ? extracted_params.skills.join(", ") : "Tidak ada keahlian diinput"}</span>
          </div>
        </div>
      </div>

      {/* Shareable Link Banner if saved */}
      {savedId && (
        <div className="bg-emerald-50 border-b border-emerald-250 py-2.5 px-4 animate-pulse">
          <div className="max-w-7xl mx-auto flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2.5 text-xs">
            <div className="font-bold text-emerald-800">
              🎉 Rencana karier tersimpan! Gunakan link ini untuk membagikan atau membuka kembali:
            </div>
            <div className="flex items-center gap-2 w-full sm:w-auto">
              <input
                type="text"
                readOnly
                value={`${window.location.origin}/student/journey/${savedId}`}
                className="bg-white border border-emerald-200 rounded px-2.5 py-1 font-mono text-[10px] text-slate-700 flex-1 sm:w-80 select-all focus:outline-none"
              />
              <button
                onClick={() => {
                  navigator.clipboard.writeText(`${window.location.origin}/student/journey/${savedId}`);
                  alert("Link berhasil disalin ke clipboard!");
                }}
                className="px-3 py-1 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded cursor-pointer transition-colors shadow-sm text-[10px]"
              >
                Salin Link
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Responsive Grid layout for Dashboard Content */}
      <div className="flex-1 max-w-7xl mx-auto w-full">
        {recommendations.length > 0 ? (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 p-4 lg:p-6">
            {/* Left side: Recommendations */}
            <div className="lg:col-span-5 space-y-4">
              <OpportunityOverview
                recommendations={recommendations}
                selectedCareerId={selectedCareerId}
                onSelectCareer={setSelectedCareerId}
              />
            </div>
            
            {/* Right side: Selected Timeline Roadmap */}
            <div className="lg:col-span-7 space-y-4">
              <JourneyTimeline
                overviewText={journey_plan.opportunity_overview}
                plan={activePlan}
              />
            </div>

            {/* Cost Forecaster Section */}
            <div className="lg:col-span-12 mt-2">
              <CostForecaster
                defaultDurationYears={getEduDuration(extracted_params.education)}
                onChangeForecast={setCostForecast}
              />
            </div>
          </div>
        ) : (
          <div className="p-8 text-center bg-white flex flex-col items-center justify-center min-h-[50vh]">
            <p className="text-sm text-slate-500 mb-4 font-semibold">Tidak ada pekerjaan yang sesuai dengan kriteria Anda.</p>
            <button
              onClick={onRestart}
              className="px-4 py-2 rounded bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs flex items-center gap-1.5 transition-colors shadow-sm"
            >
              <ArrowLeft className="w-3.5 h-3.5" /> Ubah Kriteria
            </button>
          </div>
        )}

        {/* CSAT Rating Component */}
        <div className="p-4 lg:p-6 border-t border-slate-200 mt-8 max-w-7xl mx-auto w-full">
          <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-sm text-center space-y-4 max-w-xl mx-auto">
            <h3 className="font-bold text-sm text-slate-900">Seberapa terbantu kamu dengan rencana ini?</h3>
            {!csatSubmitted ? (
              <div className="flex justify-center items-center gap-2">
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    onClick={() => handleCsatSubmit(star)}
                    onMouseEnter={() => setHoveredRating(star)}
                    onMouseLeave={() => setHoveredRating(null)}
                    className="p-1 cursor-pointer transition-transform transform hover:scale-125 focus:outline-none"
                    title={`Beri rating ${star} dari 5`}
                  >
                    <Star
                      className={`w-8 h-8 transition-colors ${
                        star <= (hoveredRating ?? csatRating ?? 0)
                          ? "text-amber-400 fill-amber-400"
                          : "text-slate-350"
                      }`}
                    />
                  </button>
                ))}
              </div>
            ) : (
              <div className="space-y-1 py-2 animate-pulse">
                <p className="text-xs text-emerald-600 font-bold">Terima kasih atas penilaian Anda!</p>
                <p className="text-[10px] text-slate-500 font-medium">Feedback Anda membantu kami terus menyempurnakan rekomendasi karir IT CareerPath AI.</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
