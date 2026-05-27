// Treasury solvency state machine: NORMAL -> IN_ARREARS -> BANKRUPTCY (and back).
// All transitions go through these helpers. distribute_daily_payments and the debt-skim
// path read treasury_state but never mutate it.

/datum/controller/subsystem/treasury/proc/is_in_receivership()
	return treasury_state == TREASURY_BANKRUPTCY

/datum/controller/subsystem/treasury/proc/is_in_arrears_or_worse()
	return treasury_state != TREASURY_NORMAL

/datum/controller/subsystem/treasury/proc/enter_arrears(projected_total)
	if(treasury_state != TREASURY_NORMAL)
		return FALSE
	var/shortfall = max(0, projected_total - discretionary_fund.balance)
	var/loan_amount = max(TREASURY_ARREARS_LOAN, shortfall)
	treasury_state = TREASURY_IN_ARREARS
	treasury_debt += loan_amount
	GLOB.azure_round_stats[STATS_TREASURY_DEBT_OUTSTANDING] = treasury_debt
	record_round_statistic(STATS_ARREARS_DECLARED, 1)
	// Direct credit so the loan itself isn't immediately skimmed against the debt we just registered.
	discretionary_fund.balance += loan_amount
	log_fund_entry(new /datum/treasury_entry("mint", null, discretionary_fund, loan_amount, "Arrears advance from the Azurian Trading Company"))
	priority_announce(
		"Казна Короны опустела при выплате жалования. Горожане Азурии, верные своему Обету, ссужают [loan_amount]м без процентов на покрытие дневных выплат. Если Корона снова не справится завтрашним утром, королевство подвергнется секвестрации.",
		"ССУДА ГОРОЖАН",
		'sound/misc/royal_decree2.ogg',
		"Captain",
	)
	return TRUE

/datum/controller/subsystem/treasury/proc/enter_bankruptcy()
	if(treasury_state == TREASURY_BANKRUPTCY)
		return FALSE
	bankruptcy_count += 1
	record_round_statistic(STATS_BANKRUPTCY_DECLARED, 1)

	// Reset purse to the operating floor. Adjust by difference and log so the ledger reflects
	// the residual being burned (or topped up) rather than a silent assignment.
	if(discretionary_fund.balance > BANKRUPTCY_OPERATING_FLOOR)
		var/excess = discretionary_fund.balance - BANKRUPTCY_OPERATING_FLOOR
		discretionary_fund.balance = BANKRUPTCY_OPERATING_FLOOR
		log_fund_entry(new /datum/treasury_entry("burn", discretionary_fund, null, excess, "Sequestration: residual purse forfeit"))
	else if(discretionary_fund.balance < BANKRUPTCY_OPERATING_FLOOR)
		var/topup = BANKRUPTCY_OPERATING_FLOOR - discretionary_fund.balance
		discretionary_fund.balance = BANKRUPTCY_OPERATING_FLOOR
		log_fund_entry(new /datum/treasury_entry("mint", null, discretionary_fund, topup, "Sequestration: operating reserve from the Azurian Trading Company"))

	// Existing arrears debt is rolled into the new sequestration debt rather than dropped,
	// so the Crown doesn't escape the smaller obligation by failing harder.
	var/new_debt = BANKRUPTCY_DEBT_FLAT
	treasury_debt += new_debt
	GLOB.azure_round_stats[STATS_TREASURY_DEBT_OUTSTANDING] = treasury_debt
	treasury_state = TREASURY_BANKRUPTCY

	suspend_charters_for_bankruptcy()
	override_trade_for_bankruptcy()
	suspend_wages_for_bankruptcy()

	priority_announce(
		"Вслед за изъятием [atc_seizure_blurb()] в счёт невыполненных обязательств Короны, Азурианская Торговая Компания — благословеннейший и преданнейший слуга Малума Труженика и Абиссора Сновидца — милостиво предоставила беспроцентный резерв в [BANKRUPTCY_OPERATING_FLOOR]м в обмен на признание долга перед Компанией в размере [new_debt]м. До полной выплаты долга Компания удерживает изъятые доходы королевства и бессрочно принимает на откуп таможенные и соляные пошлины; склад и торговые механизмы переходят в её руки, дабы упорядоченная торговля была обеспечена ради общего блага. Выплата жалования приостановлена; все Хартии, кроме Золотой Буллы, аннулированы.",
		"ОБЪЯВЛЕНА СЕКВЕСТРАЦИЯ",
		'sound/misc/royal_decree.ogg',
		"Captain",
	)
	return TRUE

