#define SANDMAN_ASCENSION_GOAL 25

/datum/antagonist/sandman
	name = "Sandman"
	roundend_category = "Sandmen"
	antagpanel_category = "Sandman"
	job_rank = ROLE_SANDMAN
	storyteller_antag_flags = STORYTELLER_ANTAG_VILLAIN | STORYTELLER_ANTAG_ROUNDSTART
	antag_hud_type = ANTAG_HUD_VAMPIRE
	antag_hud_name = "vamp_spawn_hud"
	rogue_enabled = TRUE
	show_in_antagpanel = TRUE
	overrides_forlorne_vice = TRUE
	var/essence = 1
	var/total_essence_gained = 0
	var/ascended = FALSE
	var/list/unlocked_nodes = list("core" = TRUE)
	var/list/drain_cooldowns = list()
	var/datum/weakref/mortal_body_ref
	var/datum/weakref/spirit_body_ref
	var/in_spirit_form = FALSE
	var/datum/action/sandman_tree_btn/tree_action
	var/datum/action/sandman_astral_exit/exit_action
	var/datum/action/sandman_return_body/return_action
	var/datum/action/cooldown/spell/sandman_siphon/siphon_action

/datum/antagonist/sandman/get_antag_cap_weight()
	return 2

/datum/antagonist/sandman/on_gain()
	owner.special_role = name
	. = ..()
	mortal_body_ref = WEAKREF(owner.current)
	add_antag_hud(antag_hud_type, antag_hud_name, owner.current)
	grant_base_actions(owner.current)
	greet()

/datum/antagonist/sandman/greet()
	to_chat(owner.current, span_userdanger("Вы — Песочный Человек (Sandman)."))
	to_chat(owner.current, span_notice("В обычном теле вы можете только прокачивать древо и высасывать силы из живых."))
	to_chat(owner.current, span_notice("Усните, чтобы выйти из тела и использовать свои кошмарные способности. Накопите [SANDMAN_ASCENSION_GOAL] сил для полного Возвышения!"))
	owner.announce_objectives()

/datum/antagonist/sandman/on_removal()
	if(in_spirit_form)
		return_to_mortal_body(forced = TRUE)
	var/mob/living/mortal = mortal_body_ref?.resolve()
	if(mortal)
		revoke_unlocked_abilities(mortal)
		remove_base_actions(mortal)
		remove_antag_hud(antag_hud_type, mortal)
	SStgui.close_uis(src)
	if(!silent && owner.current)
		to_chat(owner.current, span_danger("Я больше не [job_rank]!"))
	owner.special_role = null
	return ..()

/datum/antagonist/sandman/proc/grant_base_actions(mob/living/target)
	if(!target)
		return
	if(!tree_action)
		tree_action = new(target, src)
	tree_action.Grant(target)

	if(!siphon_action)
		siphon_action = new(target, src)
	owner.AddSpell(siphon_action)

	if(!in_spirit_form && !ascended)
		if(!exit_action)
			exit_action = new(target, src)
		exit_action.Grant(target)

/datum/antagonist/sandman/proc/remove_base_actions(mob/living/target)
	tree_action?.Remove(target)
	exit_action?.Remove(target)
	return_action?.Remove(target)
	if(siphon_action && owner)
		owner.RemoveSpell(siphon_action)


/datum/antagonist/sandman/proc/enter_spirit_form()
	if(in_spirit_form || ascended)
		return FALSE
	var/mob/living/carbon/human/mortal = mortal_body_ref?.resolve()
	if(!istype(mortal) || QDELETED(mortal) || mortal.stat == DEAD)
		return FALSE
	if(!mortal.IsSleeping())
		to_chat(mortal, span_warning("Вы должны крепко спать, чтобы покинуть своё тело!"))
		return FALSE

	var/turf/spawn_turf = get_turf(mortal)
	if(!spawn_turf)
		return FALSE

	var/mob/living/carbon/human/species/human/northern/sandman_spirit/spirit = new(spawn_turf)
	spirit.real_name = "Кошмар ([mortal.real_name])"
	spirit.name = spirit.real_name
	spirit.mortal_anchor_ref = WEAKREF(mortal)

	spirit_body_ref = WEAKREF(spirit)
	in_spirit_form = TRUE

	RegisterSignal(mortal, list(COMSIG_ATOM_WAS_ATTACKED, COMSIG_LIVING_DEATH), PROC_REF(on_mortal_disturbed))
	RegisterSignal(spirit, COMSIG_LIVING_DEATH, PROC_REF(on_spirit_died))

	remove_base_actions(mortal)
	owner.transfer_to(spirit, TRUE)
	spirit.SetSleeping(0, ignore_canstun = TRUE)
	spirit.SetUnconscious(0, ignore_canstun = TRUE)
	spirit.update_stat()
	spirit.update_sight()
	if(spirit.client)
		spirit.client.eye = spirit

	grant_base_actions(spirit)
	if(!return_action)
		return_action = new(spirit, src)
	return_action.Grant(spirit)

	grant_unlocked_abilities(spirit)

	spirit.alpha = 0
	animate(spirit, alpha = 140, time = 0.4 SECONDS, easing = SINE_EASING | EASE_OUT)
	to_chat(spirit, span_notice("Вы покинули спящее тело. Теперь вам подвластны все пробуждённые способности!"))
	return TRUE

