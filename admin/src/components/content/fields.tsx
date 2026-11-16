"use client";

import { useTranslations } from "next-intl";
import { useEffect, useId, useState } from "react";

import { searchContent } from "@/app/(app)/content/actions";
import { Icon } from "@/components/icons/Icon";
import { useAction } from "@/hooks/use-action";
import { RULE_METRICS, RULE_OPERATORS, type FieldSpec } from "@/lib/content-schema";
import type { ContentType } from "@/lib/content-types";
import { direction, LOCALES, type Locale } from "@/lib/locales";

import { MediaField, SubtitlesField } from "./media";

/**
 * Champs de l'éditeur de contenus. Chaque champ reçoit sa valeur et la remplace en entier (données
 * immuables) ; l'éditeur parent garde l'état et l'envoie tel quel à l'API.
 */
type Value = unknown;
type Change = (value: Value) => void;
type Obj = Record<string, unknown>;
type I18n = Partial<Record<Locale, string>>;

export type FieldProps = { spec: FieldSpec; value: Value; onChange: Change; locale: Locale; error?: string; disabled?: boolean };

const asObj = (v: Value): Obj => (v && typeof v === "object" && !Array.isArray(v) ? (v as Obj) : {});
const asList = <T,>(v: Value): T[] => (Array.isArray(v) ? (v as T[]) : []);
const asI18n = (v: Value): I18n => asObj(v) as I18n;

function useLabel(name: string) {
  const t = useTranslations("admin.content");
  return t.has(`field_${name}`) ? t(`field_${name}`) : name;
}

function Shell({ label, htmlFor, error, hint, children }: { label: string; htmlFor?: string; error?: string; hint?: string; children: React.ReactNode }) {
  return (
    <div className="f">
      {htmlFor ? <label htmlFor={htmlFor}>{label}</label> : <span className="label">{label}</span>}
      {children}
      {hint ? <span className="hint">{hint}</span> : null}
      {error ? (
        <span className="err" role="alert">
          {error}
        </span>
      ) : null}
    </div>
  );
}

