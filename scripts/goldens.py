"""
Read the goldens from Python (NumPy and the standard library only).

    from goldens import load_grid, load_ensemble
    steps = load_grid("goldens/ca/grids/parity.csv.gz")   # (step, y, x) array of str
    ens = load_ensemble("goldens/ca/ensembles/growth.csv.gz")
    ens["alive"]                                           # (seed, step) array of counts

A grid golden holds the state of every cell before the first step (step 0)
and after every step; row ``y`` and column ``x`` are TerraME's coordinates.
"""
from __future__ import annotations

import csv
import gzip
from pathlib import Path

import numpy as np


def load_grid(path: str | Path) -> np.ndarray:
    """Array of shape (steps + 1, ydim, xdim) with the cell values as strings."""
    with gzip.open(path, "rt", newline="") as f:
        rows = list(csv.reader(f))
    header, body = rows[0], rows[1:]
    nx = len(header) - 2
    steps = max(int(r[0]) for r in body) + 1
    ny = max(int(r[1]) for r in body) + 1
    out = np.empty((steps, ny, nx), dtype=object)
    for r in body:
        out[int(r[0]), int(r[1])] = r[2:]
    return out


def load_ensemble(path: str | Path) -> dict[str, np.ndarray]:
    """``{value: counts}`` with counts of shape (seeds, steps + 1); absent = 0."""
    with gzip.open(path, "rt", newline="") as f:
        rows = list(csv.DictReader(f))
    seeds = sorted({int(r["seed"]) for r in rows})
    steps = max(int(r["step"]) for r in rows) + 1
    index = {s: i for i, s in enumerate(seeds)}
    out: dict[str, np.ndarray] = {}
    for r in rows:
        arr = out.setdefault(r["value"], np.zeros((len(seeds), steps), dtype=int))
        arr[index[int(r["seed"])], int(r["step"])] = int(r["count"])
    return out
