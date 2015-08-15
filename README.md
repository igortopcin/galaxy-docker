# Galaxy for Medical Imaging - Docker Image

## Building the docker image
Make sure you init and update ``galaxy`` submodule by doing:
```shell
git submodule init
git submodule update
```

The commands above will fetch the latest version of galaxy. You are now prepared to build the docker image:

```shell
docker build -t galaxy .
```

## Running galaxy
The following will run galaxy on host port 8080:
```shell
docker run -d --name galaxy -p 8080:8080 galaxy
```

# HTCondor configuration
HTCondor is installed by default in this image, but it does not run by default. Its default configuration can be found in ``./config``, but any configuration parameter can be overriden by environment variables prefixed by ``_CONDOR_``.

To enable HTCondor, one must start the docker image with ``--run-condor`` argument. For example:
```shell
docker run -d --name galaxy -p 8080:8080 galaxy --run-condor
```

When HTCondor is enabled, ``./config/job_conf.xml.sample_condor`` is used. However, when HTCondor is disabled (the default), ``./config/job_conf.xml.sample_basic`` is used.

## Bootstrapping
TBD

## Mounting ``/data``
TBD

## Setting up postgres
Create a new user for galaxy in your postgres:
```shell
su postgres

createuser -P galaxy
#choose a password for galaxy user and then retype it.

createdb -O galaxy galaxy
```

Now you are ready to run galaxy. Note that the first time galaxy is run, it will try to bootstrap the database (create tables and initial data). Examples:

```shell
docker run -d --name galaxy --link postgres -p 8080:8080 galaxy
```

```shell
docker run -d --name galaxy --add-host postgres:10.8.0.26 -p 8080:8080 galaxy
```
