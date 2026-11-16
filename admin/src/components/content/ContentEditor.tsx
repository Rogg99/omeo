"use client";

import * as Dialog from "@radix-ui/react-dialog";
import { useTranslations } from "next-intl";
import { useRouter } from "next/navigation";
import { useMemo, useState } from "react";

import { deleteContent, saveContent, transitionContent, translateContent } from "@/app/(app)/content/actions";
import { Icon } from "@/components/icons/Icon";
import { useStaff } from "@/components/providers/StaffProvider";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { useAction } from "@/hooks/use-action";
import { isPending, PROBLEM } from "@/lib/action-result";
import type { components } from "@/lib/api/schema";
import { CONTENT_FIELDS } from "@/lib/content-schema";
import { NEXT_STATUSES, type ContentStatus, type ContentType } from "@/lib/content-types";
import { formatDateTime } from "@/lib/format";
import { direction, LOCALES, REFERENCE_LOCALE, type Locale } from "@/lib/locales";

import { Field } from "./fields";

type Item = components["schemas"]["AdminContentItem"];
type Revision = { id: string; author: string; created_at: string };
type Data = Record<string, unknown>;
type I18n = Partial<Record<Locale, string>>;

const isI18n = (v: unknown): v is I18n => typeof v === "object" && v !== null && !Array.isArray(v) && "fr" in v;

/** Textes multilingues d'un contenu (à toute profondeur) : sert au décompte par onglet de langue. */
function i18nValues(value: unknown, out: I18n[] = []): I18n[] {
  if (isI18n(value)) out.push(value);
  else if (Array.isArray(value)) value.forEach((v) => i18nValues(v, out));
  else if (value && typeof value === "object") Object.values(value).forEach((v) => i18nValues(v, out));
  return out;
}

/** Champs modifiés localement par rapport à la version chargée (fusion après un conflit). */
function changedKeys(local: Data, base: Data): string[] {
  return Object.keys(local).filter((k) => JSON.stringify(local[k]) !== JSON.stringify(base[k]));
}

