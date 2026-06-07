#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple


SKIP_DIRS = {
    ".git", "node_modules", "__pycache__", ".venv", "venv", "vendor",
    "dist", "build", "target", "archaeology", ".tox", ".mypy_cache",
    ".pytest_cache", ".eggs", ".bundle", ".cargo", "deps", "_build",
}

LANG_MAP = {
    ".py": "python", ".pyi": "python",
    ".js": "javascript", ".mjs": "javascript", ".cjs": "javascript",
    ".ts": "typescript", ".tsx": "typescript", ".jsx": "javascript",
    ".go": "go",
    ".java": "java", ".kt": "kotlin", ".kts": "kotlin",
    ".rs": "rust",
    ".c": "c", ".h": "c", ".cpp": "cpp", ".cc": "cpp", ".cxx": "cpp",
    ".hpp": "cpp", ".hh": "cpp",
    ".rb": "ruby", ".rake": "ruby",
    ".nix": "nix",
    ".ex": "elixir", ".exs": "elixir",
    ".php": "php",
    ".sh": "shell", ".bash": "shell", ".zsh": "shell", ".fish": "shell",
    ".lua": "lua",
    ".swift": "swift",
    ".scala": "scala",
    ".zig": "zig",
    ".tf": "hcl", ".hcl": "hcl",
    ".yml": "yaml", ".yaml": "yaml",
    ".toml": "toml",
    ".json": "json",
    ".md": "markdown", ".mdx": "markdown",
    ".sql": "sql",
    ".graphql": "graphql", ".gql": "graphql",
    ".proto": "protobuf",
    ".css": "css", ".scss": "scss", ".less": "less",
    ".html": "html", ".htm": "html",
    ".svelte": "svelte", ".vue": "vue",
}

BUILD_FILES = {
    "Makefile", "makefile", "GNUmakefile",
    "pom.xml", "build.gradle", "build.gradle.kts",
    "package.json", "go.mod", "Cargo.toml",
    "flake.nix", "default.nix", "shell.nix",
    "CMakeLists.txt", "pyproject.toml", "setup.py", "setup.cfg",
    "Gemfile", "Rakefile", "mix.exs", "composer.json",
    "Dockerfile", "docker-compose.yml", "docker-compose.yaml",
    "justfile", "Taskfile.yml",
}

ENTRY_STEMS = {"main", "index", "app", "server", "routes", "cli", "cmd"}

IMPORT_PATTERNS: Dict[str, List[re.Pattern]] = {
    "python": [
        re.compile(r"^import\s+(\S+)"),
        re.compile(r"^from\s+(\S+)\s+import"),
    ],
    "javascript": [
        re.compile(r"""import\s+.*?from\s+['"](\..*?)['"]"""),
        re.compile(r"""require\(\s*['"](\..*?)['"]\s*\)"""),
    ],
    "typescript": [
        re.compile(r"""import\s+.*?from\s+['"](\..*?)['"]"""),
        re.compile(r"""require\(\s*['"](\..*?)['"]\s*\)"""),
    ],
    "go": [
        re.compile(r'"([^"]+)"'),
    ],
    "java": [
        re.compile(r"^import\s+([\w.]+);"),
    ],
    "kotlin": [
        re.compile(r"^import\s+([\w.]+)"),
    ],
    "rust": [
        re.compile(r"^use\s+([\w:]+)"),
        re.compile(r"^mod\s+(\w+)"),
    ],
    "c": [
        re.compile(r'^#include\s*[<"](.+)[>"]'),
    ],
    "cpp": [
        re.compile(r'^#include\s*[<"](.+)[>"]'),
    ],
    "ruby": [
        re.compile(r"""^require\s+['"](.+)['"]"""),
        re.compile(r"""^require_relative\s+['"](.+)['"]"""),
    ],
    "nix": [
        re.compile(r"import\s+(\./[\w/.-]+)"),
    ],
    "elixir": [
        re.compile(r"^\s*(?:import|alias|use)\s+([\w.]+)"),
    ],
    "php": [
        re.compile(r"^use\s+([\w\\]+)"),
        re.compile(r"""(?:require|include)(?:_once)?\s+['"](.+)['"]"""),
    ],
}

