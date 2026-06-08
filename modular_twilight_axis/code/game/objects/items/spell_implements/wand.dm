/obj/projectile/magic/spell/wand_bolt
	name = "wand bolt"
	icon_state = "spell"

/datum/intent/shoot/wand
	name = "wand shoot"
	icon_state = "inshoot"
	tranged = TRUE
	warnie = "aimwarn"
	item_d_type = "stab"
	chargetime = 6
	chargedrain = 1
	charging_slowdown = 2
	releasedrain = 1
	misscost = 1

/datum/intent/shoot/wand/can_charge(atom/clicked_object)
	if(!mastermob)
		return FALSE
	if(mastermob.anti_magic_check())
		to_chat(mastermob, span_warning("Антимагия блокирует фокусировку моих чар!"))
		return FALSE
	return TRUE

/datum/intent/shoot/wand/prewarning()
	if(mastermob && masteritem)
		mastermob.visible_message(span_warning("[mastermob] направляет [masteritem], концентрируя ману!"))

/datum/intent/arc/wand
	name = "wand arc"
	icon_state = "inarc"
	tranged = TRUE
	warnie = "aimwarn"
	item_d_type = "blunt"
	chargetime = 6
	chargedrain = 1
	charging_slowdown = 2
	releasedrain = 1
	misscost = 1

/datum/intent/arc/wand/can_charge(atom/clicked_object)
	if(!mastermob)
		return FALSE
	if(mastermob.anti_magic_check())
		to_chat(mastermob, span_warning("Антимагия блокирует фокусировку моих чар!"))
		return FALSE
	return TRUE

/datum/intent/arc/wand/prewarning()
	if(mastermob && masteritem)
		mastermob.visible_message(span_warning("[mastermob] направляет [masteritem], концентрируя ману по дуге!"))

/datum/intent/proc/get_wand_chargetime(base_time)
	if(!mastermob)
		return base_time
	
	var/intel = mastermob.get_stat(STAT_INTELLIGENCE)
	var/mult = 1
	if(intel <= 9)
		mult = 3
	else if(intel >= 15)
		mult = 1
	else
		mult = 1 + (15 - intel) * 0.333

	return round(base_time * mult)

/datum/intent/shoot/wand/get_chargetime()
	return get_wand_chargetime(initial(chargetime))

/datum/intent/arc/wand/get_chargetime()
	return get_wand_chargetime(initial(chargetime))

/obj/item/rogueweapon/wand
	var/datum/action/cooldown/spell/loaded_spell_path = null
	var/mana_charges = 0
	COOLDOWN_DECLARE(wand_spell_cooldown)
	possible_item_intents = list(/datum/intent/shoot/wand, /datum/intent/arc/wand, SPEAR_BASH)

/obj/item/rogueweapon/wand/attack_self(mob/user)
	if(twohands_required)
		return ..()
	choose_wand_spell(user)

