# Makefile for Smart Rain AI IoT System
# Usage:
#   make start   -> builds services, starts them in the background, and opens the frontend URL
#   make up      -> builds and starts services in the background
#   make down    -> stops and removes containers
#   make build   -> rebuilds services
#   make logs    -> tails service logs
#   make open    -> opens the frontend URL in the default browser

URL := http://localhost:3000

.PHONY: default start up down build logs open help

default: help

start:
ifeq ($(OS),Windows_NT)
	powershell -ExecutionPolicy Bypass -File ./start.ps1
else
	@chmod +x ./start.sh && ./start.sh
endif

stop:
ifeq ($(OS),Windows_NT)
	powershell -ExecutionPolicy Bypass -File ./stop.ps1
else
	@chmod +x ./stop.sh && ./stop.sh
endif

down: stop

up:
	docker compose up --build -d


build:
	docker compose build

logs:
	docker compose logs -f

open:
	@printf "Opening project URL: %s\n" "$(URL)"
	@if command -v xdg-open >/dev/null 2>&1; then \
	  xdg-open "$(URL)" >/dev/null 2>&1; \
	elif command -v open >/dev/null 2>&1; then \
	  open "$(URL)" >/dev/null 2>&1; \
	elif [ -n "$$COMSPEC" ]; then \
	  cmd.exe /c start "" "$(URL)" >/dev/null 2>&1; \
	else \
	  echo "Please open $(URL) manually"; \
	fi

help:
	@echo "Available targets:"
	@echo "  make start   - start DB, backend, frontend, and python serial bridge"
	@echo "  make stop    - stop all running services and databases"
	@echo "  make up      - start docker compose services in background"
	@echo "  make down    - stop all running services (alias for stop)"
	@echo "  make build   - rebuild service images"
	@echo "  make logs    - follow logs for all services"
	@echo "  make open    - open frontend URL in browser"
