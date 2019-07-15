#!/usr/bin/env bash

IMAGE_NAME="blackmorth/docker-satis"
VERSION="1.0"
CONTAINER_NAME="test-satis"
EXIT_CODE=0

function check_errors() {
  [[ "$1" == "0" ]] || EXIT_CODE=$?
}

function build() {
  docker build -t "${IMAGE_NAME}:${VERSION}" .
  check_errors $?
}

function run() {
  docker rm -f "${CONTAINER_NAME}" || true

  docker run -itd --name "${CONTAINER_NAME}" "${IMAGE_NAME}:${VERSION}"
  check_errors $?

  sleep 3

  docker exec -it "${CONTAINER_NAME}" ./scripts/build.sh
  check_errors $?

  docker rm -f "${CONTAINER_NAME}"
  check_errors $?
}

function test_all() {
  build
  run
}

test_all
exit ${EXIT_CODE}
