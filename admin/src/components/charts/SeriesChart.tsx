"use client";

import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

import { formatDate, formatNumber } from "@/lib/format";

type Point = { date?: string; value?: number };

/**
 * Courbe d'une seule série (couleur primaire, pas de légende : le titre la nomme). Trait de 2 px,
 * grille discrète, infobulle au survol. Une table masquée reprend les valeurs pour les lecteurs
 * d'écran. Couleurs lues dans les tokens : clair et sombre cohérents.
 */
export function SeriesChart({ points, label }: { points: Point[]; label: string }) {
  const data = points.map((p) => ({ date: p.date ?? "", value: p.value ?? 0 }));
  return (
    <figure style={{ margin: 0 }}>
      <div style={{ height: 200 }} aria-hidden="true">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data} margin={{ top: 8, right: 8, bottom: 0, left: 0 }} accessibilityLayer={false}>
            <CartesianGrid vertical={false} stroke="var(--line)" />
            <XAxis
              dataKey="date"
              tickFormatter={(d: string) => formatDate(d).replace(/ \d{4}$/, "")}
              tick={{ fill: "var(--text-3)", fontSize: 12 }}
              axisLine={false}
              tickLine={false}
              minTickGap={24}
            />
            <YAxis
              tickFormatter={(v: number) => formatNumber(v)}
              tick={{ fill: "var(--text-3)", fontSize: 12 }}
              axisLine={false}
              tickLine={false}
              width={56}
            />
            <Tooltip
              cursor={{ stroke: "var(--line-strong)" }}
              contentStyle={{ background: "var(--bg-elev)", border: "1px solid var(--line)", borderRadius: 10, color: "var(--text)" }}
              labelFormatter={(d) => formatDate(String(d))}
              formatter={(v) => [formatNumber(Number(v)), label]}
            />
            <Area
              type="monotone"
              dataKey="value"
              stroke="var(--primary)"
              strokeWidth={2}
              fill="var(--primary)"
              fillOpacity={0.12}
              activeDot={{ r: 5, stroke: "var(--surface)", strokeWidth: 2 }}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
      <table className="sr-only">
        <caption>{label}</caption>
        <tbody>
          {data.map((p) => (
            <tr key={p.date}>
              <th scope="row">{formatDate(p.date)}</th>
              <td>{formatNumber(p.value)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}
