#!/usr/bin/env python3
"""Standalone Sony timecode fixer for Final Cut Pro XML files.

This ports the practical conversion path from CommandPost's Sony Timecode
toolbox into a small script that can live inside a macOS app bundle.
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
import tempfile
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path
from typing import Iterable
from urllib.parse import unquote, urlparse


SONY_META_START = '<?xml version="1.0" encoding="UTF-8"?>'
SONY_META_END = "</NonRealTimeMeta>"


class FixError(Exception):
    """Raised when an input cannot be processed."""


@dataclass
class ProcessResult:
    input_path: Path
    output_path: Path
    adjusted_assets: int
    package: bool = False


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def children_named(node: ET.Element, name: str) -> list[ET.Element]:
    return [child for child in list(node) if local_name(child.tag) == name]


def first_child_named(node: ET.Element, name: str) -> ET.Element | None:
    for child in list(node):
        if local_name(child.tag) == name:
            return child
    return None


def iter_named(node: ET.Element, name: str) -> Iterable[ET.Element]:
    for child in node.iter():
        if local_name(child.tag) == name:
            yield child


def parse_fcpxml_time(value: str | None) -> Fraction:
    if not value:
        return Fraction(0, 1)
    value = value.strip()
    if not value.endswith("s"):
        raise FixError(f"Unsupported FCPXML time value: {value}")
    raw = value[:-1]
    if "/" in raw:
        numerator, denominator = raw.split("/", 1)
        return Fraction(int(numerator), int(denominator))
    return Fraction(raw)


def format_fcpxml_time(value: Fraction) -> str:
    value = Fraction(value)
    if value.denominator == 1:
        return f"{value.numerator}s"
    return f"{value.numerator}/{value.denominator}s"


def path_from_file_url(value: str, base_dir: Path) -> Path:
    parsed = urlparse(value)
    if parsed.scheme == "file":
        return Path(unquote(parsed.path))
    path = Path(unquote(value))
    if not path.is_absolute():
        path = base_dir / path
    return path


def extract_embedded_sony_xml(mp4_path: Path) -> Path | None:
    try:
        data = mp4_path.read_bytes()
    except OSError:
        return None

    tail = data[-262144:].decode("utf-8", errors="ignore")
    start = tail.rfind(SONY_META_START)
    end = tail.rfind(SONY_META_END)
    if start == -1 or end == -1 or end < start:
        return None

    end += len(SONY_META_END)
    metadata = tail[start:end]
    handle = tempfile.NamedTemporaryFile("w", suffix=".xml", delete=False, encoding="utf-8")
    with handle:
        handle.write(metadata)
    return Path(handle.name)


def sony_sidecar_for_media(media_path: Path) -> Path | None:
    candidates = [
        media_path.with_name(f"{media_path.stem}M01.XML"),
        media_path.with_name(f"{media_path.stem}M01.xml"),
        media_path.with_suffix(".XML"),
        media_path.with_suffix(".xml"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate

    embedded = extract_embedded_sony_xml(media_path)
    if embedded:
        return embedded

    return None


def parse_sony_metadata(path: Path) -> tuple[float, bool, str, str]:
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as exc:
        raise FixError(f"Could not read Sony metadata XML: {path} ({exc})") from exc

    ltc_table = next(iter_named(root, "LtcChangeTable"), None)
    if ltc_table is None:
        raise FixError(f"No LtcChangeTable found in {path}")

    tc_fps_raw = ltc_table.get("tcFps")
    if not tc_fps_raw:
        raise FixError(f"No tcFps found in {path}")
    tc_fps = float(tc_fps_raw)
    half_step = ltc_table.get("halfStep") == "true"

    video_frame = next(iter_named(root, "VideoFrame"), None)
    format_fps = video_frame.get("formatFps") if video_frame is not None else None
    if not format_fps:
        raise FixError(f"No formatFps found in {path}")

    start_value = None
    for change in iter_named(root, "LtcChange"):
        if change.get("status") == "increment":
            start_value = change.get("value")
            break
    if not start_value:
        raise FixError(f"No increment LTC value found in {path}")

    return tc_fps, half_step, format_fps, start_value


def fps_number(format_fps: str) -> int:
    match = re.match(r"(\d+(?:\.\d+)?)", format_fps)
    if not match:
        raise FixError(f"Unsupported formatFps value: {format_fps}")
    return int(float(match.group(1)) + 0.999999)


def ffssmmhh_to_total_frames(value: str, tc_fps: float, half_step: bool, format_fps: str) -> int:
    digits = re.sub(r"\D", "", value)
    if len(digits) != 8:
        raise FixError(f"Invalid Sony timecode value '{value}'; expected FFSSMMHH")

    drop_frame = int(digits[0]) >= 4
    if drop_frame:
        first_frame_digit = max(int(digits[0]) - 4, 0)
        digits = str(first_frame_digit) + digits[1:]
        frames = int(digits[0:2])
        seconds = int(digits[2:4])
        minutes = int(digits[4:6])
        hours = int(digits[6:8])
        frame_rate = 29.97
        drop_frames = int(frame_rate * 0.066666 + 0.999999)
        time_base = int(frame_rate + 0.999999)
        total_minutes = (60 * hours) + minutes
        total_frames = (
            (time_base * 60 * 60 * hours)
            + (time_base * 60 * minutes)
            + (time_base * seconds)
            + frames
            - (drop_frames * (total_minutes - (total_minutes // 10)))
        )
    else:
        frames = int(digits[0:2])
        seconds = int(digits[2:4])
        minutes = int(digits[4:6])
        hours = int(digits[6:8])
        total_frames_float = (((hours * 60 + minutes) * 60 + seconds) * tc_fps) + frames
        if total_frames_float != int(total_frames_float):
            raise FixError(f"Non-integer frame count from timecode value '{value}'")
        total_frames = int(total_frames_float)

    if half_step:
        multiplier = fps_number(format_fps) / tc_fps
        if multiplier != int(multiplier):
            raise FixError(f"Non-integer half-step multiplier: {multiplier}")
        total_frames = int(total_frames * multiplier)

    return total_frames


def project_name(root: ET.Element) -> str:
    project = first_child_named(root, "project")
    if project is None:
        library = first_child_named(root, "library")
        event = first_child_named(library, "event") if library is not None else None
        project = first_child_named(event, "project") if event is not None else None
    if project is None or not project.get("name"):
        raise FixError("No FCPXML project name found")
    return project.get("name", "Sony Timecode")


def find_project(root: ET.Element) -> ET.Element | None:
    direct = first_child_named(root, "project")
    if direct is not None:
        return direct
    for node in iter_named(root, "project"):
        return node
    return None


def find_resources(root: ET.Element) -> ET.Element:
    resources = first_child_named(root, "resources")
    if resources is None:
        raise FixError("No FCPXML resources element found")
    return resources


def format_frame_durations(resources: ET.Element) -> dict[str, Fraction]:
    durations: dict[str, Fraction] = {}
    for node in children_named(resources, "format"):
        node_id = node.get("id")
        frame_duration = node.get("frameDuration")
        if node_id and frame_duration:
            durations[node_id] = parse_fcpxml_time(frame_duration)
    return durations


def update_time_map(time_map: ET.Element, start_time: Fraction) -> None:
    for timept in children_named(time_map, "timept"):
        value = parse_fcpxml_time(timept.get("value"))
        timept.set("value", format_fcpxml_time(value + start_time))


def update_start_time_in_node(node: ET.Element, start_times: dict[str, Fraction]) -> Fraction | None:
    if local_name(node.tag) not in {"asset-clip", "video"}:
        return None
    asset_start = start_times.get(node.get("ref", ""))
    if asset_start is None:
        return None

    time_map = first_child_named(node, "timeMap")
    if time_map is not None:
        update_time_map(time_map, asset_start)
        return None

    new_start = parse_fcpxml_time(node.get("start")) + asset_start
    node.set("start", format_fcpxml_time(new_start))
    return new_start


def process_node_tree(nodes: Iterable[ET.Element], start_times: dict[str, Fraction], parent_start: Fraction | None = None) -> None:
    for node in nodes:
        if parent_start is not None and "offset" in node.attrib:
            node.set("offset", format_fcpxml_time(parse_fcpxml_time(node.get("offset")) + parent_start))
        new_start = update_start_time_in_node(node, start_times)
        process_node_tree(list(node), start_times, new_start)


def ensure_library_event(root: ET.Element) -> None:
    project = first_child_named(root, "project")
    if project is None:
        return
    root.remove(project)
    library = ET.Element("library")
    event = ET.SubElement(library, "event")
    event.append(project)
    root.append(library)


def fcpxml_asset_media_rep(asset: ET.Element) -> ET.Element | None:
    for child in children_named(asset, "media-rep"):
        if child.get("kind") == "original-media":
            return child
    return None


def unique_path(path: Path) -> Path:
    if not path.exists():
        return path
    for index in range(2, 1000):
        candidate = path.with_name(f"{path.stem} {index}{path.suffix}")
        if not candidate.exists():
            return candidate
    raise FixError(f"Could not create a unique output path for: {path}")


def is_fcpxml_file(path: Path) -> bool:
    if not path.is_file():
        return False
    try:
        root = ET.parse(path).getroot()
    except (ET.ParseError, OSError):
        return False
    return local_name(root.tag) == "fcpxml"


def find_fcpxml_in_package(package_path: Path) -> Path:
    preferred = package_path / "Info.fcpxml"
    if is_fcpxml_file(preferred):
        return preferred

    candidates = sorted(
        [path for path in package_path.rglob("*") if path.suffix.lower() in {".fcpxml", ".xml"}],
        key=lambda path: (path.suffix.lower() != ".fcpxml", len(path.parts), path.name.lower()),
    )
    for candidate in candidates:
        if is_fcpxml_file(candidate):
            return candidate

    raise FixError(f"No FCPXML document found inside package: {package_path}")


def process_fcpxml_file(input_path: Path, output_path: Path, media_base_dir: Path | None = None) -> ProcessResult:
    input_path = input_path.expanduser().resolve()
    if not input_path.exists():
        raise FixError(f"Input file does not exist: {input_path}")

    try:
        tree = ET.parse(input_path)
    except ET.ParseError as exc:
        raise FixError(f"Invalid FCPXML: {exc}") from exc

    root = tree.getroot()
    if local_name(root.tag) != "fcpxml":
        raise FixError("Input is not an FCPXML file")

    resources = find_resources(root)
    durations = format_frame_durations(resources)
    start_times: dict[str, Fraction] = {}
    media_base_dir = media_base_dir or input_path.parent

    for asset in children_named(resources, "asset"):
        if asset.get("start") != "0s":
            continue

        asset_id = asset.get("id")
        format_id = asset.get("format")
        frame_duration = durations.get(format_id or "")
        if not asset_id or frame_duration is None:
            continue

        media_rep = fcpxml_asset_media_rep(asset)
        src = media_rep.get("src") if media_rep is not None else None
        if not src or not src.lower().endswith(".mp4"):
            continue

        media_path = path_from_file_url(src, media_base_dir)
        sidecar = sony_sidecar_for_media(media_path)
        if sidecar is None:
            continue

        tc_fps, half_step, format_fps, start_value = parse_sony_metadata(sidecar)
        total_frames = ffssmmhh_to_total_frames(start_value, tc_fps, half_step, format_fps)
        start_time = Fraction(total_frames, 1) * frame_duration

        asset.set("start", format_fcpxml_time(start_time))
        start_times[asset_id] = start_time

    if start_times:
        project = find_project(root)
        if project is not None:
            sequence = first_child_named(project, "sequence")
            spine = first_child_named(sequence, "spine") if sequence is not None else None
            if spine is not None:
                process_node_tree(list(spine), start_times)
        process_node_tree(list(resources), start_times)

    ensure_library_event(root)

    ET.indent(tree, space="  ")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    tree.write(output_path, encoding="utf-8", xml_declaration=True, short_empty_elements=True)

    return ProcessResult(input_path=input_path, output_path=output_path, adjusted_assets=len(start_times))


def process_fcpxml(input_path: Path, output_dir: Path | None = None) -> ProcessResult:
    input_path = input_path.expanduser().resolve()
    output_dir = output_dir.expanduser().resolve() if output_dir else input_path.parent
    output_dir.mkdir(parents=True, exist_ok=True)

    if input_path.is_dir() or input_path.suffix.lower() == ".fcpxmld":
        source_xml = find_fcpxml_in_package(input_path)
        project = project_name(ET.parse(source_xml).getroot())
        output_package = unique_path(output_dir / f"{project} - Fixed.fcpxmld")
        shutil.copytree(input_path, output_package, symlinks=True)

        relative_xml = source_xml.relative_to(input_path)
        output_xml = output_package / relative_xml
        result = process_fcpxml_file(output_xml, output_xml, media_base_dir=output_xml.parent)
        result.input_path = input_path
        result.output_path = output_package
        result.package = True
        return result

    project = project_name(ET.parse(input_path).getroot())
    output_path = unique_path(output_dir / f"{project} - Fixed.fcpxml")
    return process_fcpxml_file(input_path, output_path, media_base_dir=input_path.parent)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Fix Sony timecode starts in Final Cut Pro XML files/packages.")
    parser.add_argument("fcpxml", nargs="+", help="FCPXML file(s) or FCPXMLD package(s) to process")
    parser.add_argument("--output-dir", type=Path, default=None, help="Directory for fixed FCPXML output")
    args = parser.parse_args(argv)

    results = []
    try:
        for item in args.fcpxml:
            results.append(process_fcpxml(Path(item), args.output_dir))
    except FixError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    for result in results:
        kind = "package" if result.package else "file"
        print(f"{result.output_path} ({kind}, {result.adjusted_assets} Sony asset(s) adjusted)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
