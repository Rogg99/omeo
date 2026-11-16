"use server";

import { z } from "zod";

import type { ActionResult, ApprovalRequest } from "@/lib/action-result";
import { staffAction } from "@/server/action";
import source from "@/server/data/source";

/** Approuve (applique l'action) ou rejette. Step-up imposé par l'API ; jamais sa propre demande. */
export async function decideApproval(raw: unknown): Promise<ActionResult<ApprovalRequest>> {
  return staffAction(
    raw,
    z.object({ id: z.uuid(), decision: z.enum(["approve", "reject"]), comment: z.string().trim().max(500).optional() }),
    ({ id, ...input }, ctx) => source.approvals.decide(id, input, ctx),
  );
}

export async function cancelApproval(raw: unknown): Promise<ActionResult<ApprovalRequest>> {
  return staffAction(raw, z.object({ id: z.uuid() }), ({ id }, ctx) => source.approvals.cancel(id, ctx));
}
