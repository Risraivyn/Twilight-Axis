#define EQUALIZED_GLOW "equalizer glow"
#define CROWNFORTHEKING_GLOW "crown for the king glow"
#define FREEDOM_FILTER "freedom glow"
#define WEIGHTOFCHAINS_GLOW "weight of chains glow"

//T0

/obj/effect/proc_holder/spell/invoked/appraise
	overlay_state = "apprise"
	action_icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'

/obj/effect/proc_holder/spell/self/twilight_shacklebreaker
	name = "Shacklebreaker"
	desc = "Break anything restraining you, and protect yourself from being slowed down further."
	overlay_state = "shacklebreaker"
	action_icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'
	recharge_time = 3 MINUTES
	invocations = list("Отец, сломи мои цепи.",
		"Маттиос, не дай им сдержать меня.",
		"Отец Свободы, разрушь эти цепи."
	)
	invocation_type = "whisper"
	sound = 'sound/misc/chain_snap.ogg'
	releasedrain = 30
	miracle = TRUE
	devotion_cost = 40
	antimagic_allowed = FALSE

/obj/effect/proc_holder/spell/self/twilight_shacklebreaker/cast(list/targets, mob/user)
	. = ..()
	if(!ishuman(user))
		revert_cast()
		return FALSE
	var/mob/living/carbon/human/H = user
	if(H.handcuffed)
		var/obj/item/I = H.handcuffed
		H.clear_cuffs(I, cuff_break = TRUE)
	if(H.legcuffed)
		var/obj/item/I = H.legcuffed
		H.clear_cuffs(I, cuff_break = TRUE)
	H.apply_status_effect(/datum/status_effect/buff/twilight_freedom)
	return TRUE

/atom/movable/screen/alert/status_effect/buff/twilight_freedom
	name = "FREEDOM"
	desc = "Freed by the Father's grace, now run for it!"
	icon_state = "shacklebreaker_buff"
	icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'

/datum/status_effect/buff/twilight_freedom
	id = "twilight_freedom"
	alert_type = /atom/movable/screen/alert/status_effect/buff/twilight_freedom
	effectedstats = list(STATKEY_SPD = 3)
	var/outline_color = "#713b6d"
	duration = 15 SECONDS

/datum/status_effect/buff/twilight_freedom/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_IGNORESLOWDOWN, TRAIT_MIRACLE)
	var/holyskill = owner.get_skill_level(/datum/skill/magic/holy)
	duration = ((15 SECONDS) * holyskill)
	var/filter = owner.get_filter(FREEDOM_FILTER)
	if(!filter)
		owner.add_filter(FREEDOM_FILTER, 2, list("type" = "outline", "color" = outline_color, "alpha" = 60, "size" = 2))
	return TRUE

/datum/status_effect/buff/twilight_freedom/on_remove()
	. = ..()
	REMOVE_TRAIT(owner, TRAIT_IGNORESLOWDOWN, TRAIT_MIRACLE)
	owner.remove_filter(FREEDOM_FILTER)

/obj/effect/proc_holder/spell/invoked/twilight_weightofchains
	name = "Weight of Chains"
	desc = "Make those who would oppress others feel the burden of the chains they wield, slowing them down for each symbol of oppression they have on their person."
	overlay_state = "weightofchains"
	action_icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'
	clothes_req = FALSE
	associated_skill = /datum/skill/magic/holy
	chargedloop = /datum/looping_sound/invokeascendant
	sound = 'sound/magic/ENDVRE.ogg'
	chargedrain = 0
	chargetime = 15
	releasedrain = 30
	devotion_cost = 30
	no_early_release = TRUE
	antimagic_allowed = TRUE
	movement_interrupt = FALSE
	recharge_time = 2 MINUTES
	range = 4
	var/list/symbols_of_authority = list(
		/obj/item/rope,
		/obj/item/clothing/cloak/tabard/stabard/surcoat/guard,
		/obj/item/clothing/cloak/tabard/stabard/guard,
		/obj/item/clothing/cloak/tabard/knight,
		/obj/item/clothing/cloak/tabard/stabard/surcoat/bailiff,
		/obj/item/rogueweapon/mace/cudgel/justice,
		/obj/item/clothing/suit/roguetown/armor/brigandine/retinue,
		/obj/item/rogueweapon/lordscepter,
		/obj/item/clothing/head/roguetown/crown,
		/obj/item/clothing/head/roguetown/circlet,
		/obj/item/clothing/ring/signet,
		/obj/item/clothing/head/roguetown/priestmask,
		/obj/item/clothing/neck/roguetown/ornateamulet/noble,
		/obj/item/rogueweapon/woodstaff/aries
	)

