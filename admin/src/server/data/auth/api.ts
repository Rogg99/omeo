import "server-only";

import { anonymous, api, authed, call, callEmpty, isProblem, problem } from "../http";
import type { AuthRepository } from ".";

function mfaToken(meta: Record<string, unknown> | undefined): string | undefined {
  const token = meta?.mfa_token;
  return typeof token === "string" && token.length > 0 ? token : undefined;
}

export const authApi: AuthRepository = {
  async login(email, password, ctx) {
    try {
      const { data, error, response } = await api.POST("/auth/login", {
        body: { email, password, device: { platform: "admin", name: "Omeo Admin" } },
        ...anonymous(ctx),
      });
      if (response.ok && data) return { ok: true, data: { kind: "session", tokens: data.tokens } };
      if (isProblem(error)) {
        const token = error.code === "mfa_required" ? mfaToken(error.meta) : undefined;
        return token ? { ok: true, data: { kind: "mfa", mfaToken: token } } : { ok: false, problem: error };
      }
      return { ok: false, problem: problem(response.status, "server_error") };
    } catch {
      return { ok: false, problem: problem(503, "network_error") };
    }
  },

  async verifyMfa(token, code, ctx) {
    const result = await call(() => api.POST("/auth/mfa/verify", { body: { mfa_token: token, code }, ...anonymous(ctx) }));
    return result.ok ? { ok: true, data: result.data.tokens } : result;
  },

  refresh: (refresh, ctx) => call(() => api.POST("/auth/refresh", { body: { refresh }, ...anonymous(ctx) })),

  logout: (ctx) => callEmpty(() => api.POST("/auth/logout", { body: { all_devices: false }, ...authed(ctx) })),

  stepUp: (code, ctx) => call(() => api.POST("/auth/mfa/step-up", { body: { code }, ...authed(ctx) })),

  setupMfa: (code, ctx) => call(() => api.POST("/admin/mfa/setup", { body: code ? { code } : {}, ...authed(ctx) })),

  forgotPassword: (email, ctx) => callEmpty(() => api.POST("/auth/password/forgot", { body: { email }, ...anonymous(ctx) })),
};
