import pandas as pd
import json
import numpy as np # For mathematical functions like log, tan, radians

# List of European countries (ISO2 codes for consistency with your CSV)
# This list is based on common definitions of European countries.
EUROPEAN_COUNTRIES = [
    "AL", "AD", "AM", "AT", "BY", "BE", "BA", "BG", "HR", "CY", "CZ",
    "DK", "EE", "FI", "FR", "GE", "DE", "GR", "HU", "IS", "IE", "IT",
    "XK", "LV", "LI", "LT", "LU", "MT", "MD", "MC", "ME", "NL", "MK", "NO",
    "PL", "PT", "RO", "RU", "SM", "RS", "SK", "SI", "ES", "SE", "CH", "TR",
    "UA", "GB", "VA"
]

# --- Mercator Projection Parameters ---
# Earth's radius in meters (standard for Web Mercator / EPSG:3857)
R = 6378137.0

def mercator_x(lon):
    """Converts longitude (degrees) to Mercator x-coordinate."""
    return R * np.radians(lon)

def mercator_y(lat):
    """Converts latitude (degrees) to Mercator y-coordinate."""
    # Clip latitude to avoid infinity near poles for Mercator projection
    lat_rad = np.radians(np.clip(lat, -85.05112878, 85.05112878))
    return R * np.log(np.tan(np.pi / 4 + lat_rad / 2))

# Reference points for coordinate transformation
# Istanbul:   lng=28.9795, lat=41.0082 -> pixel_x=730, pixel_y=600
# Copenhagen: lng=12.5683, lat=55.6761 -> pixel_x=517, pixel_y=338

# Calculate Mercator coordinates for new reference points
istanbul_lng_merc = mercator_x(28.9795)
istanbul_lat_merc = mercator_y(41.0082)

copenhagen_lng_merc = mercator_x(12.5683)
copenhagen_lat_merc = mercator_y(55.6761)

# Now, calculate the scaling factors and offsets from Mercator coordinates to pixel coordinates
# pixel_x = scale_x * mercator_x_coord + offset_x
# pixel_y = scale_y * mercator_y_coord + offset_y

# For X coordinates (pixel_x vs mercator_x_coord):
# 730 = SCALE_X * istanbul_lng_merc + OFFSET_X
# 517 = SCALE_X * copenhagen_lng_merc + OFFSET_X
# Solving for SCALE_X and OFFSET_X
# (730 - 517) = SCALE_X * (istanbul_lng_merc - copenhagen_lng_merc)
SCALE_X = (730 - 517) / (istanbul_lng_merc - copenhagen_lng_merc)
OFFSET_X = 730 - SCALE_X * istanbul_lng_merc

# For Y coordinates (pixel_y vs mercator_y_coord):
# 600 = SCALE_Y * istanbul_lat_merc + OFFSET_Y
# 338 = SCALE_Y * copenhagen_lat_merc + OFFSET_Y
# Solving for SCALE_Y and OFFSET_Y
# (600 - 338) = SCALE_Y * (istanbul_lat_merc - copenhagen_lat_merc)
SCALE_Y = (600 - 338) / (istanbul_lat_merc - copenhagen_lat_merc)
OFFSET_Y = 600 - SCALE_Y * istanbul_lat_merc


def filter_cities_to_json(csv_file_path, json_file_path):
    """
    Reads city data from a CSV using pandas, filters it, and writes selected data to a JSON file.
    Coordinates are transformed using Mercator projection and then scaled to pixel values.

    Args:
        csv_file_path (str): The path to the input CSV file.
        json_file_path (str): The path to the output JSON file.
    """
    try:
        # Read the CSV file into a pandas DataFrame
        df = pd.read_csv(csv_file_path)

        # Ensure relevant columns are treated correctly
        df['population'] = pd.to_numeric(df['population'], errors='coerce').fillna(0).astype(int)
        df['capital'] = df['capital'].fillna('').astype(str).str.strip().str.lower()
        df['iso2'] = df['iso2'].fillna('').astype(str).str.upper()
        df['lng'] = pd.to_numeric(df['lng'], errors='coerce')
        df['lat'] = pd.to_numeric(df['lat'], errors='coerce')
        
        # Drop rows where 'lng' or 'lat' became NaN due to coercion errors
        df.dropna(subset=['lng', 'lat'], inplace=True)

        # Filter criteria:
        is_european = df['iso2'].isin(EUROPEAN_COUNTRIES)
        meets_criteria = ((df['capital'] == 'primary') | (df['population'] > 500000))
        
        filtered_df = df[is_european & meets_criteria].copy()

        # Apply Mercator projection to longitude and latitude
        filtered_df['merc_x'] = mercator_x(filtered_df['lng'])
        filtered_df['merc_y'] = mercator_y(filtered_df['lat'])

        # Apply the linear transformation from Mercator coordinates to pixel coordinates
        filtered_df['x'] = SCALE_X * filtered_df['merc_x'] + OFFSET_X
        filtered_df['y'] = SCALE_Y * filtered_df['merc_y'] + OFFSET_Y

        is_in_map_area = filtered_df['x'].between(0, 1000) & filtered_df['y'].between(0, 1000)
        filtered_df = filtered_df[is_in_map_area]

        # Select columns for the output JSON
        output_data = filtered_df[['city', 'x', 'y']]

        # Convert DataFrame to a list of dictionaries
        locations_list = output_data.to_dict(orient='records')

        # Write the data to a JSON file
        with open(json_file_path, mode='w', encoding='utf-8') as outfile:
            json.dump({"locations": locations_list}, outfile, indent=4, ensure_ascii=False)
        
        print(f"Successfully processed {len(locations_list)} cities and saved to {json_file_path}")

    except FileNotFoundError:
        print(f"Error: CSV file not found at {csv_file_path}")
    except KeyError as e:
        print(f"Error: Missing expected column in CSV: {e}. Please ensure all required columns are present.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

# --- Usage Example ---
csv_input_file = "worldcities.csv"
json_output_file = "locations.json"

filter_cities_to_json(csv_input_file, json_output_file)
