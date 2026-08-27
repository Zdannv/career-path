import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import Navbar from "@/components/Navbar";
import PostHogClient from "@/components/PostHogClient";

/**
 * The Figma file specifies SF Pro, which Apple does not license for the web.
 * Apple devices get it natively through the system stack in globals.css; Inter
 * is the closest open face and covers every other platform.
 */
const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "CareerPath AI - Perencana Karier Siswa & Lulusan Baru",
  description: "Perencana karier multi-tahun berbasis pencocokan hibrida KBF, CBF, dan analisis kesenjangan keahlian.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="id"
      className={`${inter.variable} h-full antialiased`}
      suppressHydrationWarning
    >
      <body className="min-h-full flex flex-col bg-slate-50" suppressHydrationWarning>
        <PostHogClient />
        <Navbar />
        <main className="flex-1 w-full flex flex-col">
          {children}
        </main>
      </body>
    </html>
  );
}