/datum/antagonist/sandman/proc/return_to_mortal_body(forced = FALSE)
	if(!in_spirit_form)
		return FALSE

	var/mob/living/carbon/human/mortal = mortal_body_ref?.resolve()
	var/mob/living/carbon/human/spirit = spirit_body_ref?.resolve()

	in_spirit_form = FALSE

	if(mortal)
		UnregisterSignal(mortal, list(COMSIG_ATOM_WAS_ATTACKED, COMSIG_LIVING_DEATH))
	if(spirit)
		UnregisterSignal(spirit, COMSIG_LIVING_DEATH)
		revoke_unlocked_abilities(spirit)
		remove_base_actions(spirit)

	if(mortal && !QDELETED(mortal))
		owner.transfer_to(mortal, TRUE)
		grant_base_actions(mortal)
		if(ascended)
			grant_unlocked_abilities(mortal)
		if(forced)
			to_chat(mortal, span_userdanger("Ваше тело потревожили — дух насильно вернулся обратно!"))
		else
			to_chat(mortal, span_notice("Вы возвращаетесь в своё тело."))

	if(spirit && !QDELETED(spirit))
		qdel(spirit)
	spirit_body_ref = null
	return TRUE

/datum/antagonist/sandman/proc/on_mortal_disturbed(datum/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(return_to_mortal_body), TRUE)

/datum/antagonist/sandman/proc/on_spirit_died(datum/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(return_to_mortal_body), TRUE)


/datum/antagonist/sandman/proc/ascend()
	if(ascended)
		return
	ascended = TRUE

	if(in_spirit_form)
		return_to_mortal_body(forced = FALSE)

	var/mob/living/carbon/human/mortal = mortal_body_ref?.resolve()
	if(mortal && !QDELETED(mortal))
		exit_action?.Remove(mortal)
		grant_unlocked_abilities(mortal)
		mortal.SetSleeping(0, ignore_canstun = TRUE)
		playsound(mortal, 'sound/magic/whiteflame.ogg', 100, TRUE)
		mortal.visible_message(
			span_userdanger("Вокруг [mortal] вспыхивает фиолетовое марево — Песочный Человек возвысился!"),
			span_userdanger("ВЫ ВОЗВЫСИЛИСЬ! Отныне все кошмарные способности доступны вам прямо в вашем обычном теле!")
		)
	SStgui.update_uis(src)

/datum/antagonist/sandman/proc/get_tree_nodes()
	return list(
		list(
			"id" = "core",
			"name" = "Сердце Песка",
			"desc" = "Пробуждение древней сущности. Открывает пути развития.",
			"cost" = 0,
			"x" = 0,
			"y" = 0,
			"parent" = null,
		),
		list(
			"id" = "shadow_step_1",
			"name" = "Шёпот Тени",
			"desc" = "Даёт ночное зрение в форме духа (или всегда после Возвышения).",
			"cost" = 1,
			"x" = 0,
			"y" = -100,
			"parent" = "core",
		),
		list(
			"id" = "shadow_domain",
			"name" = "Shadow Domain",
			"desc" = "Открывает заклинание Shadow Domain: затягивает всех вокруг в карманное измерение.",
			"cost" = 3,
			"x" = 0,
			"y" = -200,
			"parent" = "shadow_step_1",
		),
		list(
			"id" = "dream_1",
			"name" = "Сонная Пыльца",
			"desc" = "(Заготовка под способность сна). +1 к Интеллекту в форме духа / после Возвышения.",
			"cost" = 1,
			"x" = -120,
			"y" = 60,
			"parent" = "core",
		),
		list(
			"id" = "dream_2",
			"name" = "Кошмар",
			"desc" = "(Заготовка под продвинутую способность сна). +1 к Воле.",
			"cost" = 2,
			"x" = -230,
			"y" = 120,
			"parent" = "dream_1",
		),
		list(
			"id" = "body_1",
			"name" = "Песчаная Плоть",
			"desc" = "+1 к Телосложению и Скорости в форме духа / после Возвышения.",
			"cost" = 1,
			"x" = 120,
			"y" = 60,
			"parent" = "core",
		),
		list(
			"id" = "body_2",
			"name" = "Неуловимый Силуэт",
			"desc" = "+2 к Скорости в форме духа / после Возвышения.",
			"cost" = 2,
			"x" = 230,
			"y" = 120,
			"parent" = "body_1",
		),
	)

