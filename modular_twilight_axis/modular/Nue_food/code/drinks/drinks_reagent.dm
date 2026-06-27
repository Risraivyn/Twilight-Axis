/datum/reagent/consumable/caffeine/coffee/on_mob_life(mob/living/carbon/M)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.days_without_sleep > 0 || H.has_status_effect(/datum/status_effect/debuff/sleepytime))
			H.reset_sleep_deprivation()
			to_chat(H, span_nicegreen("Крепкий горячий кофе наполняет мое тело бодростью и прогоняет накопившуюся усталость!"))	
	..()
