import "server-only";

import { randomUUID } from "node:crypto";

import { audit, problem, run, staffMember } from "@/server/mock/runtime";
import { store } from "@/server/mock/state";

import type { TeamRepository } from ".";

const activeSuperadmins = () => store().staff.filter((s) => s.active && s.roles.includes("superadmin"));

export const teamMock: TeamRepository = {
  list: (ctx) => run(ctx, { permission: "team.manage", stepUp: true }, () => store().staff.map((s) => staffMember(s))),

  invite: (input, ctx) =>
    run(ctx, { permission: "team.manage", stepUp: true }, ({ staff }) => {
      if (store().staff.some((s) => s.email.toLowerCase() === input.email.toLowerCase())) {
        return problem(422, "validation_error", { errors: { email: [{ code: "unique", message: "Déjà membre" }] } });
      }
      const member = { id: randomUUID(), email: input.email, name: input.email.split("@")[0], roles: input.roles, mfa_enabled: false, active: true, last_login_at: null };
      store().staff.push(member);
      audit(staff, "team.invite", { type: "staff", id: member.id }, null, { email: member.email, roles: member.roles });
      return staffMember(member);
    }),

  update: (id, input, ctx) =>
    run(ctx, { permission: "team.manage", stepUp: true }, ({ staff }) => {
      const member = store().staff.find((s) => s.id === id);
      if (!member) return problem(404, "not_found");
      const losesSuperadmin =
        member.roles.includes("superadmin") &&
        ((input.roles && !input.roles.includes("superadmin")) || input.active === false);
      if (losesSuperadmin && member.id === staff.id) {
        return problem(422, "validation_error", { errors: { roles: [{ code: "self", message: "Tu ne peux pas retirer ton propre rôle superadmin" }] } });
      }
      if (losesSuperadmin && activeSuperadmins().length <= 1) {
        return problem(422, "validation_error", { errors: { roles: [{ code: "last_superadmin", message: "Dernier superadmin actif" }] } });
      }
      const before = { roles: member.roles, active: member.active, mfa_enabled: member.mfa_enabled };
      if (input.roles) member.roles = input.roles;
      if (input.active !== undefined) member.active = input.active;
      if (input.reset_mfa) member.mfa_enabled = false;
      audit(staff, "team.update", { type: "staff", id }, before, { roles: member.roles, active: member.active, mfa_enabled: member.mfa_enabled });
      return staffMember(member);
    }),
};
