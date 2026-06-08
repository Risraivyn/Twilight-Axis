/datum/action/cooldown/spell/swap
	button_icon = 'icons/mob/actions/roguespells.dmi'
	name = "Swap Places"
	desc = "Switch locations with a target you can see. Can pass through glass and bars."
	button_icon_state = "knowledge"
	sound = 'sound/magic/blink.ogg'
	spell_color = GLOW_COLOR_DISPLACEMENT
	glow_intensity = GLOW_INTENSITY_LOW

	click_to_activate = TRUE
	cast_range = 7

	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = 25

	invocations = list("Pachisto!")
	invocation_type = INVOCATION_SHOUT

	charge_required = TRUE
	charge_time = 3 SECONDS
	charge_drain = 1
	charge_slowdown = CHARGING_SLOWDOWN_SMALL
	charge_sound = 'sound/magic/charging.ogg'
	cooldown_time = 40 SECONDS

	associated_skill = /datum/skill/magic/arcane
	spell_tier = 3
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC | SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

	var/phase_effect = /obj/effect/temp_visual/blink

/datum/action/cooldown/spell/swap/cast(atom/cast_on)
	. = ..()
	var/mob/living/carbon/human/user = owner
	if(!istype(user))
		return FALSE

	var/atom/movable/target = cast_on
	if(!istype(target))
		to_chat(user, span_warning("You can't swap with that!"))
		return FALSE

	if(!isliving(target) && !isitem(target))
		to_chat(user, span_warning("You can't swap with that!"))
		return FALSE

	if(!isturf(target.loc))
		to_chat(user, span_warning("[target] must be on the ground!"))
		return FALSE

	if(target.anchored && !isliving(target))
		to_chat(user, span_warning("[target] is fixed in place!"))
		return FALSE

	var/turf/user_turf = get_turf(user)
	var/turf/target_turf = get_turf(target) 

	if(!target_turf || !user_turf || target_turf.z != user_turf.z)
		return FALSE

	if(target == user)
		to_chat(user, span_warning("You are already here!"))
		return FALSE

	if(!(target in view(cast_range, user)))
		to_chat(user, span_warning("Target is too far!"))
		return FALSE

	if(target_turf.density)
		to_chat(user, span_warning("The target's location is too solid to materialize!"))
		return FALSE

	new phase_effect(user_turf)
	new phase_effect(target_turf)
	playsound(user_turf, 'sound/magic/blink.ogg', 50, TRUE)
	playsound(target_turf, 'sound/magic/blink.ogg', 50, TRUE)

	if(user.buckled)
		user.buckled.unbuckle_mob(user, TRUE)
	if(isliving(target))
		var/mob/living/L = target
		if(L.buckled)
			L.buckled.unbuckle_mob(L, TRUE)

	target.forceMove(user_turf)
	do_teleport(user, target_turf, channel = TELEPORT_CHANNEL_MAGIC)

	user.visible_message(span_danger("<b>[user]</b> swaps places with <b>[target]</b>!"), \
						 span_notice("You swap places with [target]!"))
	
	return TRUE
