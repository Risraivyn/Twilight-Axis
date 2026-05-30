GLOBAL_LIST_EMPTY(active_economic_events)

/datum/economic_event
	var/name
	var/description
	var/announcement
	var/list/affected_goods
	var/price_mod = 1.0
	var/event_type
	var/duration_days = ECON_EVENT_DURATION
	var/day_started = 0
	var/day_expires = 0
	var/datum/weakref/urgent_order_ref
	var/saturation_target = 0
	var/saturation_progress = 0
	var/relief_triggered = FALSE

/datum/economic_event/proc/on_apply()
	for(var/good_id in affected_goods)
		var/datum/trade_good/tg = GLOB.trade_goods[good_id]
		if(tg)
			tg.global_price_mod *= price_mod
	refresh_affected_stockpile_caches()
	if(event_type == ECON_EVENT_SHORTAGE)
		var/limit_sum = 0
		var/limit_count = 0
		for(var/good_id in affected_goods)
			var/datum/roguestock/D = SStreasury.stockpile_by_trade_good[good_id]
			if(!D || D.stockpile_limit <= 0)
				continue
			limit_sum += D.stockpile_limit
			limit_count++
		saturation_target = limit_count > 0 ? max(1, round(limit_sum * ECON_EVENT_SATURATION_MULT / limit_count)) : 1
	if(announcement && !(SSeconomy?.daily_report_diff))
		scom_announce(announcement)

/datum/economic_event/proc/on_expire()
	for(var/good_id in affected_goods)
		var/datum/trade_good/tg = GLOB.trade_goods[good_id]
		if(tg && price_mod != 0)
			tg.global_price_mod /= price_mod
	refresh_affected_stockpile_caches()
	// Withdraw auto-price ratchets downward only, so a glut that pushed it below
	// baseline never recovers on its own. When an oversupply ends, snap any
	// auto-priced stockpile entry back to the restored market.
	if(event_type != ECON_EVENT_OVERSUPPLY)
		return
	for(var/datum/roguestock/D as anything in SStreasury.stockpile_datums)
		if(!D.automatic_price || !D.trade_good_id)
			continue
		if(!(D.trade_good_id in affected_goods))
			continue
		D.snap_auto_prices()

/// Refresh cached market reference prices and (for auto-priced entries) the live
/// payout/withdraw prices on every stockpile entry whose trade good was affected by
/// this event. Replaces the per-tick refresh_auto_price + get_market_*_price work
/// the stewardry UI used to do for every good every tick.
/datum/economic_event/proc/refresh_affected_stockpile_caches()
	for(var/datum/roguestock/D as anything in SStreasury.stockpile_datums)
		if(!D.trade_good_id || !(D.trade_good_id in affected_goods))
			continue
		var/datum/trade_good/tg = GLOB.trade_goods[D.trade_good_id]
		if(!tg)
			continue
		D.recompute_market_reference_prices(tg)
		if(D.automatic_price)
			D.compute_auto_prices(tg)
	SStreasury.dirty_market_view()

/datum/economic_event/proc/end_with_relief()
	if(relief_triggered)
		return
	relief_triggered = TRUE
	on_expire()
	GLOB.active_economic_events -= src
	if(SSeconomy)
		SSeconomy.event_path_cooldowns[type] = GLOB.dayspassed + ECON_EVENT_REROLL_COOLDOWN_DAYS
	record_round_statistic(STATS_SHORTAGES_ENDED, 1)
	var/list/diff = SSeconomy?.daily_report_diff
	if(diff)
		var/list/relieved = diff["events_relieved"]
		if(!relieved)
			relieved = list()
			diff["events_relieved"] = relieved
		relieved += name
	else
		scom_announce("<font color='#5cb85c'>RELIEF: [name] eased by relief efforts. Prices return to normal.</font>")

/proc/credit_economic_event_saturation(good_id, units)
	if(!good_id || units <= 0)
		return
	var/list/relieved = list()
	for(var/datum/economic_event/E as anything in GLOB.active_economic_events)
		if(E.event_type != ECON_EVENT_SHORTAGE)
			continue
		if(E.relief_triggered)
			continue
		if(!(good_id in E.affected_goods))
			continue
		E.saturation_progress += units
		if(E.saturation_progress >= E.saturation_target)
			relieved += E
	for(var/datum/economic_event/E as anything in relieved)
		E.end_with_relief()


// ============================================================================
// SHORTAGES
// ============================================================================

