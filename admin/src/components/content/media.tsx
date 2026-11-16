"use client";

import Image from "next/image";
import { useTranslations } from "next-intl";
import { useId, useState } from "react";

import { createUpload } from "@/app/(app)/content/actions";
import { useAction } from "@/hooks/use-action";
import type { Locale } from "@/lib/locales";

/**
 * Téléversement direct vers l'URL présignée renvoyée par POST /admin/media : le fichier ne passe
 * pas par le serveur de l'admin. Progression (XHR), aperçu local, identifiant enregistré dans le contenu.
 */
const ACCEPT = { image: "image/jpeg,image/png,image/webp", video: "video/mp4,video/webm,video/quicktime", subtitles: "text/vtt" } as const;

function put(url: string, file: File, headers: Record<string, string>, onProgress: (ratio: number) => void): Promise<boolean> {
  return new Promise((resolve) => {
    const xhr = new XMLHttpRequest();
    xhr.open("PUT", url);
    for (const [k, v] of Object.entries(headers)) xhr.setRequestHeader(k, v);
    xhr.upload.onprogress = (e) => e.lengthComputable && onProgress(e.loaded / e.total);
    xhr.onload = () => resolve(xhr.status >= 200 && xhr.status < 300);
    xhr.onerror = () => resolve(false);
    xhr.send(file);
  });
}

function useUploader(kind: keyof typeof ACCEPT) {
  const { run } = useAction(createUpload);
  const [progress, setProgress] = useState<number | null>(null);
  const [failed, setFailed] = useState(false);
  async function upload(file: File): Promise<string | null> {
    setFailed(false);
    const ticket = await run({ kind, content_type: file.type || "text/vtt", size: file.size });
    if (!ticket.ok || !("data" in ticket)) return null;
    setProgress(0);
    const ok = await put(ticket.data.upload_url, file, ticket.data.headers, setProgress);
    setProgress(null);
    if (!ok) setFailed(true);
    return ok ? ticket.data.id : null;
  }
  return { upload, progress, failed };
}

export function MediaField({ label, media, value, onChange, disabled }: { label: string; media: "image" | "video"; value: unknown; onChange: (v: unknown) => void; disabled?: boolean }) {
  const t = useTranslations("admin.content");
  const id = useId();
  const { upload, progress, failed } = useUploader(media);
  const [preview, setPreview] = useState<string | null>(null);

  return (
    <div className="f">
      <label htmlFor={id}>{label}</label>
      {preview ? media === "image" ? <Image src={preview} alt="" width={160} height={120} className="thumb" style={{ width: 160, height: 120 }} unoptimized /> : <video src={preview} controls style={{ maxWidth: 320 }} /> : null}
      {typeof value === "string" && value ? <span className="faint small">{t("media_attached", { id: value.slice(0, 8) })}</span> : null}
      <input
        id={id}
        type="file"
        accept={ACCEPT[media]}
        disabled={disabled || progress !== null}
        onChange={async (e) => {
          const file = e.target.files?.[0];
          if (!file) return;
          setPreview(URL.createObjectURL(file));
          const uploaded = await upload(file);
          if (uploaded) onChange(uploaded);
        }}
      />
      {progress !== null ? <progress max={1} value={progress} aria-label={t("uploading")} /> : null}
      {failed ? (
        <span className="err" role="alert">
          {t("upload_failed")}
        </span>
      ) : null}
    </div>
  );
}

/** Sous-titres VTT, un fichier par langue (exercices vidéo). */
export function SubtitlesField({ label, value, onChange, disabled, locales }: { label: string; value: unknown; onChange: (v: unknown) => void; disabled?: boolean; locales: readonly Locale[] }) {
  const t = useTranslations("admin.content");
  const { upload, progress } = useUploader("subtitles");
  const map = (value && typeof value === "object" ? value : {}) as Record<string, string>;
  return (
    <fieldset className="f" style={{ border: 0, padding: 0, margin: 0 }}>
      <legend className="label">{label}</legend>
      <div className="grid g4">
        {locales.map((l) => (
          <label key={l} className="f small">
            <span className="row">
              {l.toUpperCase()}
              {map[l] ? <span className="tag green">{t("subtitles_ok")}</span> : null}
            </span>
            <input
              type="file"
              accept=".vtt,text/vtt"
              disabled={disabled || progress !== null}
              onChange={async (e) => {
                const file = e.target.files?.[0];
                if (!file) return;
                const uploaded = await upload(file);
                if (uploaded) onChange({ ...map, [l]: uploaded });
              }}
            />
          </label>
        ))}
      </div>
    </fieldset>
  );
}
