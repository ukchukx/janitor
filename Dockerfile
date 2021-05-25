#  --- Build ---
FROM bitwalker/alpine-elixir-phoenix:1.11.3 AS builder
WORKDIR /app
COPY . .
RUN apk update && apk --no-cache add --virtual builds-deps build-base python3 python2
ENV MIX_ENV=prod
RUN cd janitor_web && mix do deps.get --only prod, deps.compile
RUN cd janitor_web/assets && npm i node-sass && npm rebuild node-sass && npm i && npm run deploy
RUN cd janitor_web && mix do phx.digest, release --overwrite

#  --- Run ---
FROM alpine:latest AS runner
RUN apk update && apk --no-cache --update add bash openssl
WORKDIR /app
COPY --from=builder /app/janitor_web/_build/prod/rel/janitor_web .

ENTRYPOINT ["bin/janitor_web"]
CMD ["start"]