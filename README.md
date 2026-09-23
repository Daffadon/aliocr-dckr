# aliocr-deployed

Run [Alibaba Open Code Review](https://github.com/alibaba/open-code-review) (`ocr` CLI) inside Docker. Code under review mounts into the container. Review output lands back on the host.

## How it works

- Image: `node:22-slim` + `git` + `npm install -g @alibaba-group/open-code-review`.
- `docker-entrypoint.sh` applies provider config from environment on every start, then runs `ocr`.
- Project mounts at `/repo` (read-write). `--output /repo/<file>` appears on the host as `./<file>`.
- No state persists between runs (`--rm`). Config comes from `.env` each time.

## Files

| File | Purpose |
| --- | --- |
| `Dockerfile` | Build `aliocr-dckr:latest` image. |
| `docker-entrypoint.sh` | Map env vars to `ocr config set` on startup. |
| `docker-compose.yml` | Compose wrapper around the same image. |
| `review.sh` | Build + run with sane defaults. |
| `.env.example` | Template for `.env`. |
| `.dockerignore` | Keep secrets and output out of the build context. |
| `.github/workflows/docker.yml` | Build + push prebuilt image to GHCR. |


## Prerequisites

- Docker with Compose v2 (verified in WSL Ubuntu, Docker 28).
- Git repo to review (workspace, range, and commit modes all need git history).
- LLM API key, unless using delegation mode.

## Quickstart

1. Copy and fill the env file, then run a workspace review (staged + unstaged + untracked changes). Output lands in `./review.json`:

```sh
cp .env.example .env
# edit .env, set provider key
./review.sh
```

2. Review a branch range or a single commit:
```sh
./review.sh review --from main --to feature-branch -o /repo/review.json
./review.sh review --commit abc123 -o /repo/review.json
./review.sh review --preview
./review.sh scan --path internal/agent -o /repo/scan.json
```

3. Or call Docker directly (no wrapper script):

```sh
docker build -t aliocr-dckr:latest .
docker run --rm --env-file .env -v ./:/repo -w /repo aliocr-dckr:latest review --format json --audience agent --output /repo/review.json
```

## Prebuilt image

Push to `main` (or run the workflow manually) builds a multi-arch (`linux/amd64`, `linux/arm64`) image with OCR pinned to `1.12.9` and pushes three tags to GHCR:

```text
ghcr.io/<owner>/aliocr-dckr:latest          # tracks main
ghcr.io/<owner>/aliocr-dckr:1.12.9          # OCR release inside
ghcr.io/<owner>/aliocr-dckr:sha-abc1234     # exact build
```

> [!NOTE]
> GHCR lowercases the owner name. No extra secrets needed: the workflow logs in with `GITHUB_TOKEN`. For a private repo, grant the machine user `read:packages` on the image.

Skip the local build and pull instead:

```sh
REVIEW_IMAGE=ghcr.io/<owner>/aliocr-dckr:latest PULL_IMAGE=1 ./review.sh
REVIEW_IMAGE=ghcr.io/<owner>/aliocr-dckr:latest PULL_IMAGE=1 ./review.sh review --from main --to feature-branch -o /repo/review.json
```

Bump the pinned version (workflow `env.OCR_VERSION` and `Dockerfile` default stay in sync):

```sh
docker build --build-arg OCR_VERSION=1.12.9 -t aliocr-dckr:1.12.9 .
```

Or use Compose:

```sh
docker compose run --rm review
```

## Configuration

All config flows through `.env`, loaded with `--env-file .env` (or `env_file` in Compose). The entrypoint applies it with `ocr config set` on every start.

### Built-in provider

Pick a built-in provider, set its key, done. The URL is preset.

```sh
OPENAI_API_KEY=sk-xxx
OCR_PROVIDER=openai
OCR_MODEL=gpt-4o
OCR_OUTPUT=review.json
```

Other keys follow the same pattern: `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `DEEPSEEK_API_KEY`, `DASHSCOPE_API_KEY`, and 20+ more. See the [configuration docs](https://raw.githubusercontent.com/alibaba/open-code-review/main/pages/src/content/docs/en/configuration.md).

### Custom OpenAI-compatible endpoint

Any OpenAI-compatible endpoint works as a custom provider. Uncomment the block in `.env.example`:

```sh
OCR_PROVIDER=my-gateway
OCR_MODEL=openai/gpt-4o
OCR_CUSTOM_URL=https://gateway.internal:8000/v1
OCR_CUSTOM_PROTOCOL=openai
OCR_CUSTOM_API_KEY=sk-xxx
```

The entrypoint writes these keys on startup:

- `custom_providers.<name>.url`
- `custom_providers.<name>.protocol` (`openai`, `openai-responses`, `anthropic`, or `anthropic-bedrock`)
- `custom_providers.<name>.model`
- `custom_providers.<name>.api_key`

> [!NOTE]
> Config lives at `~/.opencodereview/config.json` inside the container. Containers run with `--rm`, so nothing persists. Every start re-applies config from `.env`. That is why the entrypoint exists: separate `docker run` calls cannot share setup state.

> [!TIP]
> Test connectivity without reviewing: `docker run --rm --env-file .env aliocr-dckr:latest llm test`. A 401/403 means the token is wrong or expired.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| No valid LLM endpoint configured | Check `OCR_PROVIDER`/`OCR_MODEL` and the provider key in `.env`. |
| 401 / 403 from provider | Key wrong or expired. Rotate key. |
| Nothing to review / skipped | Repo has no supported changed files. Try `review --preview` to list what would be reviewed. |
| Output file missing on host | Write to `/repo/<file>` (the mount), not a bare filename. Mount must stay read-write. |
| Entrypoint not found on rebuild | Shell files must use LF line endings, not CRLF. |

## Docs

- [Quickstart](https://raw.githubusercontent.com/alibaba/open-code-review/main/pages/src/content/docs/en/quickstart.md)
- [Configuration](https://raw.githubusercontent.com/alibaba/open-code-review/main/pages/src/content/docs/en/configuration.md)
- [CLI reference](https://raw.githubusercontent.com/alibaba/open-code-review/main/pages/src/content/docs/en/cli-reference.md)
- Upstream repo: [alibaba/open-code-review](https://github.com/alibaba/open-code-review)
