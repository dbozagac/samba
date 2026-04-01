import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY ?? "",
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN ?? "",
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? "",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID ?? "",
};

const missingEnvNames = Object.entries({
  NEXT_PUBLIC_FIREBASE_API_KEY: firebaseConfig.apiKey,
  NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN: firebaseConfig.authDomain,
  NEXT_PUBLIC_FIREBASE_PROJECT_ID: firebaseConfig.projectId,
  NEXT_PUBLIC_FIREBASE_APP_ID: firebaseConfig.appId,
})
  .filter(([, value]) => value.trim().length === 0)
  .map(([name]) => name);

const hasValidWebAppId =
  /^\d+:\d+:web:[a-zA-Z0-9]+$/.test(firebaseConfig.appId);

export const firebaseConfigurationError =
  missingEnvNames.length > 0
    ? `Eksik Firebase değişkenleri: ${missingEnvNames.join(", ")}.`
    : !hasValidWebAppId
      ? "NEXT_PUBLIC_FIREBASE_APP_ID değeri 1:...:web:... formatında olmalı."
      : null;

export const isFirebaseConfigured = firebaseConfigurationError === null;

const app = isFirebaseConfigured
  ? getApps().length
    ? getApp()
    : initializeApp(firebaseConfig)
  : null;

export const auth = app ? getAuth(app) : null;
export const googleProvider = (() => {
  const provider = new GoogleAuthProvider();
  provider.setCustomParameters({ prompt: "select_account" });
  return provider;
})();
