/datum/decree/golden_bull
	id = DECREE_GOLDEN_BULL
	name = "Золотая булла Кингсфилда"
	category = DECREE_CATEGORY_ANCIENT
	mechanical_text = "Для горожан установлена максимальная ставка налога/штрафа в размере 25% от остатка на счете, при этом максимальный размер штрафа составляет 50 маммон в дае, а также установлен предельный размер подушной подати."
	flavor_text = {"Настоящая Булла Кингсфилда, скрепленная златой печатью под Светом Астраты и при свидетельстве Абиссора, свидетельствует о том, что Корона Великого Герцогства Азурийского не будет вводить никаких налогов или сборов в отношении горожан Сумеречной Оси, Кингсфилда и других городов Азурии, за исключением случаев, когда на это будет дано согласие должным образом созванного Совета знатных и горожан; также ни один горожанин не может быть лишен своего имущества иначе, как в соответствии с законами герцогства.

Взамен горожане Сумеречной Оси, Кингсфилда и других городов Азурии обязуются выделять для общей защиты Королевства от пиратов, разбойников и других злоумышленников, угрожающих миру, ежегодный бюджет — сумму, собираемую среди их членов в соответствии с их достатком и распределяемую их собственным собранием.

И если Корона нарушит настоящий Кодекс, горожане освобождаются от своих обязательств, дабы Великое Герцогство познало цену вероломства по отношению к тем, кто создаёт его богатство.

Заверено золотой печатью Короны, милостью Астраты и Абиссора."}
	revoke_text = "Правитель сиих земель прекратил действие Золотой буллы Кингсфилда. Горожане теперь подвергаются полному обложению со стороны короны. Возмущенные этим решением, купцы Азурии более не станут уплачивать взносы на нужды общей обороны Герцогства."
	restore_text = "Правитель сиих земель восстановил Золотую буллу Кингсфилда. Соглашение вновь вступило в силу, и горожане возобновили уплату взносов на нужды общей обороны."

/datum/decree/golden_bull/roll_initial_year()
	return CALENDAR_EPOCH_YEAR - rand(40, 100)

/datum/decree/golden_bull/apply_rate_cap(mob/living/payer, tax_category, current_cap)
	if(!is_protected_by_bull(payer))
		return current_cap
	return min(current_cap, GOLDEN_BULL_BURGHER_CAP)

/// Per-stroke mammon ceiling for Bull-protected subjects. Combined with the realm's
/// one-fine-per-day rule this becomes an effective daily cap.
/datum/decree/golden_bull/apply_daily_fine_cap(mob/living/payer, current_remaining)
	if(!is_protected_by_bull(payer))
		return current_remaining
	return min(current_remaining, GOLDEN_BULL_DAILY_FINE_CAP)

/// Cap the Burgher poll-tax daily charge at GOLDEN_BULL_POLL_CAP.
/datum/decree/golden_bull/apply_poll_tax_cap(mob/living/payer, poll_category, current_rate)
	if(poll_category != POLL_TAX_CAT_BURGHER)
		return current_rate
	return min(current_rate, GOLDEN_BULL_POLL_CAP)

/// Returns TRUE if the payer is currently shielded by the Golden Bull.
/datum/decree/golden_bull/proc/is_protected_by_bull(mob/living/payer)
	if(!active)
		return FALSE
	if(HAS_TRAIT(payer, TRAIT_OUTLAW))
		return FALSE
	if(HAS_TRAIT(payer, TRAIT_RESIDENT))
		return TRUE
	if(payer.job in GLOB.wanderer_positions)
		return FALSE
	if(payer.job == "Mercenary")
		return FALSE
	return TRUE

