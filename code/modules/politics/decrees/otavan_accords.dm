/datum/decree/otavan_accords
	id = DECREE_OTAVAN_ACCORDS
	name = "Отаванские соглашения"
	category = DECREE_CATEGORY_NEW
	mechanical_text = "Inquisition members pay no taxes."
	flavor_text = {"In the name of the Ten, under the Almighty Allfather's watch, be it known that the Holy Otavan Inquisition, sworn servants of Psydon and emissaries of the Orthodoxy, shall keep vigil against heresy athupon this land: to defend and protect the Duchy of Azuria from those who would do it harm, and to counsel and advise the leaders and peoples of the nation. The Inquisition is hereby granted the right to try foreigners, those sanctioned and outlawed by the Duchy for crimes of high heresy, or those who are handed over by order of Crown and Court. The Holy Inquisition is to be granted permission to aid in trials of citizenry alongside the lawful authorities of the land, save for the Nobility, who must be tried before the Crown.

Взамен, будучи признанными духовенством Отаванской Церкви Всеотца, Инквизиция освобождается от обложения налогами и сборами в отношении своих членов и инструментов их служения; и Корона не будет препятствовать их святому долгу, за исключением случая предъявления законных претензий перед Церковью Десяти.

Заверено печатью Короны, в присутствии Псайдона и его Десяти."}
	revoke_text = "Правитель сиих земель нарушил Отаванские соглашения. Инквизиция лишается защиты, предусмотренной договором — и Отава не оставит такое оскорбление без ответа."
	restore_text = "Правитель сиих земель возобновил Отаванские соглашения. Святая Отаванская Инквизиция возобновляет свою миссию по очищению земель от еретиков без какого-либо вмешательства Короны."

/datum/decree/otavan_accords/roll_initial_year()
	return 1492 // Canonical year

/datum/decree/otavan_accords/apply_exemption(mob/living/payer, tax_category)
	if(!active)
		return FALSE
	if(payer.job in GLOB.inquisition_positions)
		return TRUE
	return FALSE
