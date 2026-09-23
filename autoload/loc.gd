extends Node

func t(key: String) -> String:
	var trs := tr(key)
	if trs == key:
		return key
	return trs

func gender_form(male: String, female: String) -> String:
	return male if Game.hero.get("gender", "m") == "m" else female
