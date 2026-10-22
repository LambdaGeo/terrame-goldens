# Third-party material and licences

| Path | What it is | Origin | Licence |
|---|---|---|---|
| `lua/`, `scripts/`, `Makefile`, `packages.lock` | Our code: drivers that run the TerraME models and record their state, and the harness | this repository | MIT (`LICENSE`) |
| `goldens/` | Values computed by TerraME 2.0.1 running the models of the packages in `packages.lock`, plus our selection, organisation and hashes | this repository | see below |

## What is not stored here

The TerraME packages themselves are **not copied** into this repository. `scripts/fetch_packages.sh`
clones each one from its upstream repository at the commit fixed in `packages.lock`, and the run
scripts mount it into TerraME:

| Package | Upstream | Commit | Licence (as declared upstream) |
|---|---|---|---|
| `ca` 0.5.9 | [TerraME/ca](https://github.com/TerraME/ca) | `854a5c405478d712013a0baffd382f438f367642` (2018-09-25) | GPL (`description.lua`), GPL-3.0 text in `license.txt`; author Pedro R. Andrade |

## The goldens

The `goldens/` files are the output of upstream software (TerraME 2.0.1 and the packages above) run
with the default parameters of each model. What we add (the choice of cases and seeds, the file
format, the hashes and the documentation) is offered under CC-BY-4.0. Reuse the goldens with
attribution to this repository and to the authors of TerraME and of each package (INPE and
TerraLAB/UFOP).