export function ContentEditor({ type, initial, initialData, revisions = [] }: { type: ContentType; initial: Item | null; initialData: Data; revisions?: Revision[] }) {
  const t = useTranslations("admin.content");
  const tc = useTranslations("common.action");
  const router = useRouter();
  const { staff, can } = useStaff();
  const fields = CONTENT_FIELDS[type];
  const [data, setData] = useState<Data>(initialData);
  const [locale, setLocale] = useState<Locale>(REFERENCE_LOCALE);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [conflict, setConflict] = useState<Item | null>(null);
  const [proposals, setProposals] = useState<Record<string, I18n> | null>(null);
  const [accepted, setAccepted] = useState<Record<string, boolean>>({});
  const save = useAction(saveContent);
  const move = useAction(transitionContent);
  const remove = useAction(deleteContent);
  const translate = useAction(translateContent);

  const editable = can("content.edit") && initial?.status !== "archived";
  const dirty = JSON.stringify(data) !== JSON.stringify(initialData);
  const missingCount = useMemo(() => {
    const values = i18nValues(data);
    return Object.fromEntries(LOCALES.map((l) => [l, values.filter((v) => !v[l]?.trim()).length])) as Record<Locale, number>;
  }, [data]);

  function validate(): boolean {
    const next: Record<string, string> = {};
    for (const f of fields) {
      const v = data[f.name];
      if (f.required && f.kind === "i18n" && !(isI18n(v) && v.fr?.trim())) next[f.name] = t("required_fr");
      else if (f.required && (v === undefined || v === null || v === "" || (Array.isArray(v) && v.length === 0))) next[f.name] = t("required");
      else if (f.kind === "number" && typeof v === "number" && ((f.min !== undefined && v < f.min) || (f.max !== undefined && v > f.max))) {
        next[f.name] = t("range", { min: f.min ?? "—", max: f.max ?? "—" });
      } else if (f.kind === "text" && f.pattern && typeof v === "string" && v && !new RegExp(f.pattern).test(v)) next[f.name] = t("format");
    }
    setErrors(next);
    if (Object.keys(next).length) setLocale(REFERENCE_LOCALE);
    return Object.keys(next).length === 0;
  }

  async function onSave() {
    if (!validate()) return;
    const result = await save.run({ type, id: initial?.id, version: initial ? (conflict?.version ?? initial.version) : undefined, data }, { handleConflict: true, handleValidation: true, success: t("saved") });
    if (!result.ok) {
      const current = result.problem.meta?.current as Item | undefined;
      if (result.problem.code === PROBLEM.conflict && current) setConflict(current);
      if (result.problem.errors) setErrors(Object.fromEntries(Object.entries(result.problem.errors).map(([k, v]) => [k.replace(/^data\./, ""), v.join(" ")])));
      return;
    }
    setConflict(null);
    if (!initial && "data" in result) router.push(`/content/${type}/${result.data.id}`);
  }

  /** Fusion : la version actuelle du serveur, avec mes champs modifiés par-dessus. */
  function merge() {
    if (!conflict) return;
    const mine = changedKeys(data, initialData);
    setData({ ...conflict.data, ...Object.fromEntries(mine.map((k) => [k, data[k]])) });
  }

  async function onTranslate() {
    if (!initial) return;
    const targets = LOCALES.filter((l) => l !== REFERENCE_LOCALE && missingCount[l] > 0);
    if (targets.length === 0) return;
    const result = await translate.run({ type, id: initial.id, locales: targets });
    if (result.ok && "data" in result) {
      setProposals(result.data);
      setAccepted(Object.fromEntries(Object.keys(result.data).map((k) => [k, true])));
    }
  }

  function applyProposals() {
    if (!proposals) return;
    const next = { ...data };
    for (const [key, text] of Object.entries(proposals)) {
      if (!accepted[key]) continue;
      const current = isI18n(next[key]) ? (next[key] as I18n) : {};
      next[key] = { ...text, ...Object.fromEntries(Object.entries(current).filter(([, v]) => v?.trim())) };
    }
    setData(next);
    setProposals(null);
  }

  async function onTransition(to: ContentStatus, comment?: string) {
    if (!initial) return false;
    const result = await move.run(
      { type, id: initial.id, to, ...(comment ? { comment } : {}) },
      {
        success: t(`moved_${to}`),
        // Archiver se défait en repassant en brouillon (seule transition permise depuis « archivé »).
        undo: to === "archived" ? { label: t("undo"), run: () => void move.run({ type, id: initial.id, to: "draft" }) } : undefined,
      },
    );
    return result.ok || isPending(result);
  }

  const own = initial?.updated_by === staff.name;
  const canPublishOther = can("content.publish") && !own;
  const canPublishOwn = own && can("content.publish_own");
  const nextStatuses = initial ? NEXT_STATUSES[initial.status] : [];
  const title = data.name ?? data.common_name ?? data.title ?? data.question;

  return (
    <div className="grid g-21">
      <div className="stack">
        <div className="card stack">
          <div className="row" style={{ flexWrap: "wrap", justifyContent: "space-between" }}>
            <div role="tablist" aria-label={t("languages")} className="row" style={{ gap: 4, flexWrap: "wrap" }}>
              {LOCALES.map((l) => (
                <button
                  key={l}
                  type="button"
                  role="tab"
                  aria-selected={locale === l}
                  className={`btn sm ${locale === l ? "" : "ghost"}`}
                  onClick={() => setLocale(l)}
                  title={missingCount[l] ? t("missing_n", { count: missingCount[l] }) : t("translations_complete")}
                >
                  {l.toUpperCase()}
                  {missingCount[l] ? <span className="tag orange">{missingCount[l]}</span> : <Icon name="check" size={14} />}
                </button>
              ))}
            </div>
            {initial && can("content.translate") ? (
              <button type="button" className="btn ghost sm" onClick={onTranslate} disabled={translate.busy || dirty}>
                <Icon name="wand" />
                {t("translate_ai")}
              </button>
            ) : null}
          </div>
          {dirty && initial && can("content.translate") ? <p className="faint small">{t("save_before_translate")}</p> : null}
          <div role="tabpanel" className="stack" lang={locale} dir={direction(locale)}>
            {fields.map((spec) => (
              <Field
                key={spec.name}
                type={type}
                spec={spec}
                locale={locale}
                value={data[spec.name]}
                error={errors[spec.name]}
                disabled={!editable}
                onChange={(v) => setData((d) => ({ ...d, [spec.name]: v }))}
              />
            ))}
          </div>
        </div>
      </div>

      <aside className="stack">
        {editable ? (
          <section className="card stack">
            <button type="button" className="btn primary" onClick={onSave} disabled={save.busy || (!dirty && Boolean(initial))}>
              <Icon name="check" />
              {tc("save")}
            </button>
            {initial?.status === "draft" ? (
              <ConfirmDialog
                trigger={
                  <button type="button" className="btn danger">
                    <Icon name="trash" />
                    {tc("delete")}
                  </button>
                }
                title={t("delete_title")}
                description={t("delete_body")}
                confirmLabel={tc("delete")}
                danger
                confirmValue={initial.title}
                onConfirm={async () => {
                  const r = await remove.run({ type, id: initial.id }, { success: t("deleted") });
                  if (r.ok) router.push(`/content/${type}`);
                  return r.ok;
                }}
              />
            ) : null}
          </section>
        ) : null}

        {initial ? (
          <section className="card stack" aria-labelledby="workflow">
            <h3 id="workflow">{t("workflow")}</h3>
            {nextStatuses.map((to) => {
              if (to === "published") {
                if (canPublishOwn) {
                  return (
                    <ConfirmDialog
                      key={to}
                      trigger={<button type="button" className="btn primary">{t("action_published")}</button>}
                      title={t("publish_own_title")}
                      description={t("publish_own_body")}
                      confirmLabel={t("action_published")}
                      requireReason
                      onConfirm={(reason) => onTransition("published", reason)}
                    />
                  );
                }
                if (own) {
                  return (
                    <div key={to} className="stack" style={{ gap: 6 }}>
                      <button type="button" className="btn primary" disabled aria-describedby="publish-own-note">
                        {t("action_published")}
                      </button>
                      <p id="publish-own-note" className="note info small">
                        {t("publish_own_forbidden")}
                      </p>
                    </div>
                  );
                }
                if (!canPublishOther) return null;
              }
              if (!can("content.edit") && to !== "published") return null;
              return (
                <button key={to} type="button" className={`btn ${to === "published" ? "primary" : "ghost"}`} disabled={move.busy || dirty} onClick={() => void onTransition(to)}>
                  {t(`action_${to}`)}
                </button>
              );
            })}
            {dirty ? <p className="faint small">{t("save_before_transition")}</p> : null}
          </section>
        ) : null}

        {initial?.computed ? (
          <section className="card stack" aria-labelledby="computed">
            <h3 id="computed">{t("computed")}</h3>
            <dl className="kv">
              {Object.entries((initial.computed.per_serving ?? initial.computed.per_portion ?? initial.computed) as Record<string, unknown>).map(([k, v]) => (
                <div key={k} style={{ display: "contents" }}>
                  <dt>{t.has(`field_${k}`) ? t(`field_${k}`) : k}</dt>
                  <dd className="num">{String(v)}</dd>
                </div>
              ))}
            </dl>
            <p className="faint small">{t("computed_hint")}</p>
          </section>
        ) : null}

        <section className="card stack" aria-labelledby="preview">
          <h3 id="preview">{t("preview", { locale: locale.toUpperCase() })}</h3>
          <div lang={locale} dir={direction(locale)} className="note lock" style={{ display: "block" }}>
            <b>{isI18n(title) ? (title[locale] || title.fr) : "—"}</b>
          </div>
        </section>

        {revisions.length ? (
          <section className="card stack" aria-labelledby="history">
            <h3 id="history">{t("history")}</h3>
            {revisions.slice(0, 10).map((r, i) => (
              <div key={r.id} className="list-i small">
                <span className="tag">v{revisions.length - i}</span>
                <span style={{ flex: 1 }}>{r.author}</span>
                <span className="faint">{formatDateTime(r.created_at)}</span>
              </div>
            ))}
          </section>
        ) : null}
      </aside>

      <Dialog.Root open={conflict !== null} onOpenChange={(o) => !o && setConflict(null)}>
        <Dialog.Portal>
          <Dialog.Overlay className="scrim" />
          <Dialog.Content className="dialog">
            <Dialog.Title asChild>
              <h2>{t("conflict_title")}</h2>
            </Dialog.Title>
            <Dialog.Description className="muted">{t("conflict_body", { by: conflict?.updated_by ?? "—" })}</Dialog.Description>
            <div className="foot">
              <button type="button" className="btn ghost" onClick={() => router.refresh()}>
                {t("conflict_reload")}
              </button>
              <button type="button" className="btn primary" onClick={() => { merge(); void onSave(); }}>
                {t("conflict_merge")}
              </button>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

      <Dialog.Root open={proposals !== null} onOpenChange={(o) => !o && setProposals(null)}>
        <Dialog.Portal>
          <Dialog.Overlay className="scrim" />
          <Dialog.Content className="dialog wide">
            <Dialog.Title asChild>
              <h2>{t("proposals_title")}</h2>
            </Dialog.Title>
            <Dialog.Description className="muted">{t("proposals_body")}</Dialog.Description>
            {Object.entries(proposals ?? {}).map(([key, text]) => (
              <label key={key} className="card stack" style={{ padding: 12 }}>
                <span className="row">
                  <input type="checkbox" checked={accepted[key] ?? false} onChange={(e) => setAccepted((a) => ({ ...a, [key]: e.target.checked }))} />
                  <b>{t.has(`field_${key}`) ? t(`field_${key}`) : key}</b>
                </span>
                {Object.entries(text).map(([l, v]) => (
                  <span key={l} className="small" lang={l} dir={direction(l as Locale)}>
                    <span className="tag">{l.toUpperCase()}</span> {v}
                  </span>
                ))}
              </label>
            ))}
            <div className="foot">
              <Dialog.Close asChild>
                <button type="button" className="btn ghost">
                  {tc("cancel")}
                </button>
              </Dialog.Close>
              <button type="button" className="btn primary" onClick={applyProposals}>
                {t("proposals_apply")}
              </button>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  );
}
