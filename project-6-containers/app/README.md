# App image — build and test (no DB yet)

On the ubuntu VM, with **NAT working** (`docker pull` must succeed):

```bash
mkdir -p ~/vprofile-docker/app
cd ~/vprofile-docker/app
docker pull tomcat:8-jre11

sudo apt install -y git maven
git clone -b main https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
mvn install -DskipTests
cp target/vprofile-v2.war ~/vprofile-docker/app/
cd ~/vprofile-docker/app
```

Put [Dockerfile](Dockerfile) in this folder (WAR and Dockerfile together).

```bash
docker build -t vprofile-app:v1 .
docker run -d --name vprofile-app -p 8080:8080 vprofile-app:v1
sudo apt install -y elinks
elinks http://127.0.0.1:8080
```

`q` quits elinks.

Maven and this `docker run` do **not** need MySQL. You only prove Tomcat serves the WAR. Login needs compose, then [docs/compose-login.md](../docs/compose-login.md).
