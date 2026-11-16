/**
 * Scénarios de démonstration du mode mock (bandeau « Données simulées »). Partagé entre le sélecteur
 * (client) et le mock (serveur) ; ne contient aucune donnée simulée.
 */
export const MOCK_SCENARIO_COOKIE = "omeo_mock_scenario";

export const MOCK_SCENARIOS = ["normal", "slow", "step_up", "server_error", "rate_limited", "offline"] as const;

export type MockScenario = (typeof MOCK_SCENARIOS)[number];

export function isMockScenario(value: unknown): value is MockScenario {
  return typeof value === "string" && (MOCK_SCENARIOS as readonly string[]).includes(value);
}
