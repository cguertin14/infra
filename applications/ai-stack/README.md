# AI Stack: Ollama and Open WebUI

Ollama runs on `nvidiaserver` and is reachable inside the cluster at
`http://ollama.ai-stack.svc.cluster.local:11434`. Open WebUI has no GPU request
or node affinity, so it can run on any eligible cluster node. Open WebUI is
available at `https://chat.cguertin.dev` through Envoy Gateway and the
cluster's OAuth proxy. Ollama's API remains ClusterIP-only.

Open WebUI's built-in login remains enabled and signup is disabled; the gateway
also requires the cluster's OAuth authentication.

Open WebUI's application database is stored in the dedicated single-instance
CloudNativePG cluster `open-webui-postgres`. Its credentials are SOPS-encrypted
in `secrets/open-webui-postgres-credentials.yml`. The `open-webui-data` PVC is
retained for other WebUI files. The PostgreSQL change does not migrate any data
from an existing SQLite database.

The model cache is stored on a 20Gi `ceph-block` PVC and excluded from Velero
backups because model files can be downloaded again. Pull a model manually
after the app is healthy, for example:

```sh
kubectl -n ai-stack exec deploy/ollama -- ollama pull qwen3:4b
```

## Suggested models

The GTX 1080 has 8GiB of VRAM, with Immich currently using about 2GiB. Start
with a 4B model; the larger options below may be tight when Immich is also using
the GPU. Keep the context short and load one model at a time.

| Model | Use | Notes |
| --- | --- | --- |
| `qwen3:4b` | General chat | Recommended starting point. |
| `gemma3:4b` | General chat | Lightweight alternative. |
| `qwen2.5-coder:7b` | Coding | May be tight alongside Immich; use a short context. |
| `deepseek-r1:8b` | Reasoning | Likely tight alongside Immich and may be slower. |

The pod requests one time-sliced NVIDIA GPU allocation and keeps its one loaded
model resident until the pod restarts (`OLLAMA_KEEP_ALIVE=-1`) to avoid cold-load
delays after idle periods. Immich currently uses about 2GiB of the GTX 1080's
8GiB VRAM, so this is configured for one loaded model and a 2048-token context
to leave headroom. GPU time-slicing does not partition or reserve VRAM.

For temporary local access to Open WebUI, bypassing the gateway:

```sh
kubectl -n ai-stack port-forward service/open-webui 8080:8080
```

Open `http://localhost:8080` in a browser. Open WebUI uses its built-in login;
the first account created becomes the administrator.

For temporary direct access to the Ollama API:

```sh
kubectl -n ai-stack port-forward service/ollama 11434:11434
```

Then use the Ollama CLI locally or call `http://localhost:11434/api/chat`.
Keep the model API on trusted networks; Ollama does not provide API
authentication by default.
