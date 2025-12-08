#!/bin/sh

set -e

cd $(dirname $0)

mkdir -p out

(
./base.sh
) 2>&1 | tee out/build-base.log

(
docker compose up --build
docker compose down
) 2>&1 | tee out/build-ubuntu.log
