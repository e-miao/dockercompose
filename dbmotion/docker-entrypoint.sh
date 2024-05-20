#/bin/bash

#
# docker entrypoint for dbmtion
#  - run SAAS api server
#  - run DOCKER api server
#  - run task
#  - run dbmotion command line tool
#  - show usage
#
usage() {
echo "you can run this image as following:
  1, run dbmotion directly, e.g.
     docker run -it this-image-name:xxx dbmotion --version
  2, run api server in squids-k8s, NOTE: export port 3000 for accessing web api. e.g.
     docker run -it -e SERVER_MODE=SAAS \\
       -e K8S_NAMESPACE=squids-user -e NODE_SELECTOR_KEY=node-role.kubernetes.io/master \\
       -e NODE_SELECTOR_VALUE="" -e MASTER_TOLERATION=y \\
       -e MYSQL_HOST=squids-web-mysql-primary-headless.squids.svc.cluster.local \\
       -e MYSQL_PORT=3306 -e MYSQL_USER_NAME=squidsxxxx -e MYSQL_PASSWORD=yyyyy \\
       -e JWT_SECRET=squids_secret_xz98fj9r1wq -e PVC_CLAIM_NAME=dbmotion-saas \\
       -e ELASTICSEARCH_URI=http://elasticsearch-logging.squids-logging.svc.cluster.local:9200 \\
       -e ELASTICSEARCH_IDX=dbmotion_log \\
       -e CPU_LIMIT=4 -e CPU_REQUEST=2 -e MEMORY_LIMIT=8Gi -e MEMORY_REQUEST=4Gi \\
       -p 3000:3000 this-image-name:xxx
  3, run api server in local docker, NOTE: export port 3000 for accessing web api. e.g.
     docker run -it --name=dbmotion-api-server --network=dts-network \\
       -e SERVER_MODE=DOCKER \\
       -e MYSQL_HOST=dts-mysql -e MYSQL_PORT=3306 \\
       -e MYSQL_USER_NAME=root -e MYSQL_PASSWORD=dbmotion \\
       -p 3000:3000 this-image-name:xxx
  4, run shell, e.g.
     docker run -it this-image-name:xxx /bin/bash
"
}

logf="docker-entrypoint.log"
log(){
  echo "$1 :" >> $logf
  shift
  for arg in "$@"; do
    echo "  $arg" >> $logf
  done
}

# show help
if [[ "$1" = "help" || "$1" = "--help" || "$1" = "-h" || "$1" = "?" ]]; then
  log "show help" "$@"
  echo "  $@" >> $logf
  usage
  exit 0
fi

# run shell
if [[ "$1" = "/bin/bash" || "$1" = "bash" || "$1" = "/bin/sh" || "$1" = "sh" ]]; then
  log "run shell" "$@"
  shell=$1; shift
  exec $shell "$@"
fi

# run dbmotion directly. e.g.
# docker run -it dbmotion-image:xxx dbmotion --version
# docker run -it dbmotion-image:xxx dbmotion --get-result=y --dbtype=mongo ...
if [[ "$1" = "dbmotion" || "$1" = "dbmotions" || "$1" = "dbmtask" ]]; then
  log "dbmotion/dbmotins/dbmtask" "$@"
  progname="$1"
  shift
  exec "$progname" "$@"
fi

# run api server
if [[ -n "$SERVER_MODE" ]]; then
  log "run api server" "$@"
  fname=$(which run-api-server.sh)
  exec bash "$fname" "$@"
fi

# no commands
if [[ "$1" = "" ]]; then
  log "no command can run" "$@"
  echo "no appropriate command can run!"
  usage
  exit 0
fi

# run bash with user specified commands
log "run cmds in bash" "$@"
echo "#!/bin/bash" > cmd.sh
echo "$@" >> cmd.sh
exec bash ./cmd.sh

