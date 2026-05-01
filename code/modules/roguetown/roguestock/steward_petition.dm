GLOBAL_LIST_INIT(petition_categories, build_petition_categories())

/proc/build_petition_categories()
	var/list/cats = list()
	cats[PETITION_CATEGORY_PROVISIONS] = list(
		"label" = "Припасы",
		"description" = "Основные продукты — рационы, рыба, садовые плоды, соль, провизия.",
		"cost" = PETITION_COST_PROVISIONS,
		"templates" = list(
			/datum/standing_order/demand_rations,
			/datum/standing_order/demand_fishery,
			/datum/standing_order/demand_orchard,
			/datum/standing_order/demand_salt,
			/datum/standing_order/demand_victualling_fleet,
			/datum/standing_order/demand_victualling_garrison,
			/datum/standing_order/demand_victualling_mines,
		),
	)
	cats[PETITION_CATEGORY_MATERIALS] = list(
		"label" = "Материалы",
		"description" = "Сырье — заготовки для ковки, строительства, ткани, столярных и инженерных работ.",
		"cost" = PETITION_COST_MATERIALS,
		"templates" = list(
			/datum/standing_order/demand_smithing,
			/datum/standing_order/demand_construction,
			/datum/standing_order/demand_textile,
			/datum/standing_order/demand_artificery,
			/datum/standing_order/demand_fine_joinery,
		),
	)
	cats[PETITION_CATEGORY_ARMS] = list(
		"label" = "Оружие и Снаряжение",
		"description" = "Готовое оружие и броня — гарнизонное снаряжение, ополченческий сбор, латные комплекты.",
		"cost" = PETITION_COST_ARMS,
		"templates" = list(
			/datum/standing_order/demand_armaments,
			/datum/standing_order/demand_equipment_armaments,
			/datum/standing_order/demand_equipment_armor_heavy,
			/datum/standing_order/demand_equipment_armor_light,
			/datum/standing_order/demand_frontier_gear,
		),
	)
	cats[PETITION_CATEGORY_LUXURIES] = list(
		"label" = "Роскошь",
		"description" = "Придворное убранство, ювелирные изделия, подношения на именины и великие пиры.",
		"cost" = PETITION_COST_LUXURIES,
		"templates" = list(
			/datum/standing_order/demand_court_finery,
			/datum/standing_order/demand_jewelry,
			/datum/standing_order/demand_birthday_gift,
			/datum/standing_order/demand_great_feast,
		),
	)
	cats[PETITION_CATEGORY_ALCHEMY] = list(
		"label" = "Алхимия и Уход",
		"description" = "Готовые зелья, протезы, экзотические реагенты.",
		"cost" = PETITION_COST_ALCHEMY,
		"templates" = list(
			/datum/standing_order/demand_alchemical,
			/datum/standing_order/demand_alchemical_warband,
			/datum/standing_order/demand_prosthetic_run,
			/datum/standing_order/demand_exotic,
		),
	)
	cats[PETITION_CATEGORY_MASTERWORK] = list(
		"label" = "Мастерские работы",
		"description" = "Выставочные заказы — артефактные паноплии, турнирное снабжение, охотничьи трофеи.",
		"cost" = PETITION_COST_MASTERWORK,
		"templates" = list(
			/datum/standing_order/demand_artificed_panoply,
			/datum/standing_order/demand_tournament_supply,
			/datum/standing_order/demand_trophy_heads,
		),
	)
	return cats

/datum/controller/subsystem/economy/proc/petitions_remaining_today()
	if(last_petition_day != GLOB.dayspassed)
		return PETITIONS_PER_DAY
	return max(0, PETITIONS_PER_DAY - petitions_today)