/obj/effect/proc_holder/spell/invoked/twilight_weightofchains/cast(list/targets, mob/living/user)
	if(ishuman(targets[1]))
		var/mob/living/target = targets[1]
		var/has_chains = checksymbolsofauthority(target)
		if(has_chains == 0)
			to_chat(user, "<font color='yellow'>[target] wields no symbols of oppression... Perhaps I have misjudged them?</font>")
			revert_cast()
			return FALSE
		else
			switch(rand(1,3))
				if(1)
					user.say("Почувствуй вес наших оков!")
				if(2)
					user.say("Побудь в шкуре тех, кого ты угнетаешь!")
				if(3)
					user.say("Нам нечего терять, кроме наших цепей!")
			target.apply_status_effect(/datum/status_effect/debuff/twilight_weightofchains, has_chains)
			return TRUE
	revert_cast()
	return FALSE

/obj/effect/proc_holder/spell/invoked/twilight_weightofchains/proc/checksymbolsofauthority(atom/movable/target)
	var/symbols = 0
	for(var/obj/item/I in target.contents)
		if(is_type_in_list(I, symbols_of_authority))
			symbols++
		if(I.contents)
			symbols += checksymbolsofauthority(I)
	return symbols

/datum/status_effect/debuff/twilight_weightofchains
	id = "twilight_weightofchains"
	alert_type = /atom/movable/screen/alert/status_effect/debuff/twilight_weightofchains
	effectedstats = list(STATKEY_SPD = -2)
	duration = 1 MINUTES
	var/outline_colour = "#3f3149"

/datum/status_effect/debuff/twilight_weightofchains/on_creation(mob/living/new_owner, has_chains = 1)
	src.effectedstats = list(STATKEY_SPD = -1 * (has_chains * 2))
	return ..()

/atom/movable/screen/alert/status_effect/debuff/twilight_weightofchains
	name = "Weight of Chains"
	desc = "I feel the symbols of my authority weight down on me!"
	icon_state = "weightofchains_debuff"
	icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'

/datum/status_effect/debuff/twilight_weightofchains/on_apply()
	. = ..()
	owner.add_filter(WEIGHTOFCHAINS_GLOW, 2, list("type" = "outline", "color" = outline_colour, "alpha" = 200, "size" = 1))
	owner.visible_message(span_warning("[src] stumbles, suddenly finding it difficult to move!"), \
		span_userdanger("Suddenly, my equipment seems to weight a lot more than it used to! Its slowing me down!"))

/datum/status_effect/debuff/twilight_weightofchains/on_remove()
	. = ..()
	owner.remove_filter(WEIGHTOFCHAINS_GLOW)
	to_chat(owner, "<font color='yellow'>My equipment feels normal again.</font>")

// T1

/obj/effect/proc_holder/spell/invoked/twilight_equalize
	name = "Equalize"
	desc = "Force equality with the target, empowering yourself to match their Strength."
	overlay_state = "equalize"
	action_icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'
	clothes_req = FALSE
	associated_skill = /datum/skill/magic/holy
	chargedloop = /datum/looping_sound/invokeascendant
	sound = 'sound/magic/swap.ogg'
	chargedrain = 0
	chargetime = 15
	invocations = list("Сразись с кем-то твоего размера!",
		"Иди сюда и сражайся на равных, трус!"
	)
	invocation_type = "shout"
	releasedrain = 60
	devotion_cost = 40
	no_early_release = TRUE
	antimagic_allowed = TRUE
	movement_interrupt = FALSE
	recharge_time = 2 MINUTES
	range = 4


/obj/effect/proc_holder/spell/invoked/twilight_equalize/cast(list/targets, mob/living/user)
	if(ishuman(targets[1]))
		var/mob/living/target = targets[1]
		var/statchange = target.STASTR - user.STASTR
		user.apply_status_effect(/datum/status_effect/buff/twilight_equalizebuff, statchange)
		return TRUE
	revert_cast()
	return FALSE

 // buff
/datum/status_effect/buff/twilight_equalizebuff
	id = "equalize"
	alert_type = /atom/movable/screen/alert/status_effect/buff/twilight_equalized
	duration = 1 MINUTES
	var/outline_colour = "#FFD700"

/datum/status_effect/buff/twilight_equalizebuff/on_creation(mob/living/new_owner, statchange = 1)
	if(statchange != 0)
		src.effectedstats = list(STATKEY_STR = statchange)
	return ..()

/atom/movable/screen/alert/status_effect/buff/twilight_equalized
	name = "Equalized"
	desc = "Matthios grants you strength to face even the most wicked of tyrants."
	icon_state = "equalize_buff"
	icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'

