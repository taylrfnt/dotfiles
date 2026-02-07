# Traversal Strategy

Two-pass approach: a fast coarse inventory followed by targeted deepening from seed nodes.

## Pass 1: Coarse Inventory

Fast, low-context pass over the entire repository. Goal: build the file-level graph and identify seeds for pass 2.

### Steps

1. **Enumerate files** respecting `.gitignore` (use `git ls-files` or equivalent)
2. **Detect language** by file extension, falling back to shebang line (`#!/usr/bin/env python3`, etc.)
3. **Identify entry points** heuristically:
   - Build files: `Makefile`, `pom.xml`, `build.gradle`, `package.json`, `go.mod`, `Cargo.toml`, `flake.nix`, `CMakeLists.txt`, `pyproject.toml`, `setup.py`
   - Main files: `main.*`, `cmd/`, `server.*`, `app.*`, `index.*`, `routes.*`
   - CI/deploy: `.github/workflows/`, `Dockerfile`, `docker-compose.yml`
4. **Extract imports/dependencies** with lightweight regex per language family (see import pattern table below)
5. **Emit nodes and edges**: file nodes + `imports` and `contains` edges
6. **Compute file content hash** (SHA-256) for incremental tracking in `files.jsonl`

### Output

- `files.jsonl` populated with all tracked files
- `nodes.jsonl` with file-level nodes
- `edges.jsonl` with `imports` and `contains` edges
- Candidate seed set for pass 2

## Pass 2: Targeted Deepening

Bounded BFS from seed nodes. Goal: extract symbol-level detail where it matters most.

### Seed Selection

Seeds are chosen from pass 1 results, in priority order:

1. Entry points (build files, main files, route definitions)
2. Files with high fan-in or fan-out (many importers or many imports)
3. "Interesting" directories: `src/`, `services/`, `internal/`, `pkg/`, `api/`, `lib/`, `core/`
4. Large files (high LOC relative to repo median)

### Iterative Deepening BFS

| Hop | Scope |
|---|---|
| 0 | Seed files |
| 1 | Direct imports + same-module/same-directory files |
| 2 | Top symbols referenced by hop-1 entities |
| 3+ | Continue if budget allows |

Stop when any budget limit is reached (see budget controls below).

### Per Visited File

1. **Extract symbols**: functions, classes, types, methods, constants
2. **Emit nodes**: one node per extracted symbol
3. **Add edges**:
   - `defines` (file → symbol)
   - `calls` (function → function, best-effort via reference matching)
   - `exposes` (module → endpoint)
   - `reads`/`writes` (function → datastore, when detectable)
   - `emits`/`consumes` (function → event, when detectable)
   - `implements`/`inherits` (class → interface/parent)
4. **Tag patterns**: apply anti-pattern heuristics (god_object, hidden_io, etc.)

## Budget Controls

| Flag | Description | Default |
|---|---|---|
| `--max-files` | Maximum files to deep-analyze in pass 2 | 500 |
| `--max-depth` | Maximum BFS hops | 3 |
| `--max-loc` | Maximum total lines of code to analyze | 100000 |
| `--timeout` | Wall-clock time limit for pass 2 | 5m |

### File Prioritization

When budget is limited, files are ranked:

1. Entry points
2. High fan-in/out (top 10% by edge count)
3. Large files (top 10% by LOC)
4. Remaining files (alphabetical)

Files already analyzed are skipped on incremental runs (matched by content hash).

## Import Pattern Heuristics

| Language Family | Patterns | Example |
|---|---|---|
| Python | `import X`, `from X import Y` | `from auth.utils import hash_password` |
| JavaScript/TypeScript | `import ... from '...'`, `require('...')` | `import { login } from './auth'` |
| Go | `import "path"`, `import (...)` | `import "github.com/org/pkg/auth"` |
| Java | `import pkg.Class` | `import com.example.auth.LoginService` |
| Rust | `use crate::...`, `mod name` | `use crate::auth::login` |
| C/C++ | `#include <...>`, `#include "..."` | `#include "auth.h"` |
| Ruby | `require '...'`, `require_relative '...'` | `require_relative 'auth/login'` |
| Nix | `import ./path`, flake `inputs` | `import ./modules/auth.nix` |
| Elixir | `import Module`, `alias Module` | `alias MyApp.Auth.Login` |
| PHP | `use Namespace\Class`, `require`/`include` | `use App\Auth\LoginService` |

Regex patterns are intentionally simple — they catch 80-90% of imports. Edge confidence is set to 0.7 for regex-extracted imports.

## Symbol Extraction

### Preferred: universal-ctags

When `universal-ctags` is available on the system, use it for symbol extraction:

- Covers 100+ languages with consistent output
- Produces kind-tagged symbols (function, class, method, variable, etc.)
- Confidence: **0.9**

Invocation: `ctags --output-format=json --fields=+lKS -R <path>`

### Fallback: Regex Heuristics

When ctags is unavailable, use per-language regex patterns for common definitions:

| Language | Function | Class/Struct | Type/Interface |
|---|---|---|---|
| Python | `^\s*def \w+` | `^\s*class \w+` | — |
| JavaScript/TypeScript | `function \w+`, `const \w+ = .*=>`, `^\s*(export\s+)?(async\s+)?function` | `class \w+` | `(interface\|type) \w+` |
| Go | `^func (\(\w+ \*?\w+\) )?\w+` | `^type \w+ struct` | `^type \w+ interface` |
| Java | `(public\|private\|protected).*\w+\s*\(` | `class \w+` | `interface \w+` |
| Rust | `^(\s*pub\s+)?fn \w+` | `^(\s*pub\s+)?struct \w+` | `^(\s*pub\s+)?trait \w+` |
| C/C++ | `^\w[\w\s\*]+\w+\s*\(` | `^(class\|struct) \w+` | `^typedef` |
| Ruby | `^\s*def \w+` | `^\s*class \w+` | `^\s*module \w+` |
| Nix | `\w+\s*=\s*(.*:)?` (let/rec bindings) | — | — |

Confidence: **0.7** for regex-extracted symbols.

### Confidence by Method

| Method | Confidence | Notes |
|---|---|---|
| universal-ctags | 0.9 | Best coverage and accuracy |
| Tree-sitter (if integrated) | 0.95 | AST-level accuracy |
| Regex heuristics | 0.7 | Good enough for most cases |
| Filename inference | 0.5 | Used for entry point detection only |