SYMBOL_PATTERNS: Dict[str, List[Tuple[str, re.Pattern]]] = {
    "python": [
        ("function", re.compile(r"^\s*(?:async\s+)?def\s+(\w+)")),
        ("class", re.compile(r"^\s*class\s+(\w+)")),
    ],
    "javascript": [
        ("function", re.compile(r"^\s*(?:export\s+)?(?:async\s+)?function\s+(\w+)")),
        ("function", re.compile(r"^\s*(?:export\s+)?(?:const|let|var)\s+(\w+)\s*=")),
        ("class", re.compile(r"^\s*(?:export\s+)?class\s+(\w+)")),
    ],
    "typescript": [
        ("function", re.compile(r"^\s*(?:export\s+)?(?:async\s+)?function\s+(\w+)")),
        ("function", re.compile(r"^\s*(?:export\s+)?(?:const|let|var)\s+(\w+)\s*=")),
        ("class", re.compile(r"^\s*(?:export\s+)?class\s+(\w+)")),
        ("type", re.compile(r"^\s*(?:export\s+)?(?:interface|type)\s+(\w+)")),
    ],
    "go": [
        ("function", re.compile(r"^func\s+(?:\(.*?\)\s+)?(\w+)")),
        ("class", re.compile(r"^type\s+(\w+)\s+struct\b")),
        ("type", re.compile(r"^type\s+(\w+)\s+interface\b")),
    ],
    "java": [
        ("class", re.compile(r"^\s*(?:public|private|protected)?\s*(?:static\s+)?(?:abstract\s+)?class\s+(\w+)")),
        ("type", re.compile(r"^\s*(?:public|private|protected)?\s*interface\s+(\w+)")),
        ("function", re.compile(r"^\s*(?:public|private|protected)\s+(?:static\s+)?[\w<>\[\]]+\s+(\w+)\s*\(")),
    ],
    "kotlin": [
        ("class", re.compile(r"^\s*(?:data\s+|sealed\s+|abstract\s+)?class\s+(\w+)")),
        ("type", re.compile(r"^\s*interface\s+(\w+)")),
        ("function", re.compile(r"^\s*(?:fun|suspend\s+fun)\s+(\w+)")),
    ],
    "rust": [
        ("function", re.compile(r"^\s*(?:pub\s+)?(?:async\s+)?fn\s+(\w+)")),
        ("class", re.compile(r"^\s*(?:pub\s+)?struct\s+(\w+)")),
        ("type", re.compile(r"^\s*(?:pub\s+)?(?:trait|enum)\s+(\w+)")),
    ],
    "c": [
        ("class", re.compile(r"^\s*(?:typedef\s+)?struct\s+(\w+)")),
        ("type", re.compile(r"^\s*typedef\s+.*\s+(\w+)\s*;")),
    ],
    "cpp": [
        ("class", re.compile(r"^\s*class\s+(\w+)")),
        ("class", re.compile(r"^\s*(?:typedef\s+)?struct\s+(\w+)")),
        ("type", re.compile(r"^\s*typedef\s+.*\s+(\w+)\s*;")),
    ],
    "ruby": [
        ("function", re.compile(r"^\s*def\s+(\w+)")),
        ("class", re.compile(r"^\s*class\s+(\w+)")),
        ("module", re.compile(r"^\s*module\s+(\w+)")),
    ],
    "nix": [
        ("function", re.compile(r"^\s*(\w+)\s*=\s*(?:.*:)?\s*\{")),
    ],
    "elixir": [
        ("function", re.compile(r"^\s*def[p]?\s+(\w+)")),
        ("module", re.compile(r"^\s*defmodule\s+([\w.]+)")),
    ],
    "php": [
        ("function", re.compile(r"^\s*(?:public|private|protected)?\s*(?:static\s+)?function\s+(\w+)")),
        ("class", re.compile(r"^\s*class\s+(\w+)")),
        ("type", re.compile(r"^\s*interface\s+(\w+)")),
    ],
    "swift": [
        ("function", re.compile(r"^\s*(?:public\s+|private\s+|internal\s+)?func\s+(\w+)")),
        ("class", re.compile(r"^\s*(?:public\s+|private\s+|internal\s+)?(?:class|struct)\s+(\w+)")),
        ("type", re.compile(r"^\s*(?:public\s+|private\s+|internal\s+)?(?:protocol|enum)\s+(\w+)")),
    ],
    "scala": [
        ("class", re.compile(r"^\s*(?:case\s+)?class\s+(\w+)")),
        ("type", re.compile(r"^\s*trait\s+(\w+)")),
        ("function", re.compile(r"^\s*def\s+(\w+)")),
    ],
}

