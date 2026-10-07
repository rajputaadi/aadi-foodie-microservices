# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

"Foodie" — a learning project building a food-ordering backend as Spring Boot 3.4 / Spring Cloud microservices on Java 21. The git root is the parent directory (`Aadi-foodie-microservices/`), which also holds course artifacts (drawings, Postman collection `jb2024.postman_collection.json`, SQL dumps); all code lives in `microservices/`.

There is **no parent/aggregator POM**: each service directory is an independent Maven project with its own `mvnw`. Run commands from inside the service directory.

## Commands

```bash
# per service (e.g. cd food-service)
./mvnw clean package            # build
./mvnw spring-boot:run          # run
./mvnw test                     # run tests
./mvnw test -Dtest=FoodServiceApplicationTests            # single test class
./mvnw test -Dtest=FoodServiceApplicationTests#contextLoads  # single method

# infrastructure (from microservices/)
docker compose up -d            # MySQL :3306 (+phpMyAdmin :8084), Postgres :5432 (+pgAdmin :8082),
                                # RabbitMQ :5672 (UI :15672), Mongo :27017 (+mongo-express :8083)
```

Tests are only the generated `contextLoads` tests, which boot the full context — they need the config server / databases reachable to pass.

`postgres-data/`, `mongo-data/` and `mysql-data/` are docker bind-mount volumes, not source — don't edit them.

## Databases and seed data

| Service | DB | Credentials |
|---|---|---|
| restaurant-service | Postgres `restaurantdb` | from config repo; docker-compose creates user / user123 |
| food-service | MySQL `Fooddb` | from config repo (`{cipher}`) |
| user-service | MySQL `jb2404` | root / root1234 |
| cart-service | MySQL `cartdb` | root / root1234 |
| payement-delivery-service | MySQL `paymentdb` | root / root1234 |

- MySQL URLs use `createDatabaseIfNotExist=true`; `db-init/mysql/` also creates the DBs on first container start.
- Tables come from Hibernate `ddl-auto=update`. Dummy data is in each service's `src/main/resources/data.sql`, run on every startup after Hibernate (`spring.jpa.defer-datasource-initialization=true`, `spring.sql.init.mode=always`), so **seed statements must stay idempotent** (`INSERT IGNORE` on MySQL, `ON CONFLICT DO NOTHING` / `WHERE NOT EXISTS` on Postgres).
- Seed food items reference the fixed restaurant IDs seeded by restaurant-service (`a1b2c3d4-000N-...`) — keep them in sync.
- restaurant-service runs `data.sql` as a single script (`spring.sql.init.separator=^^^ END OF SCRIPT ^^^`) because it contains a `DO $$` block that migrates `about_restaurant` from an old `@Lob`/`oid` column to `TEXT`. Don't use `@Lob` on String fields with Postgres.
- `postgres-data/` comes from git, which drops empty directories. If the postgres container exits with `could not open directory "pg_notify"` (or similar), recreate the missing empty dirs (`pg_notify`, `pg_tblspc`, `pg_replslot`, `pg_snapshots`, `pg_stat`, `pg_serial`, `pg_twophase`, `pg_commit_ts`, `pg_dynshmem`, `pg_logical/{snapshots,mappings}`) via a throwaway `postgres:13` container, since the dir is owned by the container's postgres user.
- The config repo sets `spring.jpa.open-in-view=false`, so lazy associations can't be serialized in controllers — fetch them eagerly or map them inside the transaction (e.g. `Restaurant.pictures` is `FetchType.EAGER`).
- RabbitMQ (guest/guest) backs Spring Cloud Bus (`spring-cloud-starter-bus-amqp`) in food-service and restaurant-service.

## Architecture

Startup order matters: **discovery-server → config-server → business services → api-gateway**.

| Service | Port | Notes |
|---|---|---|
| discovery-server | 8761 | Eureka server (package `com.dicovery.server`) |
| config-server | 9096 | Spring Cloud Config, registers with Eureka |
| api-gateway | 9095 | Spring Cloud Gateway (WebFlux) |
| restaurant-service | 8088 | Postgres (`restaurantdb`); config from config server, profile `dev` |
| food-service | 9091 (prod) / 9090 (dev) / 9092 (test) / 8081 (default) | MySQL; config from config server, profile `prod` |
| user-service | 9090 | MySQL; local config only |
| cart-service | 9093 | Skeleton (no entities yet); MySQL `cartdb`; no Eureka/config client |
| payement-delivery-service | 9094 | Skeleton (no entities yet); MySQL `paymentdb`; no Eureka/config client |

### Centralized configuration

- food-service and restaurant-service have minimal local config and pull the rest via `spring.config.import=configserver:http://localhost:9096/`. Their port, datasource, Eureka and actuator settings come from the config server, so the config server must be up before they start.
- config-server runs with the **`git` profile by default, serving the user's repo `https://github.com/rajputaadi/aadifoodie-config` (branch `main`, `.properties` files)**. Port, datasource and Eureka settings for food-service and restaurant-service live there, not in this codebase — change them by committing to that repo, then restart the config server.
- `{cipher}` values are decrypted with `encrypt.key` in config-server's `application.yml`. Generate new ones with `curl localhost:9096/encrypt -H 'Content-Type: text/plain' -d <value>`. If decryption fails, the property is served as `invalid.<name>` and the service starts without it.
- `config-server/src/main/resources/config/` is an older local copy, only served with `SPRING_PROFILES_ACTIVE=native`.
- Config files follow `{application}-{profile}.{yml|properties}`; the active profile is set in each service's local `application.*`.

### Routing

- Gateway routes are defined in Java in `api-gateway/src/main/java/com/gateway/GatewayConfig.java` (the YAML route block in `application.yml` is commented out). Routes use `lb://` Eureka lookups and strip the prefix:
  - `/foods/**` → `lb://food-service`
  - `/restaurants/**` → `lb://restaurant-service` (adds header `ExtraValue: Samosa`)
  - e.g. `GET :9095/restaurants/api/v1/restaurants/{id}` → restaurant-service `/api/v1/restaurants/{id}`.
- **Circuit breaker / retry are intentionally not implemented**: the user is studying and implementing them themselves (the course's solution is upstream commit `1d78ca1`). Don't add Resilience4j, fallbacks or retry unless asked.

### Inter-service calls (food-service → restaurant-service)

`FoodItemService.getFoodItemById` enriches a food item with restaurant data. Three client styles exist side by side for teaching purposes, all resolving `restaurant-service` through Eureka:
- **WebClient** (active): `RestWebClientService` using the `@LoadBalanced WebClient.Builder` bean from `ProjectConfig`.
- **OpenFeign**: `service/external/RestaurantService` (`@EnableFeignClients`), injected but currently commented out in the main path.
- `@LoadBalanced RestTemplate` bean in `ProjectConfig` (commented-out usage).

Service names/URLs for clients are in `food-service/.../config/AppConstants.java`.

### Code conventions

Business services follow `controller → service → repository` with `entities` and `dto` packages under `com.substring.foodie.<service>`. Entity IDs are `String` UUIDs generated in the service layer. Lombok is used for entities/DTOs. Code comments are sometimes in Hinglish.
