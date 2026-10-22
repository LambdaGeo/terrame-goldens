"""
Turn the raw output of the drivers (build/) into the published goldens.

- grids: build/ca/grids/<case>.csv  -> goldens/ca/grids/<case>.csv.gz
- ensembles: build/ca/ensembles/<case>.<seed>-<seed>.csv parts are joined,
  sorted by seed, into goldens/ca/ensembles/<case>.csv.gz
- sysdyn: build/sysdyn/<case>.csv -> goldens/sysdyn/<case>.csv.gz
- manifest.json (files, SHA-256, sizes, cases, package commits, generator)
- checksums.sha256 (for ``sha256sum -c``)

The gzip files are written without name or time stamp, so the same CSV
always gives the same .gz and the same SHA-256.

    python3 scripts/build_goldens.py --version v0.1.0 --generator "..."
"""
from __future__ import annotations

import argparse
import csv
import gzip
import hashlib
import io
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def write_gz(text: bytes, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    buf = io.BytesIO()
    with gzip.GzipFile(filename="", mode="wb", fileobj=buf, mtime=0, compresslevel=9) as gz:
        gz.write(text)
    dest.write_bytes(buf.getvalue())


def lock() -> list[dict]:
    out = []
    for line in (ROOT / "packages.lock").read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            name, url, commit = line.split()
            out.append({"name": name, "repository": url, "commit": commit})
    return out


def build_grids(src: Path, dst: Path) -> list[dict]:
    cases = list(csv.DictReader(open(src / "cases.csv", newline="")))
    for c in cases:
        write_gz((src / f"{c['case']}.csv").read_bytes(), dst / f"{c['case']}.csv.gz")
    (dst / "cases.csv").write_bytes((src / "cases.csv").read_bytes())
    return cases


PART = re.compile(r"^(?P<case>[a-z_]+)\.(?P<first>\d+)-(?P<last>\d+)\.csv$")


def build_ensembles(src: Path, dst: Path, seeds: int) -> list[dict]:
    parts: dict[str, list[tuple[int, Path]]] = {}
    for p in sorted(src.glob("*.csv")):
        m = PART.match(p.name)
        if m:
            parts.setdefault(m["case"], []).append((int(m["first"]), p))
    summary = []
    for case, files in sorted(parts.items()):
        found = sorted(first for first, _ in files)
        missing = sorted(set(range(1, seeds + 1)) - set(found))
        if missing:
            raise SystemExit(f"{case}: missing seeds {missing[:10]}{'...' if len(missing) > 10 else ''}")
        lines = ["seed,step,value,count"]
        for _, p in sorted(files):
            body = p.read_text().splitlines()
            assert body[0] == "seed,step,value,count", p
            lines.extend(body[1:])
        write_gz(("\n".join(lines) + "\n").encode(), dst / f"{case}.csv.gz")
        steps = max(int(line.split(",")[1]) for line in lines[1:])
        summary.append({"case": case, "seeds": seeds, "final_step": steps})
    return summary


def build_sysdyn(src: Path, dst: Path) -> list[dict]:
    cases = list(csv.DictReader(open(src / "cases.csv", newline="")))
    for c in cases:
        write_gz((src / f"{c['case']}.csv").read_bytes(), dst / f"{c['case']}.csv.gz")
    dst.mkdir(parents=True, exist_ok=True)
    (dst / "cases.csv").write_bytes((src / "cases.csv").read_bytes())
    return cases


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--build", default=str(ROOT / "build"))
    ap.add_argument("--version", required=True)
    ap.add_argument("--generator", required=True,
                    help="how TerraME was run (image digest, or binary and OS)")
    ap.add_argument("--seeds", type=int, default=50)
    args = ap.parse_args()

    build = Path(args.build)
    out = ROOT / "goldens"
    grids = build_grids(build / "ca" / "grids", out / "ca" / "grids")
    ensembles = build_ensembles(build / "ca" / "ensembles", out / "ca" / "ensembles", args.seeds)
    sysdyn = build_sysdyn(build / "sysdyn", out / "sysdyn")

    files = []
    for p in sorted(out.rglob("*")):
        if p.is_file():
            files.append({"path": p.relative_to(ROOT).as_posix(), "sha256": sha256(p),
                          "size_bytes": p.stat().st_size})
    drivers = {p.relative_to(ROOT).as_posix(): sha256(p) for p in sorted((ROOT / "lua").glob("*.lua"))}

    manifest = {
        "name": "terrame-goldens",
        "version": args.version,
        "generator": args.generator,
        "terrame": "2.0.1",
        "packages": lock(),
        "drivers": drivers,
        "ca": {"grids": grids, "ensembles": ensembles},
        "sysdyn": sysdyn,
        "files": files,
    }
    (ROOT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    (ROOT / "checksums.sha256").write_text(
        "".join(f"{f['sha256']}  {f['path']}\n" for f in files)
    )
    print(f"{len(files)} files, manifest.json and checksums.sha256 written")


if __name__ == "__main__":
    main()
