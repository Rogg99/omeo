import type { BodyOf, Page, QueryOf, ResponseOf, Result, Schemas, StaffContext } from "../types";

export type FeedbackRow = Schemas["AdminFeedbackRow"];
export type FeedbackDetail = Schemas["AdminFeedbackDetail"];
export type FeedbackStats = Schemas["AdminFeedbackStats"];
export type FeedbackQuery = QueryOf<"adminListFeedback">;
export type FeedbackStatsQuery = QueryOf<"adminFeedbackStats">;
export type ResolveInput = BodyOf<"adminResolveFeedback">;
export type ResolveResult = ResponseOf<"adminResolveFeedback", 200>;

export interface FeedbackRepository {
  /** Les 👎 en premier par défaut. */
  list(query: FeedbackQuery, ctx: StaffContext): Promise<Result<Page<FeedbackRow>>>;
  get(id: string, ctx: StaffContext): Promise<Result<FeedbackDetail>>;
  resolve(id: string, input: ResolveInput, ctx: StaffContext): Promise<Result<ResolveResult>>;
  stats(query: FeedbackStatsQuery, ctx: StaffContext): Promise<Result<FeedbackStats>>;
}
