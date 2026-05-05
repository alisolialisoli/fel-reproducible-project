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

Outputs at end of RAD6:
  H7 --> FIELD_END_RAD6_BRANCH_A.fld.h5
  H6 --> FIELD_END_RAD6_BRANCH_B.fld.h5
  H5 --> FIELD_END_RAD6_BRANCH_C.fld.h5