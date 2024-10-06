.PHONY: up
up:
	docker-compose -f docker-compose.yaml up -d

.PHONY: down
down:
	docker-compose -f docker-compose.yaml down -v

.PHONY: logs
logs:
	docker-compose -f docker-compose.yaml logs -f

.PHONY: psql
psql:
	docker exec -it postgres psql -U postgres -d postgres