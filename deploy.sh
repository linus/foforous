#!/bin/bash

PROJECT_NAME=foforous
RELEASE="releases/$(date +%Y%m%d%H%M%S)"

DEPLOY_PATH=/tmp/$PROJECT_NAME
RELEASE_PATH=$DEPLOY_PATH/$RELEASE

SSH="ssh -p 32734 linus@prod2.hanssonlarsson.se"

function remote {
    $SSH $1
}

function upload_tar {
    git archive --format=tar $1 | gzip | remote "mkdir -p $RELEASE_PATH; cd $RELEASE_PATH; tar zxvf -"
}

function dist {
    remote "cd $RELEASE_PATH; make dist"
}

function relink {
    remote "cd $DEPLOY_PATH; rm releases/previous; mv releases/current releases/previous; ln -s $RELEASE releases/current"
}

function restart {
    remote "sudo restart $PROJECT_NAME && /etc/init.d/lighttpd restart"
}

function deploy {
    tag=$1
    if [ "x$tag" = "x" ]; then tag=master; fi
    upload_tar $tag
    dist
}

deploy $1

