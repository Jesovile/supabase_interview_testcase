# syntax=docker/dockerfile:1

# ---- Stage 1: build the static SPA ----
FROM node:20-alpine AS build
WORKDIR /app

# Install dependencies first (better layer caching).
COPY package.json package-lock.json ./
RUN npm ci

# Vite inlines VITE_* env vars at build time, so they must be present
# during `npm run build`. They are passed as build args by docker-compose.
# The anon key is a public client credential, so baking it into the bundle
# is expected and safe.
ARG VITE_SUPABASE_URL
ARG VITE_SUPABASE_ANON_KEY
ENV VITE_SUPABASE_URL=$VITE_SUPABASE_URL
ENV VITE_SUPABASE_ANON_KEY=$VITE_SUPABASE_ANON_KEY

COPY . .
RUN npm run build          # tsc -b && vite build -> /app/dist

# ---- Stage 2: serve the static files with nginx over HTTP ----
FROM nginx:alpine AS runtime

# SPA-aware config (deep-link fallback to index.html).
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Static build output.
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
