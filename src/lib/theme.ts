import { useCallback, useEffect, useState } from "react";

export type Theme = "light" | "dark" | "system";

const THEME_STORAGE = "lumi:theme:v1";

/** Inline snippet run in <head> before paint to avoid a flash of the wrong theme. */
export const THEME_INIT_SCRIPT = `(function(){try{var t=localStorage.getItem("${THEME_STORAGE}")||"system";var m=window.matchMedia("(prefers-color-scheme: dark)").matches;var dark=t==="dark"||(t==="system"&&m);document.documentElement.classList.toggle("dark",dark);}catch(e){}})();`;

function systemPrefersDark(): boolean {
  return typeof window !== "undefined" && window.matchMedia("(prefers-color-scheme: dark)").matches;
}

function resolve(theme: Theme): boolean {
  return theme === "dark" || (theme === "system" && systemPrefersDark());
}

function apply(theme: Theme): void {
  if (typeof document === "undefined") return;
  document.documentElement.classList.toggle("dark", resolve(theme));
}

export function useTheme() {
  const [theme, setThemeState] = useState<Theme>("system");

  // Load the persisted choice on mount.
  useEffect(() => {
    let stored: Theme = "system";
    try {
      stored = (localStorage.getItem(THEME_STORAGE) as Theme) || "system";
    } catch {
      /* ignore */
    }
    setThemeState(stored);
    apply(stored);
  }, []);

  // Keep in sync with the OS when following the system preference.
  useEffect(() => {
    if (theme !== "system") return;
    const mq = window.matchMedia("(prefers-color-scheme: dark)");
    const onChange = () => apply("system");
    mq.addEventListener("change", onChange);
    return () => mq.removeEventListener("change", onChange);
  }, [theme]);

  const setTheme = useCallback((next: Theme) => {
    setThemeState(next);
    apply(next);
    try {
      localStorage.setItem(THEME_STORAGE, next);
    } catch {
      /* ignore */
    }
  }, []);

  /** The theme actually shown right now (system resolved to light/dark). */
  const isDark = resolve(theme);

  return { theme, setTheme, isDark };
}
