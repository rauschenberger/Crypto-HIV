
# SAS code for Crypto-HIV phase 2

## Scope

This repository contains the SAS code for the Crypto-HIV phase 2 study. The script in the file [analysis.sas](analysis.sas) calls multiple scripts:

- file [setup.sas](code/setup.sas): defining paths
- file [macros.sas](code/macros.sas): defining macros
- file [format.sas](code/format.sas): defining formats
- file [import.sas](code/import.sas): importing datasets
- other files in folder [code](code): generating tables, figures, and listings
<!-- [devel.sas](code/devel.sas): code for PK analysis-->

In addition, this repository also contains the SAS script for the randomisation ([randomisation](randomisation.sas)), a short presentation of the statistical analysis plan ([presentation.Rmd](presentation.Rmd)), and the SAS and R scripts for reproducing the results from the Crypto-HIV phase 1 study "fed" ([reproducibility.sas](reproducibility.sas) and [reproducibility.Rmd](reproducibility.Rmd)).

## Reference

"A 15-week, open-label, randomized, controlled parallel-group trial to evaluate the comparative bioavailability, efficacy and safety of sustained-release flucytosine versus immediate-release flucytosine in adults with cryptococcal meningitis." (https://dndi.org/research-development/portfolio/5fc-cryptococcal-meningitis/)

## Disclaimer

This repository is hosted on a personal GitHub account (https://github.com/rauschenberger/Crypto-HIV), but it has a mirror on an institutional GitLab account (https://gitlab.lih.lu/arauschenberger/Crypto-HIV).

**Copyright** &copy; 2023 Armin Rauschenberger
[![AR](https://info.orcid.org/wp-content/uploads/2019/11/orcid_16x16.png)](https://orcid.org/0000-0001-6498-4801); Luxembourg Institute of Health (LIH), Department of Medical Informatics (DMI), Bioinformatics and Artificial Intelligence (BioAI) and Competence Centre for Methodology and Statistics (CCMS). This SAS code is distributed under the [BSD-3-Clause license](LICENSE.md).

> [!WARNING]
> This SAS code is still under development and has not yet been reviewed.
> It has not been validated and should not be used to support regulatory submissions.
