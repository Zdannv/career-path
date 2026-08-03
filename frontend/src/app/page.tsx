"use client";

import React, { useState } from "react";
import ChatOnboarding from "@/components/ChatOnboarding";
import Dashboard from "@/components/Dashboard";

export default function Home() {
  const [view, setView] = useState<"onboarding" | "dashboard">("onboarding");
  const [results, setResults] = useState<any>(null);

  const handleOnboardingComplete = (data: any) => {
    setResults(data);
    setView("dashboard");
  };

  const handleRestart = () => {
    setResults(null);
    setView("onboarding");
  };

  return (
    <div className="min-h-screen w-full bg-slate-50 flex items-center justify-center p-0 sm:p-6">
      {view === "onboarding" ? (
        /* Chat Onboarding supports split desktop layout with live summary */
        <div className="w-full min-h-screen sm:min-h-[85vh] sm:max-w-5xl sm:rounded-xl sm:border sm:border-slate-200 bg-white flex flex-col shadow-md overflow-hidden transition-all duration-300">
          <div className="flex-1 flex flex-col overflow-hidden relative">
            <ChatOnboarding onComplete={handleOnboardingComplete} />
          </div>
        </div>
      ) : (
        /* Dashboard expands to max-w-7xl for side-by-side matching and cost planning sheets */
        <div className="w-full min-h-screen sm:min-h-[90vh] sm:rounded-xl sm:border sm:border-slate-200 bg-white flex flex-col shadow-md overflow-hidden max-w-7xl transition-all duration-300">
          <div className="flex-1 flex flex-col overflow-hidden relative">
            <Dashboard data={results} onRestart={handleRestart} />
          </div>
        </div>
      )}
    </div>
  );
}
