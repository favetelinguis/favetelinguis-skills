"""Tests for the kb-ingest scripts. Run: python3 -m unittest discover skills/kb-ingest/scripts/tests"""
import io
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

import ledger  # noqa: E402
import rubric_hits  # noqa: E402
import vtt_to_text  # noqa: E402

FIXTURES = HERE / "fixtures"


def fixture(name):
    return (FIXTURES / name).read_text(encoding="utf-8")


class VttToText(unittest.TestCase):
    def test_rolling_captions_collapse_without_repeats(self):
        out = vtt_to_text.convert(fixture("youtube-rolling.vtt"))
        self.assertEqual(
            out,
            "[00:00:00] so today we walk through the billing service deploy pipeline and rollback\n\n"
            "[00:00:50] after lunch we look at alerts\n",
        )

    def test_speakers_open_paragraphs_and_entities_decode(self):
        out = vtt_to_text.convert(fixture("teams-voices.vtt"))
        self.assertEqual(
            out,
            "[00:00:01] Anna Berg: Welcome to the handover session. We start with on-call & paging.\n\n"
            "[00:00:07] Erik Lund: Can you share the runbook link?\n\n"
            "[00:01:05] Erik Lund: Thanks, that answers it.\n",
        )

    def test_cumulative_lines_keep_only_the_longest(self):
        out = vtt_to_text.convert(fixture("cumulative.vtt"))
        self.assertEqual(out, "[00:00:00] the queue drains every night\n")

    def test_cli_writes_txt_beside_vtt_and_keeps_existing(self):
        with tempfile.TemporaryDirectory() as tmp:
            vtt = Path(tmp) / "talk.vtt"
            shutil.copy(FIXTURES / "cumulative.vtt", vtt)
            vtt_to_text.main([tmp])
            txt = vtt.with_suffix(".txt")
            self.assertIn("the queue drains every night", txt.read_text())
            txt.write_text("edited")
            vtt_to_text.main([tmp])
            self.assertEqual(txt.read_text(), "edited")
            vtt_to_text.main([tmp, "--force"])
            self.assertIn("the queue drains", txt.read_text())


