#!/usr/bin/env python3
"""Convert Montreal's AC v7 AI files to the runtime's header + 20-byte point format."""
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / ".tools/recovery/montreal-integration-20261018/source/content/tracks/montreal"
OUTPUT = ROOT / "assets/montreal"


def extract_points(data: bytes, label: str):
    if len(data) < 16:
        raise ValueError(f"{label}: short header")
    version, count = struct.unpack_from("<Ii", data, 0)
    if version != 7 or count < 100 or count > 10000:
        raise ValueError(f"{label}: invalid AI format/version/count {version}/{count}")
    # In these AC files the fast-lane coordinate table starts at byte 16 and
    # the auxiliary spline table at byte 16 + count*20. Standalone ideal_line
    # is shorter because it contains only the primary coordinate records.
    end = 16 + count * 20
    if end > len(data):
        raise ValueError(f"{label}: truncated point table")
    points = [struct.unpack_from("<5f", data, 16 + i * 20) for i in range(count)]
    return version, points

for source, target in [
    (SOURCE / "ai/fast_lane.ai", OUTPUT / "fast_lane.ai"),
    (SOURCE / "data/ideal_line.ai", OUTPUT / "ideal_line.ai"),
]:
    version, points = extract_points(source.read_bytes(), source.name)
    with target.open("wb") as stream:
        stream.write(struct.pack("<4i", version, len(points), 0, 0))
        for point in points:
            stream.write(struct.pack("<5f", *point))
    print(f"EXTRACTED {source.name}: points={len(points)} bytes={target.stat().st_size} -> {target}")
