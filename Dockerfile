# Stage 1 - Builder
FROM node:16 AS builder
WORKDIR /app

# Copy package.json from src/
COPY src/package*.json ./src/

# Install dependencies inside the src directory
RUN cd src && npm install --omit=dev

# Copy the rest of the app
COPY . .

# Stage 2 - Final image
FROM gcr.io/distroless/nodejs:16
WORKDIR /app

COPY --from=builder /app .

CMD ["src/app.js"]  # Replace with your actual entry point
