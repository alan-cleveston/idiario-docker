FROM ruby:2.4.10-slim-buster

# Instalando postgres
RUN apt update && apt -y full-upgrade &&\
    apt -y install gnupg2 wget &&\
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - &&\
    echo "deb http://apt.postgresql.org/pub/repos/apt/ `grep VERSION_CODENAME /etc/os-release | sed 's/VERSION_CODENAME=//'`-pgdg main" |tee  /etc/apt/sources.list.d/pgdg.list &&\
    apt update &&\
    apt -y install postgresql-12 postgresql-client-12
ENV PGDATA=/var/lib/postgresql/12/main

# Instalando Redis
ENV REDIS_PASS=default \
    REDIS_PORT=6379
RUN apt -y install redis-server

# Instalando Mencached
RUN apt -y install memcached libmemcached-tools

# Limpeza
RUN apt-get clean autoclean &&\
    apt-get autoremove --yes &&\
    rm -rf /var/lib/{apt,dpkg,cache,log}/ /var/lib/postgresql/*

#Instalando i-diario
RUN apt-get install -y git
RUN apt-get install -y build-essential libpq-dev nodejs npm git shared-mime-info locales-all &&\
    npm i -g yarn

ENV app /app
RUN mkdir $app
WORKDIR $app
ENV BUNDLE_PATH /box

ARG IDIARIO_VERSION
ENV IDIARIO_ENVIRONMENT=development \
    HONEYBADGER_API_KEY=abcdefzyx
RUN echo "Clonando I-DIARIO versão $IDIARIO_VERSION" &&\
    git clone --branch $IDIARIO_VERSION https://github.com/portabilis/i-diario/ $app/

COPY src/start script/start
COPY src/entrypoint-2.sh /tmp/entrypoint-2.sh
COPY src/sidekiq.yml config/
COPY src/sidekiq.rb config/initializers/
RUN chmod +x /tmp/entrypoint-2.sh script/start

ENV LANG=en_US.UTF8 \
    LANGUAGE=en_US.UTF8 \
    LC_ALL=en_US.UTF8

ENTRYPOINT ["script/start"]
