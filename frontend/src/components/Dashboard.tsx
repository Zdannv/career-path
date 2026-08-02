"use client";

import React, { useState, useEffect } from "react";
import { GraduationCap, MapPin, Landmark, Hammer, ArrowLeft, RefreshCw, Save } from "lucide-react";
import OpportunityOverview from "./OpportunityOverview";
import JourneyTimeline from "./JourneyTimeline";

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
      education: string;
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
}

export default function Dashboard({ data, onRestart }: DashboardProps) {
  const { extracted_params, recommendations, journey_plan } = data;
  
  const defaultCareerId = recommendations.length > 0 ? recommendations[0].career_id : 0;
  const [selectedCareerId, setSelectedCareerId] = useState<number>(defaultCareerId);
  const [saving, setSaving] = useState<boolean>(false);
  const [toast, setToast] = useState<{ show: boolean; title: string; message: string; type: "success" | "error" } | null>(null);

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

  const handleSaveJourney = async () => {
    if (!activePlan) return;
    setSaving(true);
    setToast(null);

    const payload = {
      education: extracted_params.education,
      city: extracted_params.city,
      min_salary: extracted_params.min_salary,
      skills: extracted_params.skills,
      opportunity_overview: journey_plan.opportunity_overview,
      journey_plan: activePlan
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

      setToast({
        show: true,
        title: "Berhasil!",
        message: "Rencana Karier Anda telah tersimpan di sistem.",
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
            {activePlan && (
              <button
                onClick={handleSaveJourney}
                disabled={saving}
                className="px-3 py-1.5 rounded border border-slate-900 bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs flex items-center gap-1 transition-colors shadow-sm disabled:opacity-50 cursor-pointer"
              >
                <Save className="w-3.5 h-3.5" />
                {saving ? "Menyimpan..." : "Simpan Rencana Karier"}
              </button>
            )}
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
            <span className="truncate">{extracted_params.education || "Sarjana (S1)"}</span>
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
      </div>
    </div>
  );
}
