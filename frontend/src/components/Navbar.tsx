"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname, useRouter } from "next/navigation";
import type { User } from "@supabase/supabase-js";
import { supabase } from "@/lib/supabaseClient";
import { Sparkles, Brain, LogOut, Menu, X } from "lucide-react";
import AuthModal from "@/components/AuthModal";

export default function Navbar() {
  const pathname = usePathname();
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [mobileMenuOpen, setMobileMenuOpen] = useState<boolean>(false);
  const [authModalOpen, setAuthModalOpen] = useState<boolean>(false);
  const [authModalInitialMode, setAuthModalInitialMode] = useState<"prompt" | "login" | "daftar">("prompt");

  useEffect(() => {
    // Get current session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    // Listen for custom global event to open auth modal
    const handleOpenAuth = (e: Event) => {
      const customEvent = e as CustomEvent;
      const initialMode = customEvent.detail?.mode || "prompt";
      setAuthModalInitialMode(initialMode);
      setAuthModalOpen(true);
    };

    window.addEventListener("open-auth-modal", handleOpenAuth);

    return () => {
      subscription.unsubscribe();
      window.removeEventListener("open-auth-modal", handleOpenAuth);
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
  ];

  // The auth screens carry their own centered "Navika | Career path journey"
  // lockup, so the app navigation is hidden there entirely.
  const AUTH_ROUTES = ["/daftar", "/login", "/verifikasi", "/lupa-sandi", "/reset-sandi"];
  if (AUTH_ROUTES.includes(pathname)) {
    return null;
  }

  // The landing page ("/") ships its own marketing header (brand + Masuk/Daftar)
  // to match the Figma design, instead of the app's internal navigation.
  if (pathname === "/") {
    return (
      <nav className="w-full bg-white border-b border-slate-100 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <Link href="/" className="select-none">
              <Image
                src="/navika-logo.png"
                alt="Navika"
                width={101}
                height={32}
                className="h-7 w-auto"
                priority
              />
            </Link>

            {user ? (
              <div className="hidden sm:flex items-center gap-6">
                <Link href="/student" className="text-sm font-bold text-slate-600 hover:text-slate-900 transition-colors cursor-pointer">
                  Dashboard Siswa
                </Link>
                <button
                  onClick={handleLogout}
                  className="px-5 py-2 rounded-full border border-slate-200 bg-white hover:bg-slate-50 text-slate-800 text-sm font-semibold transition-all cursor-pointer"
                >
                  Keluar
                </button>
              </div>
            ) : (
              <div className="hidden sm:flex items-center gap-6">
                <Link
                  href="/login"
                  className="text-sm font-semibold text-slate-500 hover:text-slate-900 transition-colors cursor-pointer"
                >
                  Masuk
                </Link>
                <Link
                  href="/daftar"
                  className="px-5 py-2 rounded-full bg-gradient-to-r from-indigo-600 to-purple-600 text-white text-sm font-semibold shadow-sm hover:shadow-md transition-all cursor-pointer border-0 outline-none"
                >
                  Daftar
                </Link>
              </div>
            )}

            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="sm:hidden p-2 -mr-2 rounded text-slate-600 hover:bg-slate-100 cursor-pointer"
              aria-label="Menu"
            >
              {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {mobileMenuOpen && (
          <div className="sm:hidden border-t border-slate-100 bg-white px-4 py-3 space-y-2">
            {user ? (
              <>
                <Link
                  href="/student"
                  onClick={() => setMobileMenuOpen(false)}
                  className="block px-3 py-2 rounded-md text-sm font-semibold text-slate-600 hover:bg-slate-50 cursor-pointer"
                >
                  Dashboard Siswa
                </Link>
                <button
                  onClick={() => {
                    setMobileMenuOpen(false);
                    handleLogout();
                  }}
                  className="block w-full text-center px-3 py-2 rounded-md text-sm font-semibold text-white bg-slate-800"
                >
                  Keluar
                </button>
              </>
            ) : (
              <>
                <Link
                  href="/login"
                  onClick={() => setMobileMenuOpen(false)}
                  className="block px-3 py-2 rounded-md text-sm font-semibold text-slate-600 hover:bg-slate-50 cursor-pointer"
                >
                  Masuk
                </Link>
                <Link
                  href="/daftar"
                  onClick={() => setMobileMenuOpen(false)}
                  className="block w-full px-3 py-2 rounded-md text-sm font-semibold text-center text-white bg-gradient-to-r from-indigo-600 to-purple-600 cursor-pointer border-0"
                >
                  Daftar
                </Link>
              </>
            )}
          </div>
        )}

        <AuthModal
          isOpen={authModalOpen}
          onClose={() => setAuthModalOpen(false)}
          initialMode={authModalInitialMode}
        />
      </nav>
    );
  }

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
                    : "text-slate-600 hover:text-slate-900 hover:bg-slate-100"
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
