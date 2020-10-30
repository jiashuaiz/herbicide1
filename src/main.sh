#!/bin/bash

### executioner

### create output directory
mkdir ../output/
### extract farmer names
tail -n+2 ../data/Lrigidum_RESISTANCES_2018-11.csv | cut -d, -f9 - | sort | uniq | grep -v "None" \
    > names_farmer.temp
### iteratively generate the html files
for i in $(seq 1 $(cat names_farmer.temp | wc -l))
do
    # i=2
    name_farmer=$(head -n${i} names_farmer.temp | tail -n1)
    echo $name_farmer
    sed "s/BASH_REPLACE_WITH_FARMER_NAME/$name_farmer/g" herbicide_resistance_report.Rmd \
        > knitr_me-PDF.Rmd
    sed 's/pdf_document: default/html_document: default/g' knitr_me-PDF.Rmd | \
        sed 's/, fig.height=13, fig.width=20, dpi=200/, fig.height=8, fig.width=15/g' | \
        sed 's/par(cex=1.5)/par(cex=1)/g' | \
        sed 's/cex.text=1.4/cex.text=1.25/g' \
        > knitr_me-HTML.Rmd
    R -e "rmarkdown::render('knitr_me-PDF.Rmd',output_file='out.pdf')"
    R -e "rmarkdown::render('knitr_me-HTML.Rmd',output_file='out.html')"
    mv out.pdf ../output/"${name_farmer}.pdf" ### Using ${name_farmer} at knitr rendering fails...
    mv out.html ../output/"${name_farmer}.html" ### that's why we have to do this wonky renaming.
done
### clean-up
rm names_farmer.temp
rm knitr_me-*.Rmd *.log
