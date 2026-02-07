---
name: code-archaeology
description: "Use when analyzing large, legacy, or undocumented codebases to build a navigable knowledge graph for context retrieval."
---

# Code Archaeology

Analyze large, legacy, or undocumented codebases and produce a persistent knowledge graph. The graph enables fast, focused context retrieval in future sessions — any AI agent (Amp, Copilot, etc.) can query it to understand unfamiliar code without re-reading everything.

## Workflow

1. **Index** the codebase → produces a knowledge graph under `<repo>/archaeology/kg/`
2. **Query** the graph → returns focused markdown context bundles
3. **Use** context bundles in coding sessions for navigation, refactoring, or onboarding

## Indexing

Run `scripts/index.py` to build or update the knowledge graph.

```sh
python scripts/index.py <repo-root> [options]
```

| Option | Default | Description |
|---|---|---|
| `--output-dir` | `<repo>/archaeology/kg/` | Where to write graph files |
| `--full` | off | Force full re-index (ignore hashes) |
| `--since-git <ref>` | — | Only index files changed since `<ref>` (commit, tag, branch) |

**What it produces:**

- `nodes.jsonl` — all discovered symbols and structural elements
- `edges.jsonl` — relationships between nodes
- `files.jsonl` — file metadata and content hashes
- `indexes/` — lookup indexes (by symbol, path, tag)
- `summaries/` — per-module and per-package prose summaries

**Incremental behavior:** On subsequent runs, only files whose content hash has changed are re-processed. Use `--full` to force a complete rebuild.

## Querying

Run `scripts/query_graph.py` to retrieve context bundles from the graph.

```sh
python scripts/query_graph.py <kg-dir> [options]
```

| Option | Default | Description |
|---|---|---|
| `--symbol <name>` | — | Find nodes matching a symbol name |
| `--path <glob>` | — | Filter by file path |
| `--tags <tag,...>` | — | Filter by tags (e.g., `god_object,hidden_io`) |
| `--hops <n>` | 2 | Max edge traversal depth from matched nodes |
| `--max-nodes <n>` | 50 | Cap on returned nodes |
| `--format` | `markdown` | Output format (`markdown` or `json`) |

**Output:** A markdown context bundle containing the matched subgraph — nodes, edges, evidence pointers, and summaries — ready for pasting into an agent session.

## Graph Structure

The graph uses JSONL files with three entity types. See `reference/graph-schema.md` for the full schema.

### Node Types

| Type | Description |
|---|---|
| `file` | Source file |
| `module` | Language module / namespace |
| `package` | Package / crate / gem |
| `class` | Class or struct |
| `type` | Type alias, interface, protocol |
| `function` | Free function |
| `method` | Method on a class/type |
| `endpoint` | HTTP / RPC / GraphQL endpoint |
| `config` | Configuration key or block |
| `datastore` | Database, cache, queue |
| `event` | Event or message type |
| `job` | Background job / cron task |
| `test` | Test case or suite |
| `build_target` | Build rule or target |
| `external_service` | Third-party service dependency |
| `doc` | Documentation artifact |

### Edge Types

| Edge | Meaning |
|---|---|
| `contains` | Parent structurally contains child |
| `defines` | File/module defines a symbol |
| `imports` | Source imports target |
| `calls` | Source invokes target |
| `implements` | Source implements target interface |
| `inherits` | Source extends target |
| `reads` | Source reads from datastore/config |
| `writes` | Source writes to datastore/config |
| `emits` | Source emits event |
| `consumes` | Source consumes event |
| `exposes` | Module exposes an endpoint |
| `uses_config` | Source references config key |
| `depends_on` | Build/deploy dependency |
| `tests` | Test covers target |
| `documents` | Doc documents target |

### Evidence Pointers

Every node and edge carries an `evidence` array:

```json
{"file": "src/server.py", "start_line": 42, "end_line": 58}
```

## Output Structure

```
archaeology/kg/
├── nodes.jsonl
├── edges.jsonl
├── files.jsonl
├── indexes/
│   ├── by_symbol.json
│   ├── by_path.json
│   └── by_tag.json
└── summaries/
    ├── <module>.md
    └── overview.md
```

## Agent-Driven Fallback

When Python is unavailable, the agent builds the graph manually using read/search tools:

1. **Enumerate files** — list the repository tree, note languages and file counts
2. **Identify entry points** — find `main`, `index`, `app`, `server`, config files, build files
3. **Extract imports and symbols** — use search/grep to find import statements, class/function definitions, route registrations
4. **Build nodes and edges** — follow the same schema (node types, edge types, evidence pointers)
5. **Write JSONL files** — create `nodes.jsonl`, `edges.jsonl`, `files.jsonl` directly in `archaeology/kg/`
6. **Generate summaries** — write per-module markdown summaries in `summaries/`

The agent should prioritize breadth-first: get the coarse structure right before deep-diving into any single module.

## Traversal Strategy

Two-pass approach. See `reference/traversal-strategy.md` for details.

**Pass 1 — Coarse inventory:**
- Enumerate all files, detect languages, compute file hashes
- Find entry points (`main`, `index`, `app`, `server`, CLI definitions)
- Extract top-level imports and module boundaries

**Pass 2 — Targeted deepening:**
- BFS from seed nodes (entry points, high fan-in, high fan-out)
- Extract symbols: classes, functions, methods, types
- Build call edges, data-flow edges, config references
- Tag anti-patterns as discovered

## Anti-Pattern Detection

Detected patterns are stored as tags on nodes:

| Tag | Meaning |
|---|---|
| `god_object` | Class/module with excessive responsibilities |
| `feature_envy` | Entity that over-references another module's internals |
| `duplicate_logic` | Near-duplicate implementations across files |
| `hidden_io` | I/O buried inside business logic |
| `stringly_typed_config` | Config accessed via raw strings without validation |
| `shared_mutable_state` | Globals or shared state without synchronization |
| `temporal_coupling` | Operations that must happen in a specific undocumented order |

## Incremental Updates

- Every file's content hash is stored in `files.jsonl`
- On re-run, only files with changed hashes are re-processed; their old nodes/edges are replaced
- `--since-git <ref>` uses `git diff --name-only` to scope the update to changed files
- **Full re-index is needed when:** graph schema changes, indexer version changes, or the graph appears corrupted

## Design Principles

- **Navigational accuracy over precision** — it's more important to find the right area of code than to perfectly parse every symbol
- **Evidence-backed claims** — every node and edge points to source lines; no hallucinated structure
- **Minimal context bundles** — queries return the smallest subgraph that answers the question
- **Language-agnostic heuristics** — rely on universal patterns (imports, definitions, call sites) rather than language-specific ASTs
