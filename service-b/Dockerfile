FROM node:22-slim

WORKDIR /app

# Install dependencies first (layer cache)
COPY service-b/package*.json ./
RUN npm ci --omit=dev

# Copy proto (loaded at runtime via proto-loader — no codegen needed)
COPY /proto/calc.proto /proto/calc.proto

# Copy application
COPY service-b/ .

EXPOSE 50052

CMD ["node", "server.js"]
