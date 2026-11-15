import { afterEach, vi } from "vitest";

import { resetRateLimits } from "@/server/rate-limit";

afterEach(() => {
  vi.useRealTimers();
  resetRateLimits();
});
