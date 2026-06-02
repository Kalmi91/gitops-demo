# syntax=docker/dockerfile:1
# Multi-stage: build a static Go binary, ship it on distroless (~10MB, nonroot).
FROM golang:1.23 AS build
WORKDIR /src

# Cache modules first (no external deps today, but keeps the layer stable).
COPY go.mod ./
RUN go mod download

COPY . .
ARG VERSION=dev
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath -ldflags "-s -w -X main.version=${VERSION}" \
    -o /out/app .

FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=build /out/app /app
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/app"]
