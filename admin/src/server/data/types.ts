/**
 * Types communs de la couche de données de l'admin. Tous viennent du client généré depuis
 * contracts/openapi.yaml (`pnpm gen:api`) : si le contrat change, les implémentations mock et api
 * cessent de compiler, et c'est voulu. Aucun type d'API n'est écrit à la main.
 */
import type { components, operations, paths } from "@/lib/api/schema";

export type { paths };
export type Schemas = components["schemas"];

type JsonOf<T> = T extends { content: { "application/json": infer B } } ? B : never;
/** Corps JSON de la réponse `status` d'une opération. */
export type ResponseOf<Op extends keyof operations, Status extends number> =
  operations[Op]["responses"] extends Record<Status, infer R> ? JsonOf<R> : never;
/** Corps JSON de la requête d'une opération. */
export type BodyOf<Op extends keyof operations> =
  NonNullable<operations[Op]["requestBody"]> extends { content: { "application/json": infer B } } ? B : never;
/** Paramètres de requête (query) d'une opération. */
export type QueryOf<Op extends keyof operations> = operations[Op]["parameters"] extends { query?: infer Q }
  ? NonNullable<Q>
  : never;

export type Problem = Schemas["Problem"];
export type Locale = Schemas["Locale"];
export type I18nText = Schemas["I18nText"];
export type StaffMember = Schemas["StaffMember"];
export type StaffRole = Schemas["StaffRole"];
export type ApprovalRequest = Schemas["ApprovalRequest"];
export type Tokens = Schemas["Tokens"];

/** Réponse d'un appel : la donnée, ou l'erreur problem+json du contrat. */
export type Result<T> = { ok: true; data: T } | { ok: false; problem: Problem };

/**
 * Résultat d'une action « quatre yeux » : appliquée tout de suite (200), ou transformée en demande
 * de validation par une autre personne (202 + ApprovalRequest).
 */
export type Applied<T> = { status: "applied"; data: T } | { status: "pending"; approval: ApprovalRequest };

/** Page d'une liste paginée (PageMeta du contrat). */
export type Page<T> = { results: T[]; count: number; page: number; page_size: number };

/** Contexte d'une requête faite par le navigateur, avant authentification. */
export type RequestContext = {
  /** Adresse IP de la personne, transmise à l'API (X-Forwarded-For) pour l'audit et le débit. */
  clientIp?: string;
  /** Langue de l'interface (Accept-Language) : formats des montants renvoyés par l'API. */
  locale: Locale;
};

/** Contexte d'une requête authentifiée (jeton d'accès lu dans le cookie httpOnly). */
export type StaffContext = RequestContext & { accessToken: string };
