.RECIPEPREFIX := >
.DEFAULT_GOAL := test

IMAGE_NAME ?= calendar-contract
BACKEND_IMAGE_NAME ?= calendar-backend
DOTNET_SDK_IMAGE ?= mcr.microsoft.com/dotnet/sdk:8.0

.PHONY: install contract test test-coverage backend-build backend-run backend-test docker-build docker-run clean help

install: ## Install npm dependencies from lockfile
> npm ci

contract: ## Compile TypeSpec and generate contracts/openapi.yaml
> npm run contract

test: ## Generate contract, run contract tests, and enforce coverage
> npm test

test-coverage: ## Run contract tests with coverage report
> npm run test:coverage

backend-build: ## Build backend Docker image
> docker build -t $(BACKEND_IMAGE_NAME) apps/backend

backend-run: ## Run backend API on localhost:8080
> docker run --rm -p 8080:8080 $(BACKEND_IMAGE_NAME)

backend-test: ## Run backend tests in .NET SDK Docker container
> docker run --rm -v $(CURDIR)/apps/backend:/src -w /src $(DOTNET_SDK_IMAGE) dotnet test Calendar.Backend.Tests/Calendar.Backend.Tests.csproj

docker-build: ## Build Docker image and validate contract during build
> docker build -t $(IMAGE_NAME) .

docker-run: ## Run Docker contract validator
> docker run --rm $(IMAGE_NAME)

clean: ## Remove temporary generated output and coverage reports
> rm -rf generated coverage tsp-output

help: ## Show available commands
> @awk 'BEGIN {FS = ":.*##"; printf "Available targets:\n"} /^[a-zA-Z_-]+:.*##/ {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
