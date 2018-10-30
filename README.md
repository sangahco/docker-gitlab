# docker-gitlab
GitLab Server Docker Image

## Reconfigure gitlab

`docker exec -it <container name> gitlab-ctl reconfigure`

## Restart gitlab

`docker exec -it <container name> gitlab-ctl restart`

## Create a backup file

`docker exec -it <container name> gitlab-rake gitlab:backup:create`
> By default the backup file are stored in the container folder `/var/opt/gitlab/backups` (on the host into `$GITLAB_DATA_HOME/backups`)

## Restore a backup file

`docker exec -it <container name> gitlab-rake gitlab:backup:restore`

## Check LDAP configuration

`docker exec -it <container name> gitlab-rake gitlab:ldap:check`

Is possible to use docker-compose `exec` command, replacing `docker exec -it <container name>` with `./docker-auto.sh exec gitlab`.
