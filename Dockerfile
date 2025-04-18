FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build  # If you have a build step

FROM gcr.io/distroless/nodejs:16
COPY --from=builder /app /app
WORKDIR /app
CMD ["app.js"]  # Directly run JS (no npm)
