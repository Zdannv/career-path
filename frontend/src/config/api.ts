/**
 * API Configuration
 * Resolves the backend API URL dynamically based on the environment.
 */
export const getApiUrl = (): string => {
  // 1. If an environment variable is explicitly provided, always use it (Standard Production)
  if (process.env.NEXT_PUBLIC_API_URL) {
    let url = process.env.NEXT_PUBLIC_API_URL.trim().replace(/\/$/, ""); // Remove trailing slash if any
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      url = `https://${url}`;
    }
    return url;
  }

  // 2. If running in a browser, determine the host dynamically
  if (typeof window !== "undefined") {
    const hostname = window.location.hostname;
    
    // If running locally (localhost, 127.0.0.1) or on local network (192.168.x.x, 10.x.x.x, 172.x.x.x)
    if (
      hostname === "localhost" ||
      hostname === "127.0.0.1" ||
      hostname.startsWith("192.168.") ||
      hostname.startsWith("10.") ||
      hostname.startsWith("172.")
    ) {
      // Connect to port 8000 on the same host (so mobile testing on the same network works)
      return `http://${hostname}:8000`;
    }
  }

  // 3. Default fallback for local development
  return "http://localhost:8000";
};

export const API_URL = getApiUrl();
