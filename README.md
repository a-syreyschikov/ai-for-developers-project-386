### Hexlet tests and linter status:
[![Actions Status](https://github.com/a-syreyschikov/ai-for-developers-project-386/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/a-syreyschikov/ai-for-developers-project-386/actions)

# Calendar

`calendar` — учебный сервис записи на звонок по мотивам Cal.com.

Проект выполняется в подходе Design First: сначала фиксируются доменная модель и API-контракт, затем отдельно реализуются frontend и backend.

## Стек

- API-контракт: TypeSpec + OpenAPI 3.0.
- Contract tests: `node:test` + `c8`.
- Backend: .NET 8 + ASP.NET Core Minimal API + C#, запуск и тесты через Docker.
- Будущий frontend: Vite + Vue + TypeScript.
- Контейнеризация текущего шага: Docker-образ `calendar-contract`, который валидирует контракт.

## Структура

- `contracts/api/main.tsp` — источник правды API.
- `contracts/openapi.yaml` — сгенерированный OpenAPI YAML, коммитится для ревью и интеграции.
- `docs/domain.md` — доменные сущности и правила.
- `docs/agent-task.md` — инструкции будущим агентам.
- `docs/adr/` — архитектурные решения.
- `apps/backend/` — backend на .NET 8 + ASP.NET Core Minimal API.
- `apps/frontend/` — место под frontend на Vite + Vue + TypeScript.
- `tests/contract.test.mjs` — тесты API-контракта.

## Команды

```bash
make install
make contract
make test
make test-coverage
make backend-build
make backend-run
make backend-test
make docker-build
make docker-run
```

`make` по умолчанию запускает `make test`.

## Правила разработки

- TypeSpec является единым источником правды для frontend и backend.
- Любое изменение API сначала вносится в `contracts/api/main.tsp`.
- После изменения контракта нужно выполнить `make test` и закоммитить обновленный `contracts/openapi.yaml`.
- Backend реализуется от контракта и запускается через Docker, без локальной установки `dotnet`.
- `make test` проверяет contract-test tooling с coverage threshold 80% statements.
- `make backend-test` запускает backend integration tests через Docker с coverage threshold 80% lines.
- Тесты будущих frontend/backend частей добавляются вместе с реализацией соответствующего поведения.
