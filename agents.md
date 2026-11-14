I'm building "Mocha": a Flutter app (Linux + Android) that plays generated brown
noise and my own audio files, with loop controls. Offline, no accounts.
Stack: Flutter stable, Riverpod, go_router, drift, flutter_soloud, audio_service.

Rules:
- Work on ONE chunk at a time. Output at most 3 files per reply (about 250 lines
  total). If the chunk needs more, stop after 3 files, list what is left, and wait
  for me to say "next".
- Output only new or changed files, complete, with the file path as a heading.
  Explanations: 3 lines max. Don't re-print files I already have.
- Never invent package APIs. Check the installed version's docs/README. If unsure,
  use the simplest documented call and tell me what to verify. Add packages with
  `flutter pub add` (no version pins).
- No provider may throw UnimplementedError. Wire everything you create.
- Don't claim anything works. End every reply with the exact commands I should run.
- If something isn't implemented, mark it TODO and tell me. Don't fake it (no fake
  waveforms, no placeholder EQ).
- When a chunk is finished, give me an updated PROJECT_NOTES.md (max 40 lines:
  file list, what works, what's next).
- Always give me commit messages after any changes made in the code base.
