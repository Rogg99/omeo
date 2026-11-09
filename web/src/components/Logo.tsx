type LogoProps = {
  /** Hauteur du symbole en pixels. */
  size?: number;
  /** Affiche le nom à côté du symbole. */
  withText?: boolean;
  className?: string;
};

/** Logo Omeo : un disque auquel il manque une bouchée. Prend la couleur du texte. */
export function Logo({ size = 32, withText = true, className }: LogoProps) {
  return (
    <span className={`inline-flex items-center gap-1.5 ${className ?? ""}`}>
      <svg width={size} height={size} viewBox="0 0 64 64" aria-hidden="true">
        <path
          d="M55.98 32.98A24 24 0 1 1 41.12 9.8A8.5 8.5 0 0 0 50.21 21.41A7 7 0 0 0 55.98 32.98Z"
          fill="currentColor"
        />
      </svg>
      {withText ? (
        <span className="font-semibold tracking-tight" style={{ fontSize: size * 0.62 }}>
          omeo
        </span>
      ) : (
        <span className="sr-only">Omeo</span>
      )}
    </span>
  );
}