/// Returns null if the petition can proceed, otherwise a human-readable reason string.
/// Single source of truth for both the DM action and the TGUI eligibility matrix.
/datum/controller/subsystem/economy/proc/petition_blocker(region_id, category_id)
	if(petitions_remaining_today() <= 0)
		return "торговый зал уже принял петицию сегодня"
	var/list/cat = GLOB.petition_categories[category_id]
	if(!cat)
		return "Неизвестная категория петиции"
	var/datum/economic_region/region = GLOB.economic_regions[region_id]
	if(!region)
		return "Неизвестный регион"
	if(region.is_region_blockaded)
		return "[region.name] в блокаде — путь для послов закрыт"
	if(region.day_last_cleared >= 0)
		var/since = GLOB.dayspassed - region.day_last_cleared
		if(since < PETITION_BLOCKADE_RECOVERY_DAYS)
			var/wait_days = PETITION_BLOCKADE_RECOVERY_DAYS - since
			return "связи в [region.name] ещё не восстановлены — подождите ещё [wait_days] дн."
	if(GLOB.standing_order_pool.len >= STANDING_ORDERS_POOL_CAP)
		return "складская ведомость заполнена — сначала выполните текущие заказы"
	var/active_in_region = 0
	for(var/datum/standing_order/O as anything in GLOB.standing_order_pool)
		if(O.region_id == region_id)
			active_in_region++
	if(active_in_region >= STANDING_ORDERS_MAX_PER_REGION)
		return "в [region.name] уже активно [active_in_region] заказов"
	var/list/eligible = list()
	for(var/template_path in cat["templates"])
		if(template_path in region.possible_standing_order_types)
			eligible += template_path
	if(!length(eligible))
		return "торговый зал [region.name] не занимается категорией «[cat["label"]]»"
	if(!SStreasury.burgher_pledge_fund)
		return "Обет Горожан ещё не учрежден"
	var/cost = cat["cost"]
	if(SStreasury.burgher_pledge_fund.balance < cost)
		return "Обет Горожан не может покрыть расходы в [cost]м"
	return null

/datum/controller/subsystem/economy/proc/petition_for_order(mob/user, region_id, category_id)
	var/blocker = petition_blocker(region_id, category_id)
	if(blocker)
		if(user)
			to_chat(user, span_warning("В петиции отказано: [blocker]."))
		return FALSE
	var/list/cat = GLOB.petition_categories[category_id]
	var/cost = cat["cost"]
	if(!SStreasury.burn(SStreasury.burgher_pledge_fund, cost, "Steward petition - [cat["label"]] in [region_id]"))
		if(user)
			to_chat(user, span_warning("В петиции отказано: не удалось списать Обет"))
		return FALSE
	record_round_statistic(STATS_PLEDGE_CONSUMED, cost)
	record_round_statistic(STATS_PETITION_PLEDGE_SPENT, cost)
	if(last_petition_day != GLOB.dayspassed)
		petitions_today = 0
		last_petition_day = GLOB.dayspassed
	petitions_today++
	var/datum/economic_region/region = GLOB.economic_regions[region_id]
	var/list/eligible = list()
	for(var/template_path in cat["templates"])
		if(template_path in region.possible_standing_order_types)
			eligible += template_path
	var/template = pick(eligible)
	var/order_size_mult = min(STANDING_ORDER_POP_SCALE_MAX, 1.0 + (get_effective_player_count() * STANDING_ORDER_POP_SCALE_PER_PLAYER))
	var/datum/standing_order/O = instantiate_standing_order(template, region, order_size_mult, petitioned = TRUE)
	if(!O)
		SStreasury.mint(SStreasury.burgher_pledge_fund, cost, "Steward petition refund - empty roll")
		record_round_statistic(STATS_PLEDGE_CONSUMED, -cost)
		record_round_statistic(STATS_PETITION_PLEDGE_SPENT, -cost)
		petitions_today--
		if(user)
			to_chat(user, span_warning("Петиция оказалась пустой — торговый зал возвращает ваш Обет."))
		return FALSE
	record_round_statistic(STATS_STANDING_ORDERS_PETITIONED, 1)
	log_game("PETITION: [user ? key_name(user) : "system"] petitioned [cat["label"]] in [region.name]: rolled [O.name] (+[O.total_payout]m, -[cost]p)")
	if(user)
		to_chat(user, span_notice("Петиция принята: заказ «[O.name]» выставлен на складе с выплатой в [O.total_payout]м."))
	return TRUE
