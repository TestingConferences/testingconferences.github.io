#!/bin/bash

echo "Starting docker container in background"
docker-compose up -d

sleep 60

if [ -n "$(docker ps -f "name=tcorg" -f "status=running" -q )" ]; then
    echo "Docker container is running"
fi

sleep 60

echo "Loading page"

open http://localhost:4000