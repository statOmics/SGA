import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

years_historical = [2001, 2004, 2007, 2008, 2011, 2014, 2017, 2020, 2022]
cost_historical = [100000000, 20000000, 10000000, 300000, 10000, 1000, 800, 700, 525]
years_projection = [2022, 2024, 2026]
cost_projection = [525, 300, 100]
all_years = list(range(2001, 2027, 2))
moores_law = [100000000 * (0.5 ** ((y - 2001) / 2)) for y in all_years]

plt.figure(figsize=(11, 6.5))
plt.grid(True, which="both", ls="-", color='0.85')
plt.plot(all_years, moores_law, color='#d62728', linestyle=':', marker='s', alpha=0.7, linewidth=1.5, label="Moore's Law Prediction")
plt.plot(years_historical, cost_historical, color='#1f77b4', marker='o', linewidth=2.5, label='NHGRI Tracked Cost (2001–2022)')
plt.plot(years_projection, cost_projection, color='#0288d1', linestyle='--', marker='o', linewidth=2.5, label='High-Throughput Reagent Scaling (2022–2026)')
plt.axvspan(2001, 2022, color='#f1f8e9', alpha=0.5, label='Era 1: Public Core Facility Tracking (NHGRI)')
plt.axvspan(2022, 2026, color='#fff3e0', alpha=0.5, label='Era 2: Commercial Reagent Optimization')
plt.yscale('log')
plt.ylabel('Cost per Human Genome (USD)', fontsize=12, fontweight='bold')
plt.xlabel('Year', fontsize=12, fontweight='bold')
plt.title('Evolution of Whole Human Genome Sequencing Cost vs. Moore\'s Law', fontsize=13, fontweight='bold', pad=15)
plt.xticks(list(range(2001, 2027, 2)), rotation=45)
yticks = [100, 1000, 10000, 100000, 1000000, 10000000, 100000000]
ytick_labels = ['$100', '$1,000', '$10,000', '$100,000', '$1 Million', '$10 Million', '$100 Million']
plt.yticks(yticks, ytick_labels)
plt.ylim(10, 2e8)
plt.annotate('Next-Gen Sequencing (NGS)\nDisruption (c. 2007)', xy=(2007, 10000000), xytext=(2002, 100000),
             arrowprops=dict(facecolor='black', arrowstyle='->', lw=0.8))
plt.annotate('NHGRI Tracking Ends\n(May 2022: ~$525)', xy=(2022, 525), xytext=(2014, 4000),
             arrowprops=dict(facecolor='black', arrowstyle='->', lw=0.8))
plt.annotate('$100 Reagent Barrier\n(Commercial 2026)', xy=(2026, 100), xytext=(2020, 20),
             arrowprops=dict(facecolor='black', arrowstyle='->', lw=0.8))
plt.legend(loc='upper right', frameon=True, facecolor='white', edgecolor='gray', framealpha=0.9)
plt.tight_layout()
plt.savefig("figs/sequencingCost.png", dpi=200)
plt.savefig("figs/sequencingCost.pdf")
