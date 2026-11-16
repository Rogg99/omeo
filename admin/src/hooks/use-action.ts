"use client";

import { useTranslations } from "next-intl";
import { useRouter } from "next/navigation";
import { useCallback, useState } from "react";

import { useCsrf } from "@/components/providers/StaffProvider";
import { useStepUp } from "@/components/providers/StepUpProvider";
import { useToast } from "@/components/providers/ToastProvider";
import { isPending, PROBLEM, type ActionResult } from "@/lib/action-result";

type Options = {
  /** Message de réussite (toast). */
  success?: string;
  /** Laisse les erreurs de validation au formulaire appelant (pas de toast). */
  handleValidation?: boolean;
  /** Laisse le conflit 409 à l'appelant (verrou optimiste). */
  handleConflict?: boolean;
  /** Bouton « Annuler » du toast de réussite. */
  undo?: { label: string; run: () => void };
};

/**
 * Exécute une Server Action avec les comportements communs de l'admin, selon le `code` d'erreur :
 * - jeton CSRF ajouté à l'entrée ;
 * - 401 `step_up_required` : fenêtre de code TOTP, puis rejeu automatique de l'action ;
 * - 202 (quatre yeux) : « En attente de validation par une autre personne » ;
 * - 401 session : retour à la connexion ; 403 : message du refus ; autres : toast d'erreur.
 */
export function useAction<I extends object, T>(action: (input: I & { csrf: string }) => Promise<ActionResult<T>>) {
  const csrf = useCsrf();
  const requestStepUp = useStepUp();
  const toast = useToast();
  const router = useRouter();
  const t = useTranslations();
  const [busy, setBusy] = useState(false);

  const run = useCallback(
    async (input: I, options: Options = {}): Promise<ActionResult<T>> => {
      setBusy(true);
      try {
        let result = await action({ ...input, csrf });
        if (!result.ok && result.problem.code === PROBLEM.stepUpRequired && (await requestStepUp())) {
          result = await action({ ...input, csrf });
        }
        if (isPending(result)) {
          toast(t("admin.approval.pending"), { description: t("admin.approval.pending_detail", { summary: result.pending.summary }) });
          router.refresh();
        } else if (result.ok) {
          if (options.success) toast(options.success, { tone: "success", undo: options.undo });
        } else {
          const { code, status } = result.problem;
          if (code === PROBLEM.notAuthenticated || code === PROBLEM.tokenExpired) {
            router.push("/login");
          } else if (code === PROBLEM.stepUpRequired) {
            // Fenêtre fermée sans code : rien à signaler.
          } else if (code === PROBLEM.validation && options.handleValidation) {
            // Erreurs affichées par le formulaire.
          } else if (code === PROBLEM.conflict && options.handleConflict) {
            // Conflit géré par l'appelant (rechargement ou fusion).
          } else {
            const key = t.has(`errors.${code}`) ? `errors.${code}` : status >= 500 ? "errors.server_error" : "errors.forbidden";
            toast(t(key), { tone: "error" });
          }
        }
        return result;
      } finally {
        setBusy(false);
      }
    },
    [action, csrf, requestStepUp, toast, router, t],
  );

  return { run, busy };
}
