# Frontend Integration Agent (Flutter + Python RAG Backend)

You are an AI coding agent tasked with building/integrating the **Flutter frontend** with the IR-RAG Python backend. The graded IR pipeline is already in this repo; your job is to connect it cleanly without breaking it.

## Read first (priority)
1. `docs/frontend_integration.md` - API contract (`POST /ask`, `GET /health`).
2. `README.md`, `report.md` - project scope and demo expectations.
3. `src/utils/config.py` - paths and local LLM config.
4. `src/rag/` (`llm_client.py`, `prompt_builder.py`, `answer.py`) and `app.py`.
5. Course/vault task context if available: `D:\Asser_Vault\Education\University\Third_Year\First_Semester\Information_Retrieval_and_Web_Search\Exams\team_task\Asser_Task.md` and `Practical Exam - RAG System.md`.

## Current project state (important)
- **Implemented:** crawling, URL normalization, robots/politeness, extraction/noise removal, dedup, preprocessing (`preprocess` + `chunk`), TF-IDF indexing, cosine retrieval, local LLM adapter (`llama-cpp-python` + GGUF, no external API key), `app.py crawl` and `app.py build`.
- **Still missing / to wire:** `src/rag/prompt_builder.py`, `src/rag/answer.py`, `app.py ask`, and an HTTP API layer for Flutter (`POST /ask`, `GET /health`).
- **Local LLM:** default config points to `data/models/qwen2.5-1.5b-instruct-q4_k_m.gguf`. Model weights must NOT be committed.

## Backend contract to implement

### POST /ask
Request:
```json
{"question": "How does a polite crawler behave?"}
```
Response:
```json
{
  "answer": "...",
  "sources": [
    {"url": "...", "section": "...", "score": 0.81, "chunk_id": "...", "title": "..."}
  ]
}
```
Refusal:
```json
{"answer": "not found in the corpus", "sources": []}
```

### GET /health
```json
{"status": "ok"}
```

## Implementation requirements

1. **Keep IR pipeline visible and unchanged in spirit.** Do not replace retrieval with LLM-only answers.
2. **Grounded RAG only:** `preprocess/query -> retrieval.search -> prompt_builder.build_prompt -> llm_client.generate -> answer`.
3. **Refusal path:** if no relevant chunks / low confidence / empty index, return refusal JSON (no hallucinated sources).
4. **Citations:** include source URL + section/title/chunk id + score in `sources`; prompt must instruct model to use only context.
5. **Local/offline friendly:** no external API keys. Use local GGUF via existing `llm_client.py`. Handle missing model/index with clear error/health status.
6. **Scalable structure:** keep API layer thin. Put endpoint handlers in `src/api/` or similar, business logic in `src/rag/answer.py`, config in `src/utils/config.py`. Do not hardcode paths.
7. **Future sections ready:** the system will receive 2 more course sections. Design ingestion so new content can be added by rerunning crawl/build or by adding documents to `data/raw/` and rebuilding index. Avoid assumptions tied to current section count.
8. **Flutter app:** separate client (can live in `frontend/` or external folder; do not dump unnecessary generated files). Show question input, loading, answer, source chips/cards, refusal state, and backend health/error state.

## Suggested backend files
- `src/rag/prompt_builder.py` - build grounded prompt, context labels, refusal instruction.
- `src/rag/answer.py` - orchestrate retrieval + prompt + local LLM; return API payload.
- `app.py` - wire `ask` command.
- `src/api/server.py` (or FastAPI/Flask app) - expose `/ask`, `/health`; CORS for Flutter dev.
- `requirements.txt` - add minimal API dependency if needed (prefer FastAPI+uvicorn or Flask; be explicit).

## Prompt template guidance
System/instructions should enforce:
- Answer ONLY from provided context.
- If context does not contain answer, reply exactly: `not found in the corpus`.
- Cite source section/URL used.
- Do not use outside knowledge.
- Low temperature (already in config).

## Flutter UI checklist
- Input field + submit button.
- Loading indicator.
- Answer card.
- Source chips/list: title/section/URL/score.
- Refusal card when answer is "not found in the corpus".
- Error/offline state when backend unavailable or model/index missing.
- Configurable backend base URL.

## Validation checklist
- `python app.py crawl ...` works (or existing raw data used).
- `python app.py build` creates/updates index.
- `python app.py ask "..."` returns grounded answer or refusal.
- `GET /health` returns ok.
- `POST /ask` returns schema above.
- Flutter can display answer + sources + refusal.
- No API keys, no model weights, no generated raw pages committed.

## Non-goals / cautions
- Do not claim LLM is a course topic; it is integration.
- Do not bypass preprocessing/retrieval.
- Do not commit large GGUF files, `.venv`, or `data/raw` contents unless explicitly required.
- Keep changes compatible with future section files added to course/vault folder and future ingestion.
