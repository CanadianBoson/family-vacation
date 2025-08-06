# Utils.gd
extends Node

# Earth's radius in kilometers for Haversine formula
const EARTH_RADIUS_KM = 6371.0

# This function can now be called from anywhere in your project.
func calculate_haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var R = EARTH_RADIUS_KM
	var phi1 = deg_to_rad(lat1)
	var phi2 = deg_to_rad(lat2)
	var delta_phi = deg_to_rad(lat2 - lat1)
	var delta_lambda = deg_to_rad(lon2 - lon1)

	var a = sin(delta_phi / 2) * sin(delta_phi / 2) + \
			cos(phi1) * cos(phi2) * \
			sin(delta_lambda / 2) * sin(delta_lambda / 2)
	var c = 2 * atan2(sqrt(a), sqrt(1 - a))
	var d = R * c
	return d

func on_segment(p: Vector2, q: Vector2, r: Vector2) -> bool:
	return (q.x <= max(p.x, r.x) and q.x >= min(p.x, r.x) and
			q.y <= max(p.y, r.y) and q.y >= min(p.y, r.y))

func orientation(p: Vector2, q: Vector2, r: Vector2) -> int:
	var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
	if val == 0: return 0
	return 1 if val > 0 else 2

func segments_intersect(p1: Vector2, q1: Vector2, p2: Vector2, q2: Vector2) -> bool:
	var o1 = orientation(p1, q1, p2)
	var o2 = orientation(p1, q1, q2)
	var o3 = orientation(p2, q2, p1)
	var o4 = orientation(p2, q2, q1)
	if (o1 != o2 and o3 != o4): return true
	if (o1 == 0 and on_segment(p1, p2, q1)): return true
	if (o2 == 0 and on_segment(p1, q2, q1)): return true
	if (o3 == 0 and on_segment(p2, p1, q2)): return true
	if (o4 == 0 and on_segment(p2, q1, q2)): return true
	return false

# Calculates the cost of a single leg of the journey based on a non-linear model.
# Prices are rough estimates for a European tourist season and scale with sqrt(distance).
func calculate_leg_cost(transport_type: int, distance_km: float, num_menu_items: int) -> float:
	var base_cost = 0.0
	var per_km_sqrt_coeff = 0.0 # This is the coefficient for the square root of the distance
	var family_multiplier = float(num_menu_items)

	match transport_type:
		0: # Car (Represents a rental car)
			base_cost = 120.0
			per_km_sqrt_coeff = 3.0
			family_multiplier = 1.0
		1: # Boat (Ferry)
			base_cost = 40.0
			per_km_sqrt_coeff = 5.0
		2: # Train
			base_cost = 60.0
			per_km_sqrt_coeff = 8.0
		3: # Plane (Budget Airline)
			base_cost = 150.0
			per_km_sqrt_coeff = 15.0

	# The formula now uses the square root of the distance for non-linear scaling.
	# This makes very long trips less punishingly expensive.
	return (base_cost + (sqrt(distance_km) * per_km_sqrt_coeff)) * family_multiplier
