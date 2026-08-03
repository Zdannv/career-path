"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";
import { Sparkles, Brain, GraduationCap, Briefcase, LogOut, Menu, X } from "lucide-react";

export default function Navbar() {
  const pathname = usePathname();
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [mobileMenuOpen, setMobileMenuOpen] = useState<boolean>(false);

  useEffect(() => {
    // Get current session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    setUser(null);
    router.push("/");
  };

  const navLinks = [
    { name: "Home", href: "/", icon: Sparkles },
    { name: "Dashboard Siswa", href: "/student", icon: Brain },
    { name: "Job & Gigs", href: "/jobs", icon: Briefcase },
    { name: "Portal Guru BK", href: "/teacher", icon: GraduationCap },
  ];

  return (
    <nav className="w-full bg-white/85 backdrop-blur-md border-b border-slate-200 sticky top-0 z-50 transition-all duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          
          {/* Logo Brand */}
          <div className="flex items-center">
            <Link href="/" className="flex items-center gap-2 font-black text-slate-900 tracking-tight text-sm sm:text-base">
              <div className="w-8 h-8 rounded bg-slate-900 flex items-center justify-center shadow-md">
                <Sparkles className="w-4 h-4 text-white" />
              </div>
              <span>CareerPath <span className="text-indigo-600 font-extrabold">AI</span></span>
            </Link>
          </div>

          {/* Desktop Nav Links */}
          <div className="hidden md:flex items-center space-x-1">
            {navLinks.map((link) => {
              const isActive = pathname === link.href || (link.href !== "/" && pathname.startsWith(link.href));
              const Icon = link.icon;
              return (
                <Link
                  key={link.name}
                  href={link.href}
                  className={`px-3 py-2 rounded-md text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer ${
                    isActive 
                      ? "bg-slate-900 text-white shadow-sm" 
                      : "text-slate-600 hover:text-slate-900 hover:bg-slate-100"
                  }`}
                >
                  <Icon className="w-3.5 h-3.5" />
                  {link.name}
                </Link>
              );
            })}

            {/* Logout Button if authenticated */}
            {user && (
              <button
                onClick={handleLogout}
                className="ml-4 px-3 py-2 rounded-md text-xs font-bold text-rose-600 hover:text-rose-900 hover:bg-rose-50 border border-transparent hover:border-rose-100 flex items-center gap-1.5 transition-all cursor-pointer"
              >
                <LogOut className="w-3.5 h-3.5" />
                Keluar
              </button>
            )}
          </div>

          {/* Mobile Menu Button */}
          <div className="flex items-center md:hidden">
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="p-2 rounded text-slate-500 hover:text-slate-900 hover:bg-slate-100 focus:outline-none cursor-pointer"
            >
              {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>

        </div>
      </div>

      {/* Mobile Nav Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden border-b border-slate-200 bg-white px-2 pt-2 pb-4 space-y-1 shadow-inner">
          {navLinks.map((link) => {
            const isActive = pathname === link.href || (link.href !== "/" && pathname.startsWith(link.href));
            const Icon = link.icon;
            return (
              <Link
                key={link.name}
                href={link.href}
                onClick={() => setMobileMenuOpen(false)}
                className={`w-full px-4 py-2.5 rounded-md text-xs font-bold transition-all flex items-center gap-2 cursor-pointer ${
                  isActive 
                    ? "bg-slate-900 text-white shadow" 
                    : "text-slate-650 hover:text-slate-900 hover:bg-slate-100"
                }`}
              >
                <Icon className="w-4 h-4" />
                {link.name}
              </Link>
            );
          })}

          {user && (
            <button
              onClick={() => {
                setMobileMenuOpen(false);
                handleLogout();
              }}
              className="w-full px-4 py-2.5 rounded-md text-xs font-bold text-rose-600 hover:bg-rose-50 flex items-center gap-2 transition-all cursor-pointer text-left"
            >
              <LogOut className="w-4 h-4" />
              Keluar Sesi
            </button>
          )}
        </div>
      )}
    </nav>
  );
}
