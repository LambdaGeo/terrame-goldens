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
| `sysdyn` 0.8.3 | [TerraME/sysdyn](https://github.com/TerraME/sysdyn) | `9e671cb86ee33143bd910f1243bc71f2d1c5e5a9` (2020-08-20) | GPL (`description.lua`), GPL-3.0 text in `license.txt`; authors Gilberto Camara and Pedro R. Andrade |
| `logo` 0.5.6 | [TerraME/logo](https://github.com/TerraME/logo) | `bb57a26ad198694c4ae4170ab3b77b1f08f73e87` | GPL (`description.lua`), GPL-3.0 text in `license.txt`; author Pedro R. Andrade |
| `sci` 0.5 (used by `sysdyn`'s MonoLake) | [TerraME/sci](https://github.com/TerraME/sci) | `42b0b3e319b6b6fe7bc2d3566e23876db12a2bac` | GPL (`description.lua`), GPL-3.0 text in `license.txt`; author Gilberto Camara |

## The goldens

The `goldens/` files are the output of upstream software (TerraME 2.0.1 and the packages above) run
with the default parameters of each model. What we add (the choice of cases and seeds, the file
format, the hashes and the documentation) is offered under CC-BY-4.0. Reuse the goldens with
attribution to this repository and to the authors of TerraME and of each package (INPE and
TerraLAB/UFOP).
