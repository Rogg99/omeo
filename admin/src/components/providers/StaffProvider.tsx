"use client";

import { createContext, useContext, useMemo, type ReactNode } from "react";

import { createCan, type Can } from "@/lib/permissions";

/** Ce que le navigateur sait de la personne connectée (issu de GET /admin/me, sans jeton). */
export type StaffView = {
  id: string;
  name: string;
  email: string;
  roles: string[];
  permissions: string[];
  mfaVerifiedUntil: string | null;
  pendingApprovals: number;
};

type StaffContextValue = { staff: StaffView; can: Can };

const StaffContext = createContext<StaffContextValue | null>(null);

export function StaffProvider({ staff, children }: { staff: StaffView; children: ReactNode }) {
  const value = useMemo(() => ({ staff, can: createCan(staff) }), [staff]);
  return <StaffContext.Provider value={value}>{children}</StaffContext.Provider>;
}

export function useStaff(): StaffContextValue {
  const value = useContext(StaffContext);
  if (!value) throw new Error("useStaff doit être utilisé sous <StaffProvider>.");
  return value;
}

/** `can(permission)` côté client : même helper que le serveur, même liste de permissions. */
export function useCan(): Can {
  return useStaff().can;
}

const CsrfContext = createContext<string>("");

export function CsrfProvider({ token, children }: { token: string; children: ReactNode }) {
  return <CsrfContext.Provider value={token}>{children}</CsrfContext.Provider>;
}

export function useCsrf(): string {
  return useContext(CsrfContext);
}
