import pandas as pd
import json
import numpy as np
import math # For math.ceil
import pycountry

# This list is no longer used in the primary filter but is kept for reference.
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

def pixel_to_latlon(pixel_x, pixel_y, scale_x, offset_x, scale_y, offset_y):
    """
    Converts pixel coordinates back to latitude and longitude.

    Args:
        pixel_x (float): The x-coordinate of the pixel.
        pixel_y (float): The y-coordinate of the pixel.
        scale_x (float): The scaling factor used for the x-coordinate.
        offset_x (float): The offset used for the x-coordinate.
        scale_y (float): The scaling factor used for the y-coordinate.
        offset_y (float): The offset used for the y-coordinate.

    Returns:
        tuple: A tuple containing (latitude, longitude).
    """
    # Step 1: Reverse the scaling and offset to get Mercator coordinates
    merc_x = (pixel_x - offset_x) / scale_x
    merc_y = (pixel_y - offset_y) / scale_y

    # Step 2: Convert Mercator coordinates back to lon/lat in degrees
    lon = np.degrees(merc_x / R)
    lat = np.degrees(2 * np.arctan(np.exp(merc_y / R)) - np.pi / 2)
    
    return lat, lon


def calculate_transform_parameters(point1, point2):
    """
    Calculates the scale and offset for transforming Mercator coordinates to pixel coordinates.

    Args:
        point1 (dict): The first reference point with keys 'lng', 'lat', 'x', 'y'.
        point2 (dict): The second reference point with keys 'lng', 'lat', 'x', 'y'.

    Returns:
        tuple: A tuple containing (scale_x, offset_x, scale_y, offset_y).
    """
    # Calculate Mercator coordinates for the reference points
    p1_merc_x = mercator_x(point1['lng'])
    p1_merc_y = mercator_y(point1['lat'])
    p2_merc_x = mercator_x(point2['lng'])
    p2_merc_y = mercator_y(point2['lat'])

    # Calculate scale and offset for the X-axis
    scale_x = (point1['x'] - point2['x']) / (p1_merc_x - p2_merc_x)
    offset_x = point1['x'] - scale_x * p1_merc_x

    # Calculate scale and offset for the Y-axis
    scale_y = (point1['y'] - point2['y']) / (p1_merc_y - p2_merc_y)
    offset_y = point1['y'] - scale_y * p1_merc_y
    
    return scale_x, offset_x, scale_y, offset_y


def filter_cities_to_json(csv_file_path, json_file_path, scale_x, offset_x, scale_y, offset_y):
    """
    Reads city data, filters it based on map area and a dynamic population-based
    quota per country, and writes the result to a JSON file.

    Args:
        csv_file_path (str): The path to the input CSV file.
        json_file_path (str): The path to the output JSON file.
        scale_x (float): The scaling factor for the x-coordinate.
        offset_x (float): The offset for the x-coordinate.
        scale_y (float): The scaling factor for the y-coordinate.
        offset_y (float): The offset for the y-coordinate.
    """
    try:
        # Read the CSV file into a pandas DataFrame
        df = pd.read_csv(csv_file_path)

        # --- Data Cleaning and Preparation ---
        df['population'] = pd.to_numeric(df['population'], errors='coerce').fillna(0).astype(int)
        df['iso2'] = df['iso2'].fillna('').astype(str).str.upper()
        df['lng'] = pd.to_numeric(df['lng'], errors='coerce')
        df['lat'] = pd.to_numeric(df['lat'], errors='coerce')
        df['is_capital'] = (df['capital'] == "primary").fillna(False).astype(bool)
        df.dropna(subset=['lng', 'lat'], inplace=True)

        # --- Coordinate Transformation ---
        df['merc_x'] = mercator_x(df['lng'])
        df['merc_y'] = mercator_y(df['lat'])
        df['x'] = scale_x * df['merc_x'] + offset_x
        df['y'] = scale_y * df['merc_y'] + offset_y

        # --- NEW FILTERING LOGIC ---
        # 1. Filter for cities within the map's pixel boundaries.
        is_in_map_area = df['x'].between(0, 940) & df['y'].between(0, 1000)
        map_cities_df = df[is_in_map_area & df['iso2'].isin(EUROPEAN_COUNTRIES)].copy()

        # 2. Filter those cities for populations over 100k.
        pop_filtered_df = map_cities_df

        # 3. Dynamically select cities per country.
        final_selection = []
        for country_code, group in pop_filtered_df.groupby('iso2'):
            num_available = len(group)
            if num_available == 0:
                continue

            # Sum population for all cities in the country that are on the map and >100k pop
            total_country_pop = group['population'].sum()
            
            # Calculate the target number of cities based on population
            target_count = math.ceil(total_country_pop / 6_000_000)

            # Determine the number of cities to select based on availability
            if num_available >= 3:
                # If 3 or more are available, take at least 3, but up to the target_count
                num_to_select = min(num_available, max(2, target_count))
            else:
                # If 1 or 2 are available, just take 1
                num_to_select = 1
            
            # Sort by population and take the top N cities
            top_cities = group.sort_values(by='population', ascending=False).head(num_to_select)
            final_selection.append(top_cities)

        # Combine the selected cities from all countries into the final DataFrame
        if final_selection:
            final_df = pd.concat(final_selection)
        else:
            final_df = pd.DataFrame(columns=df.columns)
        # --- END OF NEW LOGIC ---

        # add country names using pycountry
        final_df['country'] = df.apply(lambda x: pycountry.countries.get(alpha_2=x.iso2).name if x.iso2 in [n.alpha_2 for n in list(pycountry.countries)] else '', axis=1)

        # Reset index for the final DataFrame
        final_df = final_df.reset_index(drop=True)
        final_df = final_df.reset_index(drop=False)

        # Select columns for the output JSON
        output_data = final_df[['index', 'city', 'x', 'y', 'lng', 'lat', 'iso2', 'country', 'population', 'is_capital']]

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
# Define reference points as dictionaries
ref_point1 = {'lng': 28.9795, 'lat': 41.0082, 'x': 730, 'y': 600} # Istanbul
ref_point2 = {'lng': 12.5683, 'lat': 55.6761, 'x': 517, 'y': 338} # Copenhagen

# Calculate transformation parameters
scale_x, offset_x, scale_y, offset_y = calculate_transform_parameters(ref_point1, ref_point2)
print(f"Calculated parameters: scale_x={scale_x}, offset_x={offset_x}, scale_y={scale_y}, offset_y={offset_y}")

# Define file paths
csv_input_file = "worldcities.csv"
json_output_file = "locations.json"

# Run the main function with the calculated parameters
filter_cities_to_json(csv_input_file, json_output_file, scale_x, offset_x, scale_y, offset_y)

# Calculate the lat/lon from the pixel coordinates
for x in [0, 1000]:
    for y in [0, 700]:
        calculated_lat, calculated_lon = pixel_to_latlon(
            x, y, scale_x, offset_x, scale_y, offset_y
        )
        print(f"Pixel ({x}, {y}) -> Lat: {calculated_lat:.3f}, Lon: {calculated_lon:.3f}")