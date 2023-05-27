# Build frontend
FROM node:lts-alpine AS frontend-build-stage
RUN corepack enable && corepack prepare yarn@stable --activate
WORKDIR /build
COPY ./dns-manager-frontend/ .
RUN yarn install && yarn build

# Build the backend binary
FROM golang:alpine AS backend-build-stage
WORKDIR /build
COPY ./dns-managerd/ .
COPY --from=frontend-build-stage /build/build/ ./html/
RUN go build -ldflags "-s -w" -trimpath -o dns-managerd

# Deploy the application binary into a lean image
FROM alpine:latest AS release-stage
COPY --from=backend-build-stage /build/dns-managerd /usr/bin/
VOLUME /data
WORKDIR /data
COPY --from=backend-build-stage /build/config.yaml .
ENTRYPOINT ["dns-managerd"]