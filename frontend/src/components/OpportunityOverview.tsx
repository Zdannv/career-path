"use client";

import React from "react";
import { Briefcase, Landmark, CheckCircle, AlertCircle, TrendingUp } from "lucide-react";

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

interface OpportunityOverviewProps {
  recommendations: CareerRecommendation[];
  selectedCareerId: number;
  onSelectCareer: (id: number) => void;
}

export default function OpportunityOverview({
  recommendations,
  selectedCareerId,
  onSelectCareer
}: OpportunityOverviewProps) {
  
  const formatIDR = (num: number) => {
    return new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      maximumFractionDigits: 0
    }).format(num);
  };

  return (
    <div className="space-y-4 px-4 py-2 bg-white">
      <div className="flex items-center gap-1.5 border-b border-slate-100 pb-2">
        <TrendingUp className="w-4 h-4 text-slate-700" />
        <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500">Karier yang Cocok (Mesin Pencocok)</h2>
      </div>

      {/* Career Horizontal List / Cards Selector */}
      <div className="space-y-3">
        {recommendations.map((rec) => {
          const isSelected = rec.career_id === selectedCareerId;
          const totalRequiredWeight = rec.skills.required.reduce((sum, s) => sum + s.weight, 0) || 1;
          const acquiredWeight = rec.skills.acquired.reduce((sum, s) => sum + s.weight, 0);
          const readinessPct = Math.round((acquiredWeight / totalRequiredWeight) * 100);

          return (
            <div
              key={rec.career_id}
              onClick={() => onSelectCareer(rec.career_id)}
              className={`p-4 rounded-lg border text-left transition-colors cursor-pointer ${
                isSelected 
                  ? "border-slate-900 bg-slate-50/60 shadow-sm" 
                  : "border-slate-200 hover:border-slate-300 bg-white"
              }`}
            >
              <div className="flex justify-between items-start mb-2">
                <div>
                  <h3 className="font-bold text-sm text-slate-900 flex items-center gap-1.5">
                    <Briefcase className={`w-4 h-4 ${isSelected ? "text-slate-900" : "text-slate-500"}`} />
                    {rec.career_name}
                  </h3>
                  <p className="text-[10px] text-slate-500 font-semibold">{rec.target_city} • Pendidikan Min. Dibutuhkan</p>
                </div>
                {/* Score Pill Badge */}
                <div className={`px-2 py-0.5 rounded text-[10px] font-bold border ${
                  rec.match_score >= 75 
                    ? "bg-emerald-50 text-emerald-700 border-emerald-200" 
                    : rec.match_score >= 50
                    ? "bg-slate-100 text-slate-800 border-slate-200"
                    : "bg-slate-55 text-slate-650 border-slate-200"
                }`}>
                  {rec.match_score}% Cocok
                </div>
              </div>

              <p className="text-[11px] text-slate-600 mb-3 leading-relaxed line-clamp-2">
                {rec.description}
              </p>

              {/* Salary Constraint */}
              <div className="flex items-center gap-1.5 text-slate-500 mb-3 border-t border-slate-100 pt-2">
                <Landmark className="w-3.5 h-3.5 text-slate-400" />
                <span className="text-[10px] font-semibold">Rentang Gaji:</span>
                <span className="text-[11px] font-bold text-slate-900">
                  {formatIDR(rec.salary_min)} - {formatIDR(rec.salary_max)} /bulan
                </span>
              </div>

              {/* Readiness bar */}
              <div className="space-y-1">
                <div className="flex justify-between text-[9px] font-bold text-slate-500">
                  <span>Tingkat Kesiapan Keahlian:</span>
                  <span>{readinessPct}%</span>
                </div>
                <div className="w-full h-1.5 bg-slate-150 rounded overflow-hidden border border-slate-100">
                  <div 
                    className="h-full bg-slate-900 transition-all duration-300"
                    style={{ width: `${readinessPct}%` }}
                  />
                </div>
              </div>

              {/* Selected Career Skills Gap Visualization */}
              {isSelected && (
                <div className="mt-4 pt-3 border-t border-slate-200 space-y-3">
                  <div>
                    <h4 className="text-[10px] font-bold text-slate-500 mb-1.5 uppercase tracking-wide flex items-center gap-1">
                      <CheckCircle className="w-3 h-3 text-emerald-600" /> Keahlian yang Dikuasai ({rec.skills.acquired.length})
                    </h4>
                    {rec.skills.acquired.length > 0 ? (
                      <div className="flex flex-wrap gap-1">
                        {rec.skills.acquired.map((s) => (
                          <span 
                            key={s.name} 
                            className="px-2 py-0.5 rounded text-[10px] bg-slate-100 text-slate-700 border border-slate-200 font-semibold"
                          >
                            {s.name} ({s.weight}%)
                          </span>
                        ))}
                      </div>
                    ) : (
                      <p className="text-[10px] text-slate-400 italic">Belum ada yang sesuai. Masukkan keahlian saat chat.</p>
                    )}
                  </div>

                  <div>
                    <h4 className="text-[10px] font-bold text-slate-500 mb-1.5 uppercase tracking-wide flex items-center gap-1">
                      <AlertCircle className="w-3 h-3 text-rose-600" /> Keahlian Utama yang Belum Dikuasai ({rec.skills.missing.length})
                    </h4>
                    {rec.skills.missing.length > 0 ? (
                      <div className="flex flex-wrap gap-1">
                        {rec.skills.missing.map((s) => (
                          <span 
                            key={s.name} 
                            className="px-2 py-0.5 rounded text-[10px] bg-rose-50 text-rose-700 border border-rose-200 font-semibold"
                          >
                            {s.name} ({s.weight}%)
                          </span>
                        ))}
                      </div>
                    ) : (
                      <p className="text-[10px] text-emerald-600 font-semibold font-sans">Selamat! Anda sudah menguasai seluruh keahlian utama untuk pekerjaan ini!</p>
                    )}
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
