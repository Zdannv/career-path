"use client";

import React from "react";
import { Compass, GraduationCap, MapPin, Award, BookOpen, AlertCircle, Sparkles } from "lucide-react";

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

interface JourneyTimelineProps {
  overviewText: string;
  plan: IndividualJourneyPlan | undefined;
}

export default function JourneyTimeline({ overviewText, plan }: JourneyTimelineProps) {
  if (!plan) {
    return (
      <div className="p-8 text-center bg-white border border-slate-200 rounded-lg">
        <Compass className="w-8 h-8 text-slate-400 mx-auto mb-2" />
        <p className="text-xs text-slate-500 font-semibold">Pilih karier yang cocok di atas untuk melihat linimasa peta jalan.</p>
      </div>
    );
  }

  return (
    <div className="space-y-5 px-4 py-2 bg-white">
      {/* High-Level Overview from LLM */}
      <div className="p-4 rounded bg-slate-50 border border-slate-200">
        <div className="flex items-center gap-1.5 mb-1.5 border-b border-slate-100 pb-1.5">
          <Sparkles className="w-3.5 h-3.5 text-slate-700" />
          <h3 className="text-[10px] font-bold uppercase tracking-wider text-slate-600">Ringkasan Peluang Karier (GenAI)</h3>
        </div>
        <p className="text-xs text-slate-700 leading-relaxed font-sans font-medium">
          {overviewText}
        </p>
      </div>

      {/* Stepper Timeline Container */}
      <div className="space-y-4">
        <div className="flex items-center gap-1.5 border-b border-slate-100 pb-2">
          <Compass className="w-4 h-4 text-slate-700" />
          <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500">Peta Jalan Karier Multi-Tahun</h2>
        </div>

        <div className="relative border-l border-slate-200 ml-3.5 pl-6 space-y-6">
          {plan.timeline.map((step, idx) => (
            <div key={idx} className="relative">
              {/* Stepper Dot Badge */}
              <div className="absolute -left-[33px] top-0.5 w-4 h-4 rounded-full bg-white border-2 border-slate-900 flex items-center justify-center z-10 shadow-sm" />

              {/* Timeline Step Content Card */}
              <div className="p-4 rounded-lg bg-white border border-slate-200 space-y-3.5 hover:border-slate-300 transition-colors">
                <div className="flex justify-between items-center">
                  <span className="text-[9px] font-bold text-slate-700 uppercase tracking-widest bg-slate-100 px-2 py-0.5 rounded border border-slate-200">
                    {step.period}
                  </span>
                </div>

                <div>
                  <h4 className="text-[9px] font-bold uppercase tracking-wider text-slate-400 mb-1">Fokus Utama</h4>
                  <p className="text-xs text-slate-900 leading-relaxed font-bold">
                    {step.focus}
                  </p>
                </div>

                {/* Skills to Learn */}
                {step.skills_to_acquire.length > 0 && (
                  <div>
                    <h4 className="text-[9px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">Keahlian yang Perlu Dipelajari</h4>
                    <div className="flex flex-wrap gap-1">
                      {step.skills_to_acquire.map((sk) => (
                        <span 
                          key={sk} 
                          className="px-2 py-0.5 rounded text-[10px] bg-slate-50 text-slate-700 border border-slate-200 font-semibold"
                        >
                          {sk}
                        </span>
                      ))}
                    </div>
                  </div>
                )}

                {/* Action Steps Checklist */}
                <div>
                  <h4 className="text-[9px] font-bold uppercase tracking-wider text-slate-400 mb-1.5">Langkah Pencapaian</h4>
                  <ul className="space-y-1.5">
                    {step.action_steps.map((action, aidx) => (
                      <li key={aidx} className="flex items-start gap-2 text-[11px] text-slate-600 leading-relaxed font-medium">
                        <span className="w-3.5 h-3.5 rounded bg-slate-55 border border-slate-200 flex items-center justify-center text-[8px] text-slate-900 select-none shrink-0 mt-0.5 font-bold">
                          ✓
                        </span>
                        <span>{action}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Target Milestones reached */}
                {step.milestones.length > 0 && (
                  <div className="p-2.5 rounded bg-slate-50 border border-slate-200 flex items-start gap-2">
                    <Award className="w-4 h-4 text-slate-700 shrink-0 mt-0.5" />
                    <div>
                      <h5 className="text-[9px] font-bold text-slate-800 uppercase tracking-wider">Target Pencapaian Utama</h5>
                      <p className="text-[10px] text-slate-600 italic font-sans leading-normal font-medium">
                        {step.milestones.join(", ")}
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Budget / Investment Guidelines */}
      <div className="p-4 rounded bg-slate-50 border border-slate-200 space-y-2">
        <div className="flex items-center gap-1.5">
          <BookOpen className="w-4 h-4 text-slate-700" />
          <h3 className="text-[10px] font-bold uppercase tracking-wider text-slate-500">Panduan Anggaran & Media Belajar</h3>
        </div>
        <p className="text-[11px] text-slate-650 leading-relaxed font-sans font-semibold">
          {plan.budget_investment_guideline}
        </p>
      </div>
    </div>
  );
}
