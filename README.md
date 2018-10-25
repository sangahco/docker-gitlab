# docker-gitlab
GitLab Server Docker Image

## Reconfigure gitlab

`docker exec -it <container name> gitlab-ctl reconfigure`

## Restart gitlab

`docker exec -it <container name> gitlab-ctl restart`

## Create a backup file

`docker exec -it <container name> gitlab-rake gitlab:backup:create`
>By default the backup file are stored in /var/opt/gitlab/backups

## Restore a backup file

`docker exec -it <container name> gitlab-rake gitlab:backup:restore`

## Check LDAP configuration

`docker exec -it <container name> gitlab-rake gitlab:ldap:check`
