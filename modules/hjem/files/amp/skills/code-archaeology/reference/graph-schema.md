# Knowledge Graph Schema

The knowledge graph is stored as JSONL files (one JSON object per line) plus JSON indexes and markdown summaries.

## Nodes (`nodes.jsonl`)

Each line is a JSON object with these fields:

| Field | Type | Description |
|---|---|---|
| `id` | string | Stable identifier: `<type>:<path>:<name>:<sig_hash>` |
| `type` | enum | Node type (see taxonomy below) |
| `name` | string | Human-readable name |
| `path` | string | File path (if applicable) |
| `lang` | string | Detected language (by extension + shebang) |
| `summary` | string | 1-3 sentence description |
| `tags` | string[] | Pattern/anti-pattern tags |
| `confidence` | float | 0-1, extraction confidence |
| `evidence` | object[] | Array of `{path, start_line, end_line, snippet_hash}` |

### Node Types

| Type | Description |
|---|---|
| `file` | Source file |
| `module` | Language module (Python module, Go package, etc.) |
| `package` | Distribution package or workspace member |
| `class` | Class or struct definition |
| `type` | Type alias, interface, trait, enum |
| `function` | Top-level function |
| `method` | Method on a class/struct/impl |
| `endpoint` | HTTP/gRPC/GraphQL endpoint |
| `config` | Configuration key or file |
| `datastore` | Database, cache, queue, or bucket |
| `event` | Event type emitted or consumed |
| `job` | Scheduled/background job |
| `test` | Test case or test suite |
| `build_target` | Build/CI target |
| `external_service` | Third-party service dependency |
| `doc` | Documentation file |

### Tags

Tags identify patterns and anti-patterns found during analysis:

- `god_object` — class/module with too many responsibilities
- `feature_envy` — entity that uses another entity's internals more than its own
- `duplicate_logic` — near-duplicate logic across multiple locations
- `hidden_io` — I/O buried in code that appears pure
- `stringly_typed_config` — configuration passed as unvalidated strings
- `shared_mutable_state` — mutable state accessed from multiple call sites
- `temporal_coupling` — operations that must happen in a specific order with no enforcement

### Example Node Lines

```jsonl
{"id":"file:src/auth.py","type":"file","name":"auth.py","path":"src/auth.py","lang":"python","summary":"Authentication module handling login, logout, and token refresh.","tags":[],"confidence":0.95,"evidence":[]}
{"id":"fn:src/auth.py:login:a3f2","type":"function","name":"login","path":"src/auth.py","lang":"python","summary":"Validates credentials and returns a JWT token pair.","tags":[],"confidence":0.85,"evidence":[{"path":"src/auth.py","start_line":12,"end_line":45,"snippet_hash":"b7c1e9"}]}
{"id":"class:src/models/user.py:User:d4e1","type":"class","name":"User","path":"src/models/user.py","lang":"python","summary":"ORM model for the users table. Stores profile and auth data.","tags":["god_object"],"confidence":0.8,"evidence":[{"path":"src/models/user.py","start_line":5,"end_line":120,"snippet_hash":"f1a3c8"}]}
{"id":"endpoint:src/routes/auth.ts:POST /api/login:ee12","type":"endpoint","name":"POST /api/login","path":"src/routes/auth.ts","lang":"typescript","summary":"Login endpoint accepting email/password, returns JWT.","tags":[],"confidence":0.9,"evidence":[{"path":"src/routes/auth.ts","start_line":22,"end_line":40,"snippet_hash":"c9d2a1"}]}
{"id":"datastore:infra/db.tf:postgres_main:ab01","type":"datastore","name":"postgres_main","path":"infra/db.tf","lang":"hcl","summary":"Primary PostgreSQL database for user and transaction data.","tags":[],"confidence":0.7,"evidence":[{"path":"infra/db.tf","start_line":1,"end_line":18,"snippet_hash":"e4f5b2"}]}
{"id":"config:config/settings.py:DATABASE_URL:cc44","type":"config","name":"DATABASE_URL","path":"config/settings.py","lang":"python","summary":"Connection string for the primary database.","tags":["stringly_typed_config"],"confidence":0.75,"evidence":[{"path":"config/settings.py","start_line":8,"end_line":8,"snippet_hash":"a1b2c3"}]}
```

## Edges (`edges.jsonl`)

Each line is a JSON object with these fields:

| Field | Type | Description |
|---|---|---|
| `from` | string | Source node ID |
| `to` | string | Target node ID |
| `type` | enum | Edge type (see taxonomy below) |
| `evidence` | object[] | Array of `{path, start_line, end_line, snippet_hash}` |
| `weight` | float? | Optional confidence or frequency proxy |

### Edge Type Taxonomy

