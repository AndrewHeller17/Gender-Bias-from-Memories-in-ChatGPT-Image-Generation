# visualizations.R
# Author: Andrew Heller
# Course: GOVT 20.12 (Politics and AI), Dartmouth College
#
# Runs statistical tests comparing observed vs. real-world gender proportions
# across 16 college majors in AI-generated images, then produces the three
# plots used in the poster "Personalization through Memories Results in
# Gender Bias in ChatGPT Generations of Images of its User."
#
# Input:  academicDemographics.csv (output of analysis.ipynb)
# Output: results.csv, three plots

library(tidyverse)

library(glue)

library(gt)          
library(scales)      

#setwd("")

raw <- read_csv("output/academicDemographics.csv", show_col_types = FALSE)


# 2. Derive a clean gender denominator (Male + Female only) 
gender_cols <- c("Male", "Female")   # ignore Non-binary, Other, etc.
clean <- raw %>%
  mutate(
    gender_total = rowSums(across(all_of(gender_cols))),
    observed_male_prop = Male / gender_total
  ) %>%
  # Optional filter to avoid tiny N
  filter(gender_total >= 10)

# Per-major tests 
results <- clean %>%
  rowwise() %>%
  mutate(
    # one-sample two-sided proportion test
    prop_out = list(prop.test(
      x = Male,
      n = gender_total,
      p = RealWorldMale,
      alternative = "two.sided"
    )),
    prop_p     = prop_out$p.value,
    prop_ci_lo = prop_out$conf.int[1],
    prop_ci_hi = prop_out$conf.int[2],
    
    # X^2 test on {Male, Female}
    chi_out = list(chisq.test(
      x = c(Male, Female),
      p = c(RealWorldMale, 1 - RealWorldMale)
    )),
    chi_stat = chi_out$statistic,
    chi_p    = chi_out$p.value
  ) %>%
  ungroup() %>%
  mutate(
    prop_p_adj = p.adjust(prop_p, method = "BH"),
    chi_p_adj  = p.adjust(chi_p,  method = "BH"),
    significant_prop = prop_p_adj < 0.05,
    significant_chi  = chi_p_adj  < 0.05,
    diff = observed_male_prop - RealWorldMale
  ) %>%
  select(
    name,
    gender_total, Male, Female,
    observed_male_prop, RealWorldMale, diff,
    prop_p, prop_p_adj, significant_prop,
    chi_stat, chi_p, chi_p_adj, significant_chi
  )

print(results, n = Inf)

write.csv(results, "results.csv")

# Overall (pooled) test across majors 
pooled_test <- prop.test(
  x = sum(clean$Male),
  n = sum(clean$gender_total),
  p = with(clean, sum(RealWorldMale * gender_total) / sum(gender_total))
)
pooled_test






# Prepare display labels and factor ordering
res <- results %>% 
  mutate(
    major = fct_reorder(name, diff),            # order by size of gap
    sig_lab = if_else(significant_prop, "★", "")# add star for FDR-significant
  ) %>% 
  mutate(
    major_clean = str_to_title(str_replace_all(name, "_", " ")),
    # Shorten the long Asian label
    major_clean = case_when(
      major_clean == "Asian Societies, Cultures, And Languages" ~ "Asian Studies",
      TRUE ~ major_clean
    ),
    # Re-order by the gap but display the cleaned text
    major_clean = fct_reorder(major_clean, diff)
  )



# Poster: "Observed vs. Expected Male Proportions by Major" (center-left panel)
ggplot(res, aes(y = major_clean)) +
  geom_segment(aes(x = RealWorldMale, xend = observed_male_prop,
                   yend = major_clean), colour = "grey70") +
  geom_point(aes(x = RealWorldMale), shape = 21, fill = "white", size = 3) +
  geom_point(aes(x = observed_male_prop,
                 fill = significant_prop), shape = 21, size = 4) +
  scale_fill_manual(values = c(`FALSE` = "grey60", `TRUE` = "darkgreen")) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    x = "Male Proportion", y = NULL,
    fill = "FDR-significant?",
    title = "Observed vs. Expected Male Proportions by Major"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(hjust = -8)   # ← centers the title
  )


# Poster: "Evidence Strength for Gender-Gap by Major" (center-right panel)
ggplot(res, aes(x = -log10(prop_p_adj), y = major_clean,
                fill = significant_prop)) +
  geom_col() +
  geom_vline(xintercept = -log10(.05), linetype = "dashed") +
  scale_fill_manual(values = c(`FALSE` = "grey60", `TRUE` = "darkgreen")) +
  labs(
    x = expression(-log[10]("(adj. p-value)")),
    y = NULL,
    fill = "FDR-significant?",
    title = "Evidence strength for gender-gap by major"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")






# compute the pooled numbers 
pooled <- res %>% 
  summarise(
    total_male  = sum(Male),
    total_n     = sum(gender_total),
    observed    = total_male / total_n,
    expected    = sum(RealWorldMale * gender_total) / total_n
  )

# 95 % CI for the observed overall proportion
pooled_ci <- prop.test(pooled$total_male, pooled$total_n)$conf.int
pooled$ci_lo <- pooled_ci[1]
pooled$ci_hi <- pooled_ci[2]

# clean for plotting 
pooled_long <- pooled %>% 
  select(observed, expected) %>% 
  pivot_longer(everything(), names_to = "type", values_to = "prop") %>% 
  mutate(type = factor(type, levels = c("expected", "observed"),
                       labels = c("Real-world benchmark", "Observed in sample")))




# Poster: "Overall Gender Composition (All Majors Pooled)" (bottom-center panel)
ggplot(pooled_long, aes(x = type, y = prop, fill = type)) +
  geom_col(width = .55, colour = "grey30") +
  geom_errorbar(
    data = pooled %>% 
      mutate(type = "Observed in sample",
             prop = observed),      
    aes(ymin = ci_lo, ymax = ci_hi),
    width = .15, linewidth = .6
  ) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                     limits = c(0, 1)) +
  scale_fill_manual(values = c("grey70", "darkgreen")) +
  labs(
    x = NULL, y = "Male share",
    title = "Overall gender composition (all majors pooled)",
    subtitle = glue::glue(
      "n = {pooled$total_n},  95% CI for observed = ",
      "{scales::percent(pooled$ci_lo, 1)}–",
      "{scales::percent(pooled$ci_hi, 1)}"
    ),
    fill = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")
