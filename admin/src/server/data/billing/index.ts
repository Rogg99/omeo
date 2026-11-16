import type { Applied, BodyOf, Page, QueryOf, Result, Schemas, StaffContext } from "../types";

export type Plan = Schemas["AdminPlan"];
export type QuotaRule = Schemas["QuotaRule"];
export type SubscriptionRow = Schemas["AdminSubscriptionRow"];
export type PaymentRow = Schemas["AdminPaymentRow"];
export type PromoCode = Schemas["PromoCode"];
export type SubscriptionsQuery = QueryOf<"adminListSubscriptions">;
export type PaymentsQuery = QueryOf<"adminListPayments">;
export type PromoQuery = QueryOf<"adminListPromoCodes">;
export type RefundInput = BodyOf<"adminRefundPayment">;

export interface BillingRepository {
  plans(ctx: StaffContext): Promise<Result<Plan[]>>;
  /** Toujours à quatre yeux. */
  updatePlan(code: string, plan: Plan, ctx: StaffContext): Promise<Result<Applied<Plan>>>;
  quotas(ctx: StaffContext): Promise<Result<QuotaRule[]>>;
  /** Toujours à quatre yeux. */
  replaceQuotas(rules: QuotaRule[], ctx: StaffContext): Promise<Result<Applied<QuotaRule[]>>>;
  subscriptions(query: SubscriptionsQuery, ctx: StaffContext): Promise<Result<Page<SubscriptionRow>>>;
  payments(query: PaymentsQuery, ctx: StaffContext): Promise<Result<Page<PaymentRow>>>;
  /** Paiements web uniquement. Step-up ; quatre yeux au-dessus de `billing.refund_approval_threshold_usd`. */
  refund(id: string, input: RefundInput, ctx: StaffContext): Promise<Result<Applied<PaymentRow>>>;
  promoCodes(query: PromoQuery, ctx: StaffContext): Promise<Result<Page<PromoCode>>>;
  createPromo(input: PromoCode, ctx: StaffContext): Promise<Result<PromoCode>>;
  updatePromo(id: string, input: PromoCode, ctx: StaffContext): Promise<Result<PromoCode>>;
}