/datum/antagonist/sandman/proc/grant_unlocked_abilities(mob/living/carbon/human/target)
	if(!istype(target) || QDELETED(target))
		return
	for(var/node_id in unlocked_nodes)
		if(unlocked_nodes[node_id])
			apply_single_node(node_id, target)

/datum/antagonist/sandman/proc/apply_single_node(node_id, mob/living/carbon/human/target)
	if(!istype(target) || QDELETED(target))
		return
	switch(node_id)
		if("shadow_step_1")
			target.update_sight()
		if("shadow_domain")
			if(!owner.has_spell(/datum/action/cooldown/spell/shadow_domain))
				owner.AddSpell(new /datum/action/cooldown/spell/shadow_domain)
		if("dream_1")
			target.change_stat(STATKEY_INT, 1)
		if("dream_2")
			target.change_stat(STATKEY_WIL, 1)
		if("body_1")
			target.change_stat(STATKEY_CON, 1)
			target.change_stat(STATKEY_SPD, 1)
		if("body_2")
			target.change_stat(STATKEY_SPD, 2)

/datum/antagonist/sandman/proc/revoke_unlocked_abilities(mob/living/carbon/human/target)
	if(!istype(target) || QDELETED(target))
		return
	target.update_sight()
	owner?.RemoveSpell(/datum/action/cooldown/spell/shadow_domain)

/datum/antagonist/sandman/ui_state(mob/user)
	return GLOB.always_state

/datum/antagonist/sandman/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SandmanTree", "Древо Кошмаров", 720, 600)
		ui.open()

/datum/antagonist/sandman/ui_static_data(mob/user)
	var/list/data = list()
	data["nodes"] = get_tree_nodes()
	data["ascension_goal"] = SANDMAN_ASCENSION_GOAL
	return data

/datum/antagonist/sandman/ui_data(mob/user)
	var/list/data = list()
	data["essence"] = essence
	data["total_essence"] = total_essence_gained
	data["ascended"] = ascended
	data["unlocked"] = unlocked_nodes
	return data

/datum/antagonist/sandman/ui_act(action, list/params)
	if(..())
		return
	if(usr != owner?.current)
		return

	if(action == "buy_node")
		var/node_id = params["id"]
		if(!node_id || unlocked_nodes[node_id])
			return

		var/list/chosen_node
		for(var/list/N in get_tree_nodes())
			if(N["id"] == node_id)
				chosen_node = N
				break
		if(!chosen_node)
			return

		var/parent_id = chosen_node["parent"]
		if(parent_id && !unlocked_nodes[parent_id])
			to_chat(usr, span_warning("Сначала нужно открыть предыдущий узел ветки!"))
			return

		var/cost = chosen_node["cost"]
		if(essence < cost)
			to_chat(usr, span_warning("Недостаточно Сущности! Высасывайте силы из живых."))
			return

		essence -= cost
		unlocked_nodes[node_id] = TRUE

		if(in_spirit_form || ascended)
			apply_single_node(node_id, owner.current)
			to_chat(usr, span_notice("Вы пробудили: <b>[chosen_node["name"]]</b>!"))
		else
			to_chat(usr, span_notice("Вы изучили <b>[chosen_node["name"]]</b>! Способность станет доступна во сне (при выходе из тела) или после Возвышения."))
		return TRUE



/datum/action/sandman_tree_btn
	name = "Древо Кошмаров"
	desc = "Открыть меню развития способностей Песочного Человека."
	background_icon = 'icons/mob/actions/roguespells.dmi'
	background_icon_state = "spell0"
	button_icon = 'icons/mob/actions/roguespells.dmi'
	button_icon_state = "shieldsparkles"
	check_flags = NONE
	var/datum/antagonist/sandman/linked_antag

/datum/action/sandman_tree_btn/New(Target, datum/antagonist/sandman/_antag)
	. = ..(Target)
	linked_antag = _antag

