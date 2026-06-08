/datum/action/cooldown/spell/projectile/snowball_toss
	button_icon = 'modular_twilight_axis/icons/mob/actions/roguespells.dmi'
	name = "Frost Sphere"
	desc = "Запускает магический снежный шар. При попадании наносит урон и накладывает 2 стака обморожения."
	button_icon_state = "pulse1"
	spell_color = "#00ffff"
	glow_intensity = GLOW_INTENSITY_LOW

	projectile_type = /obj/projectile/magic/frost_sphere
	cast_range = 7

	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = 5

	invocations = list("GLACIES CUSPIS!")
	invocation_type = INVOCATION_SHOUT

	charge_required = TRUE
	charge_time = 0.8 SECONDS
	charge_drain = 1
	charge_slowdown = CHARGING_SLOWDOWN_SMALL
	charge_sound = 'sound/magic/charging.ogg'
	cooldown_time = 21 SECONDS

	associated_skill = /datum/skill/magic/arcane
	spell_tier = 2
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC | SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

/datum/action/cooldown/spell/projectile/snowball_toss/cast(atom/cast_on)
	. = ..()
	var/mob/living/caster = owner
	if(caster)
		caster.visible_message(span_warning("<b>[caster]</b> throws a massive lump of ice and snow!"))
	return TRUE


/obj/projectile/magic/frost_sphere
	name = "magic snowball"
	icon_state = "pulse1" 
	damage = 45
	damage_type = BRUTE
	nodamage = FALSE
	flag = "magic"
	speed = 1.0
	range = 15
	hitsound = 'sound/spellbooks/icicle.ogg'

/obj/projectile/magic/frost_sphere/on_hit(target)
	var/turf/T = get_turf(target)
	
	
	new /obj/effect/temp_visual/snap_freeze(T)
	playsound(T, 'sound/magic/whiteflame.ogg', 40, TRUE)

	if(isliving(target))
		var/mob/living/L = target
		if(!L.anti_magic_check())
			
			L.apply_status_effect(/datum/status_effect/stacking/hypothermia, 2)

			var/push_dir = get_dir(firer, L)
			if(push_dir)
				
				step(L, push_dir)
			
			to_chat(L, span_warning("A heavy snowball throws me back!"))

	return ..()
