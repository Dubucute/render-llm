# render-llm

A lightweight, self-hosted, OpenAI-compatible LLM API that fits **Render's free tier**.
No API keys, no external dependency, no vendor lock-in — your own tiny model endpoint.

- **Inference:** llama.cpp (CPU) `b10326`
- **Model:** [Qwen2.5-0.5B-Instruct](https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF) Q4_K_M (~397 MB)
- **Size math vs free tier:** peak RAM ~460 MB (of 512 MB) with ctx 2048, image ~460 MB (of 1 GB disk), bandwidth usage negligible (KBs per request of 100 GB/mo)

## One-click deploy

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/Dubucute/render-llm)

Or: Render dashboard -> **New +** -> **Blueprint** -> paste `https://github.com/Dubucute/render-llm`.

After deploy you get `https://render-llm.onrender.com` (name may differ).

## Quick test

```bash
curl https://render-llm.onrender.com/health
# {"status":"ok"}

curl https://render-llm.onrender.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5-0.5b","messages":[{"role":"user","content":"Say hello in 5 words"}],"max_tokens":64}'
```

## Use it as a custom provider

OpenAI-compatible base URL: `https://<your-service>.onrender.com/v1` (any key string works, e.g. `none`).

**OpenCode** — add to `~/.config/opencode/opencode.json`:

```json
{
  "provider": {
    "render-llm": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Render LLM (Qwen 0.5B)",
      "options": {
        "baseURL": "https://render-llm.onrender.com/v1",
        "apiKey": "none"
      },
      "models": {
        "qwen2.5-0.5b": { "name": "Qwen 2.5 0.5B (self-hosted)" }
      }
    }
  }
}
```

Then: `opencode --provider render-llm --model qwen2.5-0.5b`

**Anything OpenAI-compatible** (Cline, Continue, Cherry Studio, LangChain, curl, ...):
point `baseURL` at `https://<your-service>.onrender.com/v1`, model id `qwen2.5-0.5b`.

## Swap models (no rebuild needed)

Change the `MODEL_URL` line in the Dockerfile to bake a different model at build time and redeploy
(the default model is baked into the image, so the runtime env fallback in `entrypoint.sh` only
kicks in if the baked file is absent).

| Model | File (GGUF) | Size | Quality |
|---|---|---|---|
| Qwen2.5-0.5B Q4_K_M (default) | `qwen2.5-0.5b-instruct-q4_k_m.gguf` | 397 MB | decent for light tasks |
| Qwen2.5-0.5B Q3_K_M | `qwen2.5-0.5b-instruct-q3_k_m.gguf` | 330 MB | lighter, worse |
| SmolLM2-135M Q4_K_M | `https://huggingface.co/HuggingFaceTB/SmolLM2-135M-Instruct-GGUF/resolve/main/smol-lm2-135m-instruct-q4_k_m.gguf` | ~99 MB | tiny, low quality |

Rule of thumb for 512 MB RAM: keep the model file under ~420 MB at ctx 2048,
or drop `CTX_SIZE` to `1024` (~25 MB KV savings) if the service restarts (OOM).

## Tuning

- `CTX_SIZE` (default `2048`) — lower saves RAM.
- `THREADS` (default `2`) — free tier is 0.1 CPU; more threads won't help.
- `PORT` — Render injects this automatically.

## Honest expectations (free tier)

- **Speed:** ~5-15 tok/s on 0.1 CPU. Fine for autocomplete, classification,
  summarization, small code tasks. Not for long agentic chats.
- **Spin-down:** after 15 min idle the instance sleeps; first request after idle
  takes ~15-30 s (image start + model load).
- **Not a replacement for ZenLite/cloud models** — it's your always-available,
  zero-limit, zero-key fallback and privacy option.
- Free tier has 100 GB/mo bandwidth and 512 MB RAM. Upgrade to Starter (0.5 CPU)
  for a 3-5x speed bump if you like it.

## Why this stack

- Ollama/LocalAI/vLLM/TGI: too heavy (multi-GB images, Python deps, GPU assumptions) for 512 MB.
- llama.cpp: single binary + one GGUF file, mmap'd weights, ~470 MB peak — built for small boxes.
- Model baked at build time so free-tier cold starts don't re-download 400 MB (ephemeral disk).
