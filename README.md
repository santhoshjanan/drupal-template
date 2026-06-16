# Drupal 11 Site Stack Template

A Docker-based starter template for running **Drupal 11** with **MariaDB (Vector)** and **Redis Stack**. This repository is intended for developers who want a quick, reproducible local environment, and for teams preparing a production-like deployment.

## What's included

| Service      | Purpose                                                |
| ------------ | ------------------------------------------------------ |
| `drupal`     | Apache + PHP 8.3 Drupal runtime                        |
| `mariadb`    | MariaDB 11.x with Vector engine (semantic/AI search) |
| `redis`      | Redis Stack (caching, queues, RediSearch/RedisJSON)    |
| `phpmyadmin` | Web-based DB management (development only)             |

---

## Prerequisites

- [Docker Engine](https://docs.docker.com/engine/install/) 24.0+
- [Docker Compose](https://docs.docker.com/compose/install/) 2.20+
- (Optional) `git` and a local IDE for live editing

---

## Quick start

1. Clone the repository (or unzip the project).
2. Copy the environment template and adjust the secrets:

   ```bash
   cp .env.example .env
   ```

   > **Important:** Edit `.env` and replace the placeholder passwords and `DRUPAL_HASH_SALT` with strong, unique values. Never commit `.env`.

3. Build the images and start the stack.

---

## Development environment

The development override mounts your local `drupal/` source code into the container, so changes are reflected immediately without rebuilding the image.

### Start in development mode

```bash
# One-time: build the production image first
docker compose up -d --build

# Run the dev override on top of the base compose file
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Install dependencies and clear cache

```bash
docker compose exec drupal composer install
docker compose exec drupal vendor/bin/drush cr
```

### Access the site

- Drupal: http://localhost:8080
- phpMyAdmin: http://localhost:8081

### Useful development commands

```bash
# View logs
docker compose logs -f drupal

# Run Drush commands
docker compose exec drupal vendor/bin/drush status
docker compose exec drupal vendor/bin/drush uli

# Stop the stack (keeps volumes)
docker compose -f docker-compose.yml -f docker-compose.dev.yml down

# Stop and remove everything including volumes (⚠️ deletes uploaded files/DB)
docker compose -f docker-compose.yml -f docker-compose.dev.yml down -v
```

### Developing custom modules/themes

Place custom code in the standard Drupal locations under `drupal/web/`:

- Modules: `drupal/web/modules/custom/<module_name>`
- Themes: `drupal/web/themes/custom/<theme_name>`
- Profiles: `drupal/web/profiles/custom/<profile_name>`

Because `docker-compose.dev.yml` bind-mounts `drupal/web`, edits appear instantly inside the container.

---

## Production environment

### Start the production stack

```bash
cp .env.example .env     # edit with production secrets first
docker compose up -d --build
```

This uses the hardened production image and named volumes for persistence. Source code is baked into the image at build time, so live editing is **not** possible.

### Production checklist

Before deploying, verify the following:

- [ ] All passwords in `.env` are strong and unique.
- [ ] `DRUPAL_HASH_SALT` is a 64+ character random string, rotated per environment.
- [ ] `DB_PASSWORD`, `DB_ROOT_PASSWORD`, and `REDIS_PASSWORD` are rotated.
- [ ] `.env` and `drupal/web/sites/default/settings.php` are **not** committed to version control.
- [ ] Use Docker Secrets or an external secret manager instead of plain `.env` files if possible.
- [ ] HTTPS/SSL termination is configured in front of the Drupal container.
- [ ] Backups are scheduled for:
  - `drupal-files` volume (`web/sites/default/files`)
  - `drupal-private` volume
  - `drupal-config` volume (configuration sync)
  - The MariaDB database
- [ ] Log rotation and monitoring are enabled.
- [ ] `composer audit` is run before adding or updating dependencies.

### Update production

```bash
# Pull latest code, rebuild image, and restart
git pull
docker compose up -d --build

# Run any pending database updates
docker compose exec drupal vendor/bin/drush updb -y

# Clear caches
docker compose exec drupal vendor/bin/drush cr
```

---

## Project structure

```
.
├── drupal/                  # Application root
│   ├── web/                 # Drupal document root
│   │   ├── modules/custom/  # Custom modules
│   │   ├── themes/custom/   # Custom themes
│   │   └── profiles/custom/ # Custom profiles
│   ├── config/              # Apache and PHP overrides
│   ├── composer.json        # PHP dependencies
│   └── composer.lock
├── docker/                  # Service configs (DB, Redis, etc.)
├── docker-compose.yml       # Production stack
├── docker-compose.dev.yml   # Dev overrides (bind mounts)
├── .env.example             # Environment/secrets template
└── README.md                # This file
```

---

## Testing

Run focused module tests from inside the Drupal container:

```bash
docker compose exec drupal vendor/bin/phpunit --group my_module
```

Tests should be placed under:

```
drupal/web/modules/custom/<module>/tests/src/
```

---

## Security notes

- Never commit `.env` or `settings.php`.
- Rotate secrets per environment.
- Keep `composer.lock` tracked and run `composer audit` before adding dependencies.
- In production, prefer Docker Secrets over plain environment variables for sensitive values.

---

## Troubleshooting

| Symptom                              | Fix                                                                           |
| ------------------------------------ | ----------------------------------------------------------------------------- |
| Site shows a connection error          | Wait for MariaDB and Redis to become healthy: `docker compose ps`             |
| Changes to code are not reflected    | Make sure you started with `docker-compose.dev.yml`                           |
| Permission denied on files           | `docker compose exec drupal chown -R www-data:www-data web/sites/default/files` |
| Container keeps restarting             | Check logs: `docker compose logs -f drupal`                                   |
| Need to wipe everything and start over | `docker compose down -v` then `docker compose up -d --build`                  |

---

## License

This template is provided as-is for building Drupal sites. Update this section with the actual license for your project.
