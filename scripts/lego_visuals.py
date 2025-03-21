import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Set consistent style for all plots
sns.set(style="whitegrid")

# =============================================================================
# 📊 Chart 1: LEGO Sets Released Per Year + Moving Averages (5Y & 10Y)
# =============================================================================

# Load merged sets data
sets = pd.read_csv("../data/merged_sets.csv")

# Filter out very early years for cleaner visualization
sets = sets[sets["year"] >= 1950]

# Count how many sets were released per year
sets_per_year = sets.groupby("year").size().reset_index(name="total_sets")

# Calculate 5-year and 10-year moving averages
sets_per_year["5yr_avg"] = sets_per_year["total_sets"].rolling(window=5).mean()
sets_per_year["10yr_avg"] = sets_per_year["total_sets"].rolling(window=10).mean()

# Plot line chart
plt.figure(figsize=(12, 6))
sns.lineplot(data=sets_per_year, x="year", y="total_sets", label="Total Sets")
sns.lineplot(data=sets_per_year, x="year", y="5yr_avg", label="5-Year Moving Avg")
sns.lineplot(data=sets_per_year, x="year", y="10yr_avg", label="10-Year Moving Avg")

plt.title("LEGO Sets Released per Year (with Moving Averages)", fontsize=14)
plt.xlabel("Year", fontsize=12)
plt.ylabel("Number of Sets", fontsize=12)
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("../visuals/sets_per_year.png")
plt.show()

# =============================================================================
# 📊 Chart 2: Top 10 LEGO Themes by Number of Unique Parts
# =============================================================================

# Load required datasets
inventory_parts = pd.read_csv("../data/merged_inventory_parts.csv")
inventories = pd.read_csv("../data/merged_inventories.csv")
sets = pd.read_csv("../data/merged_sets.csv")
themes = pd.read_csv("../data/merged_themes.csv")

# Merge inventory_parts with inventories to get set_num
merged = inventory_parts.merge(inventories[["id", "set_num"]], left_on="inventory_id", right_on="id")

# Merge with sets to get theme_id
merged = merged.merge(sets[["set_num", "theme_id"]], on="set_num", how="left")

# Merge with themes to get theme name
merged = merged.merge(themes[["id", "name"]], left_on="theme_id", right_on="id", how="left", suffixes=("", "_theme"))

# Count unique parts per theme
unique_parts_by_theme = merged.groupby("name")["part_num"].nunique().reset_index(name="unique_parts")

# Get top 10 themes with most unique parts
top_themes = unique_parts_by_theme.sort_values("unique_parts", ascending=False).head(10)

# Plot horizontal bar chart
plt.figure(figsize=(12, 6))
sns.barplot(data=top_themes, x="unique_parts", y="name", palette="viridis")

plt.title("Top 10 LEGO Themes by Number of Unique Parts", fontsize=14)
plt.xlabel("Number of Unique Parts", fontsize=12)
plt.ylabel("Theme", fontsize=12)
plt.tight_layout()
plt.savefig("../visuals/top_themes_unique_parts.png")
plt.show()

# =============================================================================
# 📊 Chart 3: Top 10 Theme-Year Combinations with Highest Year-over-Year Growth
# =============================================================================

# Merge sets with themes to get the theme names — select only needed columns
sets_with_themes = sets.merge(themes[["id", "name"]], left_on="theme_id", right_on="id", how="left")

# Count how many sets were released per theme per year
theme_year_counts = sets_with_themes.groupby(["name_themes", "year"]).size().reset_index(name="total_sets")

# Calculate previous year's total using shift() grouped by theme name
theme_year_counts["prev_year"] = theme_year_counts.groupby("name_themes")["total_sets"].shift(1)

# Calculate year-over-year growth
theme_year_counts["growth"] = theme_year_counts["total_sets"] - theme_year_counts["prev_year"].fillna(0)

# Get the top 10 combinations with the highest growth
top_theme_growth = theme_year_counts.sort_values("growth", ascending=False).head(10)

# Create a label for visualization (e.g., "City (2020)")
top_theme_growth["label"] = top_theme_growth["name_themes"] + " (" + top_theme_growth["year"].astype(str) + ")"

# Plot the results
plt.figure(figsize=(12, 6))
sns.barplot(data=top_theme_growth, x="growth", y="label", palette="rocket")

plt.title("Top 10 Theme-Year Combinations with Highest YoY Set Growth", fontsize=14)
plt.xlabel("Year-over-Year Growth in Number of Sets", fontsize=12)
plt.ylabel("Theme (Year)", fontsize=12)
plt.tight_layout()
plt.savefig("../visuals/top_theme_yoy_growth.png")
plt.show()

# =============================================================================
# 📊 Chart 4: Forecast of LEGO Set Releases (EWMA + Moving Average)
# =============================================================================

# Rebuild the base sets_per_year dataframe to avoid carryover errors
sets_per_year = sets[sets["year"] >= 1950].groupby("year").size().reset_index(name="total_sets")

# Calculate 10-year moving average
sets_per_year["10yr_avg"] = sets_per_year["total_sets"].rolling(window=10).mean()

# Calculate EWMA: Exponential Weighted Moving Average
sets_per_year["prev_year"] = sets_per_year["total_sets"].shift(1)
sets_per_year["ewma"] = (0.7 * sets_per_year["total_sets"] + 
                         0.3 * sets_per_year["prev_year"].fillna(sets_per_year["total_sets"])).round(2)

# Plot comparison of actual data vs. forecasts
plt.figure(figsize=(12, 6))
sns.lineplot(data=sets_per_year, x="year", y="total_sets", label="Actual Sets")
sns.lineplot(data=sets_per_year, x="year", y="10yr_avg", label="10-Year Moving Avg")
sns.lineplot(data=sets_per_year, x="year", y="ewma", label="EWMA (70/30)")

plt.title("LEGO Set Release Forecast: EWMA vs. Moving Average", fontsize=14)
plt.xlabel("Year", fontsize=12)
plt.ylabel("Number of Sets", fontsize=12)
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("../visuals/set_forecast_ewma.png")
plt.show()
