SHELL := /bin/bash

# Detect the OS (Linux vs. Darwin/macOS)
OS := $(shell uname -s)

# Define a variable DOCKER_CMD that might be "docker compose" or "sudo docker compose"
ifneq (,$(findstring Linux,$(OS)))
    # On Linux, often need 'sudo' for Docker unless the user is in the docker group
    DOCKER_CMD = sudo docker compose
else ifneq (,$(findstring Darwin,$(OS)))
    # On macOS, typically no sudo required
    DOCKER_CMD = docker compose
else
    # Fallback to no sudo if OS is something else
    DOCKER_CMD = docker compose
endif

# Default target if you type just `make`
.DEFAULT_GOAL := run

.PHONY: network run down logs clean

## network: Create the mlops network if not exists
network:
	@echo "Creating 'mlops' network if it doesn't exist..."
	-docker network create mlops

## run: Create the network first, then run docker compose
run: network
	@echo "Running '$(DOCKER_CMD) up -d --build'..."
	$(DOCKER_CMD) up -d --build

## down: Stop and remove containers (but keep volumes)
down:
	@echo "Stopping and removing containers..."
	$(DOCKER_CMD) down

## logs: Follow logs of all containers
logs:
	@echo "Attaching logs (Ctrl+C to quit)..."
	$(DOCKER_CMD) logs -f

## clean: Stop containers and remove volumes
clean:
	@echo "Stopping and removing containers, including volumes..."
	$(DOCKER_CMD) down -v