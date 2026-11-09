# Image commune aux apps Next.js (admin, web). Le contexte de build est le dossier de l'app.
FROM node:22-alpine AS base
RUN corepack enable
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml* ./
RUN pnpm install --frozen-lockfile

# --- Dev : code monté en volume, hot reload ---
FROM base AS dev
ENV WATCHPACK_POLLING=true \
    NEXT_TELEMETRY_DISABLED=1
CMD ["sh", "-c", "pnpm next dev --hostname 0.0.0.0 --port 3000"]

# --- Prod ---
FROM base AS build
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm build

FROM node:22-alpine AS prod
WORKDIR /app
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 HOSTNAME=0.0.0.0 PORT=3000
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static
COPY --from=build /app/public ./public
USER node
CMD ["node", "server.js"]
