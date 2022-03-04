#!/bin/bash
sudo docker pull postgres
sudo docker run --rm --name pgdocker \
  -e POSTGRES_PASSWORD="@sde_password012" \
  -e POSTGRES_USER=test_sde \
  -e POSTGRES_DB=demo \
  -d -p 5432:5432 \
  -v ~/IdeaProjects/sde_test_db/sql/:/var/lib/postgresql/sql postgres
touch ~/docker/volumes/postgres/.pgpass
echo "*:*:*:*:@sde_password012" > ~/docker/volumes/postgres/.pgpass
sudo chmod 600 ~/docker/volumes/postgres/.pgpass
export PGPASSFILE='~/docker/volumes/postgres/.pgpass'
psql demo -h localhost -U test_sde -w -f "~/IdeaProjects/sde_test_db/sql/init_db/demo.sql"
