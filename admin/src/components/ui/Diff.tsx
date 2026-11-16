import type { DiffLine } from "@/lib/diff";

/** Différence avant / après : lignes retirées (−) et ajoutées (+), jamais par la couleur seule. */
export function Diff({ lines, emptyLabel, label }: { lines: DiffLine[]; emptyLabel: string; label: string }) {
  if (lines.length === 0) return <p className="faint small">{emptyLabel}</p>;
  return (
    <div className="diff" role="group" aria-label={label}>
      {lines.map((l) => (
        <div key={l.path} style={{ marginBottom: 6 }}>
          <div className="faint">{l.path}</div>
          {l.before !== null ? <span className="m">− {l.before}</span> : null}
          {l.after !== null ? <span className="p">+ {l.after}</span> : null}
        </div>
      ))}
    </div>
  );
}
