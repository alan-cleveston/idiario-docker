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

# Instalando smtp-relay
RUN echo "postfix postfix/mailname string localdomain" | debconf-set-selections &&\
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections &&\
    apt-get install postfix mailutils libsasl2-2 ca-certificates libsasl2-modules -y &&\
    sed -i 's/    y    /    n    /g' /etc/postfix/master.cf

# Limpeza
RUN apt-get clean autoclean &&\
    apt-get autoremove --yes &&\
    rm -rf /var/lib/{apt,dpkg,cache,log}/ /var/lib/postgresql/*

#Instalando i-diario
RUN apt-get update
RUN apt-get install -y neovim
RUN apt-get install -y build-essential libpq-dev nodejs npm git shared-mime-info locales-all &&\
    npm i -g yarn

ENV app /app
RUN mkdir $app
WORKDIR $app
ENV BUNDLE_PATH /box

ARG IDIARIO_VERSION=1.4.1
ENV IDIARIO_ENVIRONMENT=development
RUN echo "Clonando I-DIARIO versão $IDIARIO_VERSION" &&\
    git clone --branch $IDIARIO_VERSION https://github.com/portabilis/i-diario/ $app/
RUN sed -i "s;gem 'prawn'.*;gem 'prawn', '2.1.2', git: 'https://github.com/portabilis/prawn.git', branch: 'master', tag: 'v2.1.2';" Gemfile &&\
    sed -i "/webpacker/a gem 'tilt', '~> 1.4.1'" Gemfile &&\
    sed -i "/webpacker/a gem 'loofah', '~>2.19.1'" Gemfile

COPY src/start script/start
COPY src/entrypoint-2.sh /tmp/entrypoint-2.sh
COPY src/sidekiq.yml config/
COPY src/sidekiq.rb config/initializers/
COPY src/updateReport.sh updateReport.sh
RUN chmod +x /tmp/entrypoint-2.sh script/start updateReport.sh

# Adicionar entrada cron para executar o script às 07:00 da manhã
RUN echo "0 7 * * * /app/updateReport.sh" | crontab -

# Adicionar entrada cron para executar o script às 13:00 da tarde
RUN echo "0 13 * * * /app/updateReport.sh" | crontab -

ENV LANG=en_US.UTF8 \
    LANGUAGE=en_US.UTF8 \
    LC_ALL=en_US.UTF8

ENTRYPOINT ["script/start"]
