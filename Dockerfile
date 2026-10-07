FROM ruby:3.4.3-alpine

ENV RUNTIME_PACKAGES="bash tzdata postgresql-dev git make" \
    DEV_PACKAGES="build-base yaml-dev" \
    HOME=/${WORKDIR} \
    LANG=C.UTF-8 \
    TZ=UTC

RUN apk update && \
    apk upgrade && \
    apk add --no-cache ${RUNTIME_PACKAGES} && \
    apk add --virtual build-dependencies --no-cache ${DEV_PACKAGES} && \
    apk add nodejs yarn

RUN mkdir /rails-api-docker
ENV APP_ROOT /rails-api-docker
WORKDIR $APP_ROOT

COPY Gemfile $APP_ROOT
COPY Gemfile.lock $APP_ROOT
RUN bundle install

COPY . $APP_ROOT

RUN apk del build-dependencies

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

CMD ["bundle", "exec", "rails", "server", "-p", "3000", "-b", "0.0.0.0"]

EXPOSE 3000
