# Final EEHG F13/F14 input packages

This directory contains the two final EEHG operating points used for the 1100 MeV, 71 keV study.

- **F13**: A1 = 2.925, A2 = 3.100
- **F14**: A1 = 2.925, A2 = 3.150

Common settings:
- sigma_E = 71 keV
- B1 = 2.380
- B2 = 0.389953
- R56_1 = 1.525825164 mm
- R56_2 = 0.250000000 mm
- seed wavelength = 260 nm
- radiator sequence: R1-R2 -> H7, R3-R4 -> H6, R5-R6 -> H5

Each ZIP contains both:
- NON_ONE4ONE
- ONE4ONE_SORTED

and includes RUN_A_H7.in, RUN_B_H6.in, RUN_C_H5.in, the planar lattice file, CASE.json, README, and SHA256 checksums.

F13 is the preferred selected operating point because its One4One validation gives the better three-color power balance and slightly better temporal-profile quality. F14 is retained as the higher-power alternative.
