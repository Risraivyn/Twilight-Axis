/datum/action/cooldown/spell/grand_meteor
	button_icon = 'icons/mob/actions/mage_geomancy.dmi'
	name = "Cataclysmic Meteor"
	desc = "Summons a massive meteor. High destruction, high cost."
	button_icon_state = "meteor_storm"
	sound = 'sound/magic/meteorstorm.ogg'
	spell_color = GLOW_COLOR_EARTHEN
	glow_intensity = GLOW_INTENSITY_LOW

	click_to_activate = TRUE
	cast_range = 7

	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = 40

	invocations = list("Anborno!")
	invocation_type = INVOCATION_SHOUT

	charge_required = TRUE
	charge_time = 2.5 SECONDS
	charge_drain = 2
	charge_slowdown = CHARGING_SLOWDOWN_HEAVY
	charge_sound = 'sound/magic/charging.ogg'
	cooldown_time = 60 SECONDS

	associated_skill = /datum/skill/magic/arcane
	spell_tier = 3
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC | SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

/datum/action/cooldown/spell/grand_meteor/cast(atom/cast_on)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE

	var/turf/T = get_turf(cast_on)
	if(!T)
		return FALSE

	if(!(T in view(H)))
		to_chat(H, span_warning("I aimed incorrectly and my concentration was knocked down!"))
		return FALSE
	
	T.visible_message(span_boldwarning("A massive shadow covers the area..."))
	new /obj/effect/temp_visual/target/massive(T)
	return TRUE

/obj/effect/temp_visual/fireball/massive
	name = "colossal meteor"
	desc = "A planet-killer heading straight for you."
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "meteor"
	duration = 25 
	pixel_z = 600
	plane = GAME_PLANE_UPPER 
	layer = MASSIVE_OBJ_LAYER 
	randomdir = FALSE

/obj/effect/temp_visual/fireball/massive/Initialize(mapload)
	. = ..()
	
	var/matrix/M = matrix()
	M.Scale(6, 6)
	transform = M
	

	pixel_x = 0
	pixel_y = 0

	animate(src, pixel_z = 0, time = duration, easing = EASE_IN)

/obj/effect/temp_visual/target/massive
	name = "impending doom"
	desc = "The ground is heating up..."
	duration = 40 
	plane = GAME_PLANE_LOWER 
	layer = LOW_SIGIL_LAYER 
	

	exp_heavy = -1 
	exp_light = 2  
	exp_flash = 3  
	exp_fire = 3  

/obj/effect/temp_visual/target/massive/Initialize(mapload)
	. = ..()
	
	var/matrix/M = matrix()
	M.Scale(5, 5)
	transform = M
	

	pixel_x = 0
	pixel_y = 0
	
	INVOKE_ASYNC(src, PROC_REF(fall_massive))

/obj/effect/temp_visual/target/massive/fall()
	return

/obj/effect/temp_visual/target/massive/proc/fall_massive()
	var/turf/T = get_turf(src)
	if(!T) 
		return

	new /obj/effect/temp_visual/fireball/massive(T)
	
	sleep(25)
	
	if(!T)
		return

	for(var/mob/living/L in range(12, T))
		shake_camera(L, 12, 4)

	playsound(T, 'sound/misc/explode/explosiongreat.ogg', 150, TRUE)
	T.visible_message(span_userdanger("<b>THE METEOR IMPACTS!</b>"))
	

	for(var/turf/nearby in range(6, T))
		var/dist = get_dist(T, nearby)
		for(var/mob/living/L in nearby.contents)
			if(dist <= 0)
				L.adjustBruteLoss(100)
				L.adjustFireLoss(100)
				L.Knockdown(60)
			else if(dist <= 3)
				L.adjustFireLoss(60)
				L.adjustBruteLoss(40)
				L.Knockdown(60)
			else
				L.adjustFireLoss(20)


	explosion(T, -1, exp_heavy, exp_light, exp_flash, 0, flame_range = exp_fire)
	

	for(var/turf/open/OT in range(2, T))
		if(prob(40) && isopenturf(OT))
			new /obj/effect/hotspot(OT)

	qdel(src)