/datum/status_effect/buff/twilight_equalizebuff/on_apply()
	. = ..()
	owner.add_filter(EQUALIZED_GLOW, 2, list("type" = "outline", "color" = outline_colour, "alpha" = 200, "size" = 1))

/datum/status_effect/buff/twilight_equalizebuff/on_remove()
	. = ..()
	owner.remove_filter(EQUALIZED_GLOW)
	to_chat(owner, "<font color='yellow'>My borrowed power fades, leaving me to fend for myself once more.</font>")

/obj/effect/proc_holder/spell/invoked/transact
	overlay_state = "transact"
	action_icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'

//T2

/obj/effect/proc_holder/spell/invoked/twilight_churnwealthy
	chargetime = 30
	action_icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'
	overlay_state = "churnwealthy"
	name = "Churn Wealthy"
	desc = "Attacks the target by weight of their greed, dealing increased damage and effects depending on how wealthy they are."
	clothes_req = FALSE
	associated_skill = /datum/skill/magic/holy
	chargedloop = /datum/looping_sound/invokeascendant
	chargedrain = 0
	releasedrain = 90
	no_early_release = TRUE
	antimagic_allowed = TRUE
	movement_interrupt = FALSE
	recharge_time = 2 MINUTES
	range = 4

/obj/effect/proc_holder/spell/invoked/twilight_churnwealthy/cast(list/targets, mob/living/user)
	if(ishuman(targets[1]))
		var/mob/living/carbon/human/target = targets[1]

		if(user.z != target.z) //Stopping no-interaction snipes
			to_chat(user, "<font color='yellow'>The Free-God compels me to face [target] on level ground before I transact.</font>")
			revert_cast()
			return
		var/mammonsonperson = get_mammons_in_atom(target)
		var/mammonsinbank = SStreasury.bank_accounts[target]
		var/totalvalue = mammonsinbank + mammonsonperson
		if(HAS_TRAIT(target, TRAIT_NOBLE))
			totalvalue += 101 // We're ALWAYS going to do a medium level smite minimum to nobles.
		if(totalvalue <=10)
			to_chat(user, "<font color='yellow'>[target] one has no wealth to hold against them.</font>")
			revert_cast()
			return
		if(totalvalue <=30)
			user.say("Жадность есть препятствие для свободы!")
			target.visible_message(span_danger("[target] is burned by holy light!"), span_userdanger("I feel the weight of my wealth burning at my soul!"))
			target.adjustFireLoss(30)
			playsound(user, 'sound/magic/churn.ogg', 100, TRUE)
			return
		if(totalvalue <=60)
			user.say("Жадность есть препятствие для свободы!")
			target.visible_message(span_danger("[target] is burned by holy light!"), span_userdanger("I feel the weight of my wealth burning at my soul!"))
			target.adjustFireLoss(60)
			playsound(user, 'sound/magic/churn.ogg', 100, TRUE)
			return
		if(totalvalue <=100)
			user.say("Жадность есть препятствие для свободы!")
			target.visible_message(span_danger("[target] is burned by holy light!"), span_userdanger("I feel the weight of my wealth burning at my soul!"))
			target.adjustFireLoss(80)
			target.Stun(20)
			playsound(user, 'sound/magic/churn.ogg', 100, TRUE)
			return
		if(totalvalue <=200)
			user.say("Бог Свободы отвергает тебя!")
			target.visible_message(span_danger("[target] is burned by holy light!"), span_userdanger("I feel the weight of my wealth tearing at my soul!"))
			target.adjustFireLoss(100)
			target.adjust_fire_stacks(7, /datum/status_effect/fire_handler/fire_stacks/divine)
			target.Stun(20)
			target.ignite_mob()
			playsound(user, 'sound/magic/churn.ogg', 100, TRUE)
			return
		if(totalvalue <=500)
			user.say("Бог Свободы отвергает тебя!")
			target.visible_message(span_danger("[target] is burned by holy light!"), span_userdanger("I feel the weight of my wealth tearing at my soul!"))
			target.adjustFireLoss(120)
			target.adjust_fire_stacks(9, /datum/status_effect/fire_handler/fire_stacks/divine)
			target.ignite_mob()
			target.Stun(40)
			playsound(user, 'sound/magic/churn.ogg', 100, TRUE)
			return
		if(totalvalue <= 2500)
			target.visible_message(span_danger("[target] is smited with holy light!"), span_userdanger("I feel the weight of my wealth rend my soul apart!"))
			user.say("Твоя последняя транзакция! Бог Свободы отвергает тебя!!")
			target.Stun(60)
			target.emote("agony")
			target.adjustFireLoss(140)
			target.adjust_fire_stacks(9, /datum/status_effect/fire_handler/fire_stacks/divine)
			target.ignite_mob()
			playsound(user, 'sound/magic/churn.ogg', 100, TRUE)
			explosion(get_turf(target), light_impact_range = 1, flame_range = 1, smoke = FALSE)
			return
		if(totalvalue >=2501) //THE POWER OF MY STAND: 'EXPLODE AND DIE INSTANTLY'
			target.visible_message(span_danger("[target]'s skin begins to SLOUGH AND BURN HORRIFICALLY, glowing like molten metal!"), span_userdanger("MY LIMBS BURN IN AGONY..."))
			user.say("Богатство сверх всякой меры - ТВОЯ ПОСЛЕДНЯЯ ТРАНЗАКЦИЯ!!")
			target.Stun(80)
			target.emote("agony")
			target.adjustFireLoss(50)
			target.adjust_fire_stacks(9, /datum/status_effect/fire_handler/fire_stacks/divine)
			target.ignite_mob()
			playsound(user, 'sound/magic/churn.ogg', 100, TRUE)
			explosion(get_turf(target), light_impact_range = 1, flame_range = 1, smoke = FALSE)
			sleep(80)

			target.visible_message(span_danger("[target]'s limbs REND into coin and gem!"), span_userdanger("WEALTH. POWER. THE FINAL SIGHT UPON MYNE EYE IS A DRAGON'S MAW TEARING ME IN TWAIN. MY ENTRAILS ARE OF GOLD AND SILVER."))
			playsound(user, 'sound/magic/churn.ogg', 100, TRUE)
			playsound(user, 'sound/magic/whiteflame.ogg', 100, TRUE)
			explosion(get_turf(target), light_impact_range = 1, flame_range = 1, smoke = FALSE)
			new /obj/item/roguecoin/silver/pile(target.loc)
			new /obj/item/roguecoin/gold/pile(target.loc)
			new /obj/item/roguegem/random(target.loc)
			new /obj/item/roguegem/random(target.loc)

			var/list/possible_limbs = list()
			for(var/zone in list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG))
				var/obj/item/bodypart/limb = target.get_bodypart(zone)
				if(limb)
					possible_limbs += limb
				var/limbs_to_gib = min(rand(1, 4), possible_limbs.len)
				for(var/i in 1 to limbs_to_gib)
					var/obj/item/bodypart/selected_limb = pick(possible_limbs)
					possible_limbs -= selected_limb
					if(selected_limb?.drop_limb())
						var/turf/limb_turf = get_turf(selected_limb) || get_turf(target) || target.drop_location()
						if(limb_turf)
							new /obj/effect/decal/cleanable/blood/gibs/limb(limb_turf)

			target.death()
			return

