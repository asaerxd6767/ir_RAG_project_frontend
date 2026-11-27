# IR RAG Assistant (Flutter frontend)

A responsive Flutter client for the IR-RAG Python backend. It asks grounded
questions, manages the documents that can be questioned, shows an evaluation
dashboard, and handles refusals and backend errors explicitly.

## Run the app

```bash
cd ~/Coding/flutter/ir_rag_project
flutter pub get
flutter run
```

Start the backend first (see the backend `README.md`), then open the app. The
default backend URL is `http://127.0.0.1:8000`; change it at any time with the
settings icon in the app bar. The value is saved on the device.

> **Working from WSL:** this project lives at `~/Coding/flutter/ir_rag_project`
> inside WSL. Run Flutter commands in a WSL terminal from that Linux path. Flutter's
> Windows tool cannot use the `\\wsl.localhost\...` UNC path as its working
> directory. From Windows PowerShell use the bundled helper instead:
>
> ```powershell
> & '\\wsl.localhost\Ubuntu\home\zeke\Coding\flutter\ir_rag_project\scripts\flutter.bat' pub get
> ```
>
> The helper maps the UNC path to a temporary drive with `pushd` before calling
> Flutter. The same applies to `flutter run`, `flutter test` and `flutter build`.

You can also set a build-time default:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Tabs

### Ask

Ask a question and get a grounded answer with the source chunks used to create
it. Refusals, loading, offline and error states are shown explicitly. The local
GGUF model runs on the backend's CPU, so an answer can take 20–70 seconds; the
client waits up to 180 seconds and shows progress while generating.

### Corpus

- Paste a page URL and tap **Add to corpus**.
- An animated dialog follows the real backend job through queued → crawling →
  extraction → preprocessing → indexing. The dialog stays open for the whole
  job so the animation is visible, then confirms the document is ready and lets
  you close it.
- See every added document with its title, URL, chunk count, word count, size,
  status and date.
- Rebuild happens automatically; a document becomes question-ready when the job
  completes.
- Remove a document with **Remove**. The backend deletes its files and rebuilds
  the search index.

### Evaluation

A live dashboard with:

- corpus totals (documents, chunks, words),
- retrieval quality (hit@1, hit@k, MRR, nDCG@k, mean top score, latency),
- answer telemetry (questions, answered, refusals, grounded rate),
- corpus health (coverage, chunks per document, orphan chunks, index freshness),
- a per-document content distribution chart.

## Backend contract

The app expects an HTTP server exposing:

- `GET /health` → `{"status": "ok"}`
- `POST /ask` with `{"question": "..."}` → answer payload
- `GET /documents` → document library and counts
- `POST /ingest` with `{"url": "..."}` → ingestion job
- `GET /ingest/{job_id}` → job progress
- `DELETE /documents/{id}` → remove a document and rebuild the index
- `GET /evaluation` → dashboard metrics

Exact shapes are documented in the backend `docs/frontend_integration.md`.

`POST /ask` returns:

```json
{
  "answer": "...",
  "sources": [
    {
      "url": "https://example.com/page",
      "title": "Page title",
      "section": "Section heading",
      "chunk_id": "chunk-12",
      "score": 0.81
    }
  ]
}
```

When no relevant context is retrieved, the backend returns
`{"answer": "not found in the corpus", "sources": []}` and the app shows a
dedicated refusal state instead of inventing an answer.

`title`, `section`, `chunk_id` and `score` are optional in practice: the client
parses them defensively and falls back to sensible labels.

## Connecting from a physical Android device

`127.0.0.1` on the phone means **the phone itself**, and `10.0.2.2` only works in
the emulator. Pick one of these two paths:

**Option A — USB (recommended while developing):**

```bash
adb reverse tcp:8000 tcp:8000
```

Keep the app URL at `http://127.0.0.1:8000` and restart the app. Re-run the
command after reconnecting the cable or rebooting.

**Option B — Wi-Fi:**

1. Put the phone and computer on the same Wi-Fi network.
2. Find the computer's LAN IP (for example `192.168.0.178`).
3. Start the backend with `--host 0.0.0.0`.
4. Allow inbound TCP port 8000 through Windows Firewall **as Administrator**:

   ```powershell
   New-NetFirewallRule -DisplayName "IR-RAG backend 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Private,Public
   ```

5. In the app settings, enter `http://192.168.0.178:8000` and tap **Save & test**.

The Android manifest includes `INTERNET` permission and allows cleartext HTTP,
so both debug and release builds can reach a plain-HTTP backend.

## Features

- Three top-level tabs: Ask, Corpus and Evaluation.
- Responsive layout: two panes on wide screens, stacked on phones.
- Question input with example and recent-question shortcuts.
- Loading, answer, refusal and error/offline states.
- Source cards with title, section, relevance score, chunk id and a link opener.
- URL ingestion with live job progress and document deletion.
- Professional evaluation dashboard with useful retrieval/answer/health metrics.
- Backend health badge with manual refresh.
- Light/dark theme with a manual toggle.
- Configurable, persisted backend base URL shared by every tab.

## Tests

```bash
flutter analyze
flutter test
```

Tests cover URL validation, payload parsing/refusal detection, the new library
and evaluation endpoints, settings regressions, and the HTTP client's
request/response/error mapping using a mock client.

## Backend status

The Python repository at `~/Coding/python/IR-RAG_Project` implements the full
pipeline and the HTTP API used by this app. Backend changes are tracked in that
repository's `README.md` and `docs/frontend_integration.md`.
