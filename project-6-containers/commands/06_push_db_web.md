# Push DB and web images

Do **not** push `memcached` or `rabbitmq` (official). App was already pushed in [02_push_app.md](02_push_app.md).

```bash
docker images
```

You should already see `omarrmahgoub/vprofile-db:v1` and `omarrmahgoub/vprofile-web:v1` (we tagged at build time). If a short name exists instead:

```bash
docker tag vprofile-db:v1 omarrmahgoub/vprofile-db:v1
docker tag vprofile-web:v1 omarrmahgoub/vprofile-web:v1
```

```bash
docker login
docker push omarrmahgoub/vprofile-db:v1
docker push omarrmahgoub/vprofile-web:v1
```

Hub should then have three repos: `vprofile-app`, `vprofile-db`, `vprofile-web`. The DB image includes the SQL dump — lab only.
