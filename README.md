# kapa-skills

A collection of AI agent skills for working with [Kapa](https://www.kapa.ai).

## Skills

| Skill | Description |
|-------|-------------|
| [analyze-coverage-gaps](skills/analyze-coverage-gaps/) | Analyze a Kapa coverage gaps CSV export against your documentation to identify gaps and noise. |

## Installation

### Claude Code

Copy a skill into your project's `.claude/skills/` directory:

```bash
cp -r skills/analyze-coverage-gaps /path/to/your/project/.claude/skills/
```

Then invoke it with `/analyze-coverage-gaps <csv_path>`.