/datum/action/sandman_tree_btn/Trigger(trigger_flags)
	. = ..()
	if(!. || !linked_antag || !owner)
		return FALSE
	linked_antag.ui_interact(owner)
	return TRUE


/datum/action/sandman_astral_exit
	name = "Выйти из тела"
	desc = "Покинуть спящее тело в облике Кошмара."
	background_icon = 'icons/mob/actions/roguespells.dmi'
	background_icon_state = "spell0"
	button_icon = 'icons/mob/actions/roguespells.dmi'
	button_icon_state = "shieldsparkles"
	check_flags = NONE
	var/datum/antagonist/sandman/linked_antag

/datum/action/sandman_astral_exit/New(Target, datum/antagonist/sandman/_antag)
	. = ..(Target)
	linked_antag = _antag

/datum/action/sandman_astral_exit/Trigger(trigger_flags)
	. = ..()
	if(!. || !linked_antag)
		return FALSE
	return linked_antag.enter_spirit_form()


/datum/action/sandman_return_body
	name = "Вернуться в тело"
	desc = "Вернуться обратно в своё спящее тело."
	background_icon = 'icons/mob/actions/roguespells.dmi'
	background_icon_state = "spell0"
	button_icon = 'icons/mob/actions/roguespells.dmi'
	button_icon_state = "shieldsparkles"
	check_flags = NONE
	var/datum/antagonist/sandman/linked_antag

/datum/action/sandman_return_body/New(Target, datum/antagonist/sandman/_antag)
	. = ..(Target)
	linked_antag = _antag

/datum/action/sandman_return_body/Trigger(trigger_flags)
	. = ..()
	if(!. || !linked_antag)
		return FALSE
	return linked_antag.return_to_mortal_body(forced = FALSE)


/datum/action/cooldown/spell/sandman_siphon
	name = "Высасывание сил"
	desc = "."
	button_icon = 'icons/mob/actions/roguespells.dmi'
	button_icon_state = "shieldsparkles"
	sound = 'sound/magic/whiteflame.ogg'
	spell_color = "#9932cc"

	click_to_activate = TRUE
	channel_cast = TRUE
	charge_required = TRUE
	charge_time = 2 SECONDS
	cast_range = 2
	self_cast_possible = FALSE

	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = 15
	cooldown_time = 10 SECONDS
	spell_requirements = SPELL_REQUIRES_HUMAN

	var/datum/antagonist/sandman/linked_antag

/datum/action/cooldown/spell/sandman_siphon/New(Target, datum/antagonist/sandman/_antag)
	. = ..(Target)
	linked_antag = _antag

/datum/action/cooldown/spell/sandman_siphon/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(cast_on))
		owner.balloon_alert(owner, "Нужен живой человек!")
		return FALSE
	var/mob/living/carbon/human/T = cast_on
	if(T.stat == DEAD)
		owner.balloon_alert(owner, "Цель мертва — сил не осталось!")
		return FALSE
	if(linked_antag)
		var/t_ref = REF(T)
		if(linked_antag.drain_cooldowns[t_ref] && world.time < linked_antag.drain_cooldowns[t_ref])
			owner.balloon_alert(owner, "Эта душа ещё не восстановилась!")
			return FALSE
	return TRUE

/datum/action/cooldown/spell/sandman_siphon/cast(atom/cast_on)
	. = ..()
	var/mob/living/carbon/human/target = cast_on
	if(!istype(target) || QDELETED(owner))
		return FALSE

	var/obj/effect/domain_bolt/orb = new(get_turf(target))
	var/dx = (owner.x - target.x) * 32
	var/dy = (owner.y - target.y) * 32
	animate(orb, pixel_x = -32 + dx, pixel_y = -32 + dy, alpha = 0, time = 0.4 SECONDS, easing = SINE_EASING | EASE_IN)
	QDEL_IN(orb, 0.45 SECONDS)

	target.stamina_add(35)
	target.AdjustSleeping(2 SECONDS, ignore_canstun = TRUE)
	to_chat(target, span_warning("Вы чувствуете внезапную, леденящую сонливость, будто из вас вытянули часть души..."))

	if(linked_antag)
		linked_antag.essence += 1
		linked_antag.total_essence_gained += 1
		linked_antag.drain_cooldowns[REF(target)] = world.time + 3 MINUTES
		SStgui.update_uis(linked_antag)
		to_chat(owner, span_notice("Вы поглотили частицу чужой силы! (+1 Сущность | Возвышение: [linked_antag.total_essence_gained]/[SANDMAN_ASCENSION_GOAL])"))

		if(!linked_antag.ascended && linked_antag.total_essence_gained >= SANDMAN_ASCENSION_GOAL)
			linked_antag.ascend()

	return TRUE

