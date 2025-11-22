FROM node:18-alpine

WORKDIR /app

# Copy your package.json and package-lock.json FIRST
COPY package*.json ./

RUN npm install --omit=dev

# Copy rest of your app
COPY . .

EXPOSE 3001

CMD ["node", "index.js"]
