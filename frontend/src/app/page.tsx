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
    <div className="min-h-screen w-full bg-slate-50 flex items-center justify-center p-0 sm:p-4">
      {view === "onboarding" ? (
        /* Chat Onboarding keeps a centered mobile container because conversational chat looks best inside a phone width */
        <div className="w-full min-h-screen sm:min-h-[800px] sm:max-w-md sm:rounded-xl sm:border sm:border-slate-200 bg-white flex flex-col shadow-sm overflow-hidden">
          <div className="flex-1 flex flex-col overflow-hidden relative">
            <ChatOnboarding onComplete={handleOnboardingComplete} />
          </div>
        </div>
      ) : (
        /* Dashboard expands fully on desktop to support a dual-pane responsive layout, and adapts on mobile */
        <div className="w-full min-h-screen sm:min-h-[800px] sm:rounded-xl sm:border sm:border-slate-200 bg-white flex flex-col shadow-sm overflow-hidden max-w-7xl">
          <div className="flex-1 flex flex-col overflow-hidden relative">
            <Dashboard data={results} onRestart={handleRestart} />
          </div>
        </div>
      )}
    </div>
  );
}
