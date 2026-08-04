"use client";

import React, { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import { Loader2, ArrowLeft, AlertCircle } from "lucide-react";
import Dashboard from "@/components/Dashboard";

export default function SavedJourneyPage() {
  const params = useParams();
  const router = useRouter();
  const id = params?.id as string;

  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [mappedData, setMappedData] = useState<any>(null);

  useEffect(() => {
    if (!id) return;
    fetchSavedJourney();
  }, [id]);

  const fetchSavedJourney = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`http://localhost:8000/api/journey/${id}`);
      if (!res.ok) {
        if (res.status === 404) {
          throw new Error("Rencana perjalanan karier tidak ditemukan.");
        }
        throw new Error("Gagal mengambil data dari server.");
      }
      const dbRecord = await res.json();
      
      // Reconstruct the expected Dashboard schema from single saved journey
      const reconstructed = {
        extracted_params: {
          student_name: dbRecord.student_name,
          class_code: dbRecord.class_code,
          education: dbRecord.education,
          major: dbRecord.major,
          city: dbRecord.city,
          min_salary: dbRecord.min_salary,
          skills: dbRecord.skills || []
        },
        recommendations: [
          {
            career_id: dbRecord.journey_plan.career_id,
            career_name: dbRecord.journey_plan.career_name,
            description: dbRecord.opportunity_overview,
            target_city: dbRecord.city,
            salary_min: dbRecord.min_salary,
            salary_max: dbRecord.min_salary * 1.5,
            match_score: 100,
            skills: {
              required: (dbRecord.skills || []).map((s: string) => ({ name: s, weight: 1.0 })),
              missing: [],
              acquired: (dbRecord.skills || []).map((s: string) => ({ name: s, weight: 1.0 }))
            }
          }
        ],
        journey_plan: {
          opportunity_overview: dbRecord.opportunity_overview,
          journey_plans: [dbRecord.journey_plan]
        }
      };
      
      setMappedData(reconstructed);
    } catch (err: any) {
      setError(err.message || "Gagal menghubungkan ke server.");
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-[85vh] bg-slate-50 flex flex-col items-center justify-center space-y-3">
        <Loader2 className="w-8 h-8 animate-spin text-slate-500" />
        <p className="text-xs text-slate-500 font-bold">Memuat rencana karier tersimpan...</p>
      </div>
    );
  }

  if (error || !mappedData) {
    return (
      <div className="min-h-[85vh] bg-slate-50 flex flex-col items-center justify-center p-4">
        <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-md text-center space-y-4 max-w-md w-full">
          <div className="w-12 h-12 rounded bg-rose-50 text-rose-600 flex items-center justify-center mx-auto border border-rose-100">
            <AlertCircle className="w-6 h-6" />
          </div>
          <h2 className="text-base font-bold text-slate-900">Rencana Tidak Ditemukan</h2>
          <p className="text-xs text-slate-500 leading-relaxed font-semibold">
            {error || "Link tidak valid atau data rencana karier telah dihapus."}
          </p>
          <button
            onClick={() => router.push("/student")}
            className="w-full py-2.5 rounded bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
          >
            <ArrowLeft className="w-4 h-4" /> Mulai Asesmen Baru
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-[90vh] bg-slate-50 w-full flex justify-center p-0 sm:p-6">
      <div className="w-full min-h-[90vh] sm:rounded-xl sm:border sm:border-slate-200 bg-white flex flex-col shadow-md overflow-hidden max-w-7xl transition-all duration-300">
        <div className="flex-1 flex flex-col overflow-hidden relative">
          <Dashboard 
            data={mappedData} 
            onRestart={() => router.push("/student")} 
            isReadOnly={true} 
          />
        </div>
      </div>
    </div>
  );
}