/obj/effect/proc_holder/spell/self/twilight_amongus
	name = "No Gods Among Us"
	desc = "Dispells all divine gifts applied to those who do not follow the Matthian creed around you, and all divine maluses that affect your allies."
	overlay_state = "nogodsamongus"
	action_icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'
	recharge_time = 5 MINUTES
	invocations = list("Нет богов среди нас!",
	"Ваши боги не защитят вас!")
	invocation_type = "shout"
	sound = 'sound/magic/timestop.ogg'
	releasedrain = 30
	miracle = TRUE
	devotion_cost = 90
	var/static/list/buffs_to_dispel = list(
	/datum/status_effect/buff/guidinglight,
	/datum/status_effect/buff/moonlightdance,
	/datum/status_effect/buff/undermaidenbargainheal,
	/datum/status_effect/buff/call_to_arms,
	/datum/status_effect/buff/call_to_slaughter,
	/datum/status_effect/buff/xylix_joy,
	/datum/status_effect/buff/vigorized,
	/datum/status_effect/buff/bloodrage,
	/datum/status_effect/buff/sermon,
	/datum/status_effect/buff/nocblessing,
	/datum/status_effect/buff/refocus,
	/datum/status_effect/buff/healing,
	/datum/status_effect/buff/psyhealing,
	/datum/status_effect/buff/convergence,
	/datum/status_effect/buff/stasis,
	/datum/status_effect/buff/order/movemovemove,
	/datum/status_effect/buff/order/takeaim,
	/datum/status_effect/buff/order/hold,
	/datum/status_effect/buff/order/onfeet,
	/datum/status_effect/buff/order/martyr_guidance,
	/datum/status_effect/buff/order/martyr_guidance/church,
	/datum/status_effect/buff/order/martyr_expedite,
	/datum/status_effect/buff/order/martyr_expedite/church,
	/datum/status_effect/buff/order/martyr_onfeet,
	/datum/status_effect/buff/order/martyr_onfeet/church,
	/datum/status_effect/buff/order/martyr_laststand,
	/datum/status_effect/buff/order/martyr_laststand/church,
	/datum/status_effect/buff/astrata_gaze,
	/datum/status_effect/buff/wise_moon,
	/datum/status_effect/buff/ravox_provocation,
	/datum/status_effect/buff/abyssal,
	/datum/status_effect/xylix_blessed_luck,
	/datum/status_effect/astrata_favor,
	/datum/status_effect/noc_favor,
	/datum/status_effect/ravox_favor,
	/datum/status_effect/malum_favor,
	/datum/status_effect/eora_favor,)
	var/static/list/debuffs_to_dispel = list(
	/datum/status_effect/incapacitating/immobilized,
	/datum/status_effect/incapacitating/paralyzed,
	/datum/status_effect/incapacitating/stun,
	/datum/status_effect/incapacitating/knockdown,
	/datum/status_effect/debuff/call_to_arms,
	/datum/status_effect/debuff/chilled,
	/datum/status_effect/debuff/ravox_burden,
	/datum/status_effect/debuff/call_to_slaughter,
	/datum/status_effect/debuff/hereticsermon,
	/datum/status_effect/debuff/mesmerised,
	/datum/status_effect/debuff/necrandeathdoorwilloss,
	/datum/status_effect/debuff/eoran_wilting,
	/datum/status_effect/debuff/viciousmockery,)

