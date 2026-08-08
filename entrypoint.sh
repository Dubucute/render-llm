#!/bin/sh
# render-llm entrypoint — starts llama-server (OpenAI-compatible) on $PORT
set -e
cd /opt/llama

# Runtime fallback: if MODEL_URL env is changed (no rebuild), fetch the model on boot.
if [ ! -s /models/model.gguf ]; then
  echo "[render-llm] model not found, downloading ${MODEL_URL} ..."
  curl -fsSL -o /models/model.gguf "${MODEL_URL}"
fi

PORT="${PORT:-10000}"
CTX_SIZE="${CTX_SIZE:-2048}"
THREADS="${THREADS:-2}"

echo "[render-llm] llama.cpp b10326 + $(basename "${MODEL_URL}")"
echo "[render-llm] listening on 0.0.0.0:${PORT}  ctx=${CTX_SIZE} threads=${THREADS}"
exec ./llama-server \
  -m /models/model.gguf \
  --host 0.0.0.0 \
  --port "${PORT}" \
  --ctx-size "${CTX_SIZE}" \
  --threads "${THREADS}" \
  "$@"
