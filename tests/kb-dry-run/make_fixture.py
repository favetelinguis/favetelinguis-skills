#!/usr/bin/env python3
"""Build a synthetic Home Repo for a dry run of the kb-* skills.

Usage: make_fixture.py TARGET_DIR

Writes TARGET_DIR/AGENTS.md (a Home Repo with no knowledge base yet) and
TARGET_DIR/handover-export/*.vtt: twelve fake platform handover recordings,
mixing relevant sessions, noise, a conflict between an old and a new claim,
and one mostly-noise session hiding a relevant service name (the snowball
case). Half use rolling YouTube-style captions, half voice-tagged meeting
captions; some filenames carry a date and some do not.
"""
import os
import sys
from pathlib import Path

AGENTS = """# Home

My Home Repo for work at Acme. Sessions start here.

## What I am doing

I am a backend engineer taking over the Acme payments platform from the
platform team, who leave at the end of the quarter. From next quarter I run
on-call for it alone and own its deploys. I need to know the services, how
they ship, how to operate them when they break, and the tools the team uses.
HR, office, and company-wide topics are not my concern.

## Other Repos

Payments API (Go service): ~/repos/acme/payments-api.
Billing worker (Python jobs): ~/repos/acme/billing-worker.
"""

# (filename, style, [(speaker, line)])
SESSIONS = [
    ("2024-01-15-billing-deploys", "rolling", [
        ("Anna", "today we walk through how the billing worker deploys"),
        ("Anna", "every merge to main builds an image in GitHub Actions"),
        ("Anna", "Argo CD syncs the staging namespace automatically"),
        ("Anna", "production needs a manual sync in Argo CD after the smoke tests pass"),
        ("Anna", "to roll back you sync the previous revision in Argo CD"),
        ("Anna", "never roll back with kubectl directly because Argo will revert it"),
        ("Anna", "the smoke tests live in the billing worker repo under smoke"),
    ]),
    ("2024-01-22-oncall-and-alerts", "voices", [
        ("Erik Lund", "On-call is a weekly rota in PagerDuty, handover is Monday at ten."),
        ("Erik Lund", "The loudest alert is PaymentsLatencyHigh, it fires when p99 goes above 800 milliseconds."),
        ("Anna Berg", "When it fires, first check the database connection pool dashboard in Grafana."),
        ("Erik Lund", "Nine times out of ten the pool is exhausted, restart the payments API pods one at a time."),
        ("Anna Berg", "If restarting does not help within fifteen minutes, page the database on-call."),
        ("Erik Lund", "The runbooks are linked from every alert annotation."),
    ]),
    ("2024-02-01-database-backups", "rolling", [
        ("Anna", "the payments database is Postgres on RDS"),
        ("Anna", "snapshots run nightly at 02:00 UTC"),
        ("Anna", "we keep seven days of snapshots"),
        ("Anna", "restoring means creating a new instance from a snapshot and switching the DNS record"),
        ("Anna", "test a restore every quarter, the last one took forty minutes"),
    ]),
    ("2024-03-20-backups-update", "voices", [
        ("Anna Berg", "Quick update on backups, we moved the snapshot window to 03:00 UTC."),
        ("Anna Berg", "Retention is now fourteen days because of the audit requirement."),
        ("Erik Lund", "Point in time recovery is enabled too, so you can restore to any minute."),
    ]),
    ("office-move-planning", "voices", [
        ("Lena Holm", "The office move is planned for April, we get the third floor."),
        ("Lena Holm", "Please pack your desks by the Friday before."),
        ("Omar Said", "Will the bike room still be in the basement?"),
        ("Lena Holm", "Yes, and the new coffee machine arrives in May."),
    ]),
    ("2024-02-10-benefits-overview", "rolling", [
        ("Lena", "welcome everyone to the benefits overview"),
        ("Lena", "the pension contribution changes in January"),
        ("Lena", "the wellness allowance can be used for gym memberships"),
        ("Lena", "questions go to the people team mailbox"),
    ]),
    ("2024-02-15-tooling-tour", "rolling", [
        ("Erik", "let me show the tools we use every day"),
        ("Erik", "Grafana for dashboards and Loki for logs"),
        ("Erik", "to find a failed payment search Loki for the payment id with the label app payments api"),
        ("Erik", "Terraform in the infra repo manages RDS and the queues"),
        ("Erik", "never apply Terraform from your laptop, it runs in the Atlantis pull request flow"),
    ]),
    ("2024-02-28-friday-retro", "voices", [
        ("Omar Said", "Great week everyone, thanks for the cake on Tuesday."),
        ("Lena Holm", "The quiz night is moved to next Thursday."),
        ("Erik Lund", "One thing from me, ledgerd fell behind again on Wednesday."),
        ("Erik Lund", "ledgerd is the service that writes settled payments to the general ledger, when its queue backs up reconciliation fails the next morning."),
        ("Erik Lund", "The fix is to scale ledgerd to four replicas and drain the dead letter queue with the replay script."),
        ("Omar Said", "Okay, and who brings snacks next week?"),
    ]),
    ("2024-03-05-incident-walkthrough", "voices", [
        ("Anna Berg", "This is the walkthrough of the March third outage."),
        ("Anna Berg", "A certificate on the payments API ingress expired at night."),
        ("Erik Lund", "Cert manager failed to renew because the DNS challenge credentials had rotated."),
        ("Anna Berg", "Action item, the cert expiry alert now fires fourteen days ahead."),
        ("Erik Lund", "If it happens again, rerun the certificate request with cmctl renew."),
    ]),
    ("roadmap-all-hands", "rolling", [
        ("Omar", "this year the company focuses on three markets"),
        ("Omar", "sales grew twelve percent last quarter"),
        ("Omar", "the mobile app gets a redesign in the autumn"),
    ]),
    ("2024-03-12-payments-architecture", "rolling", [
        ("Anna", "the payments API takes requests and writes them to the payments queue"),
        ("Anna", "the billing worker consumes that queue and creates invoices"),
        ("Anna", "settled payments go to ledgerd which writes the general ledger"),
        ("Anna", "the payments API owns the Postgres database, nothing else writes to it"),
    ]),
    ("2024-03-25-team-lunch-ideas", "voices", [
        ("Lena Holm", "For the team lunch we could try the new ramen place."),
        ("Omar Said", "Or the pizza place again, it is close."),
        ("Lena Holm", "Let us vote in the chat."),
    ]),
]


