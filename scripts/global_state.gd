# global_state.gd
extends Node

var confirmed_family = []
var initial_difficulty = 1
var current_trip_quests = []
var mode = "family"
var used_trip_ids = []
var firebase_data = []
var firebase_updated = false
var leaders = []
var is_sound_enabled = true
