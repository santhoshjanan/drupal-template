# Repository Guidelines

Contributor guide for the Drupal site stack template. Covers layout, commands, style, testing, and security.


## Non-Negotiable Instructions

- Do not automatically agree with requirements. Assess practicality, maintainability, and fit with the existing architecture.
- If a request is not the best approach, state the concern briefly, propose an alternative, listen to the user's preference, then choose the final action.
- Use the Memory System Operations below.

### Be Token Frugal

- Keep user-facing responses concise unless code, architecture, or risk requires detail.
- Do not output unnecessary reasoning.
- Use tool calls only when they add value. Prefer `rg`/`rg --files` for search and direct file reads for context.
- Spawn subagents only after preparing complete context and only when the task truly benefits from parallel independent work.


## Project Structure & Module Organization

- `drupal/` — Application root.
  - `web/` — Document root.
    - `modules/custom/` — Custom modules.
    - `themes/custom/` — Custom themes.
    - `profiles/custom/` — Custom profiles.
  - `config/` — Apache and PHP overrides.
  - `composer.json` / `composer.lock` — PHP dependencies.
  - `recipes/` — Drupal recipes.
- `docker/` — Service configs (`db/my.cnf`, `redis/redis.conf`).
- `docker-compose.yml` — Production stack.
- `docker-compose.dev.yml` — Dev overrides with live bind-mounts.
- `.env.example` — Environment and secrets template.

## Build, Test, and Development Commands

Run from the repository root:

```bash
cp .env.example .env              # configure secrets
docker compose up -d --build      # start full stack
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d  # dev mode
docker compose exec drupal composer install
docker compose exec drupal vendor/bin/drush cr
```

Stack: Drupal 11 (Apache/PHP), MariaDB Vector, Redis Stack, phpMyAdmin.

## Coding Style & Naming Conventions

- Follow `drupal/.editorconfig`: 2-space indentation; 4 spaces for `composer.json`/`composer.lock`.
- PHP follows Drupal coding standards; use PHPCS with `drupal/coder` when installed.
- Machine names: `my_module`, `my_theme`. Files use Drupal 11 conventions for info/routing/services/hooks.
- Front-end assets follow core `.eslintrc.json` and `.stylelintrc.json` rules.

## Testing Guidelines

- Core/contrib tests live under `tests/src/` inside each package.
- Add custom tests in `drupal/web/modules/custom/<module>/tests/src/`.
- Run focused module tests via the container:
  ```bash
  docker compose exec drupal vendor/bin/phpunit --group my_module
  ```
- Keep tests focused with descriptive method names.

## Commit & Pull Request Guidelines

- Use concise, descriptive commits: `Add hero paragraph bundle` or `Fix Redis cache backend`.
- PRs must include a clear summary, local verification steps, and confirmation that `docker compose up -d --build` starts cleanly. Include screenshots for UI changes.

## Security & Configuration Tips

- Never commit `.env` or `drupal/web/sites/default/settings.php`.
- Rotate `DRUPAL_HASH_SALT`, `DB_PASSWORD`, `DB_ROOT_PASSWORD`, and `REDIS_PASSWORD` per environment.
- Prefer Docker Secrets over plain env vars in production.
- Keep `composer.lock` tracked and run `composer audit` before adding dependencies.
