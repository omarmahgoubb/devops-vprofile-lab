# Step 4 — Push the app image to Docker Hub

Hub user: `omarrmahgoub`. `tag` only adds a second name. `push` uploads.

```bash
docker login
docker tag vprofile-app:v1 omarrmahgoub/vprofile-app:v1
docker images
docker push omarrmahgoub/vprofile-app:v1
```

You do not have to create the Hub repo first. Refresh My Hub when it finishes.
