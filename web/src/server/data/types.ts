/**
 * Contrat de la couche de données du site. Deux implémentations : api/ (API réelle) et mock/ (données
 * simulées), choisies au build par DATA_SOURCE (alias `@/server/data/source`, voir next.config.ts).
 * Les pages et les composants ne savent jamais laquelle est active.
 *
 * Tous les types viennent du client généré depuis contracts/openapi.yaml : si le contrat change,
 * les deux implémentations cessent de compiler.
 */
import type { components, operations } from "@/lib/api/schema";

import type { Locale } from "@/i18n/routing";

export type Schemas = components["schemas"];
type Json<T> = T extends { content: { "application/json": infer B } } ? B : never;

export type Problem = Schemas["Problem"];
export type Money = Schemas["Money"];
export type Tokens = Schemas["Tokens"];
export type AuthResult = Schemas["AuthResult"];
export type PlanCatalog = Schemas["PlanCatalog"];
export type CatalogPlan = PlanCatalog["plans"][number];
export type ComparisonRow = PlanCatalog["comparison"][number];
export type LegalKind = Schemas["LegalKind"];
export type LegalDocument = Schemas["LegalDocument"];
export type SubscriptionState = Schemas["SubscriptionState"];
export type Payment = Schemas["Payment"];
export type Channel = Schemas["Channel"];
export type TicketInput = Schemas["TicketInput"];
export type TicketCategory = Schemas["TicketCategory"];
export type FaqCategory = Json<operations["listFaq"]["responses"][200]>[number];
export type InviteCheck = Json<operations["checkInviteCode"]["responses"][200]>;
export type PaymentsPage = Json<operations["listPayments"]["responses"][200]>;
export type CheckoutInput = NonNullable<operations["createWebCheckout"]["requestBody"]>["content"]["application/json"];
export type CheckoutSession = Json<operations["createWebCheckout"]["responses"][201]>;
export type PromoCheckInput = NonNullable<operations["checkPromoCode"]["requestBody"]>["content"]["application/json"];
export type PromoCheck = Json<operations["checkPromoCode"]["responses"][200]>;
export type PlanCode = CheckoutInput["plan_code"];
export type SocialProvider = Schemas["SocialAuthRequest"]["provider"];
export type TicketCreated = Json<operations["createTicket"]["responses"][201]>;

/** Réponse d'un appel : la donnée, ou l'erreur problem+json du contrat. */
export type Result<T> = { ok: true; data: T } | { ok: false; problem: Problem };

/** Contexte d'une requête faite au nom du visiteur. */
export type RequestContext = {
  locale: Locale;
  /** Adresse IP du visiteur, transmise à l'API pour sa propre limitation de débit. */
  clientIp?: string;
};

/** Contexte d'une requête authentifiée (jeton d'accès lu dans le cookie httpOnly). */
export type AuthedContext = RequestContext & { accessToken: string };

export interface ContentRepository {
  /** Offres, prix (USD, formatés par l'API) et comparatif. Mis en cache, tag `plans`. */
  plans(locale: Locale): Promise<Result<PlanCatalog>>;
  /** FAQ du site, par catégorie. Mise en cache, tag `faq`. */
  faq(locale: Locale): Promise<Result<FaqCategory[]>>;
  /** Dernière version publiée d'un document légal. Mise en cache, tag `legal`. */
  legal(locale: Locale, kind: LegalKind): Promise<Result<LegalDocument>>;
}

export interface ReferralRepository {
  check(code: string, ctx: RequestContext): Promise<Result<InviteCheck>>;
}

export interface SupportRepository {
  createTicket(input: TicketInput, idempotencyKey: string, ctx: RequestContext): Promise<Result<TicketCreated>>;
}

export interface AccountDeletionRepository {
  /** Répond toujours sans erreur si la requête est valide (pas de fuite sur l'existence du compte). */
  request(email: string, captcha: string, ctx: RequestContext): Promise<Result<null>>;
  confirm(token: string, ctx: RequestContext): Promise<Result<null>>;
}

export interface AuthRepository {
  login(email: string, password: string, ctx: RequestContext): Promise<Result<AuthResult>>;
  social(provider: SocialProvider, idToken: string, nonce: string | undefined, ctx: RequestContext): Promise<Result<AuthResult>>;
  refresh(refreshToken: string, ctx: RequestContext): Promise<Result<Tokens>>;
  logout(ctx: AuthedContext): Promise<Result<null>>;
}

export interface BillingRepository {
  subscription(ctx: AuthedContext): Promise<Result<SubscriptionState>>;
  payments(cursor: string | undefined, ctx: AuthedContext): Promise<Result<PaymentsPage>>;
  checkout(input: CheckoutInput, idempotencyKey: string, ctx: AuthedContext): Promise<Result<CheckoutSession>>;
  promoCheck(input: PromoCheckInput, ctx: AuthedContext): Promise<Result<PromoCheck>>;
  portal(returnUrl: string, ctx: AuthedContext): Promise<Result<{ url: string }>>;
}

/** Comptes de démonstration et simulateurs, présents uniquement dans l'implémentation mock. */
export interface DemoControls {
  accounts(): readonly DemoAccount[];
  checkoutSession(id: string): DemoCheckout | undefined;
  /** Issue d'un paiement simulé : renvoie l'URL de retour vers le site. */
  completeCheckout(id: string, outcome: "success" | "failure" | "abandon"): string | undefined;
  /** Portail simulé : résiliation ou reprise du renouvellement. */
  setAutoRenew(accessToken: string, autoRenew: boolean): boolean;
  /** Connexion sociale simulée : le jeton d'identité d'un compte de démo. */
  socialIdToken(accountEmail: string | null): string;
}

export type DemoScenario =
  | "trial"
  | "free"
  | "plus_web"
  | "plus_store"
  | "past_due"
  | "unverified"
  | "granted"
  | "rate_limited"
  | "server_error";

export type DemoAccount = { email: string; scenario: DemoScenario };

export type DemoCheckout = {
  id: string;
  planName: string;
  amount: Money;
  expired: boolean;
};

export interface DataSource {
  content: ContentRepository;
  referral: ReferralRepository;
  support: SupportRepository;
  accountDeletion: AccountDeletionRepository;
  auth: AuthRepository;
  billing: BillingRepository;
  /** Absent avec l'API réelle. */
  demo?: DemoControls;
  /** Mot de passe commun des comptes de démo (affiché sur la page de connexion en mode mock). */
  demoPassword?: string;
  /** Le captcha est désactivé en mode mock uniquement. */
  captchaRequired: boolean;
}
