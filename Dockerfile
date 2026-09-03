FROM alpine/git:2.45.2 AS source

RUN git clone --depth 1 https://github.com/Izanar/AI_Nginx.git /src/ai-nginx

FROM nginx:1.27-alpine

COPY --from=source /src/ai-nginx/html/ /usr/share/nginx/html/
