import { useEffect, useState } from "react";

/**
 * Client-side API key storage.
 * The Coachio API key is kept in localStorage (browser only, never committed)
 * and sent to our own server routes via the `x-coachio-key` header, which then
 * forward it to Coachio. Server routes still fall back to process.env.COACHIO_API_KEY.
 */
const API_KEY_STORAGE = "lumi:coachio-key:v1";

export function getApiKey(): string {
  try {
    return localStorage.getItem(API_KEY_STORAGE) ?? "";
  } catch {
    return "";
  }
}

export function setStoredApiKey(value: string): void {
  try {
    const v = value.trim();
    if (v) localStorage.setItem(API_KEY_STORAGE, v);
    else localStorage.removeItem(API_KEY_STORAGE);
  } catch {
    /* ignore */
  }
}

/** Headers to attach to any fetch that talks to our Coachio-backed API routes. */
export function authHeaders(): Record<string, string> {
  const key = getApiKey();
  return key ? { "x-coachio-key": key } : {};
}

/** Reactive hook for the settings UI. */
export function useApiKey() {
  const [key, setKey] = useState("");
  useEffect(() => {
    setKey(getApiKey());
  }, []);
  const save = (value: string) => {
    setStoredApiKey(value);
    setKey(value.trim());
  };
  return { key, save };
}
