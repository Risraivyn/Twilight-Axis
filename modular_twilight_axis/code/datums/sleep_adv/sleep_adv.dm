/datum/sleep_adv
	var/list/queued_wake_events = list()
	var/noc_inspired = FALSE

/datum/sleep_adv/proc/roll_dream_event()
	var/mob/living/carbon/human/H = mind.current
	if(!istype(H))
		return
	
	var/trait_cost = 3
	if(sleep_adv_points < trait_cost)
		to_chat(H, span_warning("Мне не хватает очков снов для погружения в глубокий сон."))
		return

	sleep_adv_points -= trait_cost
	var/stress = H.get_stress_amount()
	var/positive_chance = 50
	if(stress < 0)
		positive_chance += abs(stress) * 3
	else
		positive_chance -= stress * 2

	var/bed_bonus = 0
	if(istype(H.buckled, /obj/structure/bed))
		var/obj/structure/bed/Bed = H.buckled
		var/bname = lowertext(Bed.name)
		if(findtext(bname, "royal") || findtext(bname, "luxury") || findtext(bname, "роскошн") || findtext(bname, "барск"))
			bed_bonus = 25
		else if(findtext(bname, "straw") || findtext(bname, "солом") || findtext(bname, "мешок"))
			bed_bonus = 5
		else
			bed_bonus = 15
	else
		bed_bonus = -15
	positive_chance += bed_bonus

	var/blanket_bonus = -10
	for(var/obj/item/bedsheet/BS in H.loc)
		if(BS.signal_sleeper?.resolve() == H)
			if(istype(BS, /obj/item/bedsheet/rogue/double_pelt) || istype(BS, /obj/item/bedsheet/rogue/fabric_double))
				blanket_bonus = 20
			else if(istype(BS, /obj/item/bedsheet/rogue/pelt) || istype(BS, /obj/item/bedsheet/rogue/wool))
				blanket_bonus = 15
			else
				blanket_bonus = 10
			break
	positive_chance += blanket_bonus
	if(noc_inspired)
		positive_chance += 25
		noc_inspired = FALSE
		to_chat(H, span_blue("Голубой полумесяц на моем лбу сияет теплым астральным светом, направляя мои сны по благословенному пути Нок..."))
		
	positive_chance = clamp(positive_chance, 5, 95)

	if(prob(20))
		to_chat(H, span_notice("Мой сон был глубок и спокоен, но ничто не потревожило мою душу."))
		return

	var/is_positive = prob(positive_chance)
	var/list/viable_events = list()
	for(var/path in GLOB.dream_events)
		var/datum/dream_event/DE = GLOB.dream_events[path]
		if(DE.is_positive == is_positive && DE.can_trigger(H))
			viable_events += DE

	if(!length(viable_events))
		to_chat(H, span_notice("Никакие знамения не явились мне в этом сне."))
		return

	var/datum/dream_event/chosen_event = pick(viable_events)
	chosen_event.on_dream(H, src)
	queued_wake_events += chosen_event.type