/datum/controller/subsystem/treasury/proc/suspend_wages_for_bankruptcy()
	if(!steward_machine || !steward_machine.daily_payments)
		return
	var/list/payments = steward_machine.daily_payments
	for(var/mob/living/owner as anything in bank_accounts)
		if(!owner || !(payments[owner.job] > 0))
			continue
		var/datum/fund/account = bank_accounts[owner]
		if(!account || account.wages_suspended)
			continue
		account.wages_suspended = TRUE
		to_chat(owner, span_danger("My wages have been suspended after the Crown's sequestration. They will resume when the realm recovers."))

/datum/controller/subsystem/treasury/proc/resume_wages_after_bankruptcy()
	var/list/payments = steward_machine?.daily_payments
	for(var/mob/living/owner as anything in bank_accounts)
		if(!owner)
			continue
		var/datum/fund/account = bank_accounts[owner]
		if(!account || !account.wages_suspended)
			continue
		account.wages_suspended = FALSE
		if(payments && payments[owner.job] > 0)
			to_chat(owner, span_notice("My wages have been reinstated as the Crown's sequestration lifts."))

/datum/controller/subsystem/treasury/proc/clear_treasury_debt_state()
	switch(treasury_state)
		if(TREASURY_NORMAL)
			if(atc_loan_arrears_consumed)
				atc_loan_arrears_consumed = FALSE
				priority_announce(
					"Долг Короны перед Азурианской Торговой Компанией полностью урегулирован. Льготный период Горожан восстановлен.",
					"ЗАЙМ АТК ПОГАШЕН",
					'sound/misc/royal_decree2.ogg',
					"Captain",
				)
		if(TREASURY_IN_ARREARS)
			exit_arrears()
		if(TREASURY_BANKRUPTCY)
			exit_bankruptcy()

/datum/controller/subsystem/treasury/proc/exit_arrears()
	if(treasury_state != TREASURY_IN_ARREARS)
		return
	treasury_state = TREASURY_NORMAL
	atc_loan_arrears_consumed = FALSE
	priority_announce(
		"Корона погасила задолженность перед Горожанами. Королевство вновь платежеспособно.",
		"ДОЛГ ПЕРЕД ГОРОЖАНАМИ ПОГАШЕН",
		'sound/misc/royal_decree2.ogg',
		"Captain",
	)

/datum/controller/subsystem/treasury/proc/exit_bankruptcy()
	if(treasury_state != TREASURY_BANKRUPTCY)
		return
	treasury_state = TREASURY_NORMAL

	// The skim leaves the purse at exactly the operating floor; top up to the recovery target
	// so the Crown has working capital to resume.
	if(discretionary_fund.balance < BANKRUPTCY_RECOVERY_RESET)
		var/topup = BANKRUPTCY_RECOVERY_RESET - discretionary_fund.balance
		discretionary_fund.balance = BANKRUPTCY_RECOVERY_RESET
		log_fund_entry(new /datum/treasury_entry("mint", null, discretionary_fund, topup, "Sequestration lifted: working capital"))

	resume_wages_after_bankruptcy()
	// Trade configuration intentionally NOT restored - re-tuning it is part of the cost of failure.
	bankruptcy_concession_picks = BANKRUPTCY_CONCESSION_PICKS
	atc_loan_arrears_consumed = FALSE
	GLOB.azure_round_stats[STATS_TREASURY_DEBT_OUTSTANDING] = 0

	priority_announce(
		"Азурианская Торговая Компания возвращает управление торговлей Короне. Выплата жалования возобновится завтрашним утром. Правитель может, в силу своего старинного права, немедленно восстановить до [BANKRUPTCY_CONCESSION_PICKS] из приостановленных Хартий; всем прочим придется ждать положенного срока между указами.",
		"СЕКВЕСТРАЦИЯ СНЯТА",
		'sound/misc/royal_decree.ogg',
		"Captain",
	)

