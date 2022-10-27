#!/bin/bash

echo "Turning off docker container"
docker-compose down

echo "Cleaning up docker"
docker system prune -f