/datum/economic_event/black_oak_rebellion
	name = "ВОССТАНИЕ ЧЕРНОГО ДУБА"
	description = "Черные Дубы снова восстали в Розвуде — лесорубов находят прибитыми к деревьям, а дровосеки отказываются входить в лесную чащу без эскорта Короны."
	announcement = "<font color='#c44'>ВОССТАНИЕ ЧЕРНОГО ДУБА: Лесозаготовки Розвуда заброшены. Цены на древесину резко растут.</font>"
	affected_goods = list(TRADE_GOOD_WOOD)
	price_mod = ECON_SHORTAGE_MAJOR
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/ironmongers_strike
	name = "ЗАБАСТОВКА ЖЕЛЕЗНЯКОВ"
	description = "Гильдия железняков прекратила работу из-за неоплаченных заказов — плавильные печи остыли."
	announcement = "<font color='#c44'>ЗАБАСТОВКА ЖЕЛЕЗНЯКОВ: Поставки железной руды перекрыты. Готовый металл теперь в цене.</font>"
	affected_goods = list(TRADE_GOOD_IRON_ORE, TRADE_GOOD_IRON_INGOT, TRADE_GOOD_STEEL_INGOT)
	price_mod = ECON_SHORTAGE_SEVERE
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/daftsmarch_cavein
	name = "ОБВАЛ В ДАФТСМАРЧЕ"
	description = "Глубокий обвал шахты в Дафтсмарче парализовал добычу на трех основных жилах."
	announcement = "<font color='#c44'>ОБВАЛ В ДАФТСМАРЧЕ: Шахты закрыты. Железо, уголь, камень и слитки становятся дефицитом.</font>"
	affected_goods = list(TRADE_GOOD_IRON_ORE, TRADE_GOOD_COAL, TRADE_GOOD_STONE, TRADE_GOOD_IRON_INGOT, TRADE_GOOD_STEEL_INGOT)
	price_mod = ECON_SHORTAGE_NORMAL
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/wheat_blight
	name = "ПШЕНИЧНАЯ ГНИЛЬ"
	description = "Черная гниль пробралась в зернохранилища фермерских хозяйств Кингсфилда."
	announcement = "<font color='#c44'>ПШЕНИЧНАЯ ГНИЛЬ: Зерно и овес гниют в силосных ямах. Цены на хлеб взлетели.</font>"
	affected_goods = list(TRADE_GOOD_GRAIN, TRADE_GOOD_OATS)
	price_mod = ECON_SHORTAGE_SEVERE
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/saltwick_storm
	name = "ШТОРМ В СОЛТВИКЕ"
	description = "Яростный шторм обрушился на верфи Солтвика — рыболовный флот пришвартован уже несколько дней."
	announcement = "<font color='#c44'>ШТОРМ В СОЛТВИКЕ: Рыболовный флот заблокирован. Свежая и вяленая рыба сильно подорожали.</font>"
	affected_goods = list(TRADE_GOOD_FISH_FILET, TRADE_GOOD_DRIED_FISH, TRADE_GOOD_FISH_MINCE)
	price_mod = ECON_SHORTAGE_MAJOR
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/fur_trapping_frost
	name = "ЗАМОРОЗКИ ОХОТНИКОВ"
	description = "Сезонные морозы загнали дичь глубоко в чащу — охотники возвращаются с пустыми руками."
	announcement = "<font color='#c44'>ЗАМОРОЗКИ ОХОТНИКОВ: Поставки меха, шкур и выделанной кожи прекратились. Кожевники в панике.</font>"
	affected_goods = list(TRADE_GOOD_FUR, TRADE_GOOD_HIDE, TRADE_GOOD_CURED_LEATHER)
	price_mod = ECON_SHORTAGE_NORMAL
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/cloth_smuggler_purge
	name = "ОБЛАВА НА КОНТРАБАНДИСТОВ"
	description = "Королевские репрессии против черного рынка тканей парализовали и легальные поставки."
	announcement = "<font color='#c44'>ОБЛАВА НА КОНТРАБАНДИСТОВ: Ткани и волокно изымаются с телег. Портные в отчаянии.</font>"
	affected_goods = list(TRADE_GOOD_CLOTH, TRADE_GOOD_FIBERS)
	price_mod = ECON_SHORTAGE_MAJOR
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/essence_scarcity
	name = "ДЕФИЦИТ ЭССЕНЦИИ"
	description = "Сбор эссенции в Болотах ужаса провалился — алхимические реагенты становятся редкостью."
	announcement = "<font color='#c44'>ДЕФИЦИТ ЭССЕНЦИИ: Запасы эссенции Дендора и потрохов истощены. Волшебники в ярости.</font>"
	affected_goods = list(TRADE_GOOD_DENDOR_ESSENCE, TRADE_GOOD_VISCERA)
	price_mod = ECON_SHORTAGE_CRISIS
	event_type = ECON_EVENT_SHORTAGE


