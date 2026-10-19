# Application and Python environment

The example app is a small FastAPI service that demonstrates a LangGraph workflow and LangChain message types. It intentionally returns a deterministic response so the infrastructure works without an API key, model download, or external network dependency.

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

## Add a model provider

Install and pin the appropriate LangChain integration package, configure the provider through a secret, and replace the deterministic graph node with a model call. For local inference, point to an internal inference service and allow only that destination through the namespace egress policy. Define timeouts, retries, concurrency, token limits, and redacted logging.

Python dependencies are constrained in `requirements.txt` but should be locked with hashes and reviewed for an actual release. Rebuild images from a clean environment and scan dependencies before deployment.
