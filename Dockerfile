# render-llm — lightweight self-hosted OpenAI-compatible LLM for Render free tier
# Stack: llama.cpp (CPU) + Qwen2.5-0.5B-Instruct Q4_K_M
# Peak RAM ~460 MB (fits the 512 MB free instance), image ~460 MB (fits 1 GB disk)
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LLAMA_VERSION=b10326
ENV MODEL_URL=https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf

# libgomp1 = OpenMP runtime required by llama.cpp CPU kernels (libgomp.so.1)
# curl pulls libssl3t64 automatically; libstdc++6/libgcc-s1 come with the base image
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates libgomp1 libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/llama
# Official llama.cpp prebuilt (glibc, x64 — Render build runners are amd64)
RUN curl -fsSL -o /tmp/llama.tar.gz \
        "https://github.com/ggml-org/llama.cpp/releases/download/${LLAMA_VERSION}/llama-${LLAMA_VERSION}-bin-ubuntu-x64.tar.gz" \
    && tar xzf /tmp/llama.tar.gz -C /opt/llama --strip-components=1 \
    && rm /tmp/llama.tar.gz

# Model baked into the image at BUILD time: Render free-tier disks are ephemeral,
# so a runtime download would re-fetch ~400 MB on every cold start.
RUN mkdir -p /models && curl -fsSL -o /models/model.gguf "${MODEL_URL}"

COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

EXPOSE 10000
ENTRYPOINT ["/opt/entrypoint.sh"]
