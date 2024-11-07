.PHONY: up
up:
	docker-compose -f docker-compose.yaml up -d

.PHONY: down
down:
	docker-compose -f docker-compose.yaml down -v

.PHONY: clean
clean:
	rm -rf primary/data
	rm -rf replica/data


.PHONY: logs
logs:
	docker-compose -f docker-compose.yaml logs -f

.PHONY: psql_primary
psql_primary:
	docker exec -it postgres_primary psql -U postgres -d postgres

.PHONY: psql_replica
psql_replica:
	docker exec -it postgres_replica psql -U postgres -d thai

.PHONY: connect_primary
connect_primary:
	docker exec -it postgres_primary bash

.PHONY: connect_replica
connect_replica:
	docker exec -it postgres_replica bash