## Public repository

This repository is public. Never reveal internal architecture in code, comments,
docs, commits, issues or pull requests. That includes names of private
repositories, internal services or source files, infrastructure layout,
databases, cloud accounts, hostnames and secrets. Describe behavior only in terms
of the public API this script calls and what already exists in this repository.

## Writing style (code, comments, docs, commits, PRs)

Write like an experienced maintainer of this repo, not like an assistant.
Match the existing style of the surrounding code and docs before anything else.

### Comments
- Only comment on *why*, never on *what* the code obviously does.
- No comments that narrate changes ("// Updated to use new API", "// Fixed bug").
- No docstrings on trivial functions. Keep existing docstring conventions.

### Docs & README
- Plain, factual sentences. No marketing tone.
- Don't add sections nobody asked for (Overview, Features, Conclusion, Contributing).
- Avoid filler words: comprehensive, robust, seamless, leverage, powerful,
  streamline, enhance, ensure, utilize, delve, cutting-edge, best-in-class.
- No bold-prefixed bullet lists ("**Fast:** ..."). Use prose or plain lists.
- Don't end with a summary of what was just said.
- Use em dashes sparingly.

### Commits
Use Conventional Commits: `<type>(<optional scope>): <subject>`

Allowed types, nothing else:
- `feat`: new user-facing functionality
- `fix`: bug fix
- `refactor`: code change with no behavior change
- `docs`: documentation only
- `test`: adding or fixing tests
- `chore`: build, deps, CI, tooling, everything else

Rules:
- Do not invent other types (no `perf`, `style`, `build`, `ci`, `improvement`, etc.).
  If unsure, use `chore`.
- Scope is optional; if used, it must be an existing top-level module or directory name.
  Leave it out for the main code directory (`src` in this repo), so `fix: ...` rather
  than `fix(src): ...`. Use a scope only for other areas, such as `tests`.
- Subject: imperative, lowercase, no trailing period, max ~60 chars.
- Breaking changes: add `!` after the type/scope (`feat(api)!: ...`) and explain in the body.
- Body only if the *why* isn't obvious from the subject.
