# OpenVAS in Docker

Simply build it with:

```shell
$ git clone https://github.com/sevaho/openvas-docker.git
$ cd openvas-docker
$ docker build -t "openvas" .
```

> NOTE: Building this container will take a long time +- 45 minutes

Run the container:

```shell
$ docker run -p 80:80 -p 443:443 openvas run -u "admin" -p "admin" # you can change username and password
```
