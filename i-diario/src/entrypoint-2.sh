#!/bin/bash

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
sed -i "s;username:.*;username: $IDIARIO_DB_USER;" config/database.sample.yml
sed -i "s;password:.*;password: $IDIARIO_DB_PASS;" config/database.sample.yml
sed -i "s;database:.*;database: $IDIARIO_DB_NAME;" config/database.sample.yml
sed -i "s;host:.*;host: $IDIARIO_DB_HOST;" config/database.sample.yml
echo -e "
production:
  <<: *default
  database: $IDIARIO_DB_NAME" >> config/database.sample.yml

# Conf config/initializers/*.rb
echo "Configurando config/initializers/*"
sed -i "s;'redis://.*';'redis://localhost:$REDIS_PORT';" config/initializers/sidekiq.rb
sed -i "s;.*config.secret_key.*;config.secret_key = '$IDIARIO_SECRET_KEY';" config/initializers/devise.rb
