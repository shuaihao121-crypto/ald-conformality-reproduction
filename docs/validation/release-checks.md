# Release checks — v0.1.0

Review date: **2026-10-09**, Asia/Shanghai. MATLAB environment: **R2025b, 25.2.0.2998904, Windows 11, win64**. Full Table 2 scans and full-scale baselines were not executed for this archival release.

## Executed checks

| Check | Result and scope |
|---|---|
| Original source preservation | All 21 original `.m` files match the SHA-256 source manifest; the original engineering folder was not edited |
| MATLAB small-system smoke | **22 checks passed**, including three portable SHA-256 vectors, geometry, transport, coverage limits and A/B unit mapping |
| Small view-factor column conservation | Maximum absolute error 2.22×10⁻¹⁶; tolerance 2×10⁻¹³ |
| Area-weighted reciprocity | Maximum absolute error 2.22×10⁻¹⁶; tolerance 2×10⁻¹³ |
| FFT versus dense products | Maximum absolute error 4.44×10⁻¹⁶ over three probes; tolerance 2×10⁻¹³ |
| Partial-surface absorption + escape | Probability closure error 4.44×10⁻¹⁶; tolerance 2×10⁻¹² |
| Fully covered surface | Escape probability equals 1 within 2.22×10⁻¹⁶; adsorption probability is zero |
| No half-coverage front | Half depth and slope return NaN. Low-coverage raw broadness can be zero and is excluded by entrance screening |
| Matched-dose small geometry | Profile difference is zero for the tested 2 Pa × 0.001 s and 8 Pa × 0.00025 s pair; step counts match |
| A pressure boundary and unit mapping | Finite zero-collision Knudsen limit, inlet pA=pA0, physical pressure interval, and q·s₀=1 checks pass |
| Legacy-script isolation | A synthetic clear/clc script leaves the outer sentinel intact, restores the working directory and retains baseline metadata rather than its last parameter override |
| Historical replot | **26/26/24** valid pairs; ratios **1.4858283832 / 1.9894567185 / 2.7564552931** reproduced from CSV without model integration |
| Figure exports | PNG, vector PDF and SVG generated; PNG inspected for readable axes, legends and uncropped scientific content |
| License copies | Exact upstream license byte hashes match the retained provenance records |
| Citation metadata | CITATION.cff passes the official CFF 1.2.0 JSON schema, including format validation |
| New MATLAB code analysis | 16 added MATLAB files inspected; no syntax diagnostic. One renderer-option recommendation is retained for older-release compatibility, along with informational annotation diagnostics |

[Machine-readable smoke results](smoke_checks.json) · [Historical replot summary](replot_summary.json) · [Citation schema check](citation-check.json) · [Code Analyzer record](code-analysis.json)

The smoke geometry is AR=5, fs=4. Its small integration examples use β₀=0.1 and ep=0.05. These checks test meaningful structural and numerical invariants; they are not mesh/time-step convergence evidence for the full research parameter sweep.

Task output and warning text are captured with `evalc`, without changing the user's diary state. MATLAB and Python validate the actual source bytes. The portable hash implementation is exercised explicitly, even when a JVM is available.

## Packaging and portability

The final source ZIP excludes generated runs, `.asv` files, private reports/chats and machine-local authentication material. A release manifest records file sizes and SHA-256 hashes; the ZIP has a separate SHA-256 checksum.

**Fresh ZIP extraction passed in a new MATLAB process**, from a working directory outside the extracted repository: help, all 22 small-system checks, 21 source hashes, historical pair counts and PNG/PDF/SVG exports. Unknown output options were rejected. A deliberately changed source file in the temporary extracted work copy was rejected before simulation; its failed manifest, workspace and log were preserved, and the original bytes were restored. The delivered source directory was never changed by that negative fixture. [Machine-readable portability check](fresh-archive-check.json)

The Python archive checker also passed on the restored extracted copy. It checks local Markdown file targets, source preservation, the 82-row archive, transcription, parameter mappings, missingness, screening and statistics. It does not execute MATLAB. The workflow is provided for GitHub; no hosted Actions run has been claimed before upload.

R2020a is the wrapper compatibility target, but **only R2025b has been executed**. The presence of a script or CI configuration does not establish numerical validation of an unexecuted scan.

## Previously observed scientific limitations

These observations come from the preceding investigation and are retained as context; they are separate from the small-system checks above:

- The original B solver can return an unconverged iterate and continue after a warning. An AR=4000, fs=4 fully covered transport check from its default initial guess returned flag=1, residual≈1.505×10⁻⁴ and probability closure error≈4.319×10⁻³. This does not prove every warm-start trajectory fails, but rules out unconditional full-range reliability.
- Model A's inherited persistent pressure is updated on RHS evaluations. High-reactivity entrance values can differ from an independent analytic inlet solution, affecting the historical 0.999 mask.
- High-β B scan results use larger ep values without a fine-step convergence study.
- Full eight-case historical slope/broadness aggregates lack the individual Case VIII A values needed for an independent reconstruction.

[Numerical notes](../zh/numerics.md) · [Result evidence and differences](../zh/results.md) · [History coverage](history-coverage.md)
