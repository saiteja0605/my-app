# Build stage
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
# Force create node_modules and verify installation
RUN mkdir -p node_modules && \
    npm install --omit=dev --verbose && \
    ls -la node_modules
COPY . .

# Runtime stage
FROM gcr.io/distroless/nodejs:16
WORKDIR /app
COPY --from=builder /app ./
CMD ["index.js"]
