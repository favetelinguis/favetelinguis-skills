# Cleaning: conversations (chat threads, agent sessions, email)

Save each conversation as `kb/raw/conversations/<YYYY-MM-DD>-<slug>.md`, one paragraph per message:

```
[<YYYY-MM-DD hh:mm>] <author>: <message text>
```

Keep code blocks and links; drop reactions, join notices, and signatures. The file is its own cleaned text, dated by the first message. The locator is the message time: `<slug>@14:05`.
