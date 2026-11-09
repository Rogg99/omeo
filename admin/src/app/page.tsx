import { Logo } from "@/components/Logo";

export default function Home() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center gap-4 px-6 text-center">
      <Logo size={48} />
      <p className="text-zinc-600 dark:text-zinc-400">Back-office</p>
    </main>
  );
}
