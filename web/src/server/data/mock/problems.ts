import type { Problem } from "../types";

/** Erreurs problem+json du contrat (docs/technique/conventions-api.md), telles que l'API les renvoie. */
const TITLES: Record<string, string> = {
  validation_error: "Validation error",
  invalid_credentials: "Invalid credentials",
  not_authenticated: "Not authenticated",
  token_expired: "Token expired",
  email_not_verified: "Email not verified",
  conflict: "Conflict",
  not_found: "Not found",
  rate_limited: "Too many requests",
  server_error: "Server error",
};

export function problem(status: number, code: string, extra?: Partial<Problem>): Problem {
  return {
    type: `https://api.omeo.app/problems/${code}`,
    title: TITLES[code] ?? code,
    status,
    code,
    request_id: "mock-request",
    ...extra,
  };
}

export function fieldError(field: string, code: string, message: string): Problem {
  return problem(400, "validation_error", { errors: { [field]: [{ code, message }] } });
}
