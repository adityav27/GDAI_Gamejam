extends Node

signal is_player_detected(state : bool)
signal damage_player(damage : float)
signal regen_player

var is_player_invisible : bool
var is_player_dead : bool

var is_keycard_1 : bool
var is_keycard_2 : bool
var is_keycard_3 : bool
var is_keycard_4 : bool
