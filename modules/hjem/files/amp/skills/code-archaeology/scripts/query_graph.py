#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict, deque
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class Node:
    id: str
    name: str
    type: str
    path: str = ""
    lang: str = ""
    tags: list[str] = field(default_factory=list)
    summary: str = ""
    evidence: list[str] = field(default_factory=list)
    raw: dict[str, Any] = field(default_factory=dict)


@dataclass
class Edge:
    source: str
    target: str
    type: str
    confidence: float = 1.0
    raw: dict[str, Any] = field(default_factory=dict)


@dataclass
class ContextBundle:
    query: str
    nodes: list[Node]
    edges: list[Edge]
    hotspots: list[dict[str, Any]]


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    items = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if line:
            items.append(json.loads(line))
    return items


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def parse_node(raw: dict[str, Any]) -> Node:
    return Node(
        id=raw.get("id", ""),
        name=raw.get("name", ""),
        type=raw.get("type", ""),
        path=raw.get("path", ""),
        lang=raw.get("lang", ""),
        tags=raw.get("tags", []),
        summary=raw.get("summary", ""),
        evidence=raw.get("evidence", []),
        raw=raw,
    )


def parse_edge(raw: dict[str, Any]) -> Edge:
    return Edge(
        source=raw.get("source", ""),
        target=raw.get("target", ""),
        type=raw.get("type", ""),
        confidence=raw.get("weight", raw.get("confidence", 1.0)),
        raw=raw,
    )


def resolve_by_symbol(
    symbol: str,
    symbol_index: dict[str, Any],
    all_nodes: list[Node],
) -> set[str]:
    node_ids: set[str] = set()
    if symbol in symbol_index:
        val = symbol_index[symbol]
        if isinstance(val, list):
            node_ids.update(val)
        else:
            node_ids.add(str(val))
    if not node_ids:
        lower = symbol.lower()
        for node in all_nodes:
            if lower in node.name.lower():
                node_ids.add(node.id)
    return node_ids


def resolve_by_path(
    path_query: str,
    path_index: dict[str, Any],
    all_nodes: list[Node],
) -> set[str]:
    node_ids: set[str] = set()
    for indexed_path, val in path_index.items():
        if path_query in indexed_path:
            if isinstance(val, list):
                node_ids.update(val)
            else:
                node_ids.add(str(val))
    if not node_ids:
        lower = path_query.lower()
        for node in all_nodes:
            if lower in node.path.lower():
                node_ids.add(node.id)
    return node_ids


def resolve_by_tags(tags: list[str], all_nodes: list[Node]) -> set[str]:
    tag_set = {t.lower() for t in tags}
    return {
        node.id
        for node in all_nodes
        if tag_set & {t.lower() for t in node.tags}
    }


def resolve_by_type(types: list[str], all_nodes: list[Node]) -> set[str]:
    type_set = {t.lower() for t in types}
    return {
        node.id
        for node in all_nodes
        if node.type.lower() in type_set
    }


def expand_neighborhood(
    initial_ids: set[str],
    all_edges: list[Edge],
    node_map: dict[str, Node],
    hops: int,
    max_nodes: int,
    max_edges: int,
) -> tuple[list[Node], list[Edge]]:
    adjacency: dict[str, list[Edge]] = defaultdict(list)
    for edge in all_edges:
        adjacency[edge.source].append(edge)
        adjacency[edge.target].append(edge)

    visited: set[str] = set(initial_ids)
    queue: deque[tuple[str, int]] = deque((nid, 0) for nid in initial_ids)
    collected_edges: list[Edge] = []
    seen_edges: set[tuple[str, str, str]] = set()

    while queue:
        current, depth = queue.popleft()
        if depth >= hops:
            continue
        for edge in adjacency.get(current, []):
            edge_key = (edge.source, edge.target, edge.type)
            if edge_key not in seen_edges:
                seen_edges.add(edge_key)
                collected_edges.append(edge)
            neighbor = edge.target if edge.source == current else edge.source
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append((neighbor, depth + 1))

    collected_edges.sort(key=lambda e: e.confidence, reverse=True)
    collected_edges = collected_edges[:max_edges]

    result_ids = set(initial_ids)
    for edge in collected_edges:
        result_ids.add(edge.source)
        result_ids.add(edge.target)

    result_nodes = [node_map[nid] for nid in result_ids if nid in node_map]
    result_nodes = result_nodes[:max_nodes]

    return result_nodes, collected_edges