// ============================================================================
// OVERSUPPLIES
// ============================================================================

/datum/economic_event/bumper_harvest
	name = "НЕБЫВАЛЫЙ УРОЖАЙ"
	description = "Кингсфилд сообщает о лучшем урожае зерна в истории — амбары переполнены."
	announcement = "<font color='#5cb85c'>НЕБЫВАЛЫЙ УРОЖАЙ: Зерно и овес наводнили рынок. Цены рухнули.</font>"
	affected_goods = list(TRADE_GOOD_GRAIN, TRADE_GOOD_OATS)
	price_mod = ECON_OVERSUPPLY_SEVERE
	event_type = ECON_EVENT_OVERSUPPLY

/datum/economic_event/rosawood_overcut
	name = "ПЕРЕИЗБЫТОК В РОЗВУДЕ"
	description = "Лесозаготовительные лагеря Розвуда превысили все квоты — баржи на реке забиты древесиной."
	announcement = "<font color='#5cb85c'>ПЕРЕИЗБЫТОК В РОЗВУДЕ: Избыток леса на реке. Цены на древесину поползли вниз.</font>"
	affected_goods = list(TRADE_GOOD_WOOD)
	price_mod = ECON_OVERSUPPLY_MAJOR
	event_type = ECON_EVENT_OVERSUPPLY

/datum/economic_event/herring_swarm
	name = "КОСЯКИ СЕЛЬДИ"
	description = "Гигантские косяки рыбы зашли в воды Солтвика — сети поднимают полными."
	announcement = "<font color='#5cb85c'>КОСЯКИ СЕЛЬДИ: Сети Солтвика рвутся от рыбы. Свежая и вяленая рыба продается за гроши.</font>"
	affected_goods = list(TRADE_GOOD_FISH_FILET, TRADE_GOOD_DRIED_FISH, TRADE_GOOD_FISH_MINCE)
	price_mod = ECON_OVERSUPPLY_GLUT
	event_type = ECON_EVENT_OVERSUPPLY

/datum/economic_event/unseasonal_fur
	name = "МЕХОВОЙ СЕЗОН"
	description = "Охотники сообщают о массовой миграции стад через пограничные земли — склады завалены шкурами."
	announcement = "<font color='#5cb85c'>МЕХОВОЙ СЕЗОН: Склады забиты шкурами. Цены на мех падают.</font>"
	affected_goods = list(TRADE_GOOD_FUR)
	price_mod = ECON_OVERSUPPLY_NORMAL
	event_type = ECON_EVENT_OVERSUPPLY

/datum/economic_event/quarry_windfall
	name = "УДАЧА В КАМЕНОЛОМНЯХ"
	description = "В каменоломнях Безголовой Горы вскрыта богатая жила — телеги едут от заката до рассвета."
	announcement = "<font color='#5cb85c'>УДАЧА В КАМЕНОЛОМНЯХ: Камень и уголь наводнили дворы. Строители ликуют, рабочие ворчат.</font>"
	affected_goods = list(TRADE_GOOD_STONE, TRADE_GOOD_COAL)
	price_mod = ECON_OVERSUPPLY_MINOR
	event_type = ECON_EVENT_OVERSUPPLY


// ============================================================================
// SHORTAGES - additional
// ============================================================================

