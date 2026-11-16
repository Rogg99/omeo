import { StaffProvider, type StaffView } from "@/components/providers/StaffProvider";
import { StepUpProvider } from "@/components/providers/StepUpProvider";
import { QueryProvider } from "@/components/providers/QueryProvider";
import { Shell } from "@/components/shell/Shell";
import { getStaff } from "@/server/auth";

import { DemoBarSlot } from "../_shell/DemoBarSlot";

/**
 * Espace connecté : GET /admin/me donne rôles et permissions (menu, boutons) et la fin du step-up.
 * Seule une vue sans jeton est envoyée au navigateur.
 */
export default async function AppLayout({ children }: LayoutProps<"/">) {
  const { me } = await getStaff();
  const view: StaffView = {
    id: me.id,
    name: me.name ?? me.email,
    email: me.email,
    roles: me.roles,
    permissions: me.permissions ?? [],
    mfaVerifiedUntil: me.mfa_verified_until ?? null,
    pendingApprovals: me.pending_approvals ?? 0,
  };
  return (
    <StaffProvider staff={view}>
      <StepUpProvider>
        <QueryProvider>
          <DemoBarSlot currentEmail={me.email} />
          <Shell>{children}</Shell>
        </QueryProvider>
      </StepUpProvider>
    </StaffProvider>
  );
}
