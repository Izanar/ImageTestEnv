FROM alpine/git:2.45.2 AS source

RUN git clone --depth 1 https://github.com/Izanar/AI_Nginx.git /src/ai-nginx \
    && mkdir -p /app \
    && find /src/ai-nginx/html -mindepth 1 -maxdepth 1 ! -name audio -exec cp -r {} /app/ \;

FROM nginx:1.27-alpine

COPY --from=source /app/ /usr/share/nginx/html/
