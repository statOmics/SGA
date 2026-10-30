# Donor $\times$ treatment interaction in the macrophage design

Teaching note for the bulk RNA-seq introduction (`04-rnaseq-intro.qmd`, section *Design*).
Not part of the website.

Model: `~ donor + ifng * salmonella`, 6 donors $\times$ 4 conditions = 24 samples, one sample per donor and condition.

## What about a donor $\times$ treatment interaction?

- Every donor contributes exactly one sample per condition: there are no replicates within the blocks.
- The model has 9 parameters, so there are 24 $-$ 9 = 15 residual degrees of freedom. A donor $\times$ treatment interaction would have (6 $-$ 1) $\times$ (4 $-$ 1) = 15 degrees of freedom.
- The residual variability is thus exactly the donor $\times$ treatment interaction, together with the technical and within-donor variability, which cannot be separated without replicates.
- This is the appropriate error term: donors respond somewhat differently to the treatments, and we want to generalise the treatment effects to the population of donors. It gives the same test as a mixed model with a random donor $\times$ treatment effect.

## Intermezzo

Suppose we would have had replicates within the donor $\times$ condition combinations, e.g. several differentiations per cell line 

- a model without the interaction would then treat these replicates as independent: pseudo-replication with too liberal tests. 
- A fixed treatment x donor interaction does not solve this either, as the conclusions then only hold for these donors. 
- The replicates should then be summed per donor and condition first, or 
- the interactions should be modelled as a random effect, as in msqrob2, which is not possible in edgeR.