def clock(seconds):
    return f"{seconds // 3600:02d}:{seconds % 3600 // 60:02d}:{seconds % 60:02d}.000"


def rolling(lines):
    """YouTube-style: each cue shows the previous line plus the new one with word timings."""
    out = ["WEBVTT", "Kind: captions", "Language: en", ""]
    previous = None
    t = 0
    for _, line in lines:
        words = line.split()
        timed = words[0] + "".join(
            f"<{clock(t + i)}><c> {w}</c>" for i, w in enumerate(words[1:], 1)
        )
        end = t + 8
        out += [f"{clock(t)} --> {clock(end)} align:start position:0%", previous or " ", timed, ""]
        out += [f"{clock(end)} --> {clock(end)[:-3]}010 align:start position:0%", line, " ", ""]
        previous = line
        t = end + 12
    return "\n".join(out)


def voices(lines):
    out = ["WEBVTT", ""]
    t = 0
    for n, (speaker, line) in enumerate(lines, 1):
        out += [str(n), f"{clock(t)} --> {clock(t + 9)}", f"<v {speaker}>{line}</v>", ""]
        t += 25
    return "\n".join(out)


def main():
    target = Path(sys.argv[1])
    export = target / "handover-export"
    export.mkdir(parents=True, exist_ok=True)
    (target / "AGENTS.md").write_text(AGENTS)
    for name, style, lines in SESSIONS:
        path = export / f"{name}.vtt"
        path.write_text(rolling(lines) if style == "rolling" else voices(lines))
        os.utime(path, (1714000000, 1714000000))  # 2024-04-25: an export date, not a recording date
    print(f"wrote {len(SESSIONS)} transcripts to {export}")


if __name__ == "__main__":
    main()
