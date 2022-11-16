The scripts are in [docker-compose.yml](./docker-compose.yml).

For example

```
mkdir /tmp/unhelm && chmod a+rxw /tmp/unhelm
docker-compose up --build --force-recreate --exit-code-from logs logs
docker-compose up --build --force-recreate --exit-code-from mysql mysql
docker-compose up --build --force-recreate --exit-code-from vault vault
docker-compose up --build --force-recreate --exit-code-from fluent-bit fluent-bit
docker-compose up --build --force-recreate --exit-code-from mimir mimir
docker-compose up --build --force-recreate --exit-code-from openreplay openreplay
```
