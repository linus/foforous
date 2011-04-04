#!/bin/bash

PROJECT_NAME=foforous
DEPLOY_PATH=/opt/hanssonlarsson/$PROJECT_NAME
USER=linus

SSH="ssh -p 32734 $USER@prod2.hanssonlarsson.se"

function remote {
    $SSH -t $1
}

function setup {
    remote "sudo mkdir -p $DEPLOY_PATH; sudo chown $USER $DEPLOY_PATH; mkdir -p $DEPLOY_PATH/config"
}

function upload_tar {
    git archive --format=tar $1 | gzip | remote "mkdir -p $RELEASE_PATH; cd $RELEASE_PATH; tar zxvf -"
}

function dist {
    remote "cd $RELEASE_PATH; make dist"
}

function copy_settings {
    remote "cd $RELEASE_PATH; cp -n config.coffee.sample $DEPLOY_DIR/config/config.coffee; sudo cp -n etc/$PROJECT_NAME.conf /etc/init; sudo cp -n etc/lighttpd.conf /etc/lighttpd/conf-available/25-$PROJECT_NAME.conf; sudo ln -s /etc/lighttpd/conf-available/25-$PROJECT_NAME.conf /etc/lighttpd/conf/enabled/25-$PROJECT_NAME.conf"
}

function relink {
    remote "cd $DEPLOY_PATH; rm -f releases/previous; mv releases/current releases/previous; ln -s $RELEASE releases/current"
}

function restart {
    remote "sudo restart $PROJECT_NAME && sudo /etc/init.d/lighttpd restart"
}

function deploy {
    TAG=$1
    if [ "x$TAG" = "x" ]; then TAG=master; fi

    RELEASE="$TAG-$(date +%Y%m%d%H%M%S)"
    RELEASE_PATH=$DEPLOY_PATH/releases/$RELEASE

    setup
    upload_tar $TAG
    dist
    copy_settings
    relink
    restart
}

deploy $1

