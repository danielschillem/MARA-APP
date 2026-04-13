BINARY=mara-api

.PHONY: run build tidy test

run:
	cp -n .env.example .env 2>/dev/null || true
	DB_SEED=true go run ./cmd/server

build:
	go build -o $(BINARY) ./cmd/server

tidy:
	go mod tidy

test:
	go test ./...

seed:
	DB_SEED=true go run ./cmd/server &
