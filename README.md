The scripts are in [docker-compose.yml](./docker-compose.yml).

For example

```
mkdir /tmp/unhelm && chmod a+rxw /tmp/unhelm
docker-compose up --build --exit-code-from logs logs
docker-compose up --build --exit-code-from mysql mysql
```
