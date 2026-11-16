"use client";

import { useTranslations } from "next-intl";
import { useState } from "react";

import { ApprovalStatusTag } from "@/components/ui/Tags";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { useAction } from "@/hooks/use-action";
import type { components } from "@/lib/api/schema";

import { cancelApproval, decideApproval } from "./actions";

export function ApprovalStatus({ status }: { status: components["schemas"]["ApprovalRequest"]["status"] }) {
  return <ApprovalStatusTag status={status} />;
}

/** Boutons d'une demande en attente : approuver / rejeter (autre personne), annuler (la sienne). */
export function ApprovalDecision({ id, mine }: { id: string; mine: boolean }) {
  const t = useTranslations("admin.approvals");
  const decide = useAction(decideApproval);
  const cancel = useAction(cancelApproval);
  const [comment, setComment] = useState("");

  if (mine) {
    return (
      <div className="row">
        <ConfirmDialog
          trigger={
            <button type="button" className="btn ghost">
              {t("cancel")}
            </button>
          }
          title={t("cancel_title")}
          confirmLabel={t("cancel")}
          onConfirm={async () => (await cancel.run({ id }, { success: t("canceled") })).ok}
        />
      </div>
    );
  }

  const field = (
    <div className="f">
      <label htmlFor={`comment-${id}`}>{t("comment")}</label>
      <textarea id={`comment-${id}`} maxLength={500} value={comment} onChange={(e) => setComment(e.target.value)} />
    </div>
  );

  return (
    <div className="row" style={{ flexWrap: "wrap" }}>
      <ConfirmDialog
        trigger={
          <button type="button" className="btn primary">
            {t("approve")}
          </button>
        }
        title={t("approve_title")}
        description={t("approve_body")}
        confirmLabel={t("approve")}
        onConfirm={async () =>
          (await decide.run({ id, decision: "approve", ...(comment.trim() ? { comment: comment.trim() } : {}) }, { success: t("approved") })).ok
        }
      >
        {field}
      </ConfirmDialog>
      <ConfirmDialog
        trigger={
          <button type="button" className="btn danger">
            {t("reject")}
          </button>
        }
        title={t("reject_title")}
        confirmLabel={t("reject")}
        danger
        onConfirm={async () =>
          (await decide.run({ id, decision: "reject", ...(comment.trim() ? { comment: comment.trim() } : {}) }, { success: t("rejected") })).ok
        }
      >
        {field}
      </ConfirmDialog>
    </div>
  );
}
