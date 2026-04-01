"use client";

import dynamic from "next/dynamic";

// Firebase Auth uses localStorage — must be rendered only on the client.
const HomePage = dynamic(() => import("./home-client"), { ssr: false });

export default function Page() {
  return <HomePage />;
}
