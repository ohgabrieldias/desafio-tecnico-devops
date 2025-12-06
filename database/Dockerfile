FROM postgres:15.8-alpine

ENV POSTGRES_DB=desafio_db
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=password
ENV PGDATA=/opt/postgres/data
COPY script.sql /docker-entrypoint-initdb.d/

EXPOSE 5432

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD pg_isready -U postgres -d desafio_db || exit 1