#!/usr/bin/env python3
"""
Spigot Statistical Report and Curve Generator
Analyzes pipetting accuracy, precision (%CV), and renders ASCII calibration curves.
"""

import argparse
import math
import sys


def calculate_precision_stats(volumes):
    """Computes mean, standard deviation, and coefficient of variation (%CV)."""
    if not volumes:
        return {"n": 0, "mean": 0.0, "std": 0.0, "cv_percent": 0.0}

    n = len(volumes)
    mean = sum(volumes) / n
    if n > 1:
        variance = sum((x - mean) ** 2 for x in volumes) / (n - 1)
        std = math.sqrt(variance)
    else:
        std = 0.0

    cv = (std / mean * 100.0) if mean > 0.0 else 0.0
    return {
        "n": n,
        "mean": mean,
        "std": std,
        "cv_percent": cv,
        "min": min(volumes),
        "max": max(volumes),
    }


def render_ascii_histogram(volumes, bins=10, width=40):
    """Renders an ASCII frequency distribution histogram."""
    if not volumes:
        return "No volume data to plot."

    min_val = min(volumes)
    max_val = max(volumes)
    if min_val == max_val:
        return f"All {len(volumes)} values exactly equal {min_val:.3f} uL"

    bin_width = (max_val - min_val) / bins
    counts = [0] * bins

    for v in volumes:
        idx = int((v - min_val) / bin_width)
        if idx >= bins:
            idx = bins - 1
        counts[idx] += 1

    max_count = max(counts)
    lines = ["\n=== VOLUME DISTRIBUTION HISTOGRAM ==="]
    for i in range(bins):
        low = min_val + i * bin_width
        high = low + bin_width
        bar_len = int((counts[i] / max_count) * width) if max_count > 0 else 0
        bar = "#" * bar_len
        lines.append(f"[{low:6.2f} - {high:6.2f} uL] ({counts[i]:3d}) | {bar}")
    lines.append("=====================================\n")
    return "\n".join(lines)


def render_ascii_sigmoidal_curve(bottom=0.05, top=2.50, ec50=10.0, hill=1.2, width=50, height=15):
    """Renders an ASCII plot of a 4-Parameter Logistic (4PL) sigmoidal curve."""
    lines = [f"\n=== 4PL CALIBRATION CURVE (EC50={ec50:.2f}, Hill={hill:.2f}) ==="]
    # Log concentration span from 0.01 * EC50 to 100 * EC50
    log_min = math.log10(ec50) - 2.0
    log_max = math.log10(ec50) + 2.0

    y_grid = [[" " for _ in range(width)] for _ in range(height)]

    for col in range(width):
        frac_x = col / (width - 1)
        log_x = log_min + frac_x * (log_max - log_min)
        x = 10.0 ** log_x

        # 4PL equation: y = D + (A - D) / (1 + (x / C)^B)
        # bottom=A, top=D, ec50=C, hill=B
        y = top + (bottom - top) / (1.0 + (x / ec50) ** hill)

        frac_y = (y - bottom) / (top - bottom) if top > bottom else 0.5
        row = int((1.0 - frac_y) * (height - 1))
        row = max(0, min(height - 1, row))
        y_grid[row][col] = "*"

    for r_idx, row in enumerate(y_grid):
        y_val = top - (r_idx / (height - 1)) * (top - bottom)
        row_str = "".join(row)
        lines.append(f"{y_val:6.2f} | {row_str}")

    lines.append("       +" + "-" * width)
    lines.append(f"        {10**log_min:6.2e}" + " " * (width - 18) + f"{10**log_max:6.2e} [Conc]")
    lines.append("========================================================\n")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Spigot Statistical Report & Curve Visualizer"
    )
    parser.add_argument("--demo", action="store_true", help="Generate synthetic precision and 4PL curve report")
    parser.add_argument("--nominal", type=float, default=20.0, help="Nominal target volume in uL")
    args = parser.parse_args()

    if args.demo:
        # Generate 96 simulated dispenses with nominal 20 uL and 1.8% CV
        import random
        rng = random.Random(42)
        dispenses = [rng.gauss(args.nominal, args.nominal * 0.018) for _ in range(96)]

        stats = calculate_precision_stats(dispenses)
        print("=== SPIGOT LIQUID HANDLING PRECISION REPORT ===")
        print(f"Sample Count (N):    {stats['n']}")
        print(f"Nominal Target:      {args.nominal:.2f} uL")
        print(f"Mean Volume:         {stats['mean']:.4f} uL")
        print(f"Std Deviation:       {stats['std']:.4f} uL")
        print(f"Precision (%CV):     {stats['cv_percent']:.2f}%")
        print(f"Min / Max Volume:    {stats['min']:.4f} / {stats['max']:.4f} uL")
        print(f"Inaccuracy (Bias):   {((stats['mean'] - args.nominal) / args.nominal * 100.0):+.2f}%")
        print("===============================================")

        print(render_ascii_histogram(dispenses, bins=8))
        print(render_ascii_sigmoidal_curve(bottom=0.08, top=2.85, ec50=12.5, hill=1.15))
    else:
        print("Run with --demo to view sample precision distribution and 4PL curve.")


if __name__ == "__main__":
    main()
