FROM node:24-alpine

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY contracts ./contracts
COPY tests ./tests
COPY Makefile ./Makefile

RUN npm test

CMD ["npm", "test"]
