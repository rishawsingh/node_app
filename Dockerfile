# Build stage
FROM node:14-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production

COPY . .

RUN npm run build && \
    rm -rf node_modules && \
    npm ci --only=production

# Run stage
FROM node:14-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production

COPY --from=build /app .

ENV NODE_ENV=production

EXPOSE 3000

CMD ["npm", "start"]
