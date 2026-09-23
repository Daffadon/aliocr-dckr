FROM node:22-slim
RUN apt-get update && apt-get install -y --no-install-recommends git openssh-client ca-certificates && rm -rf /var/lib/apt/lists/*
ARG OCR_VERSION=1.12.9
RUN npm install -g @alibaba-group/open-code-review@${OCR_VERSION}
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
WORKDIR /repo
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["--help"]

