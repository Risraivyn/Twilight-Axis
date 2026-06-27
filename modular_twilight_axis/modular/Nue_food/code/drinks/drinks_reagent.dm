/datum/reagent/consumable/caffeine/coffee/on_mob_life(mob/living/carbon/M)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.days_without_sleep > 0 || H.has_status_effect(/datum/status_effect/debuff/sleepytime))
			H.days_without_sleep = 0
			H.remove_status_effect(/datum/status_effect/debuff/sleepytime)
			H.remove_stress(/datum/stressevent/sleepytime)
			H.remove_stress(/datum/stressevent/sleep_deprivation_2)
			H.remove_stress(/datum/stressevent/sleep_deprivation_3)
			H.remove_stress(/datum/stressevent/sleep_deprivation_4)

			if(H.hallucination > 0 && !H.has_flaw(/datum/charflaw/mind_broken))
				H.hallucination = 0
			REMOVE_TRAIT(H, TRAIT_PSYCHOSIS, "sleep_deprivation")
			to_chat(H, span_nicegreen("Крепкий горячий кофе наполняет мое тело бодростью и прогоняет накопившуюся усталость!"))	
	..()
