FROM node:22-bookworm-slim
WORKDIR /app/server
COPY server/package*.json ./
RUN npm ci --omit=dev
COPY server/ ./
COPY public/ /app/public/
RUN mkdir -p /app/public/spot-pictures && chown -R node:node /app
USER node
EXPOSE 3000
CMD ["node", "index.js"]
