# IR RAG Assistant (Flutter frontend)

A responsive Flutter client for the IR-RAG Python backend. It asks grounded
questions, shows the generated answer, lists the source chunks behind it, and
handles refusals and backend errors explicitly.

## Backend contract

The app expects an HTTP server exposing:

- `GET /health` → `{"status": "ok"}`
- `POST /ask` with `{"question": "..."}` →

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

## Run

```bash
flutter pub get
flutter run
```

> **Working from WSL:** this project lives at `~/Coding/flutter/ir_rag_project`
> inside WSL. Run Flutter commands in a WSL terminal from that Linux path. Flutter's
> Windows tool cannot use the `\\wsl.localhost\...` UNC path as its working
> directory — running `flutter pub get` from PowerShell with that UNC path fails
> with `UNC paths are not supported` / `Expected to find project root`. From
> Windows PowerShell you can use the bundled helper instead:
>
> ```powershell
> & '\\wsl.localhost\Ubuntu\home\zeke\Coding\flutter\ir_rag_project\scripts\flutter.bat' pub get
> ```
>
> The helper maps the UNC path to a temporary drive with `pushd` before calling
> Flutter. The same applies to `flutter run`, `flutter test` and `flutter build`.

By default the app talks to `http://127.0.0.1:8000`. You can:

- change it at runtime via the settings icon in the app bar (saved locally), or
- provide a build-time default:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Use `10.0.2.2` to reach the host machine from the Android emulator, or the host
LAN IP for a physical device. Web/desktop builds can use `127.0.0.1`.

### Connecting from a physical Android device

`127.0.0.1` on the phone means **the phone itself**, and `10.0.2.2` only works
in the emulator. That is why the badge stays offline even when the backend is
running. Pick one of these two paths:

**Option A — USB (no network or firewall changes, recommended while developing):**

```bash
adb reverse tcp:8000 tcp:8000
```

Keep the app URL at `http://127.0.0.1:8000` and restart the app. The phone's
localhost is tunnelled to your computer over USB. Re-run the command after
reconnecting the cable or rebooting.

**Option B — Wi-Fi:**

1. Put the phone and computer on the same Wi-Fi network.
2. Find the computer's LAN IP (for example `192.168.0.178`). In WSL, `ip addr`;
   on Windows, `ipconfig`. With WSL2 the address you need is usually the Windows
   Wi-Fi adapter address. Mirrored networking (`networkingMode=mirrored`) shares it.
3. Start the backend on all interfaces:
   `python -m uvicorn src.api.server:app --host 0.0.0.0 --port 8000`.
4. Allow inbound TCP port 8000 through Windows Firewall **as Administrator**:

   ```powershell
   New-NetFirewallRule -DisplayName "IR-RAG backend 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Private,Public
   ```

5. In the app settings, enter `http://192.168.0.178:8000` (your IP) and tap
   **Save & test**.

The Android manifest includes `INTERNET` permission and allows cleartext HTTP,
so both debug and release builds can reach a plain-HTTP backend.

## Features

- Responsive layout: two panes on wide screens, stacked on phones.
- Question input with example and recent-question shortcuts.
- Loading, answer, refusal and error/offline states.
- Source cards with title, section, relevance score, chunk id and a link opener.
- Backend health badge with manual refresh.
- Light/dark theme following the system setting, with a manual toggle.
- Configurable, persisted backend base URL.

## Tests

```bash
flutter test
flutter analyze
```

Tests cover URL validation, payload parsing/refusal detection, and the HTTP
client's request/response/error mapping using a mock client.

## Backend status

As of the latest review, the Python repository at `~/Coding/python/IR-RAG_Project`
has the IR pipeline but **does not yet implement the HTTP API**: `src/api/` is
missing, `POST /ask` / `GET /health` have no server, and `src/rag/answer.py`,
`src/rag/prompt_builder.py` and `app.py ask` are still stubs. Until those exist,
this app will show "Backend offline" / "Endpoint not found" states rather than
fake data.
