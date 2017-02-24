#!/bin/bash

set -e

if [ "$1" == "build" ]; then
  shift

  docker-compose build app
elif [ "$1" == "prepare" ]; then
  shift

  docker-compose up -d db
  sleep 5
  docker-compose run --rm prepare
elif [ "$1" == "shell" ]; then
  docker-compose run --rm test bash
elif [ "$1" == "devprepare" ]; then
  docker-compose run --rm devprepare
elif [ "$1" == "devshell" ]; then
  docker-compose run --rm dev bash
elif [ "$1" == "serve" ]; then
  docker-compose run --rm dev rake db:create
  docker-compose run --rm dev rake db:migrate
  docker-compose up dev
else
  echo "Running tests"
  docker-compose run --rm test rspec
  EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    echo "Tests Failed"
    exit $EXIT_CODE
  else
    echo "Tests Succeeded"
  fi

  docker-compose run --rm test cucumber
  EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    echo "Tests Failed"
  else
    echo "Tests Succeeded"
  fi

  exit $EXIT_CODE
fi

