#!/usr/bin/env python3
import re
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GRAPH_DIR = ROOT / ".graph"
IGNORE_DIRS = {".git", "build", "ios", "android", "macos", "linux", "windows", ".gradle", ".idea", ".dart_tool", ".pub-cache", ".graph", "Pods"}
FEATURE_FILE_EXTENSIONS = {".dart", ".md", ".yaml", ".yml", ".json", ".graphql", ".xml", ".kt", ".kts", ".swift", ".m", ".h"}


def normalize_feature_id(name: str) -> str:
    result = re.sub(r"[^0-9a-zA-Z_]+", "_", name.strip().lower())
    result = re.sub(r"_+", "_", result).strip("_")
    return result or "feature"


def humanize_feature_name(name: str) -> str:
    return re.sub(r"[_\-]+", " ", name).strip().title()


def parse_proposal_md(path: Path):
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    feature_items = []
    title = None
    description = []
    slug = None
    for line in lines:
        if line.startswith("# ") and title is None:
            title = line[2:].strip()
        slug_match = re.match(r"^\s*-\s*`([^`]+)`\s*:\s*(.+)", line)
        if slug_match:
            slug = slug_match.group(1).strip()
            desc = slug_match.group(2).strip()
            feature_items.append((slug, desc))
        elif title and line.strip() and not line.startswith("-") and not line.startswith("#"):
            if description is not None:
                description.append(line.strip())
    if feature_items:
        return [(normalize_feature_id(slug), desc, path.parent) for slug, desc in feature_items]
    if title:
        desc = " ".join(description).strip() or title
        return [(normalize_feature_id(title), title if title else "Project feature", path.parent)]
    return []


def parse_spec_md(path: Path):
    text = path.read_text(encoding="utf-8")
    headings = []
    for line in text.splitlines():
        if line.startswith("### ") or line.startswith("## "):
            heading = line.lstrip("#").strip()
            if heading:
                headings.append(heading)
    if headings:
        return [(normalize_feature_id(headings[0]), headings[0], path.parent)]
    return []


def scan_paths():
    features = {}
    for dirpath, dirnames, filenames in ROOT.rglob("*"):
        pass


def build_feature_for_path(path: Path):
    parts = path.relative_to(ROOT).parts
    if len(parts) < 2:
        return None
    if parts[0] == "lib":
        if parts[1] in {"widgets", "pages", "services", "repositories", "blocs", "models", "theme", "router", "utils", "dependency_injection"}:
            name = "/".join(parts[1:])
            feature_id = normalize_feature_id(name)
            description = f"{humanize_feature_name(parts[1])} feature from {path.name}."
            return feature_id, description, path
    elif parts[0] == "openspec":
        name = "/".join(parts[1:])
        feature_id = normalize_feature_id(name)
        description = f"OpenSpec artifact from {path.name}."
        return feature_id, description, path
    return None


def collect_features():
    features = {}
    for path in ROOT.rglob("*"):
        if any(part in IGNORE_DIRS for part in path.parts):
            continue
        if path.is_dir():
            continue
        if path.suffix not in FEATURE_FILE_EXTENSIONS:
            continue
        if path.match("**/.git/**"):
            continue
        if path.match("**/__pycache__/**"):
            continue

        if path.match("openspec/changes/*/proposal.md"):
            for feature_id, name, folder in parse_proposal_md(path):
                entry = features.setdefault(feature_id, {"name": name, "description": name, "paths": set()})
                entry["paths"].add(str(path.relative_to(ROOT)))
                entry["paths"].add(str(folder.relative_to(ROOT)))
        elif path.match("openspec/changes/*/specs/**/*.md"):
            for feature_id, name, folder in parse_spec_md(path):
                entry = features.setdefault(feature_id, {"name": name, "description": name, "paths": set()})
                entry["paths"].add(str(path.relative_to(ROOT)))
                entry["paths"].add(str(folder.relative_to(ROOT)))
        else:
            candidate = build_feature_for_path(path)
            if candidate:
                feature_id, desc, file_path = candidate
                entry = features.setdefault(feature_id, {"name": humanize_feature_name(feature_id), "description": desc, "paths": set()})
                entry["paths"].add(str(file_path.relative_to(ROOT)))

    # Sort feature paths and add a fallback feature for the project root
    if not features:
        features["project_root"] = {
            "name": "Project Root",
            "description": "Main project index.",
            "paths": {"."},
        }
    return features


def render_xml(features):
    root = ET.Element("ProjectGraph")
    root.set("generated", datetime.utcnow().isoformat() + "Z")
    root.set("project", ROOT.name)

    metadata = ET.SubElement(root, "Metadata")
    build_time = ET.SubElement(metadata, "BuildTime")
    build_time.text = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%SZ")
    summary = ET.SubElement(metadata, "FeatureCount")
    summary.text = str(len(features))

    features_elem = ET.SubElement(root, "Features")
    for feature_id, values in sorted(features.items(), key=lambda item: item[0]):
        feature_elem = ET.SubElement(features_elem, "Feature")
        feature_elem.set("id", feature_id)
        name_elem = ET.SubElement(feature_elem, "Name")
        name_elem.text = values["name"]
        desc_elem = ET.SubElement(feature_elem, "Description")
        desc_elem.text = values["description"]
        paths_elem = ET.SubElement(feature_elem, "Paths")
        for path in sorted(values["paths"]):
            path_elem = ET.SubElement(paths_elem, "Path")
            absolute = ROOT / path
            path_elem.set("type", "file" if absolute.is_file() else "dir")
            path_elem.text = path
    return ET.ElementTree(root)


def main():
    GRAPH_DIR.mkdir(exist_ok=True)
    features = collect_features()
    tree = render_xml(features)
    out_path = GRAPH_DIR / "project-features.xml"
    tree.write(out_path, encoding="utf-8", xml_declaration=True)
    print(f"Project index generated: {out_path}")


if __name__ == "__main__":
    main()
