FROM node:18 AS user

WORKDIR /opt/app

COPY package.json package.json
COPY yarn.lock yarn.lock

RUN yarn --frozen-lockfile && \
    rm -rf .npmrc

COPY bin ./bin
COPY src ./src

CMD [ "node", "src/000.js" ]
