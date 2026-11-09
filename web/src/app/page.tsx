import { Logo } from "@/components/Logo";

export default function Home() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center gap-6 px-6 text-center">
      <Logo size={56} />
      <p className="text-lg text-zinc-600 dark:text-zinc-400">Scanne. Comprends. Mange mieux.</p>
    </main>
  );
}
