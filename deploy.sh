#!/bin/bash

PROJECT_NAME=foforous
DEPLOY_PATH=/tmp/$PROJECT_NAME
USER=linus

SSH="ssh -p 32734 $USER@prod2.hanssonlarsson.se"

function remote {
    $SSH $1
}

function setup {
    remote "sudo mkdir -p $DEPLOY_PATH; sudo chown $USER $DEPLOY_PATH; sudo mkdir -p $DEPLOY_PATH/config; sudo chown $USER $DEPLOY_PATH/config"
}

function upload_tar {
    git archive --format=tar $1 | gzip | remote "mkdir -p $RELEASE_PATH; cd $RELEASE_PATH; tar zxvf -"
}

function dist {
    remote "cd $RELEASE_PATH; make dist"
}

function copy_settings {
    remote "cd $RELEASE_PATH; cp -n config.coffee.sample $DEPLOY_DIR/config/config.coffee; sudo cp -n etc/$PROJECT_NAME.conf /etc/init; sudo cp -n etc/lighttpd.conf /etc/lighttpd/conf-available/25-$PROJECT_NAME.conf"
}

function relink {
    remote "cd $DEPLOY_PATH; rm releases/previous; mv releases/current releases/previous; ln -s $RELEASE releases/current"
}

function restart {
    remote "sudo restart $PROJECT_NAME && /etc/init.d/lighttpd restart"
}

function deploy {
    TAG=$1
    if [ "x$TAG" = "x" ]; then TAG=master; fi

    RELEASE="releases/$TAG-$(date +%Y%m%d%H%M%S)"
    RELEASE_PATH=$DEPLOY_PATH/$RELEASE

    setup
    upload_tar $TAG
    dist
    copy_settings
    relink
    restart
}

deploy $1