def compute_hotspots(nodes: list[Node], edges: list[Edge]) -> list[dict[str, Any]]:
    edge_count: dict[str, int] = defaultdict(int)
    for edge in edges:
        edge_count[edge.source] += 1
        edge_count[edge.target] += 1

    node_names = {n.id: n.name for n in nodes}
    ranked = sorted(edge_count.items(), key=lambda x: x[1], reverse=True)
    return [
        {"id": nid, "name": node_names.get(nid, nid), "edge_count": count}
        for nid, count in ranked[:10]
        if nid in node_names
    ]


def format_md(bundle: ContextBundle, include_evidence: bool) -> str:
    lines = [f"# Context Bundle: {bundle.query}", ""]

    lines.append(f"## Nodes ({len(bundle.nodes)})")
    lines.append("")
    for node in bundle.nodes:
        lines.append(f"### {node.name} ({node.type})")
        if node.path:
            lines.append(f"- **Path**: {node.path}")
        if node.lang:
            lines.append(f"- **Language**: {node.lang}")
        if node.tags:
            lines.append(f"- **Tags**: {', '.join(node.tags)}")
        if node.summary:
            lines.append(f"- **Summary**: {node.summary}")
        if include_evidence and node.evidence:
            lines.append(f"- **Evidence**: {', '.join(node.evidence)}")
        lines.append("")

    lines.append(f"## Edges ({len(bundle.edges)})")
    lines.append("")
    if bundle.edges:
        node_names = {n.id: n.name for n in bundle.nodes}
        lines.append("| From | Relationship | To |")
        lines.append("|------|-------------|-----|")
        for edge in bundle.edges:
            src = node_names.get(edge.source, edge.source)
            tgt = node_names.get(edge.target, edge.target)
            lines.append(f"| {src} | {edge.type} | {tgt} |")
        lines.append("")

    if bundle.hotspots:
        lines.append("## Hotspots")
        lines.append("")
        for hs in bundle.hotspots:
            lines.append(f"- **{hs['name']}**: {hs['edge_count']} connections")
        lines.append("")

    return "\n".join(lines)


def format_json(bundle: ContextBundle) -> str:
    return json.dumps(
        {
            "query": bundle.query,
            "nodes": [n.raw for n in bundle.nodes],
            "edges": [e.raw for e in bundle.edges],
            "hotspots": bundle.hotspots,
        },
        indent=2,
    )


