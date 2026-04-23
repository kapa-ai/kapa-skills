# kapa-skills

A collection of AI agent skills for working with [Kapa](https://www.kapa.ai).

## Skills

| Skill | Description |
|-------|-------------|
| [analyze-coverage-gaps](skills/analyze-coverage-gaps/) | Walk through documentation gaps flagged by Kapa together with your coding agent. Review each gap, decide whether it needs a fix, and fill it — all inside your documentation repository. |
| [analyze-top-questions](skills/analyze-top-questions/) | Walk through the most frequently asked topics from Kapa together with your coding agent. Assess whether your documentation serves each topic well and improve it on the spot. |

## Installation

Copy a skill into your AI coding agent's skills directory:

| Agent | Skills directory |
|-------|-----------------|
| Claude Code | `.claude/skills/` |
| Cursor | `.cursor/skills/` |
| Codex | `.agents/skills/` |

For example, with Claude Code:

```bash
cp -r skills/analyze-coverage-gaps /path/to/your/project/.claude/skills/
```

Then invoke it with `/analyze-coverage-gaps <csv_path>`.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
