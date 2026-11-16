"use client";

import * as Toast from "@radix-ui/react-toast";
import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from "react";

type Tone = "info" | "success" | "error";
type ToastItem = { id: number; title: string; description?: string; tone: Tone; undo?: { label: string; run: () => void } };
type Show = (title: string, options?: { description?: string; tone?: Tone; undo?: ToastItem["undo"] }) => void;

const ToastContext = createContext<Show | null>(null);

/** Notifications (Radix Toast : annoncées aux lecteurs d'écran), avec annulation facultative. */
export function ToastProvider({ children, closeLabel }: { children: ReactNode; closeLabel: string }) {
  const [items, setItems] = useState<ToastItem[]>([]);
  const show = useCallback<Show>((title, options = {}) => {
    setItems((list) => [...list.slice(-3), { id: Date.now() + Math.random(), title, tone: options.tone ?? "info", ...options }]);
  }, []);
  const remove = (id: number) => setItems((list) => list.filter((i) => i.id !== id));
  const value = useMemo(() => show, [show]);

  return (
    <ToastContext.Provider value={value}>
      <Toast.Provider swipeDirection="right" duration={6000}>
        {children}
        {items.map((item) => (
          <Toast.Root
            key={item.id}
            className="toast"
            data-tone={item.tone}
            type={item.tone === "error" ? "foreground" : "background"}
            onOpenChange={(open) => !open && remove(item.id)}
          >
            <div className="grow">
              <Toast.Title className="bold">{item.title}</Toast.Title>
              {item.description ? <Toast.Description className="small">{item.description}</Toast.Description> : null}
            </div>
            {item.undo ? (
              <Toast.Action altText={item.undo.label} onClick={item.undo.run}>
                {item.undo.label}
              </Toast.Action>
            ) : null}
            <Toast.Close aria-label={closeLabel}>×</Toast.Close>
          </Toast.Root>
        ))}
        <Toast.Viewport className="toasts" />
      </Toast.Provider>
    </ToastContext.Provider>
  );
}

export function useToast(): Show {
  const show = useContext(ToastContext);
  if (!show) throw new Error("useToast doit être utilisé sous <ToastProvider>.");
  return show;
}
