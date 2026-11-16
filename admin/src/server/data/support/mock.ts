import "server-only";

import { randomUUID } from "node:crypto";

import { audit, matches, paginate, problem, run } from "@/server/mock/runtime";
import { store } from "@/server/mock/state";
import type { TicketSeed } from "@/server/mock/fixtures/support";

import type { SupportRepository, TicketDetail, TicketRow } from ".";

function row(t: TicketSeed): TicketRow {
  const { id, number, subject, category, status, has_unread_reply, updated_at, email, assignee, priority, channel, created_at } = t;
  return { id, number, subject, category, status, has_unread_reply, updated_at, email, assignee, priority, channel, created_at };
}

function detail(t: TicketSeed): TicketDetail {
  const { channel: _channel, created_at: _created, ...rest } = t;
  return rest;
}

const find = (id: string) => store().tickets.find((t) => t.id === id);

export const supportMock: SupportRepository = {
  tickets: (query, ctx) =>
    run(ctx, { permission: "support.view" }, ({ staff }) => {
      const me = staff.name ?? staff.email;
      const rows = store()
        .tickets.filter((t) => !query.status || t.status === query.status)
        .filter((t) => !query.category || t.category === query.category)
        .filter((t) =>
          !query.assignee ? true : query.assignee === "me" ? t.assignee === me : query.assignee === "none" ? !t.assignee : t.assignee === query.assignee,
        )
        .filter((t) => matches(query.q, t.subject, t.email, t.number))
        .sort((a, b) => b.updated_at.localeCompare(a.updated_at))
        .map(row);
      return paginate(rows, query);
    }),

  ticket: (id, ctx) =>
    run(ctx, { permission: "support.view" }, () => {
      const t = find(id);
      return t ? detail(t) : problem(404, "not_found");
    }),

  update: (id, input, ctx) =>
    run(ctx, { permission: "support.reply" }, ({ staff }) => {
      const t = find(id);
      if (!t) return problem(404, "not_found");
      const before = { status: t.status, assignee: t.assignee, priority: t.priority };
      if (input.status) t.status = input.status;
      if (input.priority) t.priority = input.priority;
      if (input.category) t.category = input.category;
      if (input.assignee_id !== undefined) {
        t.assignee = input.assignee_id ? (store().staff.find((s) => s.id === input.assignee_id)?.name ?? null) : null;
      }
      t.updated_at = new Date().toISOString();
      audit(staff, "support.update", { type: "ticket", id }, before, { status: t.status, assignee: t.assignee, priority: t.priority });
      return detail(t);
    }),

  reply: (id, input, ctx) =>
    run(ctx, { permission: "support.reply" }, ({ staff }) => {
      const t = find(id);
      if (!t) return problem(404, "not_found");
      t.messages.push({
        id: randomUUID(),
        direction: input.kind === "reply" ? "outbound" : "internal_note",
        author: staff.name ?? staff.email,
        body: input.body,
        created_at: new Date().toISOString(),
      });
      if (input.set_status) t.status = input.set_status;
      else if (input.kind === "reply" && t.status === "new") t.status = "open";
      t.updated_at = new Date().toISOString();
      audit(staff, `support.${input.kind}`, { type: "ticket", id }, null, { status: t.status });
      return detail(t);
    }),

  templates: (ctx) => run(ctx, { permission: "support.view" }, () => store().templates),
};
