import "server-only";

import { authorize, fail, isProblem, ok, staffMember } from "@/server/mock/runtime";

import type { MeRepository } from ".";

export const meMock: MeRepository = {
  async get(ctx) {
    const actor = await authorize(ctx, { permission: "authenticated_staff" });
    if (isProblem(actor)) return fail(actor);
    return ok(staffMember(actor.staff, actor.session));
  },
};