NODE_TYPE_PREFIXES = {
    "file": "file",
    "module": "mod",
    "package": "pkg",
    "class": "cls",
    "type": "type",
    "function": "fn",
    "method": "meth",
    "endpoint": "endpoint",
    "config": "config",
    "datastore": "ds",
    "event": "event",
    "job": "job",
    "test": "test",
    "build_target": "build",
    "external_service": "ext",
    "doc": "doc",
}


@dataclass
class NodeRecord:
    id: str
    type: str
    name: str
    path: str
    lang: str
    summary: str = ""
    tags: list = field(default_factory=list)
    confidence: float = 0.7
    evidence: list = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "type": self.type,
            "name": self.name,
            "path": self.path,
            "lang": self.lang,
            "summary": self.summary,
            "tags": self.tags,
            "confidence": self.confidence,
            "evidence": self.evidence,
        }


@dataclass
class EdgeRecord:
    source: str
    target: str
    type: str
    evidence: list = field(default_factory=list)
    weight: float = 0.7

    def to_dict(self) -> Dict[str, Any]:
        return {
            "source": self.source,
            "target": self.target,
            "type": self.type,
            "evidence": self.evidence,
            "weight": self.weight,
        }


@dataclass
class FileRecord:
    path: str
    hash: str
    lang: str
    loc: int
    last_indexed: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            "path": self.path,
            "hash": self.hash,
            "lang": self.lang,
            "loc": self.loc,
            "last_indexed": self.last_indexed,
        }


@dataclass
class IndexState:
    nodes: List[NodeRecord] = field(default_factory=list)
    edges: List[EdgeRecord] = field(default_factory=list)
    files: List[FileRecord] = field(default_factory=list)
    node_ids: Set[str] = field(default_factory=set)
    edge_keys: Set[Tuple[str, str, str]] = field(default_factory=set)

    def add_node(self, node: NodeRecord) -> bool:
        if node.id in self.node_ids:
            return False
        self.node_ids.add(node.id)
        self.nodes.append(node)
        return True

    def add_edge(self, edge: EdgeRecord) -> bool:
        key = (edge.source, edge.target, edge.type)
        if key in self.edge_keys:
            return False
        self.edge_keys.add(key)
        self.edges.append(edge)
        return True


def make_node_id(node_type: str, path: str, name: str = "") -> str:
    prefix = NODE_TYPE_PREFIXES.get(node_type, node_type)
    if name:
        return f"{prefix}:{path}:{name}"
    return f"{prefix}:{path}"


