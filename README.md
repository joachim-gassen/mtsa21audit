## Code repository for the empirical part of the Master's Thesis Seminar in Accounting - Winter Term 2021/2022 

This repository contains the code that I used to create the dataset that I provided to you on Moodle for your empirical assignment. It also contains information on the assignment itself (see next section). I will extend it with my "solution" after the submission deadline.


### The empirical assignment - Part 1 (due: Dec 12, 6pm)

In our two-stage empirical project we will study audit fees of European firms. For that I provide you with a dataset based on data from Audit Analytics that I obtained using WRDS. The data is available both in Excel and CSV Format on Moodle. The code that I used to download the data is available in the `code` directory of this repository.

For the first step of the assignment (due Dec 12) I want you to provide descriptive evidence on factors that are associated with audit fees, non-audit fees and total fees. While your analysis should be exploratory in nature and thus should not be targeting causal effects, try to uncover meaningful and economically interesting associations. Your analysis can use additional data besides the data provided to you on Moodle but you do not have to. You can use tables and/or figures to communicate your findings. Please annotate both with notes so that they are self-explanatory. In addition, please provide a short abstract that summarizes your key finding. Along with a PDF file containing these materials, please also submit the code that you used to create your findings.


### About the repo and its structure

Browse around the repository and familiarize yourself with its folders. There are three folders that have files in them:

- `code`: This directory holds program scripts that are being called to download data from WRDS, prepare the data, and run the analysis. The last part will be added after your assignments are due, of course ;-).

- `data`: A directory where data is stored. You will see that it again contains sub-directories and a README file that explains their purpose. You will also see that in the `external` sub-directory there are two data files. Again, the README file explains their content.

You also see an `output` directory but it is empty. Why? Because you will create the output locally on your computer, if you want.


### I have no idea about scientific computing - Where do I start?

If you are new to scientific computing, we suggest that you also pick up a reference from the list below and browse through it. The [Gentzkow and Shapiro (2014) paper](https://web.stanford.edu/~gentzkow/research/CodeAndData.pdf) is a particularly easy and also useful read. For those that are new to R, I suggest that you take a look into the [awesome text book 'R for Data Science'](https://r4ds.had.co.nz).

If you want to set up your very own R computing environment, we have "produced" a [series of short videos](https://www.youtube.com/playlist?list=PL-9XqvJlFJ-5NDUXubrbvF3aEQPeoAki3) that guide you through the process of setting up your computing environment and using this repository. Also, there is a [blog post](https://joachim-gassen.github.io/2021/03/get-a-treat/) that details these steps in a written form.


### How do I create the output?

Assuming that you have WRDS access, RStudio and make/Rtools installed, this should be relatively straightforward.

1. Download, clone or fork the repository to your local computing environment.
2. Before building everything you most likely need to install additional packages. This repository follows the established principle not to install any packages automatically. This is your computing environment. You decide what you want to install. See the code below for installing the packages.
3. Copy the file _config.csv to config.csv in the project main directory. Edit it by adding your WRDS credentials. 
4. Run 'make all' either via the console or by identifying the 'Build All' button in the 'Build' tab (normally in the upper right quadrant of the RStudio screen). 
5. Eventually, you will be greeted with the data files in the output directory. Congratulations! 

If you do not see 'Build' tab this is most likely because you do not have 'make' installed on your system. 
  - For Windows: Install Rtools: https://cran.r-project.org/bin/windows/Rtools/
  - For MacOS: You need to install the Mac OS developer tools. Open a terminal and run `xcode-select --install` Follow the instructions
  - On Linux: I have never seen a Unix environment without 'make'. 

```
# Code to install packages to your system
install_package_if_missing <- function(pkg) {
  if (! pkg %in% installed.packages()[, "Package"]) install.packages(pkg)
}
install_package_if_missing("tidyverse")
install_package_if_missing("lubridate")
install_package_if_missing("ExPanDaR")
install_package_if_missing("RPostgres")
install_package_if_missing("DBI")

# In addition, if you have no working LaTeX environment, consider
# installing the neat tinytex LateX distribution. It is lightweight and
# you can install it from wihtin R! See https://yihui.org/tinytex/
# To install it, run from the R console:

install_package_if_missing('tinytex')
tinytex::install_tinytex()

# That's all!
```


### Disclaimer

This repository was built based on the ['treat' template for reproducible research](https://github.com/trr266/treat).


### References

These are some very helpful texts discussing collaborative workflows for scientific computing:

- Christensen, Freese and Miguel (2019): Transparent and Reproducible Social Science Research, Chapter 11: https://www.ucpress.edu/book/9780520296954/transparent-and-reproducible-social-science-research
- Gentzkow and Shapiro (2014): Code and data for the social sciences:
a practitioner’s guide, https://web.stanford.edu/~gentzkow/research/CodeAndData.pdf
- Wilson, Bryan, Cranston, Kitzes, Nederbragt and Teal (2017): Good enough practices in scientific computing, PLOS Computational Biology 13(6): 1-20, https://doi.org/10.1371/journal.pcbi.1005510


