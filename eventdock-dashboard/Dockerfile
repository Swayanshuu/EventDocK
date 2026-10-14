# Production container for EventDock Flutter Web Dashboard
FROM nginx:alpine

# Copy custom nginx configuration for SPA routing
RUN rm -rf /etc/nginx/conf.d/default.conf
RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Copy web bundle to nginx html directory
COPY build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
