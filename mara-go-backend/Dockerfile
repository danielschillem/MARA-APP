# ─── Build stage ───────────────────────────────────────────────
FROM golang:1.26-alpine AS builder

WORKDIR /app

# Install dependencies first (layer cache)
COPY go.mod go.sum ./
RUN go mod download

# Copy source and build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o mara-api ./cmd/server

# ─── Runtime stage ─────────────────────────────────────────────
FROM alpine:3.20

# Security: non-root user
RUN addgroup -S mara && adduser -S mara -G mara

WORKDIR /app

# Copy binary and create uploads directory
COPY --from=builder /app/mara-api .
RUN mkdir -p uploads && chown -R mara:mara /app

USER mara

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:${PORT:-8081}/api/health || exit 1

CMD ["./mara-api"]
