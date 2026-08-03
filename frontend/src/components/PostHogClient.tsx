"use client";

import { useEffect } from "react";
import posthog from "posthog-js";

export default function PostHogClient() {
  useEffect(() => {
    if (typeof window !== "undefined") {
      // Initialize PostHog client with placeholder key
      posthog.init("phc_placeholder_key_for_counselors_analytics_tracking", {
        api_host: "https://us.i.posthog.com",
        person_profiles: "identified_only",
        capture_pageview: true, // Automatically capture pageviews
      });
    }
  }, []);

  return null;
}
