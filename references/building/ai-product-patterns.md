# AI Product Patterns

This file covers how to build the functionality layer for AI/LLM-powered products — the dashboards and interfaces that ARE AI products (like ChatGPT, Claude, Cursor, or any SaaS wrapping LLM capabilities). This is not about adding AI features to regular dashboards. This is about building the systems that make an AI product work: streaming, context management, model orchestration, prompt management, RAG, evaluation, cost control, moderation, conversation persistence, and tool calling.

The domain section (#21 in `domain-considerations.md`) covers the *what*. This file covers the *how*.

---

## Streaming response handling

### SSE is the standard

Server-Sent Events, not WebSocket. Both Anthropic and OpenAI use SSE. The Vercel AI SDK defaults to SSE. SSE is unidirectional (server to client — the LLM's output pattern), auto-reconnects, works through CDNs/proxies, and is natively supported by all browsers.

Use WebSocket only when you need bidirectional communication beyond streaming (collaborative editing, real-time presence).

### The streaming pipeline

```
Client sends request (POST with messages)
  > Server validates, authenticates, rate-limits
  > Server calls LLM API with stream: true
  > Server processes chunks (moderation, logging)
  > Server forwards to client via SSE
  > Client renders progressively
  > Server accumulates full response, writes to DB when stream ends
```

### Client-side rendering

The problem: calling `setState` on every token (50-100/second) causes re-render jank.

Solutions:
- **Vercel AI SDK `useChat` hook** — handles all complexity. Manages messages, streams tokens, batches updates. The recommended approach for React.
- **Buffering** — accumulate tokens in a ref, flush to state on `requestAnimationFrame` cadence (batches multiple tokens per re-render).
- **Streaming-aware Markdown renderer** — regular Markdown components break with character-by-character input. Libraries like `assistant-ui` and shadcn/ui AI components handle incremental Markdown parsing without flickering.

### "Stop generating" (AbortController)

Cancellation at two levels:

- **Client:** `useChat` provides `stop()`. Aborts the fetch request.
- **Server:** forward the abort signal to the LLM call. Save whatever has been accumulated so far with `stop_reason: 'user_cancelled'`.

### Error handling mid-stream

When the LLM errors at token 500 of 1000:
1. Catch the error event from the provider.
2. Preserve partial content already accumulated.
3. Render: partial response text + error indicator + "[Retry]" button.
4. Save to DB with `status: 'error'` and the partial content.

### Streaming with tool calls

1. Model streams text: "Let me look that up..."
2. Model emits tool call (stops streaming text).
3. Server executes the tool, gets the result.
4. Server sends a new request to the LLM with the tool result appended.
5. Model resumes streaming with the tool result integrated.

On the client: text appearing > brief pause (show "Using tool: search...") > more text with results.

### Rate limiting and queuing

- **Per-user concurrency:** max 3 simultaneous in-flight requests. Return 429 for excess.
- **Per-org rate limit:** aggregate across all users.
- **Global queue with priority:** paid > free. Use BullMQ or in-memory priority queue.
- **Backpressure:** when queued, stream a "waiting in queue..." message before the actual response.
- **Provider limits:** track token/request consumption per provider. Throttle before hitting their limits.

---

## Context window management

### Token counting before sending

Count tokens before making the API call, not after:
- **OpenAI:** `tiktoken` library with `encoding_for_model("gpt-4o")`.
- **Anthropic:** token counting endpoint (`/v1/messages/count_tokens`) or approximate with tiktoken's `cl100k_base`.
- **General:** tokenize all components > check against limit > truncate if needed > send.

### Context budget allocation

```
model_context_limit = 128000
response_reserve    = 4096     (max_tokens for response)
available_input     = limit - reserve

system_prompt_tokens    = count(system_prompt)       # 200-2000 typically
current_message_tokens  = count(user_message)
remaining_for_history   = available - system - current

# Fill history from most recent backward until budget is exhausted
```

**Priority order** (what gets cut last):
1. System prompt — never truncated
2. Current user message — never truncated
3. Most recent assistant response — coherence
4. Recent turns — sliding window newest to oldest
5. Older turns — first to be dropped

### Truncation strategies

| Strategy | How | Best for |
|---|---|---|
| **Sliding window** | Keep last N messages, drop oldest | Casual chat, simplest |
| **Summarization** | Every K turns, summarize older messages with a fast model | Medium-length conversations |
| **Hybrid** (recommended) | System prompt + rolling summary + last N full messages + current | Production assistants |
| **Semantic selection** | Embed all past messages, retrieve most relevant to current query | Long-running assistants where users revisit topics |

### Making context visible

- Progress bar: "Context: 45,000 / 128,000 tokens"
- Warning at 80%: "The conversation is long. The model may forget earlier messages."
- Notification when truncation happens: "Older messages have been summarized."
- Option to start a new conversation with a carried-forward summary.

### Long context vs managed context

**Use long context (200K+):** short conversations with large documents, cost is acceptable, want simplicity.

**Manage shorter context:** hundreds of turns, cost control needed, quality consistency needed (models degrade in very long contexts — "lost in the middle"), high-volume/low-margin use cases.

---

## Model orchestration

### Fallback chains

```
Primary: Claude Sonnet > Fallback 1: GPT-4o > Fallback 2: Claude Haiku (degraded)
```

On rate limit (429), timeout, or 5xx from the primary, try the next. Log which model served each request.

### Task-based routing

| Task | Model tier | Example cost |
|---|---|---|
| Classification / extraction / tagging | Fast cheap (Haiku, GPT-4o-mini) | $0.25/M tokens |
| Generation / creative / reasoning | Capable (Sonnet, GPT-4o) | $3/M tokens |
| Complex analysis / research | Premium (Opus, o1) | $15/M tokens |

Route by task type (from your app's feature flag), not by the user's input.

### Provider abstraction

- **Vercel AI SDK** — `@ai-sdk/anthropic`, `@ai-sdk/openai` share the same `streamText`/`generateText` interface. TypeScript-native.
- **LiteLLM** — unified OpenAI-compatible interface to 100+ providers. Python-based proxy with routing, retries, fallbacks, spend tracking.
- **Custom adapter** — define `sendMessage(messages, config) > stream` and implement per provider. Simplest for 2-3 providers.

### Health monitoring per model

Track: p50/p95/p99 latency, error rate, rate limit hit frequency, cost per 1K tokens.

Auto-switch: if Model A's error rate exceeds 5% over 5 minutes, route to Model B. Circuit breaker pattern per model.

### Cost optimization via smart routing

Route by query complexity: classify incoming query (simple/medium/complex) using heuristics or a cheap model, then route to the appropriate tier. Reports show 88% cost reduction with intelligent routing vs. sending everything to the frontier model.

---

## Prompt management

### Prompt registry data model

```
Prompt: id, name, description, created_by

PromptVersion: id, prompt_id, version_number, content, model,
  temperature, max_tokens, system_prompt, few_shot_examples (JSON),
  status (draft/active/archived), created_at, commit_message

PromptDeployment: id, prompt_version_id, environment (dev/staging/prod),
  traffic_percentage, deployed_at
```

### Version control

Every edit creates a new version. Never mutate in place. Store diffs. Rollback = change the active version for an environment.

### A/B testing prompts

1. Configure two versions at different traffic splits (90%/10%).
2. Hash `user_id` for consistent sticky assignment.
3. Log which version served each request.
4. Track per version: quality scores, latency, cost, user feedback.
5. Use feature flag systems for traffic management.
6. Statistical significance is harder with LLMs (high output variance) — need larger sample sizes.

**Shadow testing** (lower risk): send to both versions, show user only the control, log both for offline comparison.

### Prompt composition

Build from reusable blocks:

```
final_prompt = compose([
  persona_block,     // "You are a helpful support agent..."
  task_block,        // "Summarize the following conversation..."
  format_block,      // "Respond in JSON with fields: summary, action_items"
  examples_block,    // Few-shot examples
  context_block,     // RAG-retrieved documents
  user_message       // The actual input
])
```

Each block versioned independently. Changing the persona doesn't require re-testing the format.

### Template variables

Use `{{variable_name}}` syntax. Inject at runtime: `{{user_name}}`, `{{company_name}}`, `{{current_date}}`, `{{retrieved_context}}`. Validate all variables are filled before sending.

### Prompt observability

Log every execution with: prompt_name, version, rendered prompt (or hash), model, temperature, tokens, latency, cost, quality_score, user_id, feature_name.

**Tooling:** Langfuse (open-source, self-hostable), Helicone (proxy-based), LangSmith (LangChain ecosystem).

---

## RAG pipeline

### Document ingestion

```
Upload > Extract text (PDF, DOCX, HTML, Markdown)
  > Chunk (split into pieces)
  > Embed (generate vectors)
  > Store (vector DB)
  > Track status (processing/ready/failed)
```

### Chunking strategies

Chunking configuration has as much influence on retrieval quality as embedding model choice.

| Strategy | How | When |
|---|---|---|
| **Fixed-size** (recommended start) | 512-768 tokens, 50-100 token overlap | Most use cases. Simple, consistently good. |
| **Semantic** | Split on paragraph/heading boundaries | Structured documents. Higher cost (embeds every sentence to find boundaries). |
| **Hierarchical** | Document > section > paragraph, store at multiple levels | Legal, medical, long-form. Search at paragraph level, return section context. |

### Embedding models

- **OpenAI text-embedding-3-small** — 1536 dims, $0.02/M tokens. Best cost/quality for most.
- **OpenAI text-embedding-3-large** — 3072 dims, $0.13/M tokens. Higher quality, supports dimension reduction.
- **Cohere embed-v3** — competitive quality, multi-language, 1024 dims.
- **Open-source (nomic-embed, e5, bge)** — free, run locally. For cost-sensitive or data sovereignty.

### Vector storage

- **pgvector** — Postgres extension. Under 1M docs, sub-50ms latency. Keeps everything in Postgres. Start here.
- **Pinecone** — managed, serverless, billions of vectors. No infrastructure to manage.
- **Qdrant** — open-source, Rust-based, high performance. Self-hosted at scale.
- **Weaviate** — open-source, native hybrid search (vector + keyword).

**Decision:** start with pgvector if you use Postgres. Move to dedicated vector DB only at millions of documents.

### Retrieval pipeline

1. **Embed the query** — same model as documents.
2. **Similarity search** — cosine/dot product, top-K (5-20 results).
3. **Rerank** (recommended) — Cohere Rerank or cross-encoder model re-scores top-K. Dramatically improves precision. Top 20 > rerank to top 5.
4. **Hybrid search** (recommended) — combine vector + keyword/BM25. Catches exact matches semantic search misses (product IDs, names, code).

### Source attribution

In the prompt: "Cite sources using [Source: document_name, page X]."

In the UI:
- Numbered inline footnotes.
- Expandable preview showing the relevant chunk.
- "View source" link to the original document.
- Highlight the specific passage used.

### Knowledge base management UI

- Document list: name, status (processing/ready/failed), upload date, chunk count.
- Upload (drag-and-drop, multi-file).
- Re-process and delete per document.
- Search within KB (search chunks, not just names).
- Chunk preview: click a document to see its chunks.
- Stats: total documents, chunks, storage used.

### Incremental updates

When a document changes: diff against previous version, identify changed sections, delete old chunks for changed sections, re-chunk and re-embed only changes. Don't re-embed the entire KB.

---

## Evaluation infrastructure

### Why it's non-negotiable

A prompt change can silently degrade quality. Without automated eval, you discover regressions from user complaints days later.

### Evaluation types

| Type | Method | Signal quality |
|---|---|---|
| **Automated metrics** | BLEU, ROUGE (summarization), exact match (extraction), custom rubrics | Medium |
| **LLM-as-judge** | Strong model scores outputs on criteria (relevance, accuracy, tone) | Medium-high |
| **Human review** | Internal team detailed review, side-by-side comparison | Highest |
| **User feedback** | Thumbs up/down from end users | Low (noisy) but cheapest |
| **Regression testing** | Same test cases against every prompt version, compare scores | High for detecting changes |

### Eval dataset

Start with 50-100 curated `(input, expected_output)` pairs. Grow to 500+. Include adversarial examples. Version control alongside prompts.

### Eval pipeline

Prompt change committed > CI runs eval dataset > compare scores to baseline > block deployment if regression > generate report.

**Tooling:** Promptfoo (open-source CLI, CI/CD), Braintrust (managed), Langfuse evals.

### Eval UI

- Test case browser with search/filter.
- Score comparison across prompt versions (side-by-side).
- Regression alerts with drill-down to specific failing cases.
- Input, expected output, actual output (both versions), judge scores with reasoning.

---

## Usage metering and cost control

### Per-request tracking

Log every LLM call:

```
request_id, timestamp, user_id, org_id, feature_name,
prompt_name, prompt_version, model, provider,
input_tokens, output_tokens, latency_ms, cost_usd,
status (success/error/cancelled), cache_hit
```

### Cost calculation

```
cost = (input_tokens / 1M * input_price) + (output_tokens / 1M * output_price)
```

Maintain a pricing table per model. Input and output are priced differently.

### Budget enforcement

- **Soft limit (80%):** warn admin, show banner.
- **Hard limit (100%):** reject requests with "Usage limit reached."
- **Granularity:** per-user (daily/monthly), per-org (monthly), per-feature.

### Usage dashboard

- Cost over time (daily/weekly/monthly line chart with comparison).
- Cost by model (bar chart).
- Cost by feature (which product areas drive cost).
- Cost by user/team (identify heavy users or runaway automation).
- Projected monthly cost (extrapolate current rate).
- Top queries (most expensive individual requests).

### Anomaly detection

Alert when: daily spend > 2x trailing 7-day average, single user > 10x their average, single request > 100K tokens, error rate spike (may indicate retry loop burning tokens).

### Token-efficient patterns

| Pattern | Savings | How |
|---|---|---|
| **Provider prefix caching** | 50-90% | Anthropic: 90% cost reduction for stable system prompts. OpenAI: 50%. Free — just keep system prompt stable. |
| **Semantic caching** | ~73% in high-repetition | Cache responses by meaning similarity. Redis LangCache. 31% of queries exhibit semantic similarity. |
| **Right-sizing models** | 50-90% | Use cheapest model that meets quality per task. |
| **Combined** | 80%+ | Semantic cache > prefix cache > full inference. |

---

## Content moderation

### Input filtering (before model)

1. **PII detection** — regex for emails, phones, SSNs, cards + NER for names, addresses. Libraries: Presidio (Microsoft, open-source), LLM Guard.
2. **Harmful content** — OpenAI Moderation API (free), Anthropic built-in filtering, custom classifiers.
3. **Prompt injection** — detect "ignore previous instructions," base64-encoded instructions, markdown injection. Multi-agent defense pipelines achieve 100% mitigation in tested scenarios.
4. **Input length limits** — reject over max token count to prevent cost abuse.

### Output filtering (after model)

1. **PII leakage** — model may include PII from training data or context. Scan with same detectors.
2. **Harmful content** — same moderation check on output.
3. **Hallucinated URLs/emails** — detect and flag.
4. **Off-topic** — did the model respond about something outside the product's domain?

### Moderation logging

Log every decision: request_id, direction (input/output), checks run, results, action taken (passed/flagged/blocked). Provide a "Report false positive" button. Build a review queue for borderline cases (confidence 0.4-0.7).

### Prompt injection defense layers

1. System prompt hardening — separate instructions from user content with delimiters.
2. Input/output separation — never embed raw user input in the control portion.
3. Guardrail models — specialized classifiers (PromptGuard, OpenAI Guardrails).
4. Multi-agent defense — separate classifier evaluates input before main agent processes.
5. Output validation — check response is consistent with intended task, not injected instructions.

---

## Conversation persistence

### Data model

```
Thread: id, user_id, org_id, title (auto-generated), model_config (JSON),
        created_at, updated_at, archived_at, metadata (tags, folder_id)

Message: id, thread_id, parent_message_id (nullable — enables branching),
         role (user/assistant/system/tool), content, content_blocks (JSON),
         model_used, prompt_version, input_tokens, output_tokens, latency_ms,
         cost_usd, status (complete/partial/error/cancelled),
         feedback (thumbs_up/thumbs_down/null), feedback_text, created_at

Attachment: id, message_id, file_url, file_type, file_name, file_size
```

### Branching (regenerate/edit)

The conversation is a **tree, not a list.**

**Regenerate:** create a new Message with the same `parent_message_id` as the original response. They become siblings. Show "Response 1 of 3" with navigation arrows.

**Edit previous message:** create a new user Message with the same parent as the original. Generate a new response as its child. This forks the conversation.

**Rendering:** start from the selected leaf, walk up the tree to root, collect messages in order. User navigates between branches at fork points.

### Search, export, sharing

- **Search:** full-text on `message.content` using Postgres GIN indexes. Show matching messages with thread context.
- **Export:** active branch as Markdown, JSON, or PDF with metadata.
- **Sharing:** unique URL with read-only view. Options: expiration, password, whether to include system prompts.
- **Auto-titling:** after first response completes, async request to a fast model: "Generate a 5-word title for this conversation." Don't block the main response.

---

## Tool/function calling

### Execution flow

```
Send messages + tool definitions to LLM
  > LLM responds with tool_use block
  > Server validates: is this tool allowed? Are params valid?
  > Server executes the tool
  > Server returns tool_result to LLM
  > LLM generates final response with tool result
  > Repeat if LLM wants another tool (multi-step)
```

### Tool approval for sensitive actions

For tools that send email, modify data, or make purchases:
1. LLM emits tool call.
2. Server identifies tool as requiring approval.
3. Stream to user: "I'd like to send an email to X. [Allow] [Deny]"
4. Pause until user responds.
5. Allow: execute, return result. Deny: return "denied by user" to LLM.

### Parallel tool calls

Some models request multiple tools simultaneously. Execute in parallel (`Promise.all`), return all results in one `tool_result` message.

### Tool result rendering

Show in the conversation as collapsible blocks:

```
[Tool: search_documents]
  Query: "refund policy"
  Results: 3 documents found
  > View details
```

Distinct visual styling (different background, icon). Show tool name, arguments, status (running/complete/error), result summary.

### Tool management

Admin configures which tools are available per org/user/role. Enable/disable toggle with immediate effect. Per-conversation tools can be added/removed based on context.

---

## AI-specific UX patterns

### Chat interface

- **Message bubbles** — distinct for user (right, colored) vs assistant (left, neutral). Role indicator, timestamp, model badge.
- **Markdown rendering** — full Markdown with syntax-highlighted code blocks (copy button, language label), tables, lists, LaTeX math.
- **"Thinking" indicator** — animated dots while waiting for first token. Switch to streaming text when tokens arrive.
- **Code blocks** — syntax highlighting, copy button, language label. Tabbed for multi-file.

**React libraries:** shadcn/ui AI components (25+), assistant-ui (200K+ monthly downloads), prompt-kit.

### Prompt playground

- Side-by-side comparison of multiple models/prompts.
- Parameter sliders (temperature, max_tokens, top_p).
- System prompt editor with template variable highlighting.
- "Run" with streaming output.
- History of previous runs.
- Cost estimate before running.

### Model selector

Dropdown showing: model name, capability indicators (speed/quality/context icons), price, context window size, availability status dot.

### Feedback system

On every assistant response:
- Thumbs up/down (always visible).
- On thumbs down: "What was wrong?" with categories (inaccurate, unhelpful, off-topic, harmful).
- "Report issue" for moderation concerns.
- Log with message_id, prompt_version, model for eval pipeline.

### Regenerate and edit

- **Regenerate** — button on every assistant message. Creates branch. Option to regenerate with a different model.
- **Edit** — click to edit previous user message. Regenerates from that point. Creates branch.
- **Branch navigation** — "Version 1 of 3" with arrows at every fork.

### Conversation starters

Empty chat state:
- 3-4 suggested prompts relevant to the product.
- Recently used templates.
- Capability cards explaining what the assistant can do.

### Citation display

- Numbered inline footnotes linking to source documents.
- Expandable source preview.
- "View source" to open original document.
- Relevance score per citation.

---

## Tooling summary

| Concern | Recommended |
|---|---|
| **Streaming UI** | Vercel AI SDK (`useChat`), assistant-ui, shadcn/ui AI |
| **Provider abstraction** | Vercel AI SDK (TypeScript), LiteLLM (Python) |
| **Observability** | Langfuse (open-source), Helicone (proxy), LangSmith |
| **Evaluation** | Promptfoo (CLI/CI), Braintrust (managed), Langfuse evals |
| **Prompt management** | Langfuse prompt registry, Braintrust |
| **Vector storage** | pgvector (<1M docs), Pinecone (managed), Qdrant (self-hosted) |
| **Moderation** | OpenAI Moderation API (free), LLM Guard, Presidio (PII) |
| **Cost tracking** | Helicone, Langfuse, LiteLLM (built-in) |
| **Caching** | Anthropic prefix caching (90%), Redis LangCache (semantic) |

---

## Don'ts

- **Don't call `setState` on every token.** Buffer and flush on `requestAnimationFrame`, or use AI SDK's `useChat`.
- **Don't skip token counting before sending.** Exceeding context limits causes silent truncation or errors.
- **Don't hardcode model names.** Use a config/registry. Models deprecate, prices change, new ones launch.
- **Don't send everything to the frontier model.** Route by task complexity. 88% cost savings are real.
- **Don't mutate prompt versions in place.** Every change creates a new version. Enable rollback.
- **Don't skip evaluation.** A prompt change can silently degrade quality. Eval is CI/CD for AI.
- **Don't store conversations as flat lists.** Use a tree structure. Regenerate and edit create branches.
- **Don't let tool calls execute without validation.** Check permissions, validate params, require approval for sensitive tools.
- **Don't ignore provider caching.** Anthropic prefix caching is 90% savings for free. Just keep system prompts stable.
- **Don't show raw model errors to users.** "Overloaded" becomes "The assistant is busy. Your request will be retried."
- **Don't skip content moderation.** Filter both input and output. Log every decision.
- **Don't let cost run unbounded.** Set per-user and per-org budgets with hard limits. Alert on anomalies.
- **Don't re-embed the entire knowledge base** when one document changes. Diff, re-chunk, and re-embed only changes.
