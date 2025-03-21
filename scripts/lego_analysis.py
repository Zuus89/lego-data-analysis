import pandas as pd

# 📂 Path to the CSV files
data_path = "../data/"
relationships_path = "../results/telationships.csv"

# 🔄 Load all tables into a dictionary `tables`
# This makes it easier to access each table by name
tables = {
    "sets": pd.read_csv(data_path + "sets.csv"),  # LEGO sets information
    "themes": pd.read_csv(data_path + "themes.csv"),  # Themes/categories for LEGO sets
    "inventories": pd.read_csv(data_path + "inventories.csv"),  # Set inventory records
    "inventory_sets": pd.read_csv(data_path + "inventory_sets.csv"),  # Relationship between sets and inventory
    "inventory_parts": pd.read_csv(data_path + "inventory_parts.csv"),  # Parts inside the inventory
    "parts": pd.read_csv(data_path + "parts.csv"),  # LEGO parts details
    "part_categories": pd.read_csv(data_path + "part_categories.csv"),  # Categories of LEGO parts
    "colors": pd.read_csv(data_path + "colors.csv"),  # Available LEGO colors
}

# 🔗 Load relationships from `telationships.csv`
# This file defines how tables are connected to each other
relationships = pd.read_csv(relationships_path)

# 🔄 Apply `merge()` operations to combine tables based on relationships
for _, row in relationships.iterrows():
    source_table = row["table_name"]  # The originating table
    source_column = row["column_name"]  # Column in the originating table
    target_table = row["referenced_table"]  # The target table to join with
    target_column = row["referenced_column"]  # Column in the target table

    # If both tables exist in our dictionary, perform the merge operation
    if source_table in tables and target_table in tables:
        print(f"🔗 Merging {source_table}.{source_column} with {target_table}.{target_column}...")
        tables[source_table] = tables[source_table].merge(
            tables[target_table],  # Table to merge with
            left_on=source_column,  # Column in the source table
            right_on=target_column,  # Column in the target table
            suffixes=("", f"_{target_table}")  # Avoid column name conflicts
        )

# 📁 Save merged tables as CSV files in `/data/`
for table_name, df in tables.items():
    df.to_csv(data_path + f"merged_{table_name}.csv", index=False)

print("✅ Tables successfully merged and saved in the `/data/` folder!")