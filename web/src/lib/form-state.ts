/** Résultat d'une Server Action de formulaire, affiché par le composant client. */
export type FormState<T = null> =
  | { status: "idle" }
  | { status: "error"; message: string; fields: string[] }
  | { status: "success"; data: T };

export const IDLE: FormState<never> = { status: "idle" };
