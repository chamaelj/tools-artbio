## Setup R error handling to go to stderr
#options( show.error.messages=F,
#       error = function () { cat( geterrmessage(), file=stderr() ); q( "no", 1, F ) } )
warnings()
library(RColorBrewer)
library(lattice)
library(latticeExtra)
library(grid)
library(gridExtra)
library(optparse)
 
option_list <- list(
    make_option(c("-r", "--output_tab"), type="character", help="path to tabular file"),
    make_option("--output_pdf", type = "character", help="path to the pdf file with plot")
    )
 
parser <- OptionParser(usage = "%prog [options] file", option_list = option_list)
args = parse_args(parser)
 
# dataset manipulation

Table = read.delim(args$output_tab, header=T, row.names=NULL)
Table <- within(Table, Nbr_reads[Polarity=="R"] <- (Nbr_reads[Polarity=="R"]*-1))
n_samples=length(unique(Table$Dataset))
genes=unique(levels(Table$Chromosome))
per_gene_readmap=lapply(genes, function(x) subset(Table, Chromosome==x))
per_gene_limit=lapply(genes, function(x) c(1, unique(subset(Table, Chromosome==x)$Chrom_length)) )
n_genes=length(per_gene_readmap)
## end of data frames implementation

## functions

plot_readmap=function(df, ...) {
combineLimits(xyplot(Nbr_reads~Coordinate|factor(Dataset, levels=unique(Dataset))+factor(Chromosome, levels=unique(Chromosome)),
data=df,
type='h',
scales= list(relation="free", x=list(rot=0, cex=0.7, axs="i", tck=0.5), y=list(tick.number=4, rot=90, cex=0.7)),
xlab=NULL, main=NULL, ylab=NULL,
as.table=T,
origin = 0,
horizontal=FALSE,
group=Polarity,
col=c("red","blue"),
par.strip.text = list(cex=0.7),
...))
}


plot_size=function(df, ...) {
combineLimits(xyplot(Median~Coordinate|factor(Dataset, levels=unique(Dataset))+factor(Chromosome, levels=unique(Chromosome)),
data=df,
type='p',
pch=0.5,
scales= list(relation="free", x=list(rot=0, cex=0.7, axs="i", tck=0.5), y=list(tick.number=4, rot=90, cex=0.7)),
xlab=NULL, main=NULL, ylab=NULL,
as.table=T,
origin = 0,
horizontal=FALSE,
group=Polarity,
col=c("red","blue"),
 a...))
}


## end of functions

## function parameters
par.settings.readmap=list(layout.heights=list(top.padding=0, bottom.padding=0), strip.background = list(col=c("lightblue","lightgreen")) )
par.settings.size=list(layout.heights=list(top.padding=-2, bottom.padding=-0.5))
## end of function parameters'

## GRAPHS

if (n_genes > 7) {page_height_simple = 11.69; page_height_combi=11.69; rows_per_page=8} else {
                 rows_per_page= n_genes; page_height_simple = 2.5*n_genes; page_height_combi=page_height_simple*2 }
if (n_samples > 4) {page_width = 8.2677*n_samples/4} else {page_width = 8.2677*n_samples/2} # to test


pdf(file=args$output_pdf, paper="special", height=page_height_simple, width=page_width)
if (rows_per_page %% 2 != 0) { rows_per_page = rows_per_page + 1}
for (i in seq(1,n_genes,rows_per_page/2)) {
    start=i
    end=i+rows_per_page/2-1
    if (end>n_genes) {end=n_genes}
    readmap_plot.list=lapply(per_gene_readmap[start:end], function(x) plot_readmap(x, xlim=c(1, x$Chrom_length[1]), par.settings=par.settings.readmap))
    size_plot.list=lapply(per_gene_readmap[start:end], function(x) plot_size(x, strip=FALSE, par.settings=par.settings.size))
    plot.list=rbind(readmap_plot.list, size_plot.list )
    args_list=c(readmap_plot.list, list(nrow=rows_per_page+1, ncol=1,
                                    top=textGrob("Read Maps and Median sizes", gp=gpar(cex=1), just="top"),
                                    left=textGrob("Read counts / Median size", gp=gpar(cex=1), vjust=1, rot=90)
                                    sub=textGrob("Nucleotide coordinates", gp=gpar(cex=1), just="bottom")
                                    )
           )
do.call(grid.arrange, args_list)
}
devname=dev.off()

