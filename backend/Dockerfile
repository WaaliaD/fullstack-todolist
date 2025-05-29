FROM node:20-alpine

WORKDIR /app

RUN wget "https://storage.yandexcloud.net/cloud-certs/CA.pem" \
    --output-document root.crt && \
    chmod 0600 root.crt

COPY package*.json ./

RUN npm install

COPY . .

COPY ./dist ./dist

ENV HOST=0.0.0.0

EXPOSE 5000

CMD ["npm", "run", "start:dev"]