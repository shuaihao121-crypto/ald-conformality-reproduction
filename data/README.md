# Data and evidence

This directory holds source provenance and recoverable historical metrics, rather than a fresh full-scale simulation dataset.

| File | Role |
|---|---|
| [source_manifest.json](source_manifest.json) | SHA-256 hashes of the 21 unchanged historical MATLAB sources |
| [historical/metrics.csv](historical/metrics.csv) | 41 conditions per model, with explicit value and validity status |
| [historical/sources.json](historical/sources.json) | Origin, precision, extraction method and missing-data limitations |
| [historical/historical_summary.json](historical/historical_summary.json) | Independently recomputed seven-case statistics and separately recorded full-series aggregates |

`replot-historical` selects Cases I–VII and requires both models' validity masks and recorded finite values. It retains repeated baseline entries as separate members of their original parameter series. Model B is the x-coordinate and Model A the y-coordinate.

## Missingness

The archive distinguishes:

- **recorded:** a numerical value appears in the source;
- **no_crossing:** the Model A log printed `NaN`, consistent with its extraction function lacking the required crossing;
- **not_recorded:** the available source did not retain a raw numerical value.

Some B array entries are `NaN` after historical filtering; their underlying raw values are unavailable, so they are represented as `not_recorded`, without claiming a specific physical cause. Case VIII A slope, broadness and entrance coverage are also unrecorded. Unknown validity is retained as `unknown`.

The historical CSV is intentionally limited to the precision available in printed logs or hard-coded arrays. More digits in a newly computed mean do not restore the missing precision of its inputs.

## New computations

The MATLAB runner writes fresh results under `results/`, or an explicit output directory. These outputs are ignored by Git and are excluded from the source ZIP. Archive a future run deliberately, together with its physical parameters, numerical settings, source hashes, environment, warnings and validity policy, before treating it as a published dataset.

The release packager additionally creates `release_manifest.json`, a byte-size and SHA-256 inventory of the delivered files. It excludes generated runs and does not hash itself.
