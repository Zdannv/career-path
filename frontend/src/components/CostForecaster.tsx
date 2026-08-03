"use client";

import React, { useState, useEffect } from "react";
import { Wallet, GraduationCap, Home, Utensils, Calendar, Info } from "lucide-react";

interface CostForecastData {
  tuition_annual: number;
  housing_monthly: number;
  living_monthly: number;
  duration_years: number;
  total_cost: number;
}

interface CostForecasterProps {
  defaultDurationYears: number;
  onChangeForecast: (forecast: CostForecastData) => void;
}

export default function CostForecaster({
  defaultDurationYears,
  onChangeForecast
}: CostForecasterProps) {
  // Inputs state
  const [tuitionAnnual, setTuitionAnnual] = useState<number>(12000000); // 12 Juta/tahun
  const [housingMonthly, setHousingMonthly] = useState<number>(1000000); // 1 Juta/bulan
  const [livingMonthly, setLivingMonthly] = useState<number>(1500000);  // 1.5 Juta/bulan
  const [durationYears, setDurationYears] = useState<number>(defaultDurationYears || 4);

  // Sync durationYears when defaultDurationYears changes
  useEffect(() => {
    if (defaultDurationYears) {
      setDurationYears(defaultDurationYears);
    }
  }, [defaultDurationYears]);

  // Real-time calculations
  const totalTuition = tuitionAnnual * durationYears;
  const totalHousing = housingMonthly * 12 * durationYears;
  const totalLiving = livingMonthly * 12 * durationYears;
  const grandTotal = totalTuition + totalHousing + totalLiving;

  // Trigger callback on change
  useEffect(() => {
    onChangeForecast({
      tuition_annual: tuitionAnnual,
      housing_monthly: housingMonthly,
      living_monthly: livingMonthly,
      duration_years: durationYears,
      total_cost: grandTotal
    });
  }, [tuitionAnnual, housingMonthly, livingMonthly, durationYears, grandTotal]);

  const formatIDR = (num: number) => {
    return new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      maximumFractionDigits: 0
    }).format(num);
  };

  // Percentages for stacked progress bar
  const tuitionPct = grandTotal > 0 ? (totalTuition / grandTotal) * 100 : 0;
  const housingPct = grandTotal > 0 ? (totalHousing / grandTotal) * 100 : 0;
  const livingPct = grandTotal > 0 ? (totalLiving / grandTotal) * 100 : 0;

  return (
    <div className="bg-white rounded-lg border border-slate-200 p-5 space-y-5 shadow-sm transition-all duration-300 hover:border-slate-300">
      {/* Title */}
      <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
        <Wallet className="w-5 h-5 text-slate-900" />
        <div>
          <h3 className="font-bold text-sm text-slate-900 leading-tight">Proyeksi & Kalkulator Biaya Pendidikan</h3>
          <p className="text-[10px] text-slate-500 font-semibold">Persona Wali Murid: Estimasikan anggaran perjalanan studi anak</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        {/* Left Side: Inputs */}
        <div className="space-y-4">
          {/* Tuition Input */}
          <div className="space-y-1.5">
            <label className="text-[11px] font-bold text-slate-750 flex items-center gap-1.5">
              <GraduationCap className="w-4 h-4 text-slate-500" />
              Biaya Pendidikan per Tahun (SPP/UKT)
            </label>
            <div className="relative">
              <span className="absolute left-3 top-2 text-xs font-bold text-slate-400">Rp</span>
              <input
                type="number"
                value={tuitionAnnual}
                onChange={(e) => setTuitionAnnual(Math.max(0, parseInt(e.target.value) || 0))}
                className="w-full bg-white border border-slate-200 rounded px-9 py-2 text-xs focus:outline-none focus:border-slate-400 text-slate-900 font-semibold"
                placeholder="Contoh: 15000000"
              />
            </div>
            <p className="text-[9px] text-slate-400 font-medium italic">Estimasi biaya SPP kuliah atau uang sekolah per tahun.</p>
          </div>

          {/* Housing Input */}
          <div className="space-y-1.5">
            <label className="text-[11px] font-bold text-slate-750 flex items-center gap-1.5">
              <Home className="w-4 h-4 text-slate-500" />
              Biaya Kost / Tempat Tinggal per Bulan
            </label>
            <div className="relative">
              <span className="absolute left-3 top-2 text-xs font-bold text-slate-400">Rp</span>
              <input
                type="number"
                value={housingMonthly}
                onChange={(e) => setHousingMonthly(Math.max(0, parseInt(e.target.value) || 0))}
                className="w-full bg-white border border-slate-200 rounded px-9 py-2 text-xs focus:outline-none focus:border-slate-400 text-slate-900 font-semibold"
                placeholder="Kos/Kontrakan per bulan. Isi 0 jika tinggal di rumah."
              />
            </div>
            <p className="text-[9px] text-slate-400 font-medium italic">Masukkan 0 jika anak tinggal di rumah sendiri (tidak kost).</p>
          </div>

          {/* Living Input */}
          <div className="space-y-1.5">
            <label className="text-[11px] font-bold text-slate-750 flex items-center gap-1.5">
              <Utensils className="w-4 h-4 text-slate-500" />
              Biaya Hidup (Makan & Trans) per Bulan
            </label>
            <div className="relative">
              <span className="absolute left-3 top-2 text-xs font-bold text-slate-400">Rp</span>
              <input
                type="number"
                value={livingMonthly}
                onChange={(e) => setLivingMonthly(Math.max(0, parseInt(e.target.value) || 0))}
                className="w-full bg-white border border-slate-200 rounded px-9 py-2 text-xs focus:outline-none focus:border-slate-400 text-slate-900 font-semibold"
                placeholder="Makan, transportasi, internet per bulan."
              />
            </div>
          </div>

          {/* Duration Slider */}
          <div className="space-y-2 pt-2">
            <div className="flex justify-between items-center text-xs">
              <span className="text-[11px] font-bold text-slate-750 flex items-center gap-1.5">
                <Calendar className="w-4 h-4 text-slate-500" />
                Durasi Masa Studi / Rencana Perjalanan
              </span>
              <span className="font-bold text-slate-900 bg-slate-100 px-2 py-0.5 rounded text-[10px]">
                {durationYears} Tahun
              </span>
            </div>
            <input
              type="range"
              min={1}
              max={6}
              step={1}
              value={durationYears}
              onChange={(e) => setDurationYears(parseInt(e.target.value))}
              className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-slate-900"
            />
            <div className="flex justify-between text-[9px] text-slate-400 font-bold">
              <span>1 Tahun</span>
              <span>6 Tahun</span>
            </div>
          </div>
        </div>

        {/* Right Side: Projections & Stacked Progress Bar */}
        <div className="bg-slate-50 rounded-lg border border-slate-200 p-4 flex flex-col justify-between space-y-4">
          <div className="space-y-3">
            <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Estimasi Total Pengeluaran ({durationYears} Tahun)</p>
            <h2 className="text-xl md:text-2xl font-black text-slate-900 tracking-tight leading-none">
              {formatIDR(grandTotal)}
            </h2>
            <p className="text-[10px] text-slate-500 font-medium flex items-center gap-1">
              <Info className="w-3.5 h-3.5 text-slate-400 shrink-0" />
              Dihitung secara akumulatif berdasarkan durasi studi anak.
            </p>
          </div>

          {/* Stacked Progress Bar Visual Breakdown */}
          <div className="space-y-2">
            <div className="flex justify-between items-center text-[9px] font-bold text-slate-500">
              <span>Visualisasi Alokasi Anggaran</span>
              <span>Total: 100%</span>
            </div>
            {/* Stacked Bar Container */}
            <div className="w-full h-4 bg-slate-200 rounded overflow-hidden flex border border-slate-100 shadow-inner">
              {tuitionPct > 0 && (
                <div
                  style={{ width: `${tuitionPct}%` }}
                  className="bg-slate-950 h-full transition-all duration-300"
                  title={`Pendidikan: ${tuitionPct.toFixed(1)}%`}
                />
              )}
              {housingPct > 0 && (
                <div
                  style={{ width: `${housingPct}%` }}
                  className="bg-slate-500 h-full transition-all duration-300"
                  title={`Kost/Tempat Tinggal: ${housingPct.toFixed(1)}%`}
                />
              )}
              {livingPct > 0 && (
                <div
                  style={{ width: `${livingPct}%` }}
                  className="bg-slate-350 h-full transition-all duration-300"
                  title={`Biaya Hidup: ${livingPct.toFixed(1)}%`}
                />
              )}
            </div>

            {/* Legend / Info breakdown */}
            <div className="grid grid-cols-1 gap-1.5 pt-2 border-t border-slate-200 text-[10px] text-slate-700 font-semibold">
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded bg-slate-950 shrink-0" />
                  Total Pendidikan ({tuitionPct.toFixed(0)}%)
                </span>
                <span className="font-bold text-slate-900">{formatIDR(totalTuition)}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded bg-slate-500 shrink-0" />
                  Total Kost/Tempat Tinggal ({housingPct.toFixed(0)}%)
                </span>
                <span className="font-bold text-slate-900">{formatIDR(totalHousing)}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded bg-slate-350 shrink-0" />
                  Total Hidup & Makan ({livingPct.toFixed(0)}%)
                </span>
                <span className="font-bold text-slate-900">{formatIDR(totalLiving)}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