/obj/effect/proc_holder/spell/self/twilight_amongus/cast(list/targets,mob/living/user = usr)
	for(var/mob/living/carbon/target in view(5, get_turf(user)))
		if(istype(target.patron, /datum/patron/inhumen/matthios))
			for(var/effect in debuffs_to_dispel)
				target.remove_status_effect(effect)
		else if(istype(target.patron, /datum/patron/old_god))
			to_chat(target, span_danger("You feel a surge of cold wash over you; leaving your body as quick as it hit.."))
		else
			for(var/effect in buffs_to_dispel)
				target.remove_status_effect(effect)
	return TRUE

/obj/effect/proc_holder/spell/invoked/projectile/twilight_crownfortheking
	name = "Crown for the King"
	desc = "Hurl a glob of molten gold at the target. While under the Crown, the target is blinded, silenced and is constantly burnt."
	range = 8
	projectile_type = /obj/projectile/magic/twilight_crownfortheking
	overlay_state = "crownfortheking"
	action_icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'
	sound = list('sound/magic/whiteflame.ogg')
	active = FALSE

	releasedrain = 30
	chargedrain = 0
	chargetime = 10
	recharge_time = 2 MINUTES //cooldown
	devotion_cost = 60

	no_early_release = TRUE
	movement_interrupt = FALSE
	antimagic_allowed = TRUE
	invocations = list("Корона для короля!")
	invocation_type = "shout"
	charging_slowdown = 3
	chargedloop = /datum/looping_sound/invokeascendant
	associated_skill = /datum/skill/magic/holy
	miracle = TRUE

/obj/effect/proc_holder/spell/self/twilight_crownfortheking/cast(mob/user = usr)
	var/mob/living/target = user
	target.visible_message(span_warning("[target] hurls an orb of molten gold!"), span_notice("You hurl an orb of molten gold!"))
	. = ..()

/obj/projectile/magic/twilight_crownfortheking
	name = "molten gold"
	icon_state = "pulse0_bl"
	damage = 10
	damage_type = BURN
	flag = "magic"
	range = 15
	speed = 3 //higher is slower

/obj/projectile/magic/twilight_crownfortheking/on_hit(atom/target, blocked = FALSE)
	. = ..()
	playsound(src, 'sound/misc/drink_blood.ogg', 100)
	if(isliving(target))
		var/mob/living/T = target
		T.apply_status_effect(/datum/status_effect/debuff/twilight_crownfortheking)

/datum/status_effect/debuff/twilight_crownfortheking
	id = "twilight_crownfortheking"
	alert_type = /atom/movable/screen/alert/status_effect/debuff/twilight_crownfortheking
	duration = 10 SECONDS
	var/const/blindness_amount = 20 // 20 should be plenty to keep the victim blind between tick()s
	var/outline_colour = "#998d5f"

