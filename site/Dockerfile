# syntax=docker/dockerfile:1.7@sha256:a57df69d0ea827fb7266491f2813635de6f17269be881f696fbfdf2d83dda33e
FROM node:24-bookworm-slim@sha256:6f7b03f7c2c8e2e784dcf9295400527b9b1270fd37b7e9a7285cf83b6951452d AS build
WORKDIR /site
COPY package.json package-lock.json ./
RUN npm ci
COPY . ./
ARG SITE_URL=http://localhost:8080
ARG BASE_URL=/
RUN npm run build

FROM nginxinc/nginx-unprivileged:1.29-alpine@sha256:0c79d56aee561a1d81c63f00eee5fb5fe29279560cdc55e91425133104c7fbe6
COPY --from=build /site/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
USER 101
EXPOSE 8080
HEALTHCHECK CMD ["wget", "--quiet", "--spider", "http://127.0.0.1:8080/"]
