#!/usr/bin/env python3
"""Collapse auto-generated WebVTT captions into timestamped paragraphs.

Usage:
  vtt_to_text.py FILE_OR_DIR... [--interval SECONDS] [--force]

Each FILE.vtt becomes FILE.txt beside it. A directory converts every .vtt
under it. Existing .txt files are kept unless --force is given.

Handles rolling captions (each cue repeating the previous line), cumulative
captions (a line growing word by word), inline word timings and <c> tags,
and <v Speaker> voice tags. A paragraph opens with [hh:mm:ss] every
--interval seconds (default 45) and on every change of speaker.
"""
import argparse
import html
import re
import sys
from pathlib import Path

TIMING = re.compile(
    r"^\s*((?:\d+:)?\d{1,2}:\d{2}[.,]\d{3})\s+-->\s+((?:\d+:)?\d{1,2}:\d{2}[.,]\d{3})"
)
VOICE = re.compile(r"<v(?:\.[^\s>]*)?\s+([^>]+)>")
TAG = re.compile(r"<[^>]*>")


def seconds(stamp):
    parts = stamp.replace(",", ".").split(":")
    total = 0.0
    for part in parts:
        total = total * 60 + float(part)
    return total


def clock(secs):
    secs = int(secs)
    return f"{secs // 3600:02d}:{secs % 3600 // 60:02d}:{secs % 60:02d}"


def cues(text):
    """Yield (start_seconds, speaker_or_None, [lines]) for each cue.

    A cue runs from its timing line to the next empty line. Lines holding
    only spaces stay inside the cue (auto-captions use them as padding).
    Everything outside a cue (header, NOTE, STYLE, cue ids) is skipped.
    """
    cue = None
    raw_cues = []
    for line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        match = TIMING.match(line)
        if match:
            cue = (seconds(match.group(1)), [])
            raw_cues.append(cue)
        elif line == "":
            cue = None
        elif cue is not None:
            cue[1].append(line)
    for start, lines in raw_cues:
        speaker = None
        body = []
        for raw in lines:
            voice = VOICE.search(raw)
            if voice:
                speaker = voice.group(1).strip()
            clean = html.unescape(TAG.sub("", raw))
            clean = re.sub(r"\s+", " ", clean).strip()
            if clean:
                body.append(clean)
        if body:
            yield start, speaker, body


def convert(text, interval=45.0):
    paragraphs = []  # [start, speaker, [lines]]
    last_line = None
    last_speaker = None
    for start, speaker, body in cues(text):
        if speaker is None:
            speaker = last_speaker
        for line in body:
            if line == last_line:
                continue
            current = paragraphs[-1] if paragraphs else None
            if (
                current
                and speaker == current[1]
                and last_line
                and line.startswith(last_line)
                and current[2][-1] == last_line
            ):
                current[2][-1] = line  # cumulative caption grew
            else:
                if (
                    current is None
                    or speaker != current[1]
                    or start - current[0] >= interval
                ):
                    paragraphs.append([start, speaker, []])
                paragraphs[-1][2].append(line)
            last_line = line
        last_speaker = speaker
    out = []
    for start, speaker, lines in paragraphs:
        prefix = f"[{clock(start)}] " + (f"{speaker}: " if speaker else "")
        out.append(prefix + " ".join(lines))
    return "\n\n".join(out) + "\n"


def targets(paths):
    for path in map(Path, paths):
        if path.is_dir():
            yield from sorted(path.rglob("*.vtt"))
        else:
            yield path


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--interval", type=float, default=45.0)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args(argv)
    converted = kept = 0
    for vtt in targets(args.paths):
        txt = vtt.with_suffix(".txt")
        if txt.exists() and not args.force:
            kept += 1
            continue
        text = vtt.read_text(encoding="utf-8-sig", errors="replace")
        header = f"# {vtt.stem}\n\nCleaned from {vtt.name} by vtt_to_text.py.\n\n"
        txt.write_text(header + convert(text, args.interval), encoding="utf-8")
        converted += 1
    print(f"converted {converted}, kept {kept}", file=sys.stderr)


if __name__ == "__main__":
    main()
