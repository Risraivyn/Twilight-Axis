/datum/supply_pack/rogue/valoria
	group = "Cultural Stock"
	crate_name = "Valorian crate"
	crate_type = /obj/structure/closet/crate/chest/merchant
	not_in_public = TRUE

/datum/supply_pack/rogue/valoria/valorian_swords
	name = "Valorian Blades"
	cost = 140
	contains = list(/obj/item/rogueweapon/example/valorian_sword, /obj/item/rogueweapon/example/valorian_broadsword)
	ship_qty_min = 1
	ship_qty_max = 4

/datum/supply_pack/rogue/valoria/valorian_greatsword
	name = "Valorian Claymore"
	cost = 360
	contains = list(/obj/item/rogueweapon/example/valorian_greatsword)
	ship_qty_min = 1
	ship_qty_max = 1

/datum/supply_pack/rogue/valoria/valorian_plate
	name = "Valorian Plate"
	cost = 480
	contains = list(/obj/item/clothing/suit/roguetown/armor/plate/full)
	ship_qty_min = 1
	ship_qty_max = 2
