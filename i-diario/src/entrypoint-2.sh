#!/bin/bash

#POSTGRES
IDIARIO_POSTGRES_START=${IDIARIO_POSTGRES_START:-true}
#POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_USER="postgres"
POSTGRES_DATABASE=${POSTGRES_DATABASE:-idiario}

if [ "$IDIARIO_POSTGRES_START" = true ]; then

 export POSTGRES_HOST=localhost
 echo "PostgreSQL Internal START=TRUE!!! -> ($POSTGRES_HOST)"

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
else
 export POSTGRES_HOST=${POSTGRES_HOST}
 echo "PostgreSQL Internal START=FALSE!!!"
 echo "Using External PostgreSQL -> $POSTGRES_HOST"
 echo "Waiting PostgreSQL UP..."
 sleep 10
fi

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
sed -i "s;host:.*;host: $POSTGRES_HOST;" config/database.sample.yml
echo -e "
production:
  <<: *default
  database: $POSTGRES_DATABASE" >> config/database.sample.yml

# Conf config/initializers/*.rb
echo "Configurando config/initializers/*"
sed -i "s;'redis://.*';'redis://localhost:$REDIS_PORT';" config/initializers/sidekiq.rb
sed -i "s;.*config.secret_key.*;config.secret_key = '$IDIARIO_SECRET_KEY';" config/initializers/devise.rb

######### SMTP ##########

RECIPIENT_RESTRICTIONS=static:OK

export SMTP_LOGIN SMTP_PASSWORD RECIPIENT_RESTRICTIONS
export SMTP_HOST=${SMTP_HOST:-"email-smtp"}
export SMTP_PORT=${SMTP_PORT:-"25"}
export USE_TLS=${USE_TLS:-"yes"}
export TLS_VERIFY=${TLS_VERIFY:-"may"}

# Render template and write postfix main config
cat <<- EOF > /etc/postfix/main.cf
#
# Just the bare minimal
#

# write logs to stdout
maillog_file = /var/log/mail.log
#maillog_file = /dev/stdout

# network bindings
inet_interfaces = all
inet_protocols = ipv4

# general params
compatibility_level = 2
myhostname = $HOSTNAME
mynetworks = 127.0.0.0/8 [::1]/128
relayhost = [$SMTP_HOST]:$SMTP_PORT

# smtp-out params
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = static:$SMTP_LOGIN:$SMTP_PASSWORD
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_tls_security_level = $TLS_VERIFY
smtp_tls_session_cache_database = btree:\$data_directory/smtp_scache
smtp_use_tls = $USE_TLS

# RCPT TO restrictions
smtpd_recipient_restrictions = check_recipient_access $RECIPIENT_RESTRICTIONS, reject

# some tweaks
biff = no
delay_warning_time = 1h
mailbox_size_limit = 0
readme_directory = no
recipient_delimiter = +
smtputf8_enable = no
EOF

# Generate default alias DB
newaliases

# Launch
echo "INICIANDO SMTP -> [$SMTP_HOST]:$SMTP_PORT"
rm -f /var/spool/postfix/pid/*.pid
postfix -c /etc/postfix start
tail -F /var/log/mail.log &
