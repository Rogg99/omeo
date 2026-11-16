import { ICON_PATHS, type IconName } from "./paths";

type IconProps = { name: IconName; className?: string; size?: number };

/** Icône décorative (trait 1,75). Le libellé vient toujours du texte voisin ou d'un aria-label. */
export function Icon({ name, className = "ico", size }: IconProps) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.75}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
      // Tracés constants générés depuis le dépôt (paths.ts), jamais une donnée externe.
      dangerouslySetInnerHTML={{ __html: ICON_PATHS[name] }}
    />
  );
}

export type { IconName };
