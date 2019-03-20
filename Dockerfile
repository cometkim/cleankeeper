FROM alpine:3.9

LABEL repository="https://github.com/cometkim/cleankeeper"
LABEL maintainer="Hyeseong Kim <cometkim.kr@gmail.com>"

LABEL com.github.actions.name="Cleankeeper"
LABEL com.github.actions.description="Cleanup opsoleted branches made by Greenkeeper"
LABEL com.github.actions.icon="delete"
LABEL com.github.actions.color="green"

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    jq

WORKDIR /action
COPY . .

ENTRYPOINT ["/action/entrypoint.sh"]