/obj/item/rogueweapon/wand/proc/choose_wand_spell(mob/user)
	if(!user.mind || !length(user.mind.major_aspects))
		to_chat(user, span_warning("Этот инструмент отвергает меня... Только те, кто овладел высшей магией, могут использовать его!"))
		return
	var/list/spells = list()
	switch(implement_tier)
		if(IMPLEMENT_TIER_LESSER)
			spells = list(
				"Lesse Arcyne Bolt" = /datum/action/cooldown/spell/projectile/arc_bolt,
				"Mending" = /datum/action/cooldown/spell/mending,
				"Create Campfire" = /datum/action/cooldown/spell/create_campfire,
				"Blink" = /datum/action/cooldown/spell/blink,
				"Heal" = /datum/action/cooldown/spell/miracle/heal
			)
		if(IMPLEMENT_TIER_GREATER)
			spells = list(
				"Fireball" = /datum/action/cooldown/spell/projectile/fireball,
				"Lightning Bolt" = /datum/action/cooldown/spell/projectile/lightning_bolt,
				"Boulder Strike" = /datum/action/cooldown/spell/projectile/boulder_strike,
				"Sawblade Volley" = /datum/action/cooldown/spell/projectile/sawblade_volley,
				"Arcyne Bolt" = /datum/action/cooldown/spell/projectile/greater_arcyne_bolt
			)
		if(IMPLEMENT_TIER_GRAND)
			spells = list(
				"Giant Rock" = /datum/action/cooldown/spell/projectile/giantrock,
				"Arcane Mortar" = /datum/action/cooldown/spell/ballistic_mortar,
				"Cataclysmic Meteor" = /datum/action/cooldown/spell/grand_meteor,
				"Snowball" =/datum/action/cooldown/spell/projectile/snowball_toss,
				"Icicle Spear" =/datum/action/cooldown/spell/projectile/icicle_spear,
				"Swap Places" = /datum/action/cooldown/spell/swap
			)

	if(!length(spells))
		return

	var/choice = tgui_input_list(user, "Выберите заклинание для палочки:", "Заклинание палочки", spells)
	if(!choice || !user.canUseTopic(src, be_close = TRUE))
		return

	var/datum/action/cooldown/spell/selected_path = spells[choice]
	if(selected_path)
		loaded_spell_path = selected_path
		mana_charges = 0
		to_chat(user, span_notice("Вы зачаровали [src] на заклинание <b>[choice]</b>."))

		var/spell_color = initial(selected_path.spell_color)
		var/spell_name = initial(selected_path.name)
		attune_implement(spell_color, spell_name)
		
		update_icon()

/obj/item/rogueweapon/wand/proc/get_mana_reagent(obj/item/reagent_containers/RC)
	if(!RC || !RC.reagents || !RC.reagents.reagent_list)
		return null
	for(var/datum/reagent/R in RC.reagents.reagent_list)
		if(findtext(lowertext(R.name), "mana"))
			return R
	return null

/obj/item/rogueweapon/wand/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers))
		var/obj/item/reagent_containers/RC = I
		var/datum/reagent/mana_reagent = get_mana_reagent(RC)

		if(mana_reagent)
			if(!loaded_spell_path)
				to_chat(user, span_warning("[src] сначала необходимо выбрать заклинание!"))
				return
			if(mana_charges >= 100)
				to_chat(user, span_warning("[src] уже полностью заряжена маной!"))
				return

			var/available_mana = mana_reagent.volume
			var/transfer_amount = min(RC.amount_per_transfer_from_this, available_mana)
			
			var/space_left = 100 - mana_charges
			var/final_transfer = min(transfer_amount, space_left)

			if(final_transfer <= 0)
				return

			user.visible_message(span_notice("[user] начинает вливать зелье маны в [src]."), \
								span_notice("Я начинаю вливать зелье маны в [src]."))

			if(do_after(user, 1 SECONDS, target = src))
				if(!RC || QDELETED(RC) || !RC.reagents)
					return
				
				mana_reagent = get_mana_reagent(RC)
				if(!mana_reagent)
					return
					
				available_mana = mana_reagent.volume
				transfer_amount = min(RC.amount_per_transfer_from_this, available_mana)
				space_left = 100 - mana_charges
				final_transfer = min(transfer_amount, space_left)
				
				if(final_transfer > 0)
					RC.reagents.remove_reagent(mana_reagent.type, final_transfer)
					mana_charges += final_transfer
					
					to_chat(user, span_notice("Вы пополнили ману в палочке на [final_transfer] ед. (Заряд: [mana_charges]/100)"))
					playsound(src, 'sound/magic/charged.ogg', 50, TRUE)
					update_icon()
			return
	return ..()

/obj/item/rogueweapon/wand/afterattack(atom/target, mob/user, flag)
	. = ..()
	if(!istype(user) || !target)
		return
		
	if(istype(user.used_intent, /datum/intent/shoot/wand) || istype(user.used_intent, /datum/intent/arc/wand))
		fire_wand_spell(target, user)

