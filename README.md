# Reverse Proxy with Docker and Nginx

This project sets up a reverse proxy using Docker Compose and nginx to redirect domains to local services.

## Configuration

The proxy is configured to redirect:
- `survey.ederbarrios.online` → `localhost:8001`
- `library.ederbarrios.online` → `localhost:8000`

## Files

- `docker-compose.yml`: Defines the nginx service
- `nginx.conf`: Proxy configuration

## Usage

1. Start the proxy:
```bash
docker-compose up -d
```

2. Stop the proxy:
```bash
docker-compose down
```

## Requirements

- Docker and Docker Compose installed
- Services must be running on ports 8000 and 8001 on your local machine