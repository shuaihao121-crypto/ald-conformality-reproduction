# Third-party notices and scientific attribution

The original physical models and public implementations remain credited to their authors. This archive preserves the local MATLAB reproduction sources and documents their relationship to DReaM-ALD and Machball. New packaging, recording, checking and documentation code is maintained by Zihao Bai under the root [MIT License](LICENSE); that license does not remove third-party notices or reassign authorship of the models.

## DReaM-ALD — Model A implementation lineage

- Authors: Emma Verkama and Riikka L. Puurunen, Aalto University.
- Upstream project: [Aalto-Puurunen/dream-ald](https://github.com/Aalto-Puurunen/dream-ald).
- Reviewed version: **v1.0.0**, commit `11311d0df0ea032329c399649e4d8c6f77ab0e7f`.
- Archived software citation: [DOI 10.5281/zenodo.7759195](https://doi.org/10.5281/zenodo.7759195).
- License: **MIT**. The exact reviewed license text is retained in [licenses/third-party-dream-ald-v1.0.0.txt](licenses/third-party-dream-ald-v1.0.0.txt).
- Copyright notice retained verbatim: `Copyright 2023 (c) Emma Verkama and Riikka Puurunen, Aalto University`.

The local Model A implements the analytical pressure approximation and Langmuir coverage equation described by Ylilammi et al. and the target comparison paper. Its persistent pressure-history approach and nonzero integration start have public DReaM-ALD precedent. The local decomposition into functions, parameter choices, metric extraction and solver-tolerance call differ from the upstream script; the archive does not claim byte equivalence with upstream DReaM-ALD.

Upstream source files examined include [ALDoriginal.m](https://github.com/Aalto-Puurunen/dream-ald/blob/11311d0df0ea032329c399649e4d8c6f77ab0e7f/script/ALDoriginal.m), [dthetadt.m](https://github.com/Aalto-Puurunen/dream-ald/blob/11311d0df0ea032329c399649e4d8c6f77ab0e7f/script/dthetadt.m) and [dpAdt.m](https://github.com/Aalto-Puurunen/dream-ald/blob/11311d0df0ea032329c399649e4d8c6f77ab0e7f/script/dpAdt.m).

## Machball — Model B implementation lineage

- Authors credited by the comparison paper: Angel Yanguas-Gil and Jeffrey W. Elam.
- Copyright holder: UChicago Argonne, LLC.
- Upstream project: [aldsim/machball](https://github.com/aldsim/machball).
- Reviewed version: **0.2.0**, commit `ef903bde5fd456c9f85bfd83a5b92140100b33fe`.
- License: **BSD 3-Clause-style terms**. The exact license supplied by this tag is retained in [licenses/third-party-machball-0.2.0.txt](licenses/third-party-machball-0.2.0.txt).
- Copyright notice retained verbatim: `Copyright 2013, UChicago Argonne, LLC`.

The upstream license file at the 0.2.0 tag still contains the literal line `Machball, Version 0.1.0`. It is preserved exactly, not corrected or replaced with the tag name. Source and binary redistribution conditions, the non-endorsement clause and warranty disclaimer remain applicable to inherited or adapted components as set out in that file. Naming the source and authors here records provenance and does not imply their endorsement of this reproduction.

The local MATLAB Model B follows the upstream slit/trench view factors, absorbing Markov-chain solve and implicit `dose_ideal` update with ordinary `ep=0.05`. It adds a Toeplitz/FFT matrix-free product, BiCGSTAB and warm starts for large structures. Certain high-reactivity scan points use larger local `ep` values. These adaptations and their limitations are documented in [the numerical notes](docs/zh/numerics.md).

Upstream source files examined include [structure.py](https://github.com/aldsim/machball/blob/ef903bde5fd456c9f85bfd83a5b92140100b33fe/machball/ballistic/structure.py), [viewfactors.py](https://github.com/aldsim/machball/blob/ef903bde5fd456c9f85bfd83a5b92140100b33fe/machball/ballistic/viewfactors.py) and [ballistic.py](https://github.com/aldsim/machball/blob/ef903bde5fd456c9f85bfd83a5b92140100b33fe/machball/ballistic/ballistic.py).

## Paper and other research references

The target paper is Järvilehto et al., *Physical Chemistry Chemical Physics* 25, 22952–22964 (2023), [DOI 10.1039/D3CP01829F](https://doi.org/10.1039/D3CP01829F). Original model descriptions and software references appear in [references.bib](references.bib), including target-paper references 9, 10, 12, 31 and 32.

The paper PDF and original private chats/reports are not redistributed in this repository. Historical numerical extracts and selected original reproduction-result screenshots are accompanied by provenance; the new parity figure uses recorded metrics rather than copies of the publisher's figures. Scientific statements should be attributed to the relevant paper or historical reproduction record, not presented as new experimental discoveries.

## Integrity of license copies

[licenses/third-party-provenance.json](licenses/third-party-provenance.json) records the reviewed tags, commit-pinned raw license URLs, local filenames, retrieval date and SHA-256 of the exact upstream bytes. This is license provenance; the local numerical-source hashes are separately recorded in [data/source_manifest.json](data/source_manifest.json).
