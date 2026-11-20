"""Tests for wiki_check.py. Run: python3 -m unittest discover skills/kb/scripts/tests"""
import io
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import wiki_check  # noqa: E402

LEDGER = """# Ledger

| source | recorded | verdict | reason | triaged | extracted | reduced |
|---|---|---|---|---|---|---|
| raw/transcripts/a.txt | 2024-01-02 | relevant | x | 2024-05-01 | 2024-05-02 | 2024-05-03 |
| raw/transcripts/b.txt | 2024-01-03 | relevant | x | 2024-05-01 | | |
"""


def build(root, pages):
    for name, text in pages.items():
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)


class WikiCheck(unittest.TestCase):
    def check(self, pages):
        with tempfile.TemporaryDirectory() as tmp:
            build(Path(tmp), pages)
            out = io.StringIO()
            with redirect_stdout(out):
                status = wiki_check.main([tmp])
            return status, out.getvalue()

    def test_clean_wiki(self):
        status, out = self.check({
            "ledger.md": LEDGER.replace("| 2024-05-01 | | |", "| 2024-05-01 | 2024-05-02 | 2024-05-03 |"),
            "raw/transcripts/a.txt": "x",
            "extracts/transcripts/a.md": "---\nsource: raw/transcripts/a.txt\n---\n",
            "wiki/index.md": "# Index\n\n- [Services](services.md): hub.\n  - [Billing](services/billing.md): child.\n",
            "wiki/log.md": "# Log\n",
            "wiki/services.md": "# Services\n\nSee [Billing](services/billing.md).\n",
            "wiki/services/billing.md": "# Billing\n\n- On 2024-01-02, deploys nightly. ([a@00:01:00](../../raw/transcripts/a.txt))\n- Undated: owned by team X. ([a@00:02:00](../../raw/transcripts/a.txt))\n\nUp: [Services](../services.md)\n",
        })
        self.assertEqual((status, out.strip()), (0, "clean"))

    def test_reports_each_kind(self):
        status, out = self.check({
            "ledger.md": LEDGER.replace("2024-05-02 | 2024-05-03", "2024-05-02 |"),
            "raw/transcripts/a.txt": "x",
            "extracts/transcripts/z.md": "---\nsource: raw/transcripts/z.txt\n---\n",
            "wiki/index.md": "# Index\n\n- [Services](services.md): hub.\n",
            "wiki/services.md": "# Services\n\n[gone](missing.md)\n- On 2024-01-02, no citation here.\n- deploys nightly ([a](../raw/transcripts/a.txt))\n" + "word " * 30,
            "wiki/lonely.md": "# Lonely\n",
        })
        self.assertEqual(status, 1)
        for expected in [
            "## broken-link\n- wiki/services.md -> missing.md",
            "## orphan\n- lonely.md",
            "## not-in-index\n- lonely.md",
            "## uncited-claim\n- services.md:4",
            "## undated-claim\n- services.md:5",
            "1 relevant or maybe rows not extracted",
            "1 extracted rows not reduced",
            "extracts/transcripts/z.md has no ledger row",
        ]:
            self.assertIn(expected, out)

    def test_labelled_claims_and_dates_against_ledger(self):
        status, out = self.check({
            "ledger.md": LEDGER,
            "raw/transcripts/a.txt": "x",
            "raw/transcripts/b.txt": "x",
            "wiki/index.md": "- [P](p.md)\n",
            "wiki/p.md": "# P\n\n- **Build**: On 2024-01-02, ok. ([a](../raw/transcripts/a.txt))\n"
                         "1. On 2023-12-31, wrong date. ([a](../raw/transcripts/a.txt))\n"
                         "- On 2024-01-02, older of two. ([a](../raw/transcripts/a.txt), [b](../raw/transcripts/b.txt))\n"
                         "- a fact with no citation\n",
        })
        self.assertNotIn("undated-claim", out)
        self.assertIn("## date-mismatch\n- p.md:4 (2023-12-31; sources 2024-01-02)\n- p.md:5 (2024-01-02; sources 2024-01-02, 2024-01-03)", out)
        self.assertIn("## bare-bullet\n- p.md:6", out)

    def test_size_limits(self):
        with tempfile.TemporaryDirectory() as tmp:
            build(Path(tmp), {"wiki/index.md": "- [Big](big.md)\n" + "w " * 50, "wiki/big.md": "w " * 50})
            buf = io.StringIO()
            with redirect_stdout(buf):
                wiki_check.main([tmp, "--max-words", "10", "--index-words", "10"])
            self.assertIn("## oversized\n- big.md", buf.getvalue())
            self.assertIn("## index-size", buf.getvalue())


if __name__ == "__main__":
    unittest.main()
