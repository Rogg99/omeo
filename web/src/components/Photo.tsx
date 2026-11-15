import Image from "next/image";

import { PHOTOS, type PhotoName } from "@/lib/photos";

type PhotoProps = { name: PhotoName; alt: string; height: number; sizes: string; priority?: boolean; radius?: string };

/** Photo recadrée (AVIF/WebP, dimensions réservées : aucun décalage de mise en page). */
export function Photo({ name, alt, height, sizes, priority = false, radius }: PhotoProps) {
  return (
    <div className="photo" style={{ blockSize: height, borderRadius: radius }}>
      <Image src={PHOTOS[name].image} alt={alt} fill sizes={sizes} placeholder="blur" priority={priority} />
    </div>
  );
}
