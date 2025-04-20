# Stage 1 - Builder
FROM node:16 AS builder
WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

# Stage 2 - Final
FROM gcr.io/distroless/nodejs:16
WORKDIR /app
COPY --from=builder /app .

CMD ["src/app.js"] # or your actual entry file
