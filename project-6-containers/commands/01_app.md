# Steps 2–3 — Build and run the app image

All of this is on the ubuntu VM. Maven does **not** start MySQL. It only produces the WAR.

```bash
mkdir -p ~/vprofile-docker/app
cd ~/vprofile-docker/app
docker pull tomcat:8-jre11
```

```bash
sudo apt update
sudo apt install -y git maven
git clone -b main https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
mvn install -DskipTests
cp target/vprofile-v2.war ~/vprofile-docker/app/
cd ~/vprofile-docker/app
```

Write [app/Dockerfile](../app/Dockerfile) in this folder (`vim Dockerfile`). WAR and Dockerfile must be together.

```bash
docker build -t vprofile-app:v1 .
docker run -d --name vprofile-app -p 8080:8080 vprofile-app:v1
sudo apt install -y elinks
elinks http://127.0.0.1:8080
```

`q` quits elinks. The UI should load. Login will fail until Compose (no DB yet).
