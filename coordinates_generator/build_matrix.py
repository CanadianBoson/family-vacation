import json
import numpy as np
from global_land_mask import globe
from math import radians, sin, cos, sqrt, atan2

def calculate_haversine_distance(lat1, lon1, lat2, lon2):
    """Calculates the distance between two points in kilometers using the Haversine formula."""
    R = 6371.0  # Earth's radius in kilometers
    
    lat1_rad = radians(lat1)
    lon1_rad = radians(lon1)
    lat2_rad = radians(lat2)
    lon2_rad = radians(lon2)
    
    dlon = lon2_rad - lon1_rad
    dlat = lat2_rad - lat1_rad
    
    a = sin(dlat / 2)**2 + cos(lat1_rad) * cos(lat2_rad) * sin(dlon / 2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    
    distance = R * c
    return distance

def classify_travel_path(lat1, lon1, lat2, lon2, distance):
    """
    Classifies the travel path between two points based on land/ocean checks.
    
    Returns:
        0 for land (distance < 300 km)
        1 for boat (distance < 500 km)
        2 for train (300 km <= distance < 1000 km)
        3 for plane (otherwise)
    """
    # Create 10 intermediate points along the path
    lats = np.linspace(lat1, lat2, 10)
    lons = np.linspace(lon1, lon2, 10)
    
    # Check for land path
    if distance < 300 and sum(globe.is_land(lats, lons)[1:-1]) >= 6:
        return 0  # Land
        
    # Check for ocean path
    if distance < 800 and sum(globe.is_ocean(lats, lons)[1:-1]) >= 6:
        return 1  # Boat

    # Check for train path
    if distance >= 300 and distance < 1000 and sum(globe.is_land(lats, lons)[1:-1]) >= 6:
        return 2  # Boat

    # Default to plane
    return 3  # Plane

def build_travel_matrix(locations_file):
    """
    Builds a matrix classifying the travel mode between all cities in a JSON file.
    
    Args:
        locations_file (str): The path to the locations.json file.
        
    Returns:
        numpy.ndarray: The classification matrix.
    """
    try:
        with open(locations_file, 'r') as f:
            data = json.load(f)
        
        cities = data['locations']
        num_cities = len(cities)
        
        # Ensure cities are sorted by index for consistent matrix mapping
        cities.sort(key=lambda c: c['index'])
        
        # Initialize an empty matrix
        travel_matrix = np.zeros((num_cities, num_cities), dtype=int)
        
        print(f"Processing {num_cities} cities...")
        
        # Iterate through all unique pairs of cities
        for i in range(num_cities):
            for j in range(i, num_cities):
                if i == j:
                    continue # No travel needed to the same city
                    
                city1 = cities[i]
                city2 = cities[j]
                
                # Calculate the distance between the two cities
                distance = calculate_haversine_distance(city1['lat'], city1['lng'], city2['lat'], city2['lng'])
                
                # Classify the path
                travel_mode = classify_travel_path(city1['lat'], city1['lng'], city2['lat'], city2['lng'], distance)
                
                # Populate the matrix symmetrically
                travel_matrix[i, j] = travel_mode
                travel_matrix[j, i] = travel_mode
                
        print("Travel matrix successfully built.")
        try:
            with open("../data/travel_matrix.json", 'w') as f:
                # Convert numpy array to a standard Python list for JSON serialization
                json.dump({"matrix": travel_matrix.tolist()}, f)
            print(f"Matrix successfully saved to JSON")
        except Exception as e:
            print(f"\nError saving matrix to JSON: {e}")
        return travel_matrix

    except FileNotFoundError:
        print(f"Error: The file {locations_file} was not found.")
        return None
    except (KeyError, IndexError) as e:
        print(f"Error: JSON data is missing a required key or is malformed: {e}")
        return None

# --- Usage Example ---
if __name__ == "__main__":
    # Ensure you have a 'locations.json' file in the same directory
    # with the format: {"locations": [{"city": "...", "lat": ..., "lng": ..., "index": ...}]}
    matrix = build_travel_matrix("locations.json")
    
    if matrix is not None:    
        # --- Calculate and print the counts for each travel mode ---
        # To avoid double-counting, we only look at the upper triangle of the matrix.
        # k=1 excludes the main diagonal (city-to-itself paths).
        num_cities = matrix.shape[0]
        upper_triangle_indices = np.triu_indices(num_cities, k=1)
        unique_paths = matrix[upper_triangle_indices]
        
        # Get the unique values (0 - 3) and their counts
        modes, counts = np.unique(unique_paths, return_counts=True)
        
        # Create a dictionary for easy lookup
        count_dict = dict(zip(modes, counts))
        
        print("\nTravel Mode Path Counts:")
        print(f"  - Car (0):   {count_dict.get(0, 0)} paths")
        print(f"  - Boat (1):   {count_dict.get(1, 0)} paths")
        print(f"  - Train (2):  {count_dict.get(2, 0)} paths")
        print(f"  - Plane (3):  {count_dict.get(3, 0)} paths")
