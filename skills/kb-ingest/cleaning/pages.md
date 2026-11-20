# Cleaning: pages (Confluence, wiki, web)

Save each page as `kb/raw/pages/<slug>.md`: its body as markdown (convert HTML; keep headings, lists, tables, and code blocks; drop navigation, footers, and comment widgets), under a header naming where it came from:

```
---
url: <source URL>
title: <page title>
fetched: <YYYY-MM-DD>
updated: <the page's last-modified date, when it shows one>
---
```

The file is its own cleaned text. Register it with the date rule from `SCHEMA.md`, or pass its `updated` date in the slug (`2024-03-12-deploy-runbook.md`) so the ledger dates it. The locator is the heading: `<slug>@#Rollback`.