/// Force-suspend bankruptcy-listed Charters, bypassing cooldown and the daily revoke gate -
/// these aren't policy decisions, they're mechanical consequences of default.
/datum/controller/subsystem/treasury/proc/suspend_charters_for_bankruptcy()
	bankruptcy_suspended_decree_ids.Cut()
	for(var/decree_id in BANKRUPTCY_SUSPENDED_DECREES)
		var/datum/decree/D = decrees[decree_id]
		if(!D)
			continue
		if(D.active)
			D.active = FALSE
			D.cooldown_expires = 0
			D.on_revoke()
		D.bankruptcy_suspended = TRUE
		bankruptcy_suspended_decree_ids += decree_id
	steward_machine?.enforce_wage_floors()

/// Force every importable good onto standing import and pin auto-export at the sequestration
/// ratio. Not snapshotted - the Steward must re-tune by hand on recovery.
/datum/controller/subsystem/treasury/proc/override_trade_for_bankruptcy()
	autoexport_percentage = BANKRUPTCY_AUTOEXPORT_PERCENTAGE
	auto_import_disabled.Cut()
	for(var/good_id in GLOB.trade_goods)
		var/datum/trade_good/tg = GLOB.trade_goods[good_id]
		if(tg && tg.importable)
			auto_import_standing[good_id] = TRUE
	dirty_auto_import_view()
	dirty_market_view()

/// Cooldown-free restore of a bankruptcy-suspended charter. Returns TRUE on success.
/datum/controller/subsystem/treasury/proc/restore_charter_via_concession(decree_id)
	if(bankruptcy_concession_picks <= 0)
		return FALSE
	var/datum/decree/D = decrees[decree_id]
	if(!D || !D.bankruptcy_suspended || D.active)
		return FALSE
	D.bankruptcy_suspended = FALSE
	D.active = TRUE
	D.year = CALENDAR_EPOCH_YEAR
	D.cooldown_expires = 0
	D.has_ever_been_active = TRUE
	D.on_restore()
	D.broadcast_state_change()
	bankruptcy_concession_picks -= 1
	bankruptcy_suspended_decree_ids -= decree_id
	steward_machine?.enforce_wage_floors()
	return TRUE

/// Called from set_decree_active before any state change. Golden Bull cannot be revoked
/// during sequestration; bankruptcy-suspended charters are immutable until concession-restored.
/datum/controller/subsystem/treasury/proc/can_mutate_decree(decree_id, new_active)
	if(treasury_state == TREASURY_BANKRUPTCY && decree_id == DECREE_GOLDEN_BULL && !new_active)
		return FALSE
	if(treasury_state != TREASURY_BANKRUPTCY)
		return TRUE
	var/datum/decree/D = decrees[decree_id]
	if(!D)
		return FALSE
	if(D.bankruptcy_suspended)
		return FALSE
	return TRUE

/proc/bankruptcy_state_label(state_value)
	switch(state_value)
		if(TREASURY_NORMAL)
			return "Solvent"
		if(TREASURY_IN_ARREARS)
			return "In Arrears"
		if(TREASURY_BANKRUPTCY)
			return "Sequestered"
	return "Unknown"

/// Properties the Azurian Trading Company "seizes" against the Crown's debts on bankruptcy entry.
/// Two or three are picked at random for the sequestration announcement. 
GLOBAL_LIST_INIT(atc_seizure_inventory, list(
	"позолоченная купальня Лорда",
	"пара соколов из королевского птичника",
	"иллюминированный пси-алтырь в шагреневом переплете",
	"великий отаванский гобелен с изображением «Охоты на вепря»",
	"две позолоченные солонки в этрусском стиле",
	"три опечатанных ларца с королевским жемчугом",
	"домашний реликварий (без самих реликвий)",
	"наледианская астролябия без трех штифтов",
	"запас шафрана и корицы, принадлежащий Стюарду",
	"шахматы из слоновой кости, без шести фигур",
	"парчовая кровать с балдахином, разобранная с большим трудом",
	"запасной позолоченный канделябр из часовни",
	"охотничий рог последнего Маршала в серебряной оправе",
	"портрет давно забытого предка, изрезанный недовольным должником",
	"оловянная утварь придворного виночерпия и ключи от нее",
	"лирванская инкрустированная самоцветами ванна непристойных размеров",
	"двенадцать бочек огненного вина с Мрачного побережья, отложенных для праздника Середины зимы",
	"казенгунский лакированный гардероб неопределенного возраста",
	"этрусский иллюминированный бестиарий, подпорченный водой",
	"горсть заводных игрушек из Хартфелта, едва слышно тикающих",
	"ручная виверра из зверинца, весьма скверного нрава",
	"великие королевские часы, разобранные и погруженные на три телеги",
	"двенадцать сотен ярдов наледианского шелка для запасных ливрей Короны",
	"королевский запас анчоусов из Солтвика в масле",
	"королевский неприкосновенный запас сыра из Кингсфилда",
	"две головы белых оленей, чучела с последней королевской охоты",
	"ящик с неизвестной белой жидкостью сомнительного происхождения, помеченный «ТОЛЬКО ДЛЯ КОРОНЫ — не для употребления»",
	"опечатанный ящик с пометкой «ИМУЩЕСТВО ПОКОЙНОГО СТЮАРДА»",
))

