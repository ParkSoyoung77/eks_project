FROM mysql:8.4

COPY ./init.sql /docker-entrypoint-initdb.d/
COPY ./my.cnf /etc/mysql/conf.d/my.cnf