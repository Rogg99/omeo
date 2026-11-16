import type { ReactNode } from "react";

import { Icon, type IconName } from "@/components/icons/Icon";

/** Indicateur chiffré (valeur prête à afficher, évolution renvoyée par l'API). */
export function Kpi({
  label,
  value,
  delta,
  trend,
  icon,
}: {
  label: string;
  value: ReactNode;
  delta?: ReactNode;
  trend?: "up" | "down";
  icon?: IconName;
}) {
  return (
    <div className="card kpi">
      <div className="l">
        {icon ? <Icon name={icon} /> : null}
        {label}
      </div>
      <div className="v num">{value}</div>
      {delta ? <div className={`d ${trend ?? ""}`}>{delta}</div> : null}
    </div>
  );
}

/** Barre de proportion (valeur déjà calculée par l'API, entre 0 et 1). */
export function Bar({ ratio, label }: { ratio: number; label: string }) {
  const clamped = Math.max(0, Math.min(1, ratio));
  return (
    <div className="bar" role="img" aria-label={label}>
      <i style={{ width: `${clamped * 100}%` }} />
    </div>
  );
}
