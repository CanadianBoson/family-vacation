# global_state.gd
extends Node

# This array will store the confirmed family members from the FamilyScene.
# Each item will be a dictionary, e.g., {"name": "Erik", "family_key": "Merchants", "gender": "male"}
var confirmed_family = []
# --- New: Store the difficulty set by the player ---
var initial_difficulty = 1 # Default to 1
var current_trip_quests = []
