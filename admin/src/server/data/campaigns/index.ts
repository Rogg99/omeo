import type { Applied, Page, QueryOf, Result, Schemas, StaffContext } from "../types";

export type Campaign = Schemas["Campaign"];
export type CampaignInput = Schemas["CampaignInput"];
export type Segment = Schemas["Segment"];
export type CampaignsQuery = QueryOf<"adminListCampaigns">;
export type CampaignAction = "schedule" | "cancel" | "send_test";

export interface CampaignsRepository {
  list(query: CampaignsQuery, ctx: StaffContext): Promise<Result<Page<Campaign>>>;
  get(id: string, ctx: StaffContext): Promise<Result<Campaign>>;
  create(input: CampaignInput, ctx: StaffContext): Promise<Result<Campaign>>;
  update(id: string, input: CampaignInput, ctx: StaffContext): Promise<Result<Campaign>>;
  /** Nombre de destinataires d'un segment (consentement marketing inclus), calculé par l'API. */
  audience(segment: Segment, ctx: StaffContext): Promise<Result<{ count: number }>>;
  /** schedule et cancel : step-up et quatre yeux ; send_test : envoi à soi-même. */
  action(id: string, action: CampaignAction, ctx: StaffContext): Promise<Result<Applied<Campaign>>>;
}
