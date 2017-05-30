# Table is the data frame
library("ggplot2")
library("gridExtra")
library(ggplus)

theme_set(theme_bw())
#Table=read.delim(your_input, header=T, row.names=NULL)
Table <- within(Table[1:27,], Nbr_reads[Polarity=="R"] <- (Nbr_reads[Polarity=="R"]*-1)) 
p <- ggplot(Table, aes(x=Coordinate, y=Nbr_reads, label=Nbr_reads, colour=Polarity), xlim=Chrom_length) +
  geom_segment(aes(y = 0, 
                   x = Coordinate, 
                   yend = Nbr_reads, 
                   xend = Coordinate)
               ) +
  facet_wrap(Dataset~Chromosome, scales="free")+
  geom_hline(yintercept=0)+
  ggplus::theme_readable(legend_position = 'right')


plot.list <- by(data     = Table,
                INDICES  = c(Table$Chromosome),
                simplify = TRUE,
                FUN      = function(x) {
                  p %+% x 
                })

multi.plot <- marrangeGrob(grobs = plot.list,nrow  = 4, ncol = 1);
ggsave(file="test.pdf", plot=multi.plot, height=11.69, width=8.2677)



