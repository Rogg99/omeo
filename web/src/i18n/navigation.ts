import { createNavigation } from "next-intl/navigation";

import { routing } from "./routing";

/** Liens et redirections qui conservent le préfixe de langue. */
export const { Link, redirect, usePathname, useRouter, getPathname } = createNavigation(routing);
