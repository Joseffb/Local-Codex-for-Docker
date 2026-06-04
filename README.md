# Codex for Docker

Codex for Docker is a local-first fork of the open source Codex CLI. Its default runtime uses Docker Model Runner through an OpenAI-compatible Chat Completions adapter, with optional Docker MCP Toolkit setup for local tools.

## Status

- Local Docker Model Runner execution has been smoke-tested.
- Large-prompt handling has been smoke-tested with a Docker Model context-size variant.
- Container packaging is present and its Dockerfile/Compose metadata has been validated, but the full container image has not yet been build-and-run validated.

## Local-Only Contract

- No OpenAI API key is required by default.
- No outbound model calls are made by default.
- There is no automatic cloud fallback.
- Cloud providers remain available only when explicitly configured or selected.
- Docker/local execution remains the default behavior.

## Defaults

The bootstrap default config is:

```toml
model_provider = "docker-model-runner"
model = "ai/qwen3-coder"
```

`ai/qwen3-coder` is only the starter model. Change `model` through the normal Codex config paths to use newer Docker Models as they become available.

Built-in local providers:

- `docker-model-runner`: `http://localhost:12434/engines/v1`
- `docker-model-gateway`: `http://localhost:4000/v1`

Both use `wire_api = "chat_completions"`. The legacy `wire_api = "chat"` value remains rejected.

## Docker MCP Toolkit

On first interactive startup, Codex for Docker checks for Docker MCP Toolkit. If it is available and no `docker` MCP server is already configured, it prompts:

```text
Docker MCP Toolkit detected. Configure automatically? [Y/n]
```

Accepting persists:

```toml
[mcp_servers.docker]
command = "docker"
args = ["mcp", "gateway", "run"]
```

Declining persists:

```toml
docker_mcp_auto_configure = false
```

Existing user-defined `docker` MCP servers are preserved.

## Runtime Order

Build and validate locally first:

1. Enable Docker Model Runner.
2. Pull the bootstrap model:

   ```sh
   docker model pull ai/qwen3-coder
   ```

3. Run Codex for Docker locally against Docker Model Runner.
4. Verify a coding-agent turn and Docker MCP tool discovery.

For large prompts, Codex for Docker inspects the selected Docker Model and creates/reuses a `codex-for-docker/...:ctxN` variant with the model's native context size when Docker exposes that metadata.

## Container Runtime

The v1 container image packages the Codex for Docker CLI/runtime and a Docker CLI. It does not start or bundle Docker Model Runner, Docker Model Gateway, or a separate Docker MCP Gateway service. Those stay on the host, or must otherwise be reachable from inside the container.

Build the image:

```sh
docker build -t codex-for-docker:local .
```

Run with Compose from this repository:

```sh
docker compose run --rm codex
```

The Compose example:

- Mounts the current directory at `/workspace`.
- Persists container Codex state in the `codex-home` volume.
- Mounts `/var/run/docker.sock` so Docker CLI commands can talk to the host Docker engine.
- Points the container provider at `http://host.docker.internal:12434/engines/v1`.

To use Docker Model Gateway instead, change the Compose provider URL to `http://host.docker.internal:4000/v1`.

To use a different Docker Model, set `model` through normal Codex config, or add another Compose `-c` override such as:

```yaml
- -c
- 'model="ai/your-model"'
```

Inside the container, dynamic context matching requires `docker model inspect` and `docker model package` to be available to the runtime Docker CLI and requires access to the host Docker socket.

This repository is licensed under the [Apache-2.0 License](LICENSE).
