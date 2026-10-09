# Historical evidence coverage

Archive review date: **2026-10-09**, Asia/Shanghai. This release organizes existing results. The CSV and parity plots do not represent a new MATLAB simulation.

## What was accessible

The desktop application exposed the following conversation records from the reproduction project:

| Conversation title | Turns returned |
|---|---:|
| 梳理KMC复现任务 | 3 |
| week1 | 5 |
| week2 | 5 |
| week3 | 5 |
| 复现任务梳理 | 5 |
| week4, active | 5 |
| week4, archived | 3 |
| **Total** | **31** |

Requests with two turns per page were followed until the application returned no cursor and no further page. Larger requests exposed the same records. These are the records available through that interface, **not proof that the full original conversation history was retrieved**. Earlier teaching and implementation stages were mentioned but were not exposed. An archived week4 assistant response was truncated at the supported 20,000-character limit. Uploaded attachment contents were not embedded in conversation text; the original MATLAB sources were inspected separately.

Private meeting notes, general conversation text, and original publisher PDFs are not part of this repository. Only a scientific console-output excerpt needed to audit the data transcription is retained.

## Dataset provenance and precision

[metrics.csv](../../data/historical/metrics.csv) contains **82 rows: 41 Model A and 41 Model B entries**, keyed by model, case number, and run index. [sources.json](../../data/historical/sources.json) records metric conventions, source identity, baseline SI parameters, the corresponding settings for each case, and known omissions.

| Source | Available evidence | Precision retained |
|---|---|---|
| Model A, Cases I-VII | User-supplied MATLAB stdout: entrance coverage, half-coverage position, slope, broadness for 36 cases | Entrance and slope: six decimal places; position and broadness: three |
| Model A, Case VIII | Five pressure/time pairs and half-coverage positions | Pressure/time: two decimal places; position: six |
| Model B | Arrays and validity masks retained in the preserved comparison script | Numeric literals retained exactly as written |

The [Model A scientific excerpt](../../data/historical/model_a_comparison_log.txt) comes from a week3 user message dated 2026-10-04 14:01:01, Asia/Shanghai. It is a historical console record, not a test log produced during this release review. Model B arrays are transcribed programmatically from [compare_modelAB.m](../../src/ModelA_Reproduction/compare_modelAB.m). That script itself copied earlier B results; it does not contain their complete profiles, entrance coverages, or solver diagnostics.

The original 21 MATLAB sources are preserved byte for byte against [source_manifest.json](../../data/source_manifest.json). Their hash capture date is 2026-10-08; the later archive review date does not alter that source snapshot.

### Missing values and screening

- **recorded:** a finite metric was retained in the source.
- **no_crossing:** Model A stdout explicitly printed NaN; its preserved extraction code has no required threshold crossing in that case.
- **not_recorded:** the available source omitted the metric. This includes all Case VIII A slopes/broadness values and B source-array NaNs. A screened B NaN does not establish why the raw metric was omitted.

Empty numeric CSV cells must be interpreted with their status column. They are not zeros. Model A Case VIII entrance coverages, slopes, broadness values, and masks remain unavailable; both validity masks are **unknown**. Model B masks preserve the comparison script's historical true/false flags. Model A Cases I-VII masks apply the preserved entrance threshold of 0.999 and the recorded existence of threshold crossings. Model B's historical screening threshold was 0.995; no missing B entrance coverage is fabricated from it.

Some original A entrance values slightly exceed one. They are preserved as recorded numerical outputs, not clamped during archival. Repeated baseline entries from different parameter cases are also retained: removing them would change the historical aggregation.

## What can be recomputed from the retained numbers

[historical_summary.json](../../data/historical/historical_summary.json) keeps source-reported aggregates separate from arithmetic that can be independently reproduced from the archived point data.

| Cases I-VII only | Paired entries | Recomputed mean |
|---|---:|---:|
| B/A half-coverage penetration | 26 | 1.4858283832 |
| A/B half-coverage slope | 26 | 1.9894567185 |
| B/A adsorption-front broadness | 24 | 2.7564552931 |

The historical console reported all-case counts of **31 / 31 / 29** and mean ratios of **1.4867 / 1.9657 / 2.6226**. Those reported aggregates must not be labelled as independently reproduced slope/broadness statistics.

Including the five recorded Case VIII half-coverage positions gives a penetration ratio of 1.486709455253 and an increase of 48.6709455253%, which round to the reported 1.4867 and 48.67%. This is a **conditional arithmetic check** using the reported all-case inclusion count. It does not recover the missing Case VIII entrance mask. Missing Case VIII slopes and broadness are not filled using baseline values, means, or image-derived coordinates.

The clean three-panel historical parity plot consequently uses Cases I-VII, with **26 / 26 / 24** pairs. Previously rendered historical images can show the original larger aggregation, but they are separate evidence and are not coordinate sources for the CSV.

## Scope of automated checks

[validate_repository.py](../../checks/validate_repository.py) uses only the Python standard library. It checks source hashes and inventory, autosave exclusion, the CSV contract, exact A-log and B-array transcription, missing-value semantics, preserved masks, SI parameter mapping, constant-exposure pairs, high-reaction-probability step settings, historical arithmetic, and local Markdown/image links.

The GitHub workflow runs these **archive checks only**. A passing run does not establish MATLAB solver convergence, physical validity, full-paper replication, or experimental validation. Missing historical profiles and solver diagnostics cannot be reconstructed by packaging the source code.

