# Application and Python environment

The example app is a small FastAPI service that demonstrates a LangGraph workflow with a LangChain chat model adapter. By default it returns a deterministic response so the infrastructure works without an API key, model download, or external network dependency.

## Local development

Python 3.11 is the supported example baseline. Use an isolated environment:

```bash
cd app
python3.11 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
uvicorn main:app --reload --host 127.0.0.1 --port 8080
```

Routes:

- `GET /healthz` — liveness response.
- `GET /readyz` — readiness response.
- `POST /chat` — run a simple LangGraph workflow with a message.

## Configure an OpenAI-compatible model

Create credentials without committing them to Git:

```bash
kubectl -n ai-box create secret generic ai-box-model-credentials \
  --from-literal=api-key="$MODEL_API_KEY" \
  --from-literal=base-url="https://api.openai.com/v1"
```

For a local OpenAI-compatible server, use its private service URL as `base-url`. Set `MODEL_BACKEND=openai` in the deployment and change `CHAT_MODEL` to a model name supported by that endpoint. Add a narrow egress policy for the local service or use a controlled egress gateway for external providers. Define timeouts, retries, concurrency, token limits, and redacted logging. The Kubernetes Secret shown here is a demo path; use an external secret manager and encryption at rest for production.

Python dependencies are constrained in `requirements.txt` but should be locked with hashes and reviewed for an actual release. Rebuild images from a clean environment and scan dependencies before deployment.
