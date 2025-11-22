###############################
# Build Stage
###############################
FROM node:20-alpine AS build
WORKDIR /app

COPY package*.json ./

# No lock file → use npm install
RUN npm install --production

COPY . .

###############################
# Runtime Stage
###############################
FROM node:20-alpine
WORKDIR /app

COPY --from=build /app /app

EXPOSE 3000

CMD ["node", "index.js"]
