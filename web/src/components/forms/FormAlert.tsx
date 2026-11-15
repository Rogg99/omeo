import type { FormState } from "@/lib/form-state";

import { Icon } from "../icons/Icon";

/** Erreur d'envoi, annoncée aux lecteurs d'écran (role="alert"). */
export function FormAlert({ state, id }: { state: FormState<unknown>; id: string }) {
  if (state.status !== "error") return <div id={id} />;
  return (
    <p id={id} className="note danger" role="alert">
      <Icon name="alert" />
      <span>{state.message}</span>
    </p>
  );
}

/** Attributs d'un champ selon l'état : invalide et relié au message d'erreur. */
export function fieldProps(state: FormState<unknown>, name: string, errorId: string) {
  const invalid = state.status === "error" && state.fields.includes(name);
  return { name, "aria-invalid": invalid || undefined, "aria-describedby": invalid ? errorId : undefined };
}