def build_query_description(args: argparse.Namespace) -> str:
    parts = []
    if args.symbol:
        parts.append(f"symbol={args.symbol}")
    if args.path:
        parts.append(f"path={args.path}")
    if args.tags:
        parts.append(f"tags={args.tags}")
    if args.type:
        parts.append(f"type={args.type}")
    return ", ".join(parts) if parts else "all"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Query a code archaeology knowledge graph and return focused context bundles.",
    )
    parser.add_argument(
        "kg_dir",
        nargs="?",
        default="./archaeology/kg",
        help="Knowledge graph directory (default: ./archaeology/kg)",
    )
    parser.add_argument("--symbol", help="Find nodes matching this symbol name")
    parser.add_argument("--path", help="Find nodes related to this file path (partial match)")
    parser.add_argument("--tags", help="Filter nodes by tags (comma-separated)")
    parser.add_argument("--type", help="Filter by node type (comma-separated)")
    parser.add_argument("--hops", type=int, default=1, help="Neighborhood expansion depth (default: 1, max: 3)")
    parser.add_argument("--max-nodes", type=int, default=30, help="Maximum nodes to return (default: 30)")
    parser.add_argument("--max-edges", type=int, default=60, help="Maximum edges to return (default: 60)")
    parser.add_argument("--format", choices=["md", "json"], default="md", help="Output format (default: md)")
    parser.add_argument("--include-evidence", action="store_true", help="Include evidence pointers in output")
    parser.add_argument("--summary", action="store_true", help="Show only the top-level KG.md summary")

    args = parser.parse_args()
    args.hops = min(max(args.hops, 0), 3)

    has_filter = any([args.symbol, args.path, args.tags, args.type])
    if not has_filter and not args.summary:
        print("Usage: query_graph.py [OPTIONS] [KG_DIR]")
        print()
        print("Provide at least one query filter:")
        print("  --symbol NAME    Find nodes matching a symbol name")
        print("  --path PATH      Find nodes related to a file path")
        print("  --tags TAG,...   Filter nodes by tags")
        print("  --type TYPE,...  Filter by node type")
        print()
        print("Other options:")
        print("  --hops N         Neighborhood depth (default: 1, max: 3)")
        print("  --max-nodes N    Max nodes returned (default: 30)")
        print("  --max-edges N    Max edges returned (default: 60)")
        print("  --format md|json Output format (default: md)")
        print("  --include-evidence  Include evidence pointers")
        print("  --summary        Show KG.md summary")
        sys.exit(0)

    kg_dir = Path(args.kg_dir)
    if not kg_dir.exists():
        print(f"Error: Knowledge graph directory not found: {kg_dir}", file=sys.stderr)
        sys.exit(1)

    if args.summary:
        kg_md = kg_dir / "KG.md"
        if kg_md.exists():
            print(kg_md.read_text())
        else:
            print(f"Error: No KG.md found in {kg_dir}", file=sys.stderr)
            sys.exit(1)
        return

    symbol_index = load_json(kg_dir / "symbol_to_node.json")
    path_index = load_json(kg_dir / "path_to_file.json")
    raw_nodes = load_jsonl(kg_dir / "nodes.jsonl")
    raw_edges = load_jsonl(kg_dir / "edges.jsonl")

    all_nodes = [parse_node(r) for r in raw_nodes]
    all_edges = [parse_edge(r) for r in raw_edges]
    node_map = {n.id: n for n in all_nodes}

    candidate_sets: list[set[str]] = []

    if args.symbol:
        candidate_sets.append(resolve_by_symbol(args.symbol, symbol_index, all_nodes))

    if args.path:
        candidate_sets.append(resolve_by_path(args.path, path_index, all_nodes))

    if args.tags:
        tag_list = [t.strip() for t in args.tags.split(",") if t.strip()]
        candidate_sets.append(resolve_by_tags(tag_list, all_nodes))

    if args.type:
        type_list = [t.strip() for t in args.type.split(",") if t.strip()]
        candidate_sets.append(resolve_by_type(type_list, all_nodes))

    if candidate_sets:
        initial_ids = candidate_sets[0]
        for s in candidate_sets[1:]:
            initial_ids &= s
    else:
        initial_ids = set()

    if not initial_ids:
        query_desc = build_query_description(args)
        print(f"No nodes found matching query: {query_desc}", file=sys.stderr)
        sys.exit(1)

    result_nodes, result_edges = expand_neighborhood(
        initial_ids,
        all_edges,
        node_map,
        args.hops,
        args.max_nodes,
        args.max_edges,
    )

    hotspots = compute_hotspots(result_nodes, result_edges)
    query_desc = build_query_description(args)

    bundle = ContextBundle(
        query=query_desc,
        nodes=result_nodes,
        edges=result_edges,
        hotspots=hotspots,
    )

    if args.format == "json":
        print(format_json(bundle))
    else:
        print(format_md(bundle, args.include_evidence))


if __name__ == "__main__":
    main()
