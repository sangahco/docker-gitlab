#!/usr/bin/env bash

set -e

SCRIPT_BASE_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "$SCRIPT_BASE_PATH"

###############################################
# Extract Environment Variables from .env file
# Ex. REGISTRY_URL="$(getenv REGISTRY_URL)"
###############################################
getenv(){
    local _env="$(printenv $1)"
    echo "${_env:-$(cat .env | awk 'BEGIN { FS="="; } /^'$1'/ {sub(/\r/,"",$2); print $2;}')}"
}

DOCKER_COMPOSE_VERSION="1.29.2"
CONF_ARG="-f docker-compose.yml"
PATH=$PATH:/usr/local/bin/
PROJECT_NAME="$(getenv PROJECT_NAME)"
REGISTRY_URL="$(getenv REGISTRY_URL)"

########################################
# Install docker-compose
# DOCKER_COMPOSE_VERSION need to be set
########################################
install_docker_compose() {
    sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    return 0
}

if ! command -v docker-compose >/dev/null 2>&1; then
    install_docker_compose
elif [[ "$(docker-compose version --short)" != "$DOCKER_COMPOSE_VERSION" ]]; then
    install_docker_compose
fi

usage() {
echo "Usage:  $(basename "$0") [MODE] [OPTIONS] [COMMAND]"
echo 
echo "Mode:"
echo "  --with-hub          Production mode - have to run under the hub web server"
echo "  --autoscale-runner  Set the autoscale runner"
echo
echo "Options:"
echo "  --help          Show this help message"
echo
echo "Commands:"
echo "  up              Start the services"
echo "  down            Stop the services"
echo "  reconfigure     Update gitlab with the new settings"
echo "  backup          Do a backup of gitlab data folder"
echo "  ps              Show the status of the services"
echo "  logs            Follow the logs on console"
echo "  login           Log in to a Docker registry"
echo "  remove-all      Remove all containers"
echo "  stop-all        Stop all containers running"
echo "  start-runner    Start a gitlab runner"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

for i in "$@"
do
case $i in
    --with-hub)
        CONF_ARG="-f docker-compose-with-hub.yml"
        shift
        ;;
    --autoscale-runner)
        CONF_ARG="-f docker-compose-autoscale-runner.yml --project-name gitlab-runner"
        shift
        ;;
    --help|-h)
        usage
        exit 1
        ;;
    *)
        ;;
esac
done

echo "Arguments: $CONF_ARG"
echo "Command: $@"

if [ "$1" == "login" ]; then
    docker login $REGISTRY_URL
    exit 0

elif [ "$1" == "up" ]; then
    docker-compose $CONF_ARG pull
    docker-compose $CONF_ARG build --pull
    docker-compose $CONF_ARG up -d --remove-orphans
    exit 0

elif [ "$1" == "reconfigure" ]; then
    docker-compose $CONF_ARG exec gitlab gitlab-ctl reconfigure
    exit 0

elif [ "$1" == "backup" ]; then
    # -T flag Disable pseudo-tty allocation so we can use it on crontab
    docker-compose $CONF_ARG exec -T gitlab gitlab-rake gitlab:backup:create
    exit 0
    
elif [ "$1" == "stop-all" ]; then
    if [ -n "$(docker ps --format {{.ID}})" ]
    then docker stop $(docker ps --format {{.ID}}); fi
    exit 0

elif [ "$1" == "remove-all" ]; then
    if [ -n "$(docker ps -a --format {{.ID}})" ]
    then docker rm $(docker ps -a --format {{.ID}}); fi
    exit 0

elif [ "$1" == "logs" ]; then
    shift
    docker-compose $CONF_ARG logs -f --tail 200 "$@"
    exit 0
    
elif [ "$1" == "start-runner" ]; then
    shift
    docker run -d --restart always -v ./gitlab-runner/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest
    exit 0

fi

docker-compose $CONF_ARG "$@"