/** Texte multilingue : on édite la langue active ; le français sert de référence. */
function I18nField({ spec, value, onChange, locale, error, disabled }: FieldProps) {
  const t = useTranslations("admin.content");
  const id = useId();
  const label = useLabel(spec.name);
  const text = asI18n(value);
  const long = spec.kind === "i18n" && spec.long;
  const props = {
    id,
    value: text[locale] ?? "",
    lang: locale,
    dir: direction(locale),
    disabled,
    "aria-invalid": error ? true : undefined,
    onChange: (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => onChange({ ...text, [locale]: e.target.value }),
  };
  return (
    <Shell
      label={`${label} (${locale.toUpperCase()})`}
      htmlFor={id}
      error={error}
      hint={locale !== "fr" && text.fr ? t("reference", { text: text.fr }) : undefined}
    >
      {long ? <textarea {...props} rows={4} /> : <input {...props} />}
    </Shell>
  );
}

function TagsField({ spec, value, onChange, error, disabled }: FieldProps) {
  const t = useTranslations("admin.content");
  const id = useId();
  const label = useLabel(spec.name);
  const list = asList<string>(value);
  const [draft, setDraft] = useState(list.join(", "));
  return (
    <Shell label={label} htmlFor={id} error={error} hint={t("tags_hint")}>
      <input
        id={id}
        value={draft}
        disabled={disabled}
        onChange={(e) => setDraft(e.target.value)}
        onBlur={() =>
          onChange(
            draft
              .split(",")
              .map((s) => s.trim())
              .filter(Boolean),
          )
        }
      />
    </Shell>
  );
}

function NumberField({ spec, value, onChange, error, disabled }: FieldProps) {
  const id = useId();
  const label = useLabel(spec.name);
  if (spec.kind !== "number") return null;
  return (
    <Shell label={spec.unit ? `${label} (${spec.unit})` : label} htmlFor={id} error={error}>
      <input
        id={id}
        type="number"
        inputMode="decimal"
        min={spec.min}
        max={spec.max}
        step={spec.step ?? 1}
        disabled={disabled}
        value={typeof value === "number" ? value : ""}
        aria-invalid={error ? true : undefined}
        onChange={(e) => onChange(e.target.value === "" ? null : Number(e.target.value))}
      />
    </Shell>
  );
}

function SelectField({ spec, value, onChange, error, disabled }: FieldProps) {
  const t = useTranslations("admin.content");
  const id = useId();
  const label = useLabel(spec.name);
  if (spec.kind !== "select") return null;
  return (
    <Shell label={label} htmlFor={id} error={error}>
      <select id={id} value={typeof value === "string" ? value : ""} disabled={disabled} onChange={(e) => onChange(e.target.value || null)}>
        <option value="">—</option>
        {spec.options.map((o) => (
          <option key={o} value={o}>
            {t.has(`opt_${o}`) ? t(`opt_${o}`) : o}
          </option>
        ))}
      </select>
    </Shell>
  );
}

function MultiField({ spec, value, onChange, disabled }: FieldProps) {
  const t = useTranslations("admin.content");
  const label = useLabel(spec.name);
  if (spec.kind !== "multi") return null;
  const list = asList<string>(value);
  return (
    <fieldset className="f" style={{ border: 0, padding: 0, margin: 0 }}>
      <legend className="label">{label}</legend>
      <div className="row" style={{ flexWrap: "wrap" }}>
        {spec.options.map((o) => (
          <label key={o} className="row small">
            <input
              type="checkbox"
              disabled={disabled}
              checked={list.includes(o)}
              onChange={(e) => onChange(e.target.checked ? [...list, o] : list.filter((x) => x !== o))}
            />
            {t.has(`opt_${o}`) ? t(`opt_${o}`) : o}
          </label>
        ))}
      </div>
    </fieldset>
  );
}

function BooleanField({ spec, value, onChange, disabled }: FieldProps) {
  const label = useLabel(spec.name);
  return (
    <label className="row">
      <input type="checkbox" checked={value === true} disabled={disabled} onChange={(e) => onChange(e.target.checked)} />
      {label}
    </label>
  );
}

function TextField({ spec, value, onChange, error, disabled }: FieldProps) {
  const id = useId();
  const label = useLabel(spec.name);
  return (
    <Shell label={label} htmlFor={id} error={error}>
      <input
        id={id}
        value={typeof value === "string" ? value : ""}
        disabled={disabled}
        pattern={spec.kind === "text" ? spec.pattern : undefined}
        aria-invalid={error ? true : undefined}
        onChange={(e) => onChange(e.target.value)}
      />
    </Shell>
  );
}

/** JSON libre (condition d'un badge) : validé à la sortie du champ. */
function JsonField({ spec, value, onChange, error, disabled }: FieldProps) {
  const t = useTranslations("admin.content");
  const id = useId();
  const label = useLabel(spec.name);
  const [draft, setDraft] = useState(JSON.stringify(value ?? {}, null, 2));
  const [invalid, setInvalid] = useState(false);
  return (
    <Shell label={label} htmlFor={id} error={invalid ? t("json_invalid") : error}>
      <textarea
        id={id}
        rows={5}
        className="num"
        value={draft}
        disabled={disabled}
        aria-invalid={invalid || undefined}
        onChange={(e) => setDraft(e.target.value)}
        onBlur={() => {
          try {
            onChange(JSON.parse(draft));
            setInvalid(false);
          } catch {
            setInvalid(true);
          }
        }}
      />
    </Shell>
  );
}

/** Choix de contenus liés (recherche côté API). */
export function RefPicker({ type, value, onChange, multiple, label, disabled }: { type: ContentType; value: Value; onChange: Change; multiple?: boolean; label: string; disabled?: boolean }) {
  const t = useTranslations("admin.content");
  const id = useId();
  const { run } = useAction(searchContent);
  const [q, setQ] = useState("");
  const [options, setOptions] = useState<{ id: string; title: string }[]>([]);
  const selected = multiple ? asList<string>(value) : typeof value === "string" ? [value] : [];
  const [titles, setTitles] = useState<Record<string, string>>({});

  useEffect(() => {
    const timer = window.setTimeout(async () => {
      const r = await run({ type, q: q || undefined });
      if (r.ok && "data" in r) {
        setOptions(r.data);
        setTitles((prev) => ({ ...prev, ...Object.fromEntries(r.data.map((o) => [o.id, o.title])) }));
      }
    }, 250);
    return () => window.clearTimeout(timer);
  }, [q, type, run]);

  const add = (optionId: string) => onChange(multiple ? [...new Set([...selected, optionId])] : optionId);
  const remove = (optionId: string) => onChange(multiple ? selected.filter((s) => s !== optionId) : null);

  return (
    <div className="f">
      <label htmlFor={id}>{label}</label>
      <div className="row" style={{ flexWrap: "wrap" }}>
        {selected.map((s) => (
          <span key={s} className="tag">
            {titles[s] ?? s.slice(0, 8)}
            {disabled ? null : (
              <button type="button" className="icon-b" style={{ width: 22, height: 22 }} aria-label={t("remove_item", { item: titles[s] ?? s })} onClick={() => remove(s)}>
                <Icon name="x" size={12} />
              </button>
            )}
          </span>
        ))}
      </div>
      {disabled ? null : (
        <>
          <input id={id} type="search" value={q} placeholder={t("search_ref")} onChange={(e) => setQ(e.target.value)} />
          <div className="row" style={{ flexWrap: "wrap" }}>
            {options
              .filter((o) => !selected.includes(o.id))
              .slice(0, 8)
              .map((o) => (
                <button key={o.id} type="button" className="btn ghost sm" onClick={() => add(o.id)}>
                  <Icon name="plus" />
                  {o.title}
                </button>
              ))}
          </div>
        </>
      )}
    </div>
  );
}

/** Constructeur de règle : donnée, condition, seuil (sur la journée). */
export function RuleEditor({ value, onChange, disabled, label }: { value: Value; onChange: Change; disabled?: boolean; label: string }) {
  const t = useTranslations("admin.content");
  const rule = asObj(value);
  const set = (patch: Obj) => onChange({ period: "day", ...rule, ...patch });
  return (
    <fieldset className="card stack" style={{ padding: 14 }}>
      <legend className="label">{label}</legend>
      <div className="row" style={{ flexWrap: "wrap" }}>
        <span>{t("rule_each_day")}</span>
        <label>
          <span className="sr-only">{t("rule_metric")}</span>
          <select value={String(rule.metric ?? "")} disabled={disabled} onChange={(e) => set({ metric: e.target.value })}>
            {RULE_METRICS.map((m) => (
              <option key={m} value={m}>
                {t(`metric_${m}`)}
              </option>
            ))}
          </select>
        </label>
        <label>
          <span className="sr-only">{t("rule_operator")}</span>
          <select value={String(rule.operator ?? "gte")} disabled={disabled} onChange={(e) => set({ operator: e.target.value })}>
            {RULE_OPERATORS.map((o) => (
              <option key={o} value={o}>
                {t(`op_${o}`)}
              </option>
            ))}
          </select>
        </label>
        <label>
          <span className="sr-only">{t("rule_threshold")}</span>
          <input
            type="number"
            min={0}
            style={{ width: 120 }}
            disabled={disabled || rule.metric === "manual"}
            value={typeof rule.threshold === "number" ? rule.threshold : ""}
            onChange={(e) => set({ threshold: Number(e.target.value) })}
          />
        </label>
      </div>
      <p className="faint small">{t("rule_hint")}</p>
    </fieldset>
  );
}

/** Déclencheur d'un conseil de prévention : donnée, condition, seuil, sur N jours. */
function TriggerEditor({ spec, value, onChange, disabled }: FieldProps) {
  const t = useTranslations("admin.content");
  const label = useLabel(spec.name);
  const trigger = asObj(value);
  const set = (patch: Obj) => onChange({ ...trigger, ...patch });
  return (
    <fieldset className="card stack" style={{ padding: 14 }}>
      <legend className="label">{label}</legend>
      <div className="row" style={{ flexWrap: "wrap" }}>
        <label className="row small">
          {t("trigger_metric")}
          <select value={String(trigger.metric ?? "")} disabled={disabled} onChange={(e) => set({ metric: e.target.value })}>
            {["salt_g", "sugars_g", "fiber_g", "water_ml", "protein_g", "active_minutes"].map((m) => (
              <option key={m} value={m}>
                {t(`metric_${m}`)}
              </option>
            ))}
          </select>
        </label>
        <select aria-label={t("rule_operator")} value={String(trigger.operator ?? "gte")} disabled={disabled} onChange={(e) => set({ operator: e.target.value })}>
          {RULE_OPERATORS.map((o) => (
            <option key={o} value={o}>
              {t(`op_${o}`)}
            </option>
          ))}
        </select>
        <input aria-label={t("rule_threshold")} type="number" min={0} style={{ width: 100 }} disabled={disabled} value={typeof trigger.threshold === "number" ? trigger.threshold : ""} onChange={(e) => set({ threshold: Number(e.target.value) })} />
        <label className="row small">
          {t("trigger_days")}
          <input type="number" min={1} max={30} style={{ width: 80 }} disabled={disabled} value={typeof trigger.days === "number" ? trigger.days : ""} onChange={(e) => set({ days: Number(e.target.value) })} />
        </label>
      </div>
    </fieldset>
  );
}

/** Liste d'éléments ordonnés avec ajout, suppression et déplacement. */
function ListEditor<T>({
  label,
  items,
  onChange,
  make,
  render,
  disabled,
}: {
  label: string;
  items: T[];
  onChange: (items: T[]) => void;
  make: () => T;
  render: (item: T, update: (item: T) => void, index: number) => React.ReactNode;
  disabled?: boolean;
}) {
  const t = useTranslations("admin.content");
  const move = (from: number, to: number) => {
    const next = [...items];
    const [moved] = next.splice(from, 1);
    if (moved !== undefined) next.splice(to, 0, moved);
    onChange(next);
  };
  return (
    <fieldset className="stack" style={{ border: 0, padding: 0, margin: 0 }}>
      <legend className="label">{label}</legend>
      {items.map((item, i) => (
        <div key={i} className="card row" style={{ padding: 12, alignItems: "flex-start" }}>
          <span className="tag">{i + 1}</span>
          <div style={{ flex: 1 }} className="stack">
            {render(item, (next) => onChange(items.map((x, j) => (j === i ? next : x))), i)}
          </div>
          {disabled ? null : (
            <div className="stack" style={{ gap: 4 }}>
              <button type="button" className="icon-b" aria-label={t("move_up")} disabled={i === 0} onClick={() => move(i, i - 1)}>
                <Icon name="chevU" />
              </button>
              <button type="button" className="icon-b" aria-label={t("move_down")} disabled={i === items.length - 1} onClick={() => move(i, i + 1)}>
                <Icon name="chevD" />
              </button>
              <button type="button" className="icon-b" aria-label={t("remove")} onClick={() => onChange(items.filter((_, j) => j !== i))}>
                <Icon name="trash" />
              </button>
            </div>
          )}
        </div>
      ))}
      {disabled ? null : (
        <button type="button" className="btn ghost sm" onClick={() => onChange([...items, make()])} style={{ alignSelf: "flex-start" }}>
          <Icon name="plus" />
          {t("add")}
        </button>
      )}
    </fieldset>
  );
}

/** Ingrédients ou composants : un aliment de la base (Food) et un grammage ; nutriments calculés par l'API. */
function FoodLines({ spec, value, onChange, disabled }: FieldProps) {
  const t = useTranslations("admin.content");
  const label = useLabel(spec.name);
  return (
    <ListEditor<Obj>
      label={label}
      items={asList<Obj>(value)}
      onChange={onChange}
      disabled={disabled}
      make={() => ({ food_id: "", grams: 100 })}
      render={(line, update) => (
        <div className="grid g2">
          <RefPicker type="foods" label={t("field_food")} value={line.food_id || null} disabled={disabled} onChange={(v) => update({ ...line, food_id: v ?? "" })} />
          <label className="f">
            <span className="label">{t("field_grams")}</span>
            <input type="number" min={0} disabled={disabled} value={Number(line.grams ?? 0)} onChange={(e) => update({ ...line, grams: Number(e.target.value) })} />
          </label>
        </div>
      )}
    />
  );
}

function StepsField({ spec, value, onChange, locale, disabled }: FieldProps) {
  const label = useLabel(spec.name);
  return (
    <ListEditor<Obj>
      label={label}
      items={asList<Obj>(value)}
      onChange={onChange}
      disabled={disabled}
      make={() => ({ text: { fr: "" } })}
      render={(step, update) => (
        <I18nField spec={{ name: "step_text", kind: "i18n", long: true }} locale={locale} disabled={disabled} value={step.text} onChange={(v) => update({ ...step, text: v })} />
      )}
    />
  );
}

function WorkoutSteps({ spec, value, onChange, disabled }: FieldProps) {
  const t = useTranslations("admin.content");
  const label = useLabel(spec.name);
  return (
    <ListEditor<Obj>
      label={label}
      items={asList<Obj>(value)}
      onChange={onChange}
      disabled={disabled}
      make={() => ({ exercise_id: "", mode: "time", duration_s: 40, rest_s: 20 })}
      render={(step, update) => (
        <div className="stack">
          <RefPicker type="exercises" label={t("field_exercise")} value={step.exercise_id || null} disabled={disabled} onChange={(v) => update({ ...step, exercise_id: v ?? "" })} />
          <div className="row" style={{ flexWrap: "wrap" }}>
            <select aria-label={t("field_mode")} value={String(step.mode)} disabled={disabled} onChange={(e) => update({ ...step, mode: e.target.value })}>
              <option value="time">{t("opt_time")}</option>
              <option value="reps">{t("opt_reps")}</option>
            </select>
            {step.mode === "reps" ? (
              <label className="row small">
                {t("field_reps")}
                <input type="number" min={1} style={{ width: 80 }} disabled={disabled} value={Number(step.reps ?? 10)} onChange={(e) => update({ ...step, reps: Number(e.target.value) })} />
              </label>
            ) : (
              <label className="row small">
                {t("field_duration_s")}
                <input type="number" min={5} style={{ width: 80 }} disabled={disabled} value={Number(step.duration_s ?? 40)} onChange={(e) => update({ ...step, duration_s: Number(e.target.value) })} />
              </label>
            )}
            <label className="row small">
              {t("field_rest_s")}
              <input type="number" min={0} style={{ width: 80 }} disabled={disabled} value={Number(step.rest_s ?? 0)} onChange={(e) => update({ ...step, rest_s: Number(e.target.value) })} />
            </label>
          </div>
        </div>
      )}
    />
  );
}

/** Programme jour par jour : conseil, séance, recettes et tâches (avec leur règle). */
function ProgramDays({ spec, value, onChange, locale, disabled }: FieldProps) {
  const t = useTranslations("admin.content");
  const label = useLabel(spec.name);
  const days = asList<Obj>(value);
  return (
    <ListEditor<Obj>
      label={label}
      items={days}
      onChange={(next) => onChange(next.map((d, i) => ({ ...d, day_index: i + 1 })))}
      disabled={disabled}
      make={() => ({ day_index: days.length + 1, tip: { fr: "" }, workout_id: null, recipe_ids: [], tasks: [] })}
      render={(day, update, i) => (
        <div className="stack">
          <b>{t("day_n", { n: i + 1 })}</b>
          <I18nField spec={{ name: "tip", kind: "i18n", long: true }} locale={locale} disabled={disabled} value={day.tip} onChange={(v) => update({ ...day, tip: v })} />
          <RefPicker type="workouts" label={t("field_workout_id")} value={day.workout_id ?? null} disabled={disabled} onChange={(v) => update({ ...day, workout_id: v })} />
          <RefPicker type="recipes" multiple label={t("field_recipe_ids")} value={day.recipe_ids} disabled={disabled} onChange={(v) => update({ ...day, recipe_ids: v })} />
          <ListEditor<Obj>
            label={t("field_tasks")}
            items={asList<Obj>(day.tasks)}
            disabled={disabled}
            onChange={(tasks) => update({ ...day, tasks })}
            make={() => ({ label: { fr: "" }, rule: null })}
            render={(task, updateTask) => (
              <div className="stack">
                <I18nField spec={{ name: "task_label", kind: "i18n" }} locale={locale} disabled={disabled} value={task.label} onChange={(v) => updateTask({ ...task, label: v })} />
                {task.rule ? (
                  <RuleEditor label={t("field_rule")} value={task.rule} disabled={disabled} onChange={(rule) => updateTask({ ...task, rule })} />
                ) : (
                  <button type="button" className="btn ghost sm" disabled={disabled} onClick={() => updateTask({ ...task, rule: { metric: "meals_count", operator: "gte", threshold: 3, period: "day" } })} style={{ alignSelf: "flex-start" }}>
                    {t("add_rule")}
                  </button>
                )}
              </div>
            )}
          />
        </div>
      )}
    />
  );
}

/** Rendu d'un champ selon sa description (lib/content-schema.ts). */
export function Field(props: FieldProps & { type: ContentType }) {
  const label = useLabel(props.spec.name);
  const { spec } = props;
  switch (spec.kind) {
    case "i18n":
      return <I18nField {...props} />;
    case "text":
      return <TextField {...props} />;
    case "number":
      return <NumberField {...props} />;
    case "boolean":
      return <BooleanField {...props} />;
    case "select":
      return <SelectField {...props} />;
    case "multi":
      return <MultiField {...props} />;
    case "tags":
      return <TagsField {...props} />;
    case "json":
      return <JsonField {...props} />;
    case "ref":
      return <RefPicker type={spec.type} multiple={spec.multiple} label={label} value={props.value} onChange={props.onChange} disabled={props.disabled} />;
    case "rule":
      return <RuleEditor label={label} value={props.value} onChange={props.onChange} disabled={props.disabled} />;
    case "trigger":
      return <TriggerEditor {...props} />;
    case "ingredients":
    case "components":
      return <FoodLines {...props} />;
    case "steps":
      return <StepsField {...props} />;
    case "workout_steps":
      return <WorkoutSteps {...props} />;
    case "program_days":
      return <ProgramDays {...props} />;
    case "media":
      return <MediaField label={label} media={spec.media} value={props.value} onChange={props.onChange} disabled={props.disabled} />;
    case "subtitles":
      return <SubtitlesField label={label} value={props.value} onChange={props.onChange} disabled={props.disabled} locales={LOCALES} />;
  }
}
