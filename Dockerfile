FROM node:18 AS user

RUN groupadd --gid 10000 quest \
    && useradd --uid 10000 --gid 10000 -m quest

FROM user AS app

WORKDIR /opt/app
USER root
RUN chown -R quest:quest /opt/app
USER quest

COPY --chown=quest:quest package.json yarn.lock

RUN yarn --frozen-lockfile && \
    rm -rf .npmrc

COPY --chown=voice:voice bin ./bin
COPY --chown=voice:voice src ./src

CMD [ "node", "src/000.js" ]
