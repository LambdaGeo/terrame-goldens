# terrame-goldens

**Reference execution outputs (goldens) of the TerraME 2.0.1 model packages.**

This repository holds what TerraME itself computes when it runs the models of
its packages, so that re-implementations can be checked against TerraME, and
not against someone's reading of the Lua code. It plays for the cellular
automata, system dynamics and agent-based models of TerraME the role that
[`luccme-goldens`](https://github.com/LambdaGeo/luccme-goldens) plays for
LuccME, and it was made to verify the DisSModel extensions:

| TerraME package | DisSModel extension | Suite here |
| --- | --- | --- |
| [`ca`](https://github.com/TerraME/ca) | [`dissmodel-ca`](https://github.com/DisSModel/dissmodel-ca) | `goldens/ca/` (this version) |
| [`sysdyn`](https://github.com/TerraME/sysdyn) | [`dissmodel-sysdyn`](https://github.com/DisSModel/dissmodel-sysdyn) | `goldens/sysdyn/` (this version) |
| [`logo`](https://github.com/TerraME/logo) | [`dissmodel-abm`](https://github.com/DisSModel/dissmodel-abm) | planned |

## What can be compared, and how

TerraME and NumPy draw different random numbers, so a run with random draws
cannot be reproduced value by value in Python. The goldens are therefore of
two kinds:

- **Grids** (`goldens/ca/grids/`): the state of every cell before the first
  step and after every step, for the models whose rule is deterministic. Some
  of them draw their initial state at random (seed 1); the file records that
  state, so a re-implementation starts from it and must then match **cell by
  cell at every step**.
- **Ensembles** (`goldens/ca/ensembles/`): for the models that draw random
  numbers while they run, the number of cells in each state after every step,
  for seeds 1 to 50. A re-implementation is compared by distribution (for
  example, whether its runs fall within the range of TerraME's runs).

### Suite `ca` (package `ca` 0.5.9, commit `854a5c4`)

Default parameters and `finalTime` of each model.

| Golden | Model | Kind | Steps | Grid | Initial state |
| --- | --- | --- | --- | --- | --- |
| `life_glider` | Life, `pattern = "glider"` | grid | 100 | 30 × 30 | fixed |
| `life_rpentomino` | Life, `pattern = "rPentomino"` | grid | 100 | 30 × 30 | fixed |
| `life_random` | Life | grid | 100 | 30 × 30 | random, seed 1 |
| `parity` | Parity | grid | 500 | 50 × 50 | fixed |
| `excitable` | Excitable | grid | 500 | 50 × 50 | fixed |
| `wolfram_30`, `wolfram_90`, `wolfram_110` | Wolfram, `rule = 30, 90, 110` | grid | 55 | 111 × 56 | fixed |
| `fire` | Fire | grid and ensemble | 100 | 60 × 60 | random |
| `anneal` | Anneal | grid | 100 | 80 × 80 | random, seed 1 |
| `oscillator` | Oscillator | grid | 400 | 50 × 50 | random, seed 1 |
| `parasit` | Parasit | grid | 500 | 50 × 50 | random, seed 1 |
| `growth` | Growth | ensemble | 100 | 100 × 100 | fixed |
| `snow` | Snow | ensemble | 600 | 50 × 50 | fixed |
| `solid_diffusion` | SolidDiffusion | ensemble | 400 | 31 × 31 | fixed |
| `interspecific_competition` | InterspecificCompetition | ensemble | 200 | 40 × 40 | fixed |

Not included: `BandedVegetation`, `DaisyWorld` (the cellular version),
`Influenza` and `LifePatterns`, which have no DisSModel port yet.

### Suite `sysdyn` (package `sysdyn` 0.8.3, commit `9e671cb`; `sci` commit `42b0b3e`)

The value of each state variable before the first step and after every
step, written with 17 significant digits (enough to recover every double
exactly), for the default parameters and a few of the choices the models
offer. All of them are deterministic, except RandomWalk, recorded for seeds
1 to 50 in one file (`seed, step, value`).

| Golden | Model | Steps | Variables |
| --- | --- | --- | --- |
| `chaotic_growth` | ChaoticGrowth | 300 | `pop` |
| `coffee` | Coffee | 20 | `temperature` |
| `daisyworld` | Daisyworld | 100 | `whiteArea`, `blackArea`, `emptyArea`, `aveTemp`, `tempNearWhite`, `tempNearBlack` |
| `homeostasis`, `homeostasis_100` | Homeostasis, `stock = 0, 100` | 30 | `stock` |
| `limited_growth` | LimitedGrowth | 100 | `pop` |
| `lorenz` | Lorenz | 10000 | `x`, `y`, `z` |
| `mono_lake`, `mono_lake_export_50` | MonoLake, `export = 100, 50` | 50 | `waterInLake`, `level` |
| `population_growth` | PopulationGrowth | 7 | `population`, `growth` |
| `predator_prey` | PredatorPrey | 500 | `prey`, `predator` |
| `room_temperature` | RoomTemperature | 24 | `inside`, `outside` |
| `sir` | SIR | 30 | `susceptible`, `infected`, `recovered`, `contacts` |
| `tub` | Tub | 8 | `water` |
| `yeast`, `yeast_rate_2` | Yeast, `rate = 1.1, 2` | 9 | `cells` |
| `random_walk` | RandomWalk (50 seeds) | 100 | `value` |

A variable that does not exist yet at step 0 (`tempNearWhite` and
`tempNearBlack` of Daisyworld) is left empty in that row. In Tub, the inflow
event starts at `t = 10`, after `finalTime = 8`, so it never runs: the golden
records the model as it is.

### File formats

A grid golden (`<case>.csv.gz`) is a stack of grids: one row per step and
grid row, with the columns `step, y, x0, x1, ...`; the values are TerraME's
own (`"alive"`, `"burning"`, `3`, ...). `cases.csv` lists the model,
arguments, seed, final time and size of each case.

An ensemble golden (`<case>.csv.gz`) has the columns `seed, step, value,
count`; a state that no cell has in a step is not listed.

SolidDiffusion only swaps atoms, so its counts per state never change. Its
ensemble also has two spatial counts as extra values: `atom1_right`, the
`atom1` cells to the right of the middle column, and `atom2_left`, the
`atom2` cells to its left, which measure how far the atoms have mixed.

A sysdyn golden (`<case>.csv.gz`) has a column `step` and one column per
variable.

`scripts/goldens.py` reads the grids and ensembles with NumPy:

```python
from goldens import load_grid, load_ensemble

grid = load_grid("goldens/ca/grids/parity.csv.gz")     # (step, y, x), strings
ens = load_ensemble("goldens/ca/ensembles/growth.csv.gz")
ens["alive"]                                           # (seed, step) counts
```

Coordinates are TerraME's: `x` is the column, `y` the row, both from 0. A
TerraME `Timer` runs `t = 1, ..., finalTime`; step 0 is the state after the
model's `init`. In DisSModel, `Environment(start_time=1, end_time=finalTime)`
runs the same steps.

## Regenerating the goldens

The goldens were generated by the drivers in `lua/`, which run each model
unchanged and record it with an extra `Event` that runs after the model's
events (`lua/common.lua`). Graphics are turned off and every run starts with
`Random{seed = ...}`, so a run does not depend on the clock.

With Docker (the `terrame-docker` image; the `ca` package is cloned on the
host at its fixed commit and mounted into the image):

```bash
make run-docker                    # raw output in build/
make build VERSION=v0.1.0 GENERATOR="profsergiocosta/terrame-luccme@sha256:..."
make check                         # sha256sum -c checksums.sha256
```

Without Docker, with TerraME 2.0.1 installed (`TME_PATH`, `xvfb-run`, and the
packages of `packages.lock` in `$TME_PATH/packages`): `make run-local`.

Each ensemble seed runs in its own TerraME process: TerraME does not free the
cellular space of a finished model, so many seeds in one process run out of
memory.

`manifest.json` records the generator, the package commits, the SHA-256 of
each driver and the SHA-256 and size of each golden.

### How this version was generated

Version v0.1.0 was generated with the official TerraME 2.0.1 binary (the
same file, checked by SHA-256, that the `terrame-docker` image installs) run
directly on Ubuntu 24.04 under Xvfb, with `libtiff.so.6` standing in for the
`libtiff.so.5` of Ubuntu 18.04; not inside the image. Before generating, the
packages' own test suites were run in that setup. `ca`: 964 of 965 asserts
passed, including every map snapshot of the models above; the one failure is
a chart image of `Influenza` (2.9 % of the pixels differ, tolerance 0), a
model that is not in these goldens. `sysdyn`: 35 of 36 asserts passed; the
failure is the final value of `RandomWalk` with the test framework's seed (a
test last updated in 2017), and the `Tub` test stops because the test mode
treats `start = 10`, the default value, as an error (in a normal run it is a
warning). The runs are deterministic: running a driver twice gives
byte-identical files.

`make run-docker` followed by `make build` and `make check` regenerates
everything in the image; the hashes should match those of `checksums.sha256`.

## Licence

Code: MIT. Goldens: CC-BY-4.0 for what we add; see
[`THIRD_PARTY.md`](THIRD_PARTY.md) for the packages and their licences.
