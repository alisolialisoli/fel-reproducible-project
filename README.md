# Reproducible analysis of a multicolor helical GENESIS simulation

## Project overview
This project provides a reproducible post-processing workflow for a multicolor
helical HGHG FEL simulation with three output branches: **H7, H6, and H5**.

Starting from the original GENESIS input files and raw HDF5 simulation data,
the workflow regenerates:
- final temporal pulse profiles
- spectra from the final field snapshots
- transverse coherent intensity profiles
- peak power evolution along the radiator chain
- pulse energy evolution along the radiator chain
- a summary table of pulse metrics, including peak power, pulse energy, and FWHM

The main goal of the project is to improve reproducibility through:
- explicit software environment documentation
- structured data organization
- clear metadata
- an automated analysis workflow

This project was developed as a course project inspired by the principles of
reproducible computational research.

## Author
**Ali Soleimani**  
PhD candidate  
University of Trieste / FERMI, Elettra Sincrotrone Trieste

## Contact
For questions about the raw data, workflow, or analysis structure, please
contact the author.

## Scientific context
Seeded free-electron lasers can generate highly coherent radiation with precise
control over wavelength and temporal structure. In this project, the selected
case is a **multicolor helical HGHG** simulation producing three final output
branches:
- **H7** at approximately **51.43 nm**
- **H6** at **60.00 nm**
- **H5** at **72.00 nm**

All three branches are analyzed at the **end of RAD6**, using final radiation
field snapshots and longitudinal evolution diagnostics produced by GENESIS 4.

## Simulation setup overview

```text
Multicolor helical HGHG setup (schematic)

Seed (360 nm)
    |
    v
---------     ---------     ---------------------------------------------------------------
|  MOD  | --> |  R56  | --> | RAD1 | RAD2 | RAD3 | RAD4 | RAD5 | RAD6 |
---------     ---------     ---------------------------------------------------------------
                            |- H7 branch -|------ propagate to RAD6 --------->

                                          |- H6 branch -|------ to RAD6 ----->

                                                        |-H5 branch --------->

Outputs at the end of RAD6:
  H7 --> FIELD_END_RAD6_BRANCH_A.fld.h5
  H6 --> FIELD_END_RAD6_BRANCH_B.fld.h5
  H5 --> FIELD_END_RAD6_BRANCH_C.fld.h5


## Workflow
The complete analysis is executed through the main MATLAB script
`workflow/run_all.m`, which serves as the entry point of the project. Starting
from the raw GENESIS HDF5 output files stored in `data/raw/`, the workflow
automatically reproduces the main analysis products of the selected simulation
case. In particular, it checks that the required input files are present, loads
the three simulation branches, computes the temporal pulse profiles, computes
the spectra from the final field snapshots, generates transverse coherent
intensity plots, extracts the peak-power evolution and pulse-energy evolution
along the radiator chain, and saves the generated figures and summary tables in
the `results/` directory. In this way, the workflow provides a single,
transparent path from raw simulation output to the final derived results.

## Runtime
The exact runtime depends on the computer used, the MATLAB version, and the disk
speed, especially because the workflow processes relatively large HDF5 files.
For a typical desktop or laptop workstation, the complete post-processing
workflow is expected to run in a few minutes. A reasonable estimate for
reproducing all figures and summary outputs is approximately **2 to 10 minutes**
on a standard machine. The runtime may be longer if the data are stored on a
slow disk or accessed through a network location.

## Metadata design
The file `data/metadata/dataset_description.yaml` provides structured metadata
for the dataset and the analysis workflow. Its purpose is to document the
simulation case in a clear and machine-readable way, including the dataset
identity, branch definitions, workflow context, software environment, and the
relationship between raw inputs and generated outputs. The design of this
metadata file was inspired by the course material on reproducible computational
projects and by FAIR-style data organization, especially the idea that a
dataset, its processing context, and its outputs should be documented in a
structured and reusable format. This idea was then adapted to the specific needs
of this GENESIS simulation case.

## Use of LLM assistance
ChatGPT was used as an assistant during the preparation of this project in
several limited and clearly defined ways. It was used to help organize the
repository structure, improve the clarity of the README and other
documentation, refine parts of the workflow description, and improve the wording
and presentation of the project materials. However, the scientific content of
the project, including the choice of simulation case, file selection, analysis
logic, interpretation of the results, and validation of the outputs, was based
on the author’s own simulation work and checks. In this sense, the LLM was used
as a documentation and organization aid, not as a substitute for scientific
analysis.