/// Returns a semicolon-separated string of 2-3 randomly chosen seizures for the announcement.
/// Semicolons (rather than commas) keep the items distinguishable when each contains internal
/// commas of its own ("...water-damaged", "...packed in oil"). The final item is preceded by
/// "and" in the period-formal manner.
/proc/atc_seizure_blurb()
	var/list/picks = list()
	var/count = rand(2, 3)
	var/list/pool = GLOB.atc_seizure_inventory.Copy()
	for(var/i in 1 to count)
		if(!length(pool))
			break
		var/choice = pick(pool)
		picks += choice
		pool -= choice
	if(length(picks) == 1)
		return picks[1]
	if(length(picks) == 2)
		return "[picks[1]]; and [picks[2]]"
	var/last = picks[length(picks)]
	picks.Cut(length(picks), length(picks) + 1)
	return "[jointext(picks, "; ")]; and [last]"

// ============================================================================
// ATC Emergency Loan - early-round "just one more day" tool. Adds debt that future inflow
// repays, plus consumes the arrears safety net (next failed payroll skips to sequestration).
// Disabled from ATC_LOAN_CLOSED_DAY onward so it can't be used to free-ride a round-end wipe.
// ============================================================================
/datum/controller/subsystem/treasury/proc/atc_loan_available()
	if(treasury_state == TREASURY_BANKRUPTCY)
		return FALSE
	if(GLOB.dayspassed >= ATC_LOAN_CLOSED_DAY)
		return FALSE
	return TRUE

/datum/controller/subsystem/treasury/proc/atc_loan_blocker_reason()
	if(treasury_state == TREASURY_BANKRUPTCY)
		return "Компания управляет торговлей. Новые займы невозможны, пока секвестрация не будет снята."
	if(GLOB.dayspassed >= ATC_LOAN_CLOSED_DAY)
		return "Клерк Гильдий отсутствует на месте. Окно выдачи займов закрыто до конца недели."
	if(atc_loan_arrears_consumed)
		return "Предыдущий аванс остаётся неоплаченным. Компания отказывает в повторном займе, пока первый не будет погашен."
	return null

/datum/controller/subsystem/treasury/proc/take_atc_loan(amount, mob/applicant)
	var/blocker = atc_loan_blocker_reason()
	if(blocker)
		if(applicant)
			to_chat(applicant, span_warning("Loan refused: [blocker]."))
		return FALSE
	amount = clamp(round(amount), ATC_LOAN_MIN_AMOUNT, ATC_LOAN_MAX_AMOUNT)
	var/debt_owed = round(amount * (1 + ATC_LOAN_INTEREST_RATE))
	treasury_debt += debt_owed
	GLOB.azure_round_stats[STATS_TREASURY_DEBT_OUTSTANDING] = treasury_debt
	atc_loans_drawn_this_round += 1
	atc_loan_arrears_consumed = TRUE
	// Direct credit so the principal isn't immediately skimmed against the debt we just registered.
	discretionary_fund.balance += amount
	log_fund_entry(new /datum/treasury_entry("mint", null, discretionary_fund, amount, "ATC emergency loan (principal)"))
	priority_announce(
		"Корона получает аванс в размере [amount]м от Азурианской Торговой Компании под привычный интерес в одну четверть, фиксируя за собой долг в [debt_owed]м. Льготный период по задолженностям аннулирован; если Корона пропустит следующую выплату жалования, в королевстве будет объявлена секвестрация без предупреждения",
		"ЗАЙМ КОРОНЫ",
		'sound/misc/royal_decree.ogg',
		"Captain",
	)
	log_game("ATC LOAN: [applicant ? key_name(applicant) : "system"] drew [amount]m principal from the Azurian Trading Company; debt of [debt_owed]m registered")
	return TRUE