/datum/economic_event/murrain
	name = "СКОТСКИЙ МОР"
	description = "Изнуряющая болезнь выкосила стада на пастбищах Кингсфилда. Мясо и молочные продукты становятся редкостью."
	announcement = "<font color='#c44'>СКОТСКИЙ МОР: Болезнь косит стада на пастбищах. Мясо, молочные продукты и копченые колбасы сильно подорожали.</font>"
	affected_goods = list(TRADE_GOOD_MEAT, TRADE_GOOD_BUTTER, TRADE_GOOD_CHEESE, TRADE_GOOD_SAUSAGE)
	price_mod = ECON_SHORTAGE_MAJOR
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/saltmine_flooding
	name = "ЗАТОПЛЕНИЕ СОЛЯНЫХ КОПЕЙ"
	description = "Грунтовые воды прорвались в соляные выработки Дафтсмарча, затопив нижние галереи."
	announcement = "<font color='#c44'>ЗАТОПЛЕНИЕ СОЛЯНЫХ КОПЕЙ: Галереи Дафтсмарча ушли под воду. Соль теперь на вес золота.</font>"
	affected_goods = list(TRADE_GOOD_SALT)
	price_mod = ECON_SHORTAGE_SEVERE
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/copper_tin_embargo
	name = "ЭМБАРГО НА МЕДЬ И ОЛОВО"
	description = "Иноземная корона запретила экспорт меди и олова. Кузнецы, работающие с бронзой, в замешательстве."
	announcement = "<font color='#c44'>ЭМБАРГО НА МЕДЬ И ОЛОВО: Зарубежные поставки прекращены. Руда и слитки одинаково дефицитны.</font>"
	affected_goods = list(TRADE_GOOD_COPPER_ORE, TRADE_GOOD_TIN_ORE, TRADE_GOOD_COPPER_INGOT, TRADE_GOOD_TIN_INGOT)
	price_mod = ECON_SHORTAGE_MAJOR
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/tanners_plague
	name = "ЧУМА КОЖЕВНИКОВ"
	description = "Болезнь, разъедающая шкуры, вынудила кожевенные мастерские сжигать половину заготовок."
	announcement = "<font color='#c44'>ЧУМА КОЖЕВНИКОВ: Шкуры сжигают целыми телегами. Изделия из кожи дорожают.</font>"
	affected_goods = list(TRADE_GOOD_CURED_LEATHER, TRADE_GOOD_HIDE)
	price_mod = ECON_SHORTAGE_SEVERE
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/glass_furnace_failure
	name = "ПОЛОМКА СТЕКЛОВАРЕННОЙ ПЕЧИ"
	description = "Главная печь на стекольном заводе треснула. Производство остановлено до завершения ремонта."
	announcement = "<font color='#c44'>ПОЛОМКА СТЕКЛОВАРЕННОЙ ПЕЧИ: Великие стекловарни гаснут. Стекольная шихта стала большой редкостью.</font>"
	affected_goods = list(TRADE_GOOD_GLASS_BATCH)
	price_mod = ECON_SHORTAGE_SEVERE
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/orchard_locusts
	name = "ДОЛГОНОСИК ПОЕЛ УРОЖАЙ"
	description = "Заражение долгоносиком в садах Генавы привело к потере урожая. То немногое, что уцелело, продают по баснословным ценам."
	announcement = "<font color='#c44'>ДОЛГОНОСИК ПОЕЛ УРОЖАЙ: Плодовые сады опустошены. Яблоки и ягоды теперь стоят целое состояние.</font>"
	affected_goods = list(TRADE_GOOD_APPLE, TRADE_GOOD_PEAR, TRADE_GOOD_JACKSBERRY)
	price_mod = ECON_SHORTAGE_MAJOR
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/gem_cartel_squeeze
	name = "МАХИНАЦИИ ЮВЕЛИРНОГО КАРТЕЛЯ"
	description = "Торговые дома монополизировали рынок огранки. Цены на топеры и гемеральды взлетели за одну ночь."
	announcement = "<font color='#c44'>МАХИНАЦИИ ЮВЕЛИРНОГО КАРТЕЛЯ: Торговцы захватили рынок самоцветов. Обычные камни резко подорожали.</font>"
	affected_goods = list(TRADE_GOOD_TOPER, TRADE_GOOD_GEMERALD)
	price_mod = 4.5
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/silk_moth_collapse
	name = "ГИБЕЛЬ ШЕЛКОПРЯДОВ"
	description = "Сбор паучьего шелка в Блэкхолте сорван. Конклав называет это «арахнологическим несчастьем»."
	announcement = "<font color='#c44'>ГИБЕЛЬ ШЕЛКОПРЯДОВ: Урожай шелка в Блэкхолте погиб. Портные скрежещут зубами.</font>"
	affected_goods = list(TRADE_GOOD_SILK)
	price_mod = ECON_SHORTAGE_CRISIS
	event_type = ECON_EVENT_SHORTAGE