/datum/status_effect/debuff/twilight_crownfortheking/on_apply()
	. = ..()
	owner.playsound_local(get_turf(owner), 'sound/misc/lava_death.ogg', 35, FALSE, pressure_affected = FALSE)
	owner.visible_message(span_warning("[owner] is covered in molten gold!"), span_danger("I am covered in molten gold! I cannot see!"))
	owner.emote("scream")
	owner.adjust_blindness(blindness_amount)
	ADD_TRAIT(owner, TRAIT_MUTE, id)
	owner.add_filter(CROWNFORTHEKING_GLOW, 2, list("type" = "outline", "color" = outline_colour, "alpha" = 200, "size" = 1))
	var/fire_icon = "sunder_burning"
	var/mutable_appearance/new_fire_overlay = mutable_appearance('icons/mob/OnFire.dmi', fire_icon, -FIRE_LAYER)
	new_fire_overlay.color = outline_colour
	new_fire_overlay.appearance_flags = RESET_COLOR
	owner.overlays_standing[FIRE_LAYER] = new_fire_overlay
	owner.apply_overlay(FIRE_LAYER)

/datum/status_effect/debuff/twilight_crownfortheking/tick()
	var/mob/living/target = owner
	target.adjustFireLoss(10)
	target.set_blindness(max(owner.eye_blind, blindness_amount))

/datum/status_effect/debuff/twilight_crownfortheking/on_remove()
	..()
	owner.adjust_blindness(-blindness_amount)
	REMOVE_TRAIT(owner, TRAIT_MUTE, id)
	owner.remove_filter(CROWNFORTHEKING_GLOW)
	for(var/obj/effect/dummy/lighting_obj/moblight/fire/F in owner)
		qdel(F)
	owner.remove_overlay(FIRE_LAYER)

/atom/movable/screen/alert/status_effect/debuff/twilight_crownfortheking
	name = "Crown for the King"
	desc = "There is molten gold all over me! It burns!!"
	icon_state = "crownfortheking_debuff"
	icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'

//T3

/obj/effect/proc_holder/spell/invoked/twilight_commieflag
	name = "The People's Banner"
	desc = "Summon a Matthian banner and rally your comrades. So long as the banner is in your hands, you and your allies cannot be slowed down, and your will to fight strenghtens."
	clothes_req = FALSE
	overlay_state = "peoplesbanner"
	action_icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'
	invocations = list("Товарищи, сплотитесь вокруг штандарта Отца Свободы!",
	"Мы вырвем нашу свободу из их хладных рук!")
	invocation_type = "shout"
	chargedrain = 0
	chargetime = 2 SECONDS
	releasedrain = 30
	chargedloop = /datum/looping_sound/invokeascendant
	associated_skill = /datum/skill/magic/holy
	devotion_cost = 90
	miracle = TRUE
	recharge_time = 5 MINUTES
	sound = list('sound/magic/whiteflame.ogg')
	no_early_release = TRUE
	movement_interrupt = TRUE
	antimagic_allowed = TRUE
	charging_slowdown = 3
	glow_color = GLOW_COLOR_METAL
	glow_intensity = GLOW_INTENSITY_LOW
	var/obj/item/rogueweapon/conjured_weapon = null

/obj/effect/proc_holder/spell/invoked/twilight_commieflag/cast(list/targets, mob/living/user = usr)
	if(user.get_num_arms(FALSE) < 1 || (user.get_inactive_held_item() && user.get_active_held_item()))
		to_chat(user, "<span class='notice'>I need a free hand to hold the People's Banner!</span>")
		revert_cast(user)
		return

	if(src.conjured_weapon)
		qdel(src.conjured_weapon)

	var/obj/item/rogueweapon/R = new /obj/item/rogueweapon/spear/matthios_standard(user.drop_location())
	R.blade_dulling = DULLING_SHAFT_CONJURED
	if(!QDELETED(R))
		R.AddComponent(/datum/component/conjured_item, GLOW_COLOR_DISPLACEMENT)
	user.put_in_hands(R)
	ADD_TRAIT(R, TRAIT_NODROP, ABSTRACT_ITEM_TRAIT)
	src.conjured_weapon = R
	return TRUE

/obj/effect/proc_holder/spell/invoked/twilight_commieflag/Destroy()
	if(src.conjured_weapon)
		conjured_weapon.visible_message(span_warning("The [conjured_weapon]'s borders begin to shimmer and fade, before it vanishes entirely!"))
		qdel(src.conjured_weapon)
	return ..()

/obj/item/rogueweapon/spear/matthios_standard
	name = "people's banner"
	desc = "The banner of those who would stand against tyranny and oppression, proudly bearing the sigil of Matthios, Father of Freedom"
	force = 0
	force_wielded = 0
	wdefense = 1
	possible_item_intents = list(/datum/intent/spear/thrust/ducal_standard)
	icon = 'modular_twilight_axis/icons/roguetown/weapons/64.dmi'
	icon_state = "matthios_standard"
	resistance_flags = FIRE_PROOF

