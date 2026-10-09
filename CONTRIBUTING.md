# Contributing

Contributions should preserve a clear connection between model assumptions, numerical settings and scientific claims.

## Reporting a result or issue

Include the task name, MATLAB release, full physical parameters, numerical controls, source revision or hashes, and the run manifest. Attach the relevant warning or diagnostic output. Distinguish a historical record from a newly computed result.

## Changing the scientific implementation

The source files under `src/` are the preserved historical implementation. Propose scientific changes as a separately named implementation or a clearly versioned follow-up release. Document the equation or upstream source that motivates the change, and compare the changed implementation with the preserved one under matched parameters.

Use targeted checks that test a physical or numerical invariant: probability conservation, view-factor reciprocity, dense/operator agreement, analytic limits, or convergence under grid and time-step refinement. A plot that looks similar is not a numerical error bound.

## Adding historical records

Retain the original precision and a verifiable source. Keep unrecorded values separate from a solver-produced `NaN`. State the screening policy and the reason a point was excluded. Do not reconstruct missing metrics from aggregate means or digitize screenshots without explicitly describing a separate digitization dataset and its uncertainty.

Before proposing a change, run:

```sh
python checks/validate_repository.py
```

For changes to MATLAB packaging or transport checks, also run `ald_repro('smoke')` and include its manifest. Preserve third-party copyright and license notices.