class Ledger(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.cwd = os.getcwd()
        os.chdir(self.tmp)
        raw = Path("kb/raw/transcripts")
        raw.mkdir(parents=True)
        for name in ["2024-03-12-billing.txt", "intro.txt", "20230101_oncall.txt"]:
            (raw / name).write_text("x")

    def tearDown(self):
        os.chdir(self.cwd)
        shutil.rmtree(self.tmp)

    def run_ledger(self, *args):
        out = io.StringIO()
        with redirect_stdout(out):
            ledger.main(list(args))
        return out.getvalue().split()

    def test_register_dates_from_filename_then_fallback(self):
        files = sorted(str(p) for p in Path("kb/raw/transcripts").iterdir())
        self.run_ledger("register", *files, "--fallback", "undated")
        rows = ledger.index(ledger.load(Path("kb/ledger.md")))
        self.assertEqual(rows["raw/transcripts/2024-03-12-billing.txt"]["recorded"], "2024-03-12")
        self.assertEqual(rows["raw/transcripts/20230101_oncall.txt"]["recorded"], "2023-01-01")
        self.assertEqual(rows["raw/transcripts/intro.txt"]["recorded"], "undated")
        self.run_ledger("register", *files)  # idempotent
        self.assertEqual(len(ledger.load(Path("kb/ledger.md"))), 3)

    def test_single_group_date_pattern(self):
        self.run_ledger("register", "kb/raw/transcripts/2024-03-12-billing.txt", "--date-pattern", r"^(\d{4}-\d{2}-\d{2})", "--fallback", "undated")
        self.assertEqual(ledger.load(Path("kb/ledger.md"))[0]["recorded"], "2024-03-12")

    def test_set_from_tsv_mark_list_and_counts(self):
        files = sorted(str(p) for p in Path("kb/raw/transcripts").iterdir())
        self.run_ledger("register", *files)
        Path("verdicts.tsv").write_text(
            "raw/transcripts/intro.txt\tskip\tadmin chatter | no signals\n"
            "raw/transcripts/2024-03-12-billing.txt\trelevant\tDeploy pipeline\n"
        )
        self.run_ledger("set", "--from", "verdicts.tsv")
        self.run_ledger("mark", "raw/transcripts/2024-03-12-billing.txt", "--extracted")
        self.assertEqual(self.run_ledger("list", "--verdict", "pending"), ["kb/raw/transcripts/20230101_oncall.txt"])
        self.run_ledger("set", "kb/raw/transcripts/20230101_oncall.txt", "--verdict", "maybe")  # list output feeds back in
        self.assertEqual(self.run_ledger("list", "--verdict", "relevant", "--not-extracted"), [])
        counts = self.run_ledger("counts")
        self.assertEqual(counts[:2], ["total", "3"])
        self.assertIn("extracted", counts)
        text = Path("kb/ledger.md").read_text()
        self.assertIn("admin chatter / no signals", text)  # pipes cannot break the table

    def test_unknown_source_is_an_error(self):
        with self.assertRaises(SystemExit):
            self.run_ledger("set", "raw/nope.txt", "--verdict", "skip")


class RubricHits(unittest.TestCase):
    RUBRIC = """# Rubric

## Signals

- **Deploy pipeline**: how releases ship. Terms: `deploy`, `rollback`. Example: x.
- **Alerting**: paging and alerts. Terms: `alerts`, `on-call`.

## Anti-signals

- **Lunch talk**: social chatter. Terms: `lunch`.

## Session kinds

- **Demo**: Terms: `demo` (not counted, not a signal section)
"""

    def test_parse_reads_signals_and_anti_signals_only(self):
        entries = rubric_hits.parse(self.RUBRIC)
        self.assertEqual(
            entries,
            [
                ("signal", "Deploy pipeline", ["deploy", "rollback"]),
                ("signal", "Alerting", ["alerts", "on-call"]),
                ("anti", "Lunch talk", ["lunch"]),
            ],
        )

    def test_counts_per_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            rubric = Path(tmp) / "rubric.md"
            rubric.write_text(self.RUBRIC)
            txt = Path(tmp) / "a.txt"
            txt.write_text(vtt_to_text.convert(fixture("youtube-rolling.vtt")) + " Deployment redeploy")
            out = io.StringIO()
            with redirect_stdout(out):
                rubric_hits.main([str(rubric), str(txt)])
            source, signal, anti, pairs = out.getvalue().strip().split("\t")
            self.assertEqual((signal, anti), ("3", "1"))  # deploy, rollback, alerts; word edges skip Deployment
            self.assertEqual(pairs, "Deploy pipeline:2,!Lunch talk:1,Alerting:1")

    def test_speaker_labels_are_not_hits(self):
        with tempfile.TemporaryDirectory() as tmp:
            a = Path(tmp) / "a.txt"
            a.write_text("[00:00:01] Erik Lund: hello\n\n[00:00:30] Anna Berg: ask Erik Lund about it\n")
            out = io.StringIO()
            with redirect_stdout(out):
                rubric_hits.main(["--terms", "Erik Lund", str(a)])
            self.assertEqual(out.getvalue().split("\t")[1], "1")

    def test_ad_hoc_terms_print_only_hits(self):
        with tempfile.TemporaryDirectory() as tmp:
            a, b = Path(tmp) / "a.txt", Path(tmp) / "b.txt"
            a.write_text("the ledgerd service")
            b.write_text("nothing here")
            out = io.StringIO()
            with redirect_stdout(out):
                rubric_hits.main(["--terms", "ledgerd", str(a), str(b)])
            self.assertEqual(out.getvalue().count("\n"), 1)
            self.assertTrue(out.getvalue().startswith(str(a)))


class Executable(unittest.TestCase):
    def test_scripts_run_from_the_shell(self):
        for script in ["vtt_to_text.py", "ledger.py", "rubric_hits.py"]:
            result = subprocess.run([sys.executable, str(HERE.parent / script), "--help"], capture_output=True)
            self.assertEqual(result.returncode, 0, script)


if __name__ == "__main__":
    unittest.main()