def sha256_file(filepath: Path) -> str:
    h = hashlib.sha256()
    try:
        with open(filepath, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                h.update(chunk)
    except (OSError, PermissionError):
        return ""
    return h.hexdigest()


def detect_lang(filepath: Path) -> str:
    ext = filepath.suffix.lower()
    if ext in LANG_MAP:
        return LANG_MAP[ext]
    try:
        first_line = filepath.read_text(errors="replace").split("\n", 1)[0]
        if first_line.startswith("#!"):
            for lang_hint, lang_name in [
                ("python", "python"), ("node", "javascript"), ("ruby", "ruby"),
                ("bash", "shell"), ("sh", "shell"), ("perl", "perl"),
                ("elixir", "elixir"), ("php", "php"),
            ]:
                if lang_hint in first_line:
                    return lang_name
    except (OSError, PermissionError):
        pass
    return ""


def count_lines(filepath: Path) -> int:
    try:
        return len(filepath.read_text(errors="replace").splitlines())
    except (OSError, PermissionError):
        return 0


def read_lines(filepath: Path) -> List[str]:
    try:
        return filepath.read_text(errors="replace").splitlines()
    except (OSError, PermissionError):
        return []


def is_entry_point(filepath: Path, root: Path) -> bool:
    if filepath.name in BUILD_FILES:
        return True
    stem = filepath.stem.lower()
    if stem in ENTRY_STEMS:
        return True
    rel = filepath.relative_to(root)
    parts = rel.parts
    if len(parts) >= 2 and parts[-2] == "cmd" and filepath.name.startswith("main"):
        return True
    if len(parts) >= 3 and parts[0] == "cmd" and filepath.name.startswith("main"):
        return True
    return False


def list_files_git(root: Path) -> Optional[List[Path]]:
    try:
        result = subprocess.run(
            ["git", "ls-files", "-z"],
            cwd=str(root),
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != 0:
            return None
        paths = []
        for entry in result.stdout.split("\0"):
            entry = entry.strip()
            if entry:
                paths.append(root / entry)
        return paths
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None


def list_files_walk(root: Path) -> List[Path]:
    paths = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fname in filenames:
            paths.append(Path(dirpath) / fname)
    return paths


def git_changed_files(root: Path, ref: str) -> Optional[List[Path]]:
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", ref],
            cwd=str(root),
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != 0:
            return None
        paths = []
        for line in result.stdout.splitlines():
            line = line.strip()
            if line:
                paths.append(root / line)
        return paths
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None


def load_existing_hashes(output_dir: Path) -> Dict[str, str]:
    files_path = output_dir / "files.jsonl"
    if not files_path.exists():
        return {}
    hashes = {}
    for line in files_path.read_text().splitlines():
        line = line.strip()
        if line:
            try:
                obj = json.loads(line)
                hashes[obj["path"]] = obj["hash"]
            except (json.JSONDecodeError, KeyError):
                continue
    return hashes


def extract_imports(lines: List[str], lang: str) -> List[Tuple[str, int]]:
    patterns = IMPORT_PATTERNS.get(lang, [])
    if not patterns:
        return []
    results = []
    in_go_import_block = False
    for lineno, line in enumerate(lines, 1):
        stripped = line.strip()
        if lang == "go":
            if stripped == "import (":
                in_go_import_block = True
                continue
            if in_go_import_block:
                if stripped == ")":
                    in_go_import_block = False
                    continue
                for pat in patterns:
                    m = pat.search(stripped)
                    if m:
                        results.append((m.group(1), lineno))
                continue
        for pat in patterns:
            m = pat.search(stripped)
            if m:
                results.append((m.group(1), lineno))
                break
    return results


def has_ctags() -> bool:
    try:
        result = subprocess.run(
            ["ctags", "--version"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def extract_symbols_ctags(filepath: Path) -> List[Dict[str, Any]]:
    try:
        result = subprocess.run(
            ["ctags", "--output-format=json", "--fields=+lKSn", "-f", "-", str(filepath)],
            capture_output=True,
            text=True,
            timeout=15,
        )
        if result.returncode != 0:
            return []
        symbols = []
        for line in result.stdout.splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                kind = entry.get("kind", "").lower()
                sym_type = "function"
                if kind in ("class", "struct"):
                    sym_type = "class"
                elif kind in ("interface", "trait", "enum", "type", "typedef"):
                    sym_type = "type"
                elif kind in ("method",):
                    sym_type = "method"
                elif kind in ("module", "namespace", "package"):
                    sym_type = "module"
                elif kind in ("function", "func", "subroutine", "def"):
                    sym_type = "function"
                else:
                    continue
                symbols.append({
                    "name": entry.get("name", ""),
                    "type": sym_type,
                    "line": entry.get("line", 0),
                    "end_line": entry.get("end", entry.get("line", 0)),
                    "confidence": 0.9,
                })
            except json.JSONDecodeError:
                continue
        return symbols
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return []


def extract_symbols_regex(lines: List[str], lang: str) -> List[Dict[str, Any]]:
    patterns = SYMBOL_PATTERNS.get(lang, [])
    if not patterns:
        return []
    symbols = []
    seen = set()
    for lineno, line in enumerate(lines, 1):
        for sym_type, pat in patterns:
            m = pat.search(line)
            if m:
                name = m.group(1)
                key = (sym_type, name)
                if key not in seen:
                    seen.add(key)
                    symbols.append({
                        "name": name,
                        "type": sym_type,
                        "line": lineno,
                        "end_line": lineno,
                        "confidence": 0.7,
                    })
                break
    return symbols


def find_symbol_references(lines: List[str], symbol_name: str) -> List[int]:
    refs = []
    pattern = re.compile(r"\b" + re.escape(symbol_name) + r"\b")
    for lineno, line in enumerate(lines, 1):
        if pattern.search(line):
            refs.append(lineno)
    return refs


def run_pass1(
    root: Path,
    all_files: List[Path],
    existing_hashes: Dict[str, str],
    full_reindex: bool,
    state: IndexState,
    verbose: bool,
) -> Tuple[Set[str], Dict[str, int], Dict[str, int]]:
    entry_point_ids: Set[str] = set()
    fan_out: Dict[str, int] = {}
    fan_in: Dict[str, int] = {}
    now = datetime.now(timezone.utc).isoformat()

    for filepath in all_files:
        if not filepath.is_file():
            continue
        try:
            rel = str(filepath.relative_to(root))
        except ValueError:
            continue

        lang = detect_lang(filepath)
        if not lang:
            continue

        file_hash = sha256_file(filepath)
        if not file_hash:
            continue

        if not full_reindex and rel in existing_hashes and existing_hashes[rel] == file_hash:
            node_id = make_node_id("file", rel)
            state.add_node(NodeRecord(
                id=node_id, type="file", name=filepath.name,
                path=rel, lang=lang, confidence=0.9,
            ))
            state.files.append(FileRecord(
                path=rel, hash=file_hash, lang=lang,
                loc=count_lines(filepath), last_indexed=now,
            ))
            if is_entry_point(filepath, root):
                entry_point_ids.add(node_id)
            continue

        loc = count_lines(filepath)
        tags: List[str] = []
        if loc > 1000:
            tags.append("large_file")

        node_id = make_node_id("file", rel)
        state.add_node(NodeRecord(
            id=node_id, type="file", name=filepath.name,
            path=rel, lang=lang, summary="", tags=tags,
            confidence=0.9,
        ))
        state.files.append(FileRecord(
            path=rel, hash=file_hash, lang=lang, loc=loc, last_indexed=now,
        ))

        if is_entry_point(filepath, root):
            entry_point_ids.add(node_id)

        lines = read_lines(filepath)
        imports = extract_imports(lines, lang)
        fan_out[node_id] = len(imports)

        for imp_target, lineno in imports:
            target_id = f"import:{imp_target}"
            state.add_edge(EdgeRecord(
                source=node_id, target=target_id, type="imports",
                evidence=[{"path": rel, "start_line": lineno, "end_line": lineno}],
                weight=0.7,
            ))
            fan_in[target_id] = fan_in.get(target_id, 0) + 1

        if verbose:
            print(f"  [pass1] {rel} ({lang}, {loc} LOC, {len(imports)} imports)")

    return entry_point_ids, fan_out, fan_in


def select_seeds(
    entry_point_ids: Set[str],
    fan_out: Dict[str, int],
    fan_in: Dict[str, int],
    state: IndexState,
    max_files: int,
) -> List[str]:
    file_nodes = [n for n in state.nodes if n.type == "file"]

    entry_seeds = [n.id for n in file_nodes if n.id in entry_point_ids]

    all_fan = {}
    for n in file_nodes:
        all_fan[n.id] = fan_out.get(n.id, 0) + fan_in.get(n.id, 0)
    sorted_by_fan = sorted(all_fan.items(), key=lambda x: x[1], reverse=True)
    threshold = max(1, len(sorted_by_fan) // 10)
    high_fan_seeds = [nid for nid, _ in sorted_by_fan[:threshold] if nid not in entry_point_ids]

    seeds = entry_seeds + high_fan_seeds
    return seeds[:max_files]


def run_pass2(
    root: Path,
    seeds: List[str],
    state: IndexState,
    max_depth: int,
    max_files: int,
    use_ctags: bool,
    verbose: bool,
) -> None:
    node_map = {n.id: n for n in state.nodes}
    adjacency: Dict[str, List[str]] = {}
    for edge in state.edges:
        adjacency.setdefault(edge.source, []).append(edge.target)
        adjacency.setdefault(edge.target, []).append(edge.source)

    visited: Set[str] = set()
    queue = [(sid, 0) for sid in seeds]
    files_processed = 0

    while queue and files_processed < max_files:
        current_id, depth = queue.pop(0)
        if current_id in visited:
            continue
        visited.add(current_id)

        node = node_map.get(current_id)
        if not node or node.type != "file":
            continue

        filepath = root / node.path
        if not filepath.is_file():
            continue

        lines = read_lines(filepath)
        if not lines:
            continue

        if use_ctags:
            symbols = extract_symbols_ctags(filepath)
        else:
            symbols = extract_symbols_regex(lines, node.lang)

        method_count = 0
        symbol_names = []
        for sym in symbols:
            sym_name = sym["name"]
            sym_type = sym["type"]
            sym_id = make_node_id(sym_type, node.path, sym_name)

            sym_tags: List[str] = []
            if sym_type in ("class",):
                class_methods = sum(
                    1 for s in symbols if s["type"] in ("method", "function")
                )
                if class_methods > 20:
                    sym_tags.append("god_object")
                method_count += 1

            state.add_node(NodeRecord(
                id=sym_id, type=sym_type, name=sym_name,
                path=node.path, lang=node.lang, tags=sym_tags,
                confidence=sym.get("confidence", 0.7),
                evidence=[{
                    "path": node.path,
                    "start_line": sym["line"],
                    "end_line": sym.get("end_line", sym["line"]),
                }],
            ))

            state.add_edge(EdgeRecord(
                source=current_id, target=sym_id, type="defines",
                evidence=[{
                    "path": node.path,
                    "start_line": sym["line"],
                    "end_line": sym.get("end_line", sym["line"]),
                }],
                weight=0.9,
            ))

            symbol_names.append((sym_name, sym_id))

        for sym_name, sym_id in symbol_names:
            refs = find_symbol_references(lines, sym_name)
            for other_name, other_id in symbol_names:
                if other_id == sym_id:
                    continue
                for ref_line in refs:
                    if ref_line != 0:
                        state.add_edge(EdgeRecord(
                            source=sym_id, target=other_id, type="calls",
                            evidence=[{
                                "path": node.path,
                                "start_line": ref_line,
                                "end_line": ref_line,
                            }],
                            weight=0.5,
                        ))
                        break

        if node.path and count_lines(filepath) > 500 and method_count > 20:
            if "god_object" not in node.tags:
                node.tags.append("god_object")

        files_processed += 1
        if verbose:
            print(f"  [pass2] {node.path} ({len(symbols)} symbols)")

        if depth < max_depth:
            for neighbor in adjacency.get(current_id, []):
                if neighbor not in visited:
                    queue.append((neighbor, depth + 1))


def build_indexes(state: IndexState) -> Tuple[Dict[str, Any], Dict[str, Any]]:
    symbol_to_node: Dict[str, List[str]] = {}
    for node in state.nodes:
        if node.type != "file":
            symbol_to_node.setdefault(node.name, []).append(node.id)

    path_to_file: Dict[str, str] = {}
    for node in state.nodes:
        if node.type == "file":
            path_to_file[node.path] = node.id

    return symbol_to_node, path_to_file


def write_output(
    output_dir: Path,
    state: IndexState,
    symbol_to_node: Dict[str, Any],
    path_to_file: Dict[str, Any],
    root: Path,
    elapsed: float,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    indexes_dir = output_dir / "indexes"
    indexes_dir.mkdir(parents=True, exist_ok=True)
    summaries_dir = output_dir / "summaries"
    summaries_dir.mkdir(parents=True, exist_ok=True)

    with open(output_dir / "nodes.jsonl", "w") as f:
        for node in state.nodes:
            f.write(json.dumps(node.to_dict()) + "\n")

    with open(output_dir / "edges.jsonl", "w") as f:
        for edge in state.edges:
            f.write(json.dumps(edge.to_dict()) + "\n")

    with open(output_dir / "files.jsonl", "w") as f:
        for fr in state.files:
            f.write(json.dumps(fr.to_dict()) + "\n")

    with open(output_dir / "symbol_to_node.json", "w") as f:
        json.dump(symbol_to_node, f, indent=2)

    with open(output_dir / "path_to_file.json", "w") as f:
        json.dump(path_to_file, f, indent=2)

    meta = {
        "root": str(root.resolve()),
        "indexed_at": datetime.now(timezone.utc).isoformat(),
        "file_count": len(state.files),
        "node_count": len(state.nodes),
        "edge_count": len(state.edges),
        "elapsed_seconds": round(elapsed, 2),
    }
    with open(output_dir / "meta.json", "w") as f:
        json.dump(meta, f, indent=2)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Index a codebase into a JSONL knowledge graph.",
    )
    parser.add_argument(
        "root_dir",
        nargs="?",
        default=".",
        help="Repository root directory (default: current directory)",
    )
    parser.add_argument(
        "--output-dir",
        help="Output directory for the knowledge graph (default: <root>/archaeology/kg)",
    )
    parser.add_argument(
        "--full",
        action="store_true",
        help="Force full re-index (ignore content hashes)",
    )
    parser.add_argument(
        "--since-git",
        metavar="REF",
        help="Only index files changed since git ref (commit, tag, branch)",
    )
    parser.add_argument(
        "--max-files",
        type=int,
        default=500,
        help="Maximum files to deep-analyze in pass 2 (default: 500)",
    )
    parser.add_argument(
        "--max-depth",
        type=int,
        default=3,
        help="Maximum BFS depth in pass 2 (default: 3)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print detailed progress",
    )

    args = parser.parse_args()
    root = Path(args.root_dir).resolve()
    if not root.is_dir():
        print(f"Error: {root} is not a directory", file=sys.stderr)
        sys.exit(1)

    output_dir = Path(args.output_dir) if args.output_dir else root / "archaeology" / "kg"
    start_time = time.time()

    print(f"Indexing: {root}")
    print(f"Output:   {output_dir}")

    if args.since_git:
        changed = git_changed_files(root, args.since_git)
        if changed is None:
            print(f"Warning: git diff failed for ref '{args.since_git}', falling back to full scan", file=sys.stderr)
            all_files = list_files_git(root) or list_files_walk(root)
        else:
            all_files = [f for f in changed if f.is_file()]
            print(f"Scoping to {len(all_files)} files changed since {args.since_git}")
    else:
        all_files = list_files_git(root) or list_files_walk(root)

    existing_hashes = {} if args.full else load_existing_hashes(output_dir)
    use_ctags = has_ctags()
    if use_ctags:
        print("Symbol extraction: ctags (confidence: 0.9)")
    else:
        print("Symbol extraction: regex fallback (confidence: 0.7)")

    state = IndexState()

    print(f"\nPass 1: Coarse inventory ({len(all_files)} files)...")
    entry_point_ids, fan_out, fan_in = run_pass1(
        root, all_files, existing_hashes, args.full, state, args.verbose,
    )
    file_count = len([n for n in state.nodes if n.type == "file"])
    print(f"  Found {file_count} source files, {len(entry_point_ids)} entry points")

    seeds = select_seeds(entry_point_ids, fan_out, fan_in, state, args.max_files)
    print(f"\nPass 2: Targeted deepening ({len(seeds)} seeds, max depth {args.max_depth})...")
    run_pass2(root, seeds, state, args.max_depth, args.max_files, use_ctags, args.verbose)

    symbol_to_node, path_to_file = build_indexes(state)
    elapsed = time.time() - start_time
    write_output(output_dir, state, symbol_to_node, path_to_file, root, elapsed)

    symbol_count = len([n for n in state.nodes if n.type != "file"])
    print(f"\nDone in {elapsed:.1f}s")
    print(f"  Files:   {file_count}")
    print(f"  Symbols: {symbol_count}")
    print(f"  Nodes:   {len(state.nodes)}")
    print(f"  Edges:   {len(state.edges)}")
    print(f"  Output:  {output_dir}")


if __name__ == "__main__":
    main()
