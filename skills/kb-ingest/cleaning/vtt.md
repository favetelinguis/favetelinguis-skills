# Cleaning: transcripts (VTT)

Auto-generated VTT repeats every caption line two or three times and stamps every few seconds. `vtt_to_text.py` collapses it to paragraphs, each opening with `[hh:mm:ss]` (every 45 seconds, and on each change of speaker), written as `<stem>.txt` beside `<stem>.vtt`:

```
python3 <this skill's folder>/scripts/vtt_to_text.py kb/raw/transcripts
```

It skips files that already have a `.txt`; `--force` rebuilds them. The paragraph timestamp is the locator: `<stem>@00:13:20` points at the paragraph that opens there, which matches the video.

Check one output against its VTT before a bulk run: every caption line appears once, in order, with nothing lost. Repeated phrases or lost words mean this export's caption style differs from the ones the script handles (rolling, cumulative, voice-tagged); fix the script and its tests in `scripts/tests/` before cleaning the rest.
