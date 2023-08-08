#!/bin/bash

#POSTGRES
#POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_USER="postgres"
POSTGRES_DATABASE=${POSTGRES_DATABASE:-idiario}

PG_CMD_START="/usr/lib/postgresql/12/bin/pg_ctl start -D $PGDATA -l $PGDATA/postgresql.log"

if [ -e $PGDATA/PG_VERSION ]; then
 echo "$PGDATA inicializado!!!"
 chown -R postgres:postgres /var/lib/postgresql
 su - postgres -c "$PG_CMD_START"
else
 if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "ENV POSTGRES_PASSWORD vazia!!!"
 else
  chown -R postgres:postgres /var/lib/postgresql
  su - postgres -c "/usr/lib/postgresql/12/bin/initdb $PGDATA --encoding=UTF-8 --lc-collate=C --lc-ctype=C"
  echo "host all  all    0.0.0.0/0  md5" >> $PGDATA/pg_hba.conf
  sed -i "s/#listen_addresses/listen_addresses/" $PGDATA/postgresql.conf
  #su - postgres -c "$PG_CMD_START && psql --command \"ALTER USER $POSTGRES_USER WITH ENCRYPTED PASSWORD '$POSTGRES_PASSWORD';\" && psql --command \"CREATE DATABASE $POSTGRES_DATABASE\""
  su - postgres -c "$PG_CMD_START && psql --command \"ALTER USER $POSTGRES_USER WITH ENCRYPTED PASSWORD '$POSTGRES_PASSWORD';\""
 fi
fi
tail -F $PGDATA/postgresql.log &

#REDIS
echo "Iniciando Redis... na porta: $REDIS_PORT"
#echo -e 'daemonize yes\nlogfile /tmp/redis.log\nrequirepass $REDIS_PASS\nport $REDIS_PORT' > /etc/redis.conf
echo -e "daemonize yes\nlogfile /tmp/redis.log\nport $REDIS_PORT" > /etc/redis.conf
redis-server /etc/redis.conf
tail -F /tmp/redis.log &

#MEMCACHED
echo "Memcached..."
memcached -l 127.0.0.1 -d -u root

#Configurando config/database.sample.yml
sed -i "s;username:.*;username: $POSTGRES_USER;" config/database.sample.yml
sed -i "s;password:.*;password: $POSTGRES_PASSWORD;" config/database.sample.yml
sed -i "s;database:.*;database: $POSTGRES_DATABASE;" config/database.sample.yml
echo -e "
production:
  <<: *default
  database: $POSTGRES_DATABASE" >> config/database.sample.yml

# Conf config/initializers/*.rb
echo "Configurando config/initializers/*"
sed -i "s;'redis://.*';'redis://localhost:$REDIS_PORT';" config/initializers/sidekiq.rb
sed -i "s;.*config.secret_key.*;config.secret_key = '$IDIARIO_SECRET_KEY';" config/initializers/devise.rb