/datum/economic_event/clay_pit_collapse
	name = "CLAY PIT COLLAPSE"
	description = "The Blackholt clay pits have caved in, swallowing wagons and diggers alike. Potters are turned away empty-handed."
	announcement = "<font color='#c44'>CLAY PIT COLLAPSE: Blackholt's clay pits cave in. Potters and brickmakers cry out for stock.</font>"
	affected_goods = list(TRADE_GOOD_CLAY)
	price_mod = ECON_SHORTAGE_MINOR
	event_type = ECON_EVENT_SHORTAGE


// ============================================================================
// OVERSUPPLIES - additional
// ============================================================================

/datum/economic_event/dairy_surplus
	name = "МОЛОЧНЫЕ ИЗЛИШКИ"
	description = "Благоприятный сезон переполнил маслобойни Кингсфилда маслом и сыром."
	announcement = "<font color='#5cb85c'>МОЛОЧНЫЕ ИЗЛИШКИ: Масло и сыр льются рекой. Цены на молочные продукты падают.</font>"
	affected_goods = list(TRADE_GOOD_BUTTER, TRADE_GOOD_CHEESE)
	price_mod = ECON_OVERSUPPLY_MAJOR
	event_type = ECON_EVENT_OVERSUPPLY

/datum/economic_event/foreign_pig_iron_glut
	name = "ЗАБУГОРНАЯ МАХИНАЦИЯ"
	description = "Иноземная корона выбросила излишки руды на открытый рынок. Телеги с чугуном и медью идут по ценам ниже себестоимости."
	announcement = "<font color='#5cb85c'>ЗАБУГОРНАЯ МАХИНАЦИЯ: Иностранная руда наводнила склады. Шахтеры Дафтсмарча негодуют; кузнецы закупаются за бесценок.</font>"
	affected_goods = list(TRADE_GOOD_IRON_ORE, TRADE_GOOD_COPPER_ORE, TRADE_GOOD_TIN_ORE)
	price_mod = ECON_OVERSUPPLY_MAJOR
	event_type = ECON_EVENT_OVERSUPPLY

/datum/economic_event/salt_caravan
	name = "СОЛЯНОЙ КАРАВАН"
	description = "Далекий караван прибыл с возами соли — цены будут низкими, пока запасы не иссякнут."
	announcement = "<font color='#5cb85c'>СОЛЯНОЙ КАРАВАН: Телеги с солью достигли рынков. Заготовщики ликуют.</font>"
	affected_goods = list(TRADE_GOOD_SALT)
	price_mod = ECON_OVERSUPPLY_SEVERE
	event_type = ECON_EVENT_OVERSUPPLY

/datum/economic_event/cloth_fair
	name = "ЯРМАРКА ТКАНЕЙ"
	description = "Сезонная ярмарка наводнила рынок рулонами ткани по бросовым ценам."
	announcement = "<font color='#5cb85c'>ЯРМАРКА ТКАНЕЙ: Рулоны ткани заполнили прилавки. Портные празднуют.</font>"
	affected_goods = list(TRADE_GOOD_CLOTH, TRADE_GOOD_FIBERS)
	price_mod = ECON_OVERSUPPLY_MAJOR
	event_type = ECON_EVENT_OVERSUPPLY

/datum/economic_event/fat_hog_season
	name = "СЕЗОН ЖИРНЫХ БОРОВОВ"
	description = "Свиноводы провели забой раньше срока — свинина и жир на этой неделе стоят дешево."
	announcement = "<font color='#5cb85c'>СЕЗОН ЖИРНЫХ БОРОВОВ: Свинина, жир и копчености отдаются почти даром. Мясники работают всю ночь.</font>"
	affected_goods = list(TRADE_GOOD_PORK, TRADE_GOOD_FAT, TRADE_GOOD_TALLOW, TRADE_GOOD_SAUSAGE, TRADE_GOOD_SALUMOI)
	price_mod = ECON_OVERSUPPLY_MAJOR
	event_type = ECON_EVENT_OVERSUPPLY

/datum/economic_event/cidering_season
	name = "СЕЗОН СИДРА"
	description = "Прессы Генавы стонут под тяжестью плодов. Торговцы сбрасывают излишки по любым ценам."
	announcement = "<font color='#5cb85c'>СЕЗОН СИДРА: Горы фруктов лежат у прессов. Продукция садов стоит гроши.</font>"
	affected_goods = list(TRADE_GOOD_APPLE, TRADE_GOOD_PEAR, TRADE_GOOD_JACKSBERRY)
	price_mod = ECON_OVERSUPPLY_SEVERE
	event_type = ECON_EVENT_OVERSUPPLY
