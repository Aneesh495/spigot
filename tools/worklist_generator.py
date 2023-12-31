#!/usr/bin/env python3
"""
Spigot Worklist Generator and Converter
Generates synthetic cherry-picking hit worklists and converts legacy
Hamilton/Tecan formats into Spigot-compliant CSV worklists.
"""

import argparse
import csv
import random
import sys


def index_to_well_96(index):
    """Converts 0-based index (0-95) to ANSI standard well name (A1-H12)."""
    row_char = chr(ord('A') + (index // 12))
    col_num = (index % 12) + 1
    return f"{row_char}{col_num}"


def index_to_well_384(index):
    """Converts 0-based index (0-383) to ANSI standard well name (A1-P24)."""
    row_char = chr(ord('A') + (index // 24))
    col_num = (index % 24) + 1
    return f"{row_char}{col_num}"


def generate_cherry_pick_worklist(
    num_hits=24,
    source_plate="SourcePlate_CompoundLibrary",
    dest_plate="AssayPlate_TargetScreen",
    volume_ul=10.0,
    liquid_class="Viscous_Glycerol50",
    seed=42,
):
    """Generates a randomized hit-picking worklist."""
    rng = random.Random(seed)
    # Pick random distinct source wells from a 96-well library
    src_indices = sorted(rng.sample(range(96), num_hits))

    rows = []
    for dst_idx, src_idx in enumerate(src_indices):
        src_well = index_to_well_96(src_idx)
        dst_well = index_to_well_96(dst_idx)
        rows.append({
            "SourcePlate": source_plate,
            "SourceWell": src_well,
            "DestPlate": dest_plate,
            "DestWell": dst_well,
            "VolumeUL": f"{volume_ul:.2f}",
            "LiquidClass": liquid_class,
        })
    return rows


def convert_tecan_worklist(filepath):
    """
    Converts Tecan EVO Gemini/EVOware worklist (.gwl) to Spigot CSV format.
    Tecan lines typically:
    A;SrcPlate;;;SrcWell;;Vol;;;
    D;DstPlate;;;DstWell;;Vol;;;
    W; (wash)
    """
    rows = []
    pending_aspirate = None

    with open(filepath, "r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith("//") or line.startswith("#"):
                continue

            parts = [p.strip() for p in line.split(";")]
            op = parts[0].upper()

            if op == "A":
                # Aspirate: A;RackLabel;RackID;RackType;Position;TubeID;Volume;...
                plate = parts[1] if len(parts) > 1 and parts[1] else "TecanSrc"
                well = parts[4] if len(parts) > 4 else "A1"
                vol = float(parts[6]) if len(parts) > 6 and parts[6] else 10.0
                pending_aspirate = {"plate": plate, "well": well, "vol": vol}

            elif op == "D":
                # Dispense: D;RackLabel;RackID;RackType;Position;TubeID;Volume;...
                if pending_aspirate is None:
                    continue
                plate = parts[1] if len(parts) > 1 and parts[1] else "TecanDst"
                well = parts[4] if len(parts) > 4 else "A1"
                rows.append({
                    "SourcePlate": pending_aspirate["plate"],
                    "SourceWell": pending_aspirate["well"],
                    "DestPlate": plate,
                    "DestWell": well,
                    "VolumeUL": f"{pending_aspirate['vol']:.2f}",
                    "LiquidClass": "Standard_Aqueous",
                })
                pending_aspirate = None

    return rows


def convert_hamilton_worklist(filepath):
    """
    Converts Hamilton MicroLab STAR CSV worklist to Spigot CSV format.
    Standard Hamilton header: SourceLabware,SourcePosition,TargetLabware,TargetPosition,Volume
    """
    rows = []
    with open(filepath, "r", encoding="utf-8") as f:
        reader = csv.reader(f)
        for row in reader:
            if not row or len(row) < 5:
                continue
            # Skip header if present
            if "source" in row[0].lower() or "labware" in row[0].lower():
                continue
            rows.append({
                "SourcePlate": row[0].strip(),
                "SourceWell": row[1].strip(),
                "DestPlate": row[2].strip(),
                "DestWell": row[3].strip(),
                "VolumeUL": f"{float(row[4].strip()):.2f}",
                "LiquidClass": row[5].strip() if len(row) > 5 else "Standard_Aqueous",
            })
    return rows


def write_spigot_csv(rows, output_path=None):
    """Writes row dictionaries to CSV format."""
    out = sys.stdout if output_path is None else open(output_path, "w", newline="", encoding="utf-8")
    try:
        writer = csv.DictWriter(
            out,
            fieldnames=["SourcePlate", "SourceWell", "DestPlate", "DestWell", "VolumeUL", "LiquidClass"],
        )
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    finally:
        if output_path is not None:
            out.close()


def main():
    parser = argparse.ArgumentParser(
        description="Spigot Worklist Generator and Legacy Converter"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Sub-command: generate
    gen_parser = subparsers.add_parser("generate", help="Generate synthetic hit cherry-pick worklist")
    gen_parser.add_argument("--hits", type=int, default=24, help="Number of cherry-pick hits")
    gen_parser.add_argument("--volume", type=float, default=15.0, help="Transfer volume in uL")
    gen_parser.add_argument("--liquid-class", default="Standard_Aqueous", help="Spigot liquid class")
    gen_parser.add_argument("--output", "-o", default=None, help="Output CSV path (default: stdout)")

    # Sub-command: convert-tecan
    tecan_parser = subparsers.add_parser("convert-tecan", help="Convert Tecan .gwl to Spigot CSV")
    tecan_parser.add_argument("input_file", help="Path to Tecan .gwl file")
    tecan_parser.add_argument("--output", "-o", default=None, help="Output CSV path (default: stdout)")

    # Sub-command: convert-hamilton
    ham_parser = subparsers.add_parser("convert-hamilton", help="Convert Hamilton CSV to Spigot CSV")
    ham_parser.add_argument("input_file", help="Path to Hamilton worklist CSV")
    ham_parser.add_argument("--output", "-o", default=None, help="Output CSV path (default: stdout)")

    args = parser.parse_args()

    if args.command == "generate":
        rows = generate_cherry_pick_worklist(
            num_hits=args.hits,
            volume_ul=args.volume,
            liquid_class=args.liquid_class,
        )
        write_spigot_csv(rows, args.output)
    elif args.command == "convert-tecan":
        rows = convert_tecan_worklist(args.input_file)
        write_spigot_csv(rows, args.output)
    elif args.command == "convert-hamilton":
        rows = convert_hamilton_worklist(args.input_file)
        write_spigot_csv(rows, args.output)


if __name__ == "__main__":
    main()
