# 21. AI / ML / Chat

This profile is a mechanical extraction from the original domain catalog. Its inherited domain guidance is preserved.

**Archetype:** Team managing AI models, prompts, conversations, usage/cost tracking, and evaluation pipelines.

**Core entities:** Model/Deployment, Prompt/Template, Conversation/Thread, Message, Usage Record (tokens/cost), Evaluation/Benchmark, Knowledge Base/RAG Source, Fine-tune Job

**Gotchas:**
- **Token cost tracking requires per-request granularity** — input tokens, output tokens, cached tokens, and model-specific pricing all differ. Aggregate by user, by feature, by model, by time period. Costs can spike 100x overnight if a prompt change increases output length. Budget alerts and per-user/per-org rate limits are essential.
- **Streaming responses require a fundamentally different UX pattern** — the response builds token-by-token. The UI must handle: streaming display (token-by-token or chunk-by-chunk), cancellation mid-stream (AbortController), retry on failure mid-stream, and saving the final complete response. Standard request/response patterns don't work.
- **Prompt versioning is as critical as code versioning** — a prompt change can silently degrade output quality across the product. Track prompt versions, link them to evaluation scores, and support rollback. Treat prompts as deployment artifacts, not strings in a database.
- **Conversation history has context window limits** — you cannot send the entire conversation to the model forever. Implement truncation strategies (sliding window, summarization, hybrid) and make the strategy visible/configurable. Users will notice when the model "forgets."
- **Evaluation is not optional and is domain-specific** — "accuracy" means different things for summarization vs. code generation vs. classification. Build evaluation pipelines with domain-appropriate metrics, human review workflows, and A/B testing between prompt versions or models.
- **RAG (Retrieval-Augmented Generation) adds a whole subsystem** — document ingestion, chunking strategy, embedding generation, vector storage, retrieval quality measurement, source attribution in responses. Each has tuneable parameters that dramatically affect quality.
- **Content moderation is both input and output** — filter harmful inputs before they reach the model AND filter harmful outputs before they reach the user. Log moderation events. False positives frustrate users; false negatives create liability.
- **Model availability and latency vary unpredictably** — different models have different rate limits, different uptime, different latency profiles. Build fallback chains (try Model A, fall back to Model B), queue management, and latency monitoring per model.
- **Model deprecation is an operational lifecycle** — OpenAI deprecates models on ~6-month cycles. Fine-tuned models are stranded when their base is deprecated. Track model version per conversation and eval result. Build migration paths: deprecation alerts, evaluation re-runs against replacement models, forced migration deadlines.
- **Embedding model changes invalidate all existing vectors** — if you change from `text-embedding-ada-002` to `text-embedding-3-small`, every vector in your database is incompatible. You cannot mix vectors from different models in the same index. Track embedding model provenance per vector. Plan for dual-index migration strategy. This is an architecture decision that's nearly impossible to fix retroactively.
- **Structured output fails 1-20% of the time** — prompt-based JSON extraction is 80-95% reliable. Function calling raises it to 95-99%. Only constrained decoding (OpenAI `json_schema`, Anthropic tool-use-as-structured-output) reaches near-100%. Validate every response against the schema. Build graceful degradation for parse failures.
- **Multi-modal content changes everything** — images consume 1,000+ tokens per image (tiled pricing). Audio is time-based. The data model needs `content_blocks[]` not a `content` string. Context budget math must include media tokens. Storage requirements change dramatically.

**Compliance:** Data processing agreements with model providers, GDPR (conversation data is personal data if it contains PII), EU AI Act (risk classification, transparency requirements), CCPA, industry-specific rules if AI processes financial/medical/legal data, content moderation obligations.

**UX users expect:** Chat interface with streaming responses, conversation history with search, prompt playground/testing sandbox, usage/cost dashboard with per-model breakdown, model performance comparison charts, knowledge base/document management for RAG, evaluation results dashboard, system prompt editor with version history.

**Seed data shape:** 3 model deployments (GPT-4o, Claude Sonnet, a fine-tuned model). 5 system prompts with 3 versions each — linked to evaluation scores showing version-over-version improvement. 200 conversations (1,500 messages) spanning 30 days across 20 users. Token usage records with cost breakdown per model per day. 1 RAG knowledge base with 50 ingested documents and chunking metadata. 30 evaluation runs with domain-specific metrics. 5 flagged conversations (content moderation triggers). Rate limit events for 2 users.