/datum/round_event_control/antagonist/solo/sandman
	name = "Sandman"
	tags = list(TAG_COMBAT, TAG_VILLIAN)
	roundstart = TRUE
	antag_flag = ROLE_SANDMAN
	storyteller_antag_flags = STORYTELLER_ANTAG_VILLAIN | STORYTELLER_ANTAG_ROUNDSTART
	denominator = 80
	base_antags = 1
	maximum_antags = 1
	weight = 10
	max_occurrences = 1
	typepath = /datum/round_event/antagonist/solo/sandman
	antag_datum = /datum/antagonist/sandman
	restricted_roles = DEFAULT_ANTAG_BLACKLISTED_ROLES

/datum/round_event/antagonist/solo/sandman

#undef SANDMAN_ASCENSION_GOAL

/mob/living/carbon/human/species/human/northern/sandman_spirit
	density = FALSE
	pass_flags = PASS_ALL
	movement_type = FLYING
	layer = GHOST_LAYER
	invisibility = INVISIBILITY_OBSERVER
	see_invisible = SEE_INVISIBLE_OBSERVER
	see_in_dark = 100
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	alpha = 140
	color = "#8a63d2"

	var/datum/weakref/mortal_anchor_ref
	var/max_leash_range = 20
	var/next_leash_warning = 0

/mob/living/carbon/human/species/human/northern/sandman_spirit/Initialize(mapload)
	. = ..()
	add_filter("sandman_spirit", 2, list("type" = "outline", "color" = "#b366ff", "alpha" = 180, "size" = 1))
	ADD_TRAIT(src, TRAIT_NOHUNGER, "[type]")
	ADD_TRAIT(src, TRAIT_NOBREATH, "[type]")
	ADD_TRAIT(src, TRAIT_NOPAIN, "[type]")
	ADD_TRAIT(src, TRAIT_BLOODLOSS_IMMUNE, "[type]")
	ADD_TRAIT(src, TRAIT_TOXIMMUNE, "[type]")
	ADD_TRAIT(src, TRAIT_NOSOFTCRIT, "[type]")
	update_sight()

/mob/living/carbon/human/species/human/northern/sandman_spirit/update_sight()
	. = ..()
	sight |= SEE_TURFS | SEE_MOBS | SEE_OBJS
	see_invisible = SEE_INVISIBLE_OBSERVER
	see_in_dark = 100
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE

/mob/living/carbon/human/species/human/northern/sandman_spirit/proc/can_move_near_body(turf/target_turf)
	var/mob/living/mortal = mortal_anchor_ref?.resolve()
	if(!mortal || QDELETED(mortal) || !target_turf)
		return TRUE

	var/turf/body_turf = get_turf(mortal)
	if(!body_turf)
		return TRUE

	var/turf/current_turf = get_turf(src)
	if(current_turf && current_turf.z != body_turf.z)
		return TRUE

	if(body_turf.z == target_turf.z && get_dist(body_turf, target_turf) <= max_leash_range)
		return TRUE

	if(current_turf && current_turf.z == body_turf.z && body_turf.z == target_turf.z)
		if(get_dist(body_turf, target_turf) < get_dist(body_turf, current_turf))
			return TRUE

	if(client && world.time >= next_leash_warning)
		to_chat(src, span_warning("Невидимая нить не пускает меня дальше от моего тела!"))
		next_leash_warning = world.time + 2 SECONDS
	return FALSE

/mob/living/carbon/human/species/human/northern/sandman_spirit/Move(NewLoc, direct)
	var/oldloc = loc
	var/turf/target_turf

	if(NewLoc)
		target_turf = get_turf(NewLoc)
	else
		var/turf/current_turf = get_turf(src)
		if(current_turf)
			target_turf = get_step(current_turf, direct)

	if(!target_turf)
		return FALSE

	if(target_turf.x < 1 || target_turf.x > world.maxx || target_turf.y < 1 || target_turf.y > world.maxy)
		return FALSE
	if(istype(target_turf, /turf/closed/mineral/rogue/bedrock))
		return FALSE

	if(!can_move_near_body(target_turf))
		return FALSE

	if(direct)
		setDir(direct)

	set_glide_size(DELAY_TO_GLIDE_SIZE(world.tick_lag * 2))
	forceMove(target_turf)
	Moved(oldloc, direct)
	return TRUE
