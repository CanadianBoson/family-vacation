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
