import type { BodyOf, Page, QueryOf, ResponseOf, Result, Schemas, StaffContext } from "../types";

export type TicketRow = Schemas["AdminTicketRow"];
export type TicketDetail = Schemas["TicketDetail"];
export type TicketsQuery = QueryOf<"adminListTickets">;
export type TicketUpdate = BodyOf<"adminUpdateTicket">;
export type TicketReply = BodyOf<"adminReplyTicket">;
export type ReplyTemplate = ResponseOf<"adminListReplyTemplates", 200>[number];

export interface SupportRepository {
  tickets(query: TicketsQuery, ctx: StaffContext): Promise<Result<Page<TicketRow>>>;
  ticket(id: string, ctx: StaffContext): Promise<Result<TicketDetail>>;
  update(id: string, input: TicketUpdate, ctx: StaffContext): Promise<Result<TicketDetail>>;
  /** Réponse (email et notification dans l'app) ou note interne. */
  reply(id: string, input: TicketReply, ctx: StaffContext): Promise<Result<TicketDetail>>;
  templates(ctx: StaffContext): Promise<Result<ReplyTemplate[]>>;
}
