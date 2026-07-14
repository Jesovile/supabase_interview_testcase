# Construction Projects Portal — dev tasks
#
# Requires: Docker running, Node.js, and the Supabase CLI (used via `npx supabase`).

SUPABASE := npx --yes supabase
FRONTEND_DIR := frontend

.PHONY: run_local backend frontend install reset stop status clean deploy_build deploy_up deploy_down

## run_local: start Supabase (backend) then run the frontend dev server
run_local: backend install
	@echo "==> Supabase is up. Starting frontend dev server (Ctrl-C to stop)…"
	@echo "==> Frontend: http://localhost:5173   Studio: http://localhost:54323"
	$(MAKE) frontend

## backend: start the local Supabase stack and apply migrations + seed
backend:
	@echo "==> Starting local Supabase stack…"
	$(SUPABASE) start
	@echo "==> Applying migrations + seed…"
	$(SUPABASE) db reset

## frontend: run the Vite dev server (foreground)
frontend:
	cd $(FRONTEND_DIR) && npm run dev

## install: install frontend dependencies if needed
install:
	@if [ ! -d "$(FRONTEND_DIR)/node_modules" ]; then \
		echo "==> Installing frontend dependencies…"; \
		cd $(FRONTEND_DIR) && npm install; \
	fi

## reset: re-apply migrations + reseed the local database
reset:
	$(SUPABASE) db reset

## status: show local Supabase service URLs and keys
status:
	$(SUPABASE) status

## stop: stop the local Supabase stack
stop:
	$(SUPABASE) stop

## clean: stop Supabase and remove frontend build output
clean: stop
	rm -rf $(FRONTEND_DIR)/dist

# --- Production deploy (Dockerized frontend -> Supabase Cloud) ---
# Reads VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY from a root .env file
# (see .env.example). Values are baked at build time, so rebuild on change.

## deploy_build: build the frontend Docker image against Supabase Cloud
deploy_build:
	docker compose build --no-cache

## deploy_up: build (if needed) and start the frontend container on port 80
deploy_up:
	docker compose up -d --build

## deploy_down: stop and remove the frontend container
deploy_down:
	docker compose down
