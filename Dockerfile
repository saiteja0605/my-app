FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production  # Use npm ci for reproducible builds
COPY . .
RUN npm run build  # Uncomment if you have a build step

FROM gcr.io/distroless/nodejs:16
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist  # Or wherever your build outputs
CMD ["dist/index.js"]  
