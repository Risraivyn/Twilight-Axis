/datum/action/cooldown/spell/projectile/giantrock
	button_icon = 'icons/mob/actions/mage_geomancy.dmi'
	name = "Giant Rock"
	desc = "Flying piece of stone."
	button_icon_state = "meteor_storm"
	sound = 'sound/magic/xylix_slip_fail.ogg'
	spell_color = GLOW_COLOR_EARTHEN
	glow_intensity = GLOW_INTENSITY_LOW

	projectile_type = /obj/projectile/giantrock
	cast_range = 7

	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = 30

	invocations = list("SAXUM!")
	invocation_type = INVOCATION_SHOUT

	charge_required = TRUE
	charge_time = 3 SECONDS
	charge_drain = 1
	charge_slowdown = 3
	charge_sound = 'sound/magic/charging.ogg'
	cooldown_time = 30 SECONDS

	associated_skill = /datum/skill/magic/arcane
	spell_tier = 3
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC | SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

/obj/projectile/giantrock
	name = "elemental rock"
	icon_state = "rock"
	damage = 30
	damage_type = BRUTE
	flag = "magic"
	range = 15
	speed = 4 

/obj/structure/flora/rock/giant/Bumped(atom/movable/AM)
	..()
	if(isliving(AM))
		var/mob/living/L = AM
		L.adjustBruteLoss(20)
		to_chat(L, span_warning("You've been hit the [src]!"))

/obj/projectile/giantrock/on_hit(target)
	. = ..()
	var/turf/center = get_turf(target)
	if(!center)
		return

	playsound(center, 'sound/combat/hits/onstone/wallhit.ogg', 600, TRUE, 10)

	var/obj/effect/temp_visual/dust_pulse = new(center)
	dust_pulse.appearance_flags = RESET_TRANSFORM | PIXEL_SCALE
	dust_pulse.icon = 'icons/effects/effects.dmi' 
	dust_pulse.icon_state = "smoke"               
	dust_pulse.layer = ABOVE_MOB_LAYER           
	dust_pulse.color = "#8b4513"
	
	
	var/matrix/M = matrix()
	M.Scale(3) 
	animate(dust_pulse, transform = M, alpha = 0, time = 4, easing = EASE_OUT)
	QDEL_IN(dust_pulse, 5) 


	for(var/atom/movable/AM in range(1, center))
		if(AM.anchored || AM == src)
			continue

		var/turf/AM_turf = get_turf(AM)
		var/throw_dir

		if(AM_turf == center)
			throw_dir = src.dir 
			if(!throw_dir)
				throw_dir = pick(NORTH, SOUTH, EAST, WEST)
			if(isliving(AM))
				var/mob/living/L = AM
				L.Knockdown(30)
				
				if(L.client)
					shake_camera(L, 3, 2) 
				to_chat(L, span_userdanger("A powerful blow from the stone throws you back!"))
		else
			throw_dir = get_dir(center, AM)
			if(isliving(AM))
				var/mob/living/L = AM
				L.Knockdown(20)
				if(L.client)
					shake_camera(L, 2, 1)
				to_chat(L, span_danger("A powerful blow throws you back!"))

		if(throw_dir)
			var/turf/throw_to = get_edge_target_turf(center, throw_dir)
			var/dist = (AM_turf == center) ? 4 : 2
			AM.throw_at(throw_to, dist, 1, firer)

	
	var/list/possible_turfs = list()
	for(var/turf/open/T in orange(1, center))
		possible_turfs += T

	var/rocks_to_spawn = rand(0, 2) 
	for(var/i in 1 to rocks_to_spawn)
		if(!possible_turfs.len)
			break
		var/turf/chosen_turf = pick(possible_turfs)
		possible_turfs -= chosen_turf
		var/obj/structure/flora/rock/giant/giant_rock = new(chosen_turf)
		animate(giant_rock, pixel_x = rand(-2, 2), pixel_y = rand(-2, 2), time = 1, loop = -1)
		animate(pixel_x = 0, pixel_y = 0, time = 1)
		QDEL_IN(giant_rock, 100)

	qdel(src)