/obj/item/rogueweapon/spear/matthios_standard/proc/skillcheck()
	var/skill = usr.get_skill_level(/datum/skill/magic/holy)
	wdefense += skill
	wdefense_dynamic += skill
	if(skill <= 4)
		force = 5 * skill
	else
		force = 20
	
/obj/item/rogueweapon/spear/matthios_standard/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(skillcheck), src), wait = 1)
	for(var/mob/living/carbon/human/H in view(7, get_turf(src)))
		if(istype(H.patron, /datum/patron/inhumen/matthios))
			H.apply_status_effect(/datum/status_effect/buff/twilight_peoplesbanner)

/obj/item/rogueweapon/spear/matthios_standard/attack_self(mob/living/user)
	to_chat(user, "<span class='notice'>You begin dispelling the [src.name]...</span>")
	if(do_after(user, 3 SECONDS, src))
		qdel(src)

/atom/movable/screen/alert/status_effect/buff/twilight_peoplesbanner
	name = "The People's Banner"
	desc = "The sigil of Matthios inspires me to fight on!"
	icon_state = "peoplesbanner_buff"
	icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'

/datum/status_effect/buff/twilight_peoplesbanner
	id = "twilight_peoplesbanner"
	alert_type = /atom/movable/screen/alert/status_effect/buff/twilight_peoplesbanner
	effectedstats = list(STATKEY_WIL = 3, STATKEY_SPD = 2)
	var/lastcheck = 0

/datum/status_effect/buff/twilight_peoplesbanner/process()
	.=..()
	if(!(world.time < lastcheck + 5 SECONDS))
		lastcheck = world.time
		var/preserve = FALSE
		for(var/mob/living/carbon/human/H in view(7, owner))
			if(istype(H.get_inactive_held_item(), /obj/item/rogueweapon/spear/matthios_standard) || istype(H.get_active_held_item(), /obj/item/rogueweapon/spear/matthios_standard))
				preserve = TRUE
		if(!preserve)
			owner.remove_status_effect(/datum/status_effect/buff/twilight_peoplesbanner)

/datum/status_effect/buff/twilight_peoplesbanner/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_IGNORESLOWDOWN, id)
	owner.add_stress(/datum/stressevent/twilight_peoplesbanner_good)

/datum/status_effect/buff/twilight_peoplesbanner/on_remove()
	. = ..()
	REMOVE_TRAIT(owner, TRAIT_IGNORESLOWDOWN, id)
	owner.remove_stress(/datum/stressevent/twilight_peoplesbanner_good)

/datum/status_effect/debuff/twilight_peoplesbanner
	id = "twilight_peoplesbanner"
	alert_type = /atom/movable/screen/alert/status_effect/debuff/twilight_peoplesbanner
	var/lastcheck = 0

/datum/status_effect/debuff/twilight_peoplesbanner/process()
	.=..()
	if(!(world.time < lastcheck + 5 SECONDS))
		lastcheck = world.time
		var/preserve = FALSE
		for(var/mob/living/carbon/human/H in view(7, owner))
			if(istype(H.get_inactive_held_item(), /obj/item/rogueweapon/spear/matthios_standard) || istype(H.get_active_held_item(), /obj/item/rogueweapon/spear/matthios_standard))
				preserve = TRUE
		if(!preserve)
			owner.remove_status_effect(/datum/status_effect/debuff/twilight_peoplesbanner)

/atom/movable/screen/alert/status_effect/debuff/twilight_peoplesbanner
	name = "The People's Banner"
	desc = "That horrid sigil! How dare they?!"
	icon_state = "peoplesbanner_debuff"
	icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'

/datum/status_effect/debuff/twilight_peoplesbanner/on_apply()
	. = ..()
	owner.add_stress(/datum/stressevent/twilight_peoplesbanner_bad)

/datum/status_effect/debuff/twilight_peoplesbanner/on_remove()
	. = ..()
	owner.remove_stress(/datum/stressevent/twilight_peoplesbanner_bad)

/datum/stressevent/twilight_peoplesbanner_good
	timer = 999 MINUTES
	stressadd = -3
	desc = span_green("The sigil of Matthios inspires me to fight on!")

/datum/stressevent/twilight_peoplesbanner_bad
	timer = 999 MINUTES
	stressadd = 3
	desc = span_green("That horrid sigil! How dare they?!")

//T4