| Type | Description |
|---|---|
| `contains` | Parent structurally contains child (file→function, module→class) |
| `defines` | Entity defines a symbol (file defines a function) |
| `imports` | File/module imports another file/module |
| `calls` | Function/method calls another function/method |
| `implements` | Class/type implements an interface/trait |
| `inherits` | Class inherits from another class |
| `reads` | Entity reads from a datastore |
| `writes` | Entity writes to a datastore |
| `emits` | Entity emits an event |
| `consumes` | Entity consumes/handles an event |
| `exposes` | Module/file exposes an endpoint |
| `uses_config` | Entity reads a configuration value |
| `depends_on` | Build/package dependency |
| `tests` | Test entity tests a target entity |
| `documents` | Doc entity documents a target entity |

### Example Edge Lines

```jsonl
{"from":"file:src/auth.py","to":"fn:src/auth.py:login:a3f2","type":"contains","evidence":[{"path":"src/auth.py","start_line":12,"end_line":45,"snippet_hash":"b7c1e9"}]}
{"from":"file:src/auth.py","to":"file:src/models/user.py","type":"imports","evidence":[{"path":"src/auth.py","start_line":2,"end_line":2,"snippet_hash":"d3e4f5"}],"weight":1.0}
{"from":"fn:src/auth.py:login:a3f2","to":"fn:src/auth.py:hash_password:c1d2","type":"calls","evidence":[{"path":"src/auth.py","start_line":30,"end_line":30,"snippet_hash":"a9b8c7"}],"weight":0.85}
{"from":"class:src/models/user.py:User:d4e1","to":"class:src/models/base.py:BaseModel:f5e6","type":"inherits","evidence":[{"path":"src/models/user.py","start_line":5,"end_line":5,"snippet_hash":"b2c3d4"}]}
{"from":"fn:src/auth.py:login:a3f2","to":"datastore:infra/db.tf:postgres_main:ab01","type":"reads","evidence":[{"path":"src/auth.py","start_line":25,"end_line":28,"snippet_hash":"c4d5e6"}],"weight":0.7}
{"from":"endpoint:src/routes/auth.ts:POST /api/login:ee12","to":"fn:src/auth.py:login:a3f2","type":"calls","evidence":[{"path":"src/routes/auth.ts","start_line":35,"end_line":35,"snippet_hash":"d5e6f7"}]}
{"from":"fn:src/workers/notifier.py:send_welcome:bb33","to":"event:src/events.py:user_created:aa22","type":"consumes","evidence":[{"path":"src/workers/notifier.py","start_line":10,"end_line":15,"snippet_hash":"e6f7a8"}]}
{"from":"test:tests/test_auth.py:test_login:ff99","to":"fn:src/auth.py:login:a3f2","type":"tests","evidence":[{"path":"tests/test_auth.py","start_line":8,"end_line":22,"snippet_hash":"f7a8b9"}]}
```

## Files Index (`files.jsonl`)

Tracks indexed files for incremental updates. Each line:

| Field | Type | Description |
|---|---|---|
| `path` | string | Relative file path |
| `hash` | string | SHA-256 content hash |
| `lang` | string | Detected language |
| `loc` | int | Lines of code |
| `last_indexed` | string | ISO 8601 timestamp |

### Example Lines

```jsonl
{"path":"src/auth.py","hash":"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","lang":"python","loc":187,"last_indexed":"2025-12-01T14:30:00Z"}
{"path":"src/routes/auth.ts","hash":"a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2","lang":"typescript","loc":95,"last_indexed":"2025-12-01T14:30:02Z"}
```

## Indexes (`indexes/`)

Pre-built lookup tables stored as JSON files.

### `symbol_to_node.json`

Maps symbol names to arrays of node IDs (handles name collisions across files):

```json
{
  "login": ["fn:src/auth.py:login:a3f2", "fn:src/legacy/auth.py:login:b4c3"],
  "User": ["class:src/models/user.py:User:d4e1"],
  "POST /api/login": ["endpoint:src/routes/auth.ts:POST /api/login:ee12"]
}
```

### `path_to_file.json`

Maps file paths to file node IDs:

```json
{
  "src/auth.py": "file:src/auth.py",
  "src/models/user.py": "file:src/models/user.py",
  "src/routes/auth.ts": "file:src/routes/auth.ts"
}
```

## Summaries (`summaries/`)

### Per-Entity Summaries (`<node_id>.md`)

Markdown files named by node ID (with `:` replaced by `_`) containing:

- Entity description
- Key relationships (callers, callees, dependencies)
- Identified patterns/anti-patterns with evidence links
- Change frequency indicators (if git history available)

### Knowledge Graph Overview (`KG.md`)

Top-level summary covering:

- **Entry points**: main files, CLI commands, HTTP endpoints, event handlers
- **Main modules**: core packages/modules and their responsibilities
- **Data stores**: databases, caches, queues, external storage
- **Hotspots**: files/entities with high fan-in, fan-out, or churn
- **Notable patterns/anti-patterns**: god objects, hidden I/O, temporal coupling, etc.