/obj/item/rogueweapon/wand/proc/get_spell_mana_cost(mob/living/user)
	if(!user)
		return 50

	var/magic_skill = user.get_skill_level(/datum/skill/magic/arcane)
	var/mana_cost = 50
	if(magic_skill > 0)
		for(var/i in 1 to magic_skill)
			mana_cost = round(mana_cost / 2)
	mana_cost = max(1, mana_cost) 

	var/tier_cost = 0
	switch(implement_tier)
		if(IMPLEMENT_TIER_LESSER)
			tier_cost = 5
		if(IMPLEMENT_TIER_GREATER)
			tier_cost = 10
		if(IMPLEMENT_TIER_GRAND)
			tier_cost = 20
			
	return mana_cost + tier_cost

/obj/item/rogueweapon/wand/proc/fire_wand_spell(atom/target, mob/living/user)
	if(!user.mind || !length(user.mind.major_aspects))
		to_chat(user, span_warning("[src] гаснет в моих руках... Я должен овладеть высшей магией, чтобы направить эти чары!"))
		return FALSE

	if(!loaded_spell_path)
		to_chat(user, span_warning("[src] не выбрано заклинание!"))
		return FALSE

	var/datum/action/cooldown/spell/S = loaded_spell_path
	var/is_arced = istype(user.used_intent, /datum/intent/arc/wand)
	var/magic_skill = user.get_skill_level(/datum/skill/magic/arcane)
	var/mana_cost = get_spell_mana_cost(user)

	if(mana_charges < mana_cost)
		to_chat(user, span_warning("В [src] недостаточно маны! Требуется: [mana_cost] ед."))
		return FALSE

	if(!COOLDOWN_FINISHED(src, wand_spell_cooldown))
		var/time_left = round(COOLDOWN_TIMELEFT(src, wand_spell_cooldown) / 10, 0.1)
		to_chat(user, span_warning("Кристалл палочки еще не остыл! ([time_left] сек. осталось)"))
		return FALSE

	if(user.client && user.client.chargedprog < 100)
		to_chat(user, span_warning("Вы должны полностью сконцентрировать ману в палочке перед выпуском заклинания!"))
		return FALSE

	mana_charges -= mana_cost

	var/cd_time = initial(S.cooldown_time)
	COOLDOWN_START(src, wand_spell_cooldown, cd_time)
	var/datum/action/cooldown/spell/temp_spell = new loaded_spell_path()
	temp_spell.owner = user

	if(istype(temp_spell, /datum/action/cooldown/spell/projectile))
		var/datum/action/cooldown/spell/projectile/proj_spell = temp_spell
		if(is_arced && initial(proj_spell.projectile_type_arc))
			proj_spell.projectile_type = initial(proj_spell.projectile_type_arc)

	temp_spell.spell_feedback(user)

	var/cast_success = temp_spell.cast(target)

	if(cast_success == FALSE)
		qdel(temp_spell)
		mana_charges += mana_cost
		wand_spell_cooldown = 0
		return FALSE

	QDEL_IN(temp_spell, 30 SECONDS)

	update_icon()
	user.changeNext_move(CLICK_CD_RANGE)
	return TRUE

/obj/item/rogueweapon/wand/examine(mob/user)
	. = ..()
	if(loaded_spell_path)
		var/datum/action/cooldown/spell/projectile/S = loaded_spell_path
		var/spell_name = initial(S.name)
		. += span_notice("[src] заклинание <b>[spell_name]</b>.")
		. += span_notice("Заряд маны: <b>[mana_charges]/100 ед.</b>")

		var/mana_cost = get_spell_mana_cost(user)
		. += span_info("Расход маны за выстрел: <b>[mana_cost] ед.</b>")
	else
		. += span_warning("[src] не выбрано заклинание.")