/obj/effect/proc_holder/spell/targeted/shapeshift/twilight_wingsoffreedom
	name = "Wings of Freedom"
	desc = "Transform into the strongest form of Matthios' own - a dragon. A mere mortal can't sustain this form for long, yet with the power Matthios grants you, you shall burn this world of tyranny to the ground."
	overlay_state = "wingsoffreedom"
	action_icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'
	clothes_req = FALSE
	human_req = FALSE
	chargedrain = 0
	chargetime = 0
	recharge_time = 10 MINUTES
	cooldown_min = 50
	invocations = list("Я сожгу мир тирании дотла!!")
	invocation_type = "shout"
	associated_skill = /datum/skill/magic/holy
	devotion_cost = 200
	miracle = TRUE
	die_with_shapeshifted_form = FALSE
	do_gib = FALSE
	knockout_on_death = 30 SECONDS
	shapeshift_type = /mob/living/simple_animal/hostile/retaliate/rogue/dragon/matthios
	sound = 'sound/vo/mobs/vdragon/drgnroar.ogg'

/obj/effect/proc_holder/spell/targeted/shapeshift/twilight_wingsoffreedom/Shapeshift(mob/living/carbon/human/caster)
	if(!istype(caster)) // FVCK OFF
		return

	var/obj/shapeshift_holder/H = locate() in caster
	if(H)
		to_chat(caster, span_warning("You're already shapeshifted!"))
		revert_cast(caster)
		return

	if(!do_after(caster, 10 SECONDS, target = caster))
		to_chat(caster, span_userdanger("You are unable to concentrate enough to shapeshift!"))
		revert_cast(caster)
		return

	var/mob/living/simple_animal/hostile/retaliate/rogue/dragon/matthios/shape = new shapeshift_type(caster.loc)
	if(caster.mind)
		for(var/obj/effect/proc_holder/S in caster.mind.spell_list)
			if(!istype(S, /obj/effect/proc_holder/spell/targeted/shapeshift/twilight_wingsoffreedom))
				shape.spells_list += S.type
				caster.mind.RemoveSpell(S)
	H = new(shape,src,caster)
	shape.apply_status_effect(/datum/status_effect/buff/twilight_dragon_form, src)
	clothes_req = FALSE
	human_req = FALSE

	if(do_gib)
		playsound(caster.loc, pick('sound/combat/gib (1).ogg','sound/combat/gib (2).ogg'), 200, FALSE, 3)
		caster.spawn_gibs(FALSE)

/mob/living/simple_animal/hostile/retaliate/rogue/dragon/matthios
	name = "Dragon"
	desc = "It has been a very long time since the dragons ruled the skies, yet their power still remains formiddable. Despite their monstrous form, ancient intelligence in their eyes betrays their sentience."
	inherent_spells = list(/obj/effect/proc_holder/spell/invoked/projectile/fireball/greater/matthios_dragon,
	/obj/effect/proc_holder/spell/invoked/projectile/spitfire/matthios_dragon)
	del_on_deaggro = null
	var/list/spells_list = list()

/mob/living/simple_animal/hostile/retaliate/rogue/dragon/matthios/Initialize()
	. = ..()
	ai_controller = null

/mob/living/simple_animal/hostile/retaliate/rogue/dragon/matthios/death(gibbed)
	if(src.mind)
		for(var/S in spells_list)
			src.mind.AddSpell(new S, src)
	..()

/datum/status_effect/buff/twilight_dragon_form
	id = "twilight_dragon_form"
	alert_type = /atom/movable/screen/alert/status_effect/buff/twilight_dragon_form
	duration = 4 MINUTES
	var/obj/effect/proc_holder/spell/targeted/shapeshift/twilight_wingsoffreedom/base_spell

/datum/status_effect/buff/twilight_dragon_form/on_creation(mob/living/new_owner, spell)
	if(spell)
		base_spell = spell
	return ..()

/atom/movable/screen/alert/status_effect/buff/twilight_dragon_form
	name = "Dragon Form"
	desc = "Burn them! Burn them all!"
	icon_state = "wingsoffreedom_buff"
	icon = 'modular_twilight_axis/icons/mob/actions/matthios_miracles.dmi'

/datum/status_effect/buff/twilight_dragon_form/on_remove()
	. = ..()
	var/obj/shapeshift_holder/H = locate() in owner
	if(H && base_spell)
		if(owner.mind && istype(owner, /mob/living/simple_animal/hostile/retaliate/rogue/dragon/matthios))
			var/mob/living/simple_animal/hostile/retaliate/rogue/dragon/matthios/D = owner
			for(var/S in D.spells_list)
				D.mind.AddSpell(new S, D)
		base_spell.Restore(owner)

/obj/effect/proc_holder/spell/invoked/projectile/fireball/greater/matthios_dragon
	invocation_type = "none"

/obj/effect/proc_holder/spell/invoked/projectile/spitfire/matthios_dragon
	invocation_type = "none"

#undef EQUALIZED_GLOW
#undef FREEDOM_FILTER
#undef CROWNFORTHEKING_GLOW
#undef WEIGHTOFCHAINS_GLOW
