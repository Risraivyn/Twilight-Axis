GLOBAL_LIST_EMPTY(standing_order_pool)

/datum/standing_order
	var/name
	var/description
	var/region_id
	var/list/required_items = list()
	var/total_payout = 0
	var/day_issued = 0
	var/day_expires = 0
	var/is_fulfilled = FALSE
	/// Relative weight when the daily roller picks a template from a region's pool. Finished-
	/// goods orders (equipment, potions) are more interesting than raw stockpile baskets, so
	/// they weight higher. Raw-goods subtypes keep the default 1.
	var/roll_weight = 1
	/// Spawned by a Steward petition. Payout is shaved by PETITION_TAX_MULT and the UI tags it.
	var/petitioned = FALSE

/// Returns assoc list of trade_good_id -> quantity. Randomized mix.
/datum/standing_order/proc/generate_item_mix()
	return list()

/// Called after region_id is set. Return the order's display name.
/datum/standing_order/proc/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ТОРГОВЫЙ ЗАКАЗ"

/// Called after region_id is set. Return a flavor paragraph.
/// Subtypes can define per-region overrides via a project_by_region list and fall back to generic.
/datum/standing_order/proc/generate_description(datum/economic_region/region)
	return "В регионе [region.name] выставлен новый торговый заказ"


// ============================================================================
// demand_rations - garrison/feast food demand
// ============================================================================
/datum/standing_order/demand_rations
	var/list/project_by_region = list(
		TRADE_REGION_BLEAKCOAST = list("снабжение корабельной команды", "экипаж каперов", "портовая стража"),
		TRADE_REGION_NORTHFORT = list("пограничный гарнизон", "сержант дозора (пополнение запасов)", "сбор ополчения"),
		TRADE_REGION_HEARTFELT = list("свита графа", "отряд странствующих егерей", "местное братство авантюристов"),
		TRADE_REGION_KINGSFIELD = list("рыночный город", "устроители деревенского пира", "смотритель зернохранилища"),
	)

/datum/standing_order/demand_rations/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_GRAIN] = rand(25, 40)
	if(prob(60))
		mix[TRADE_GOOD_MEAT] = rand(6, 12)
	if(prob(60))
		mix[TRADE_GOOD_CHEESE] = rand(4, 10)
	return mix

/datum/standing_order/demand_rations/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ПОСТАВКА ПРОВИЗИИ"

/datum/standing_order/demand_rations/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] срочно нуждается в провианте."
	return "Снабженцы в регионе [region.name] запрашивают рационы для своих подопечных."


// ============================================================================
// demand_armaments - garrison weapons + armor
// ============================================================================
/datum/standing_order/demand_armaments
	var/list/project_by_region = list(
		TRADE_REGION_BLEAKCOAST = list("бойцы с галеры", "снаряжение отряда корсаров", "портовая стража"),
		TRADE_REGION_NORTHFORT = list("пограничный гарнизон", "отряд пограничного ополчения", "сержант дозора"),
		TRADE_REGION_HEARTFELT = list("свита графа", "местный отряд наёмников", "группа странствующих егерей"),
	)


/datum/standing_order/demand_armaments/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_IRON_INGOT] = rand(8, 14)
	if(prob(60))
		mix[TRADE_GOOD_STEEL_INGOT] = rand(3, 7)
	if(prob(60))
		mix[TRADE_GOOD_CURED_LEATHER] = rand(5, 10)
	return mix

/datum/standing_order/demand_armaments/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ПОСТАВКА ВООРУЖЕНИЯ"

/datum/standing_order/demand_armaments/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] требует перевооружения перед следующим военным сезоном."
	return "Оружейные мастера региона [region.name] запрашивают слитки и шкуры для экипировки солдат."


// ============================================================================
// demand_textile - tailors guild cloth + fiber
// ============================================================================
/datum/standing_order/demand_textile
	var/list/project_by_region = list(
		TRADE_REGION_KINGSFIELD = list("местный портной", "рыночная лавка", "странствующий купец"),
		TRADE_REGION_HEARTFELT = list("заказ знаменщика", "изготовление табард для свиты", "заказ праздничного платья к именинам"),
	)

/datum/standing_order/demand_textile/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_CLOTH] = rand(30, 50)
	if(prob(75))
		mix[TRADE_GOOD_FIBERS] = rand(15, 30)
	return mix

/datum/standing_order/demand_textile/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ЗАКАЗ ПОРТНЫХ"

/datum/standing_order/demand_textile/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] требует рулоны ткани и волокно."
	return "Гильдия портных в регионе [region.name] принимает заказы на ткани и волокна."


// ============================================================================
// demand_smithing - smithy guild ingots
// ============================================================================
/datum/standing_order/demand_smithing
	var/list/project_by_region = list(
		TRADE_REGION_DAFTSMARCH = list("гильдия кузнецов", "литейные мастерские", "мастер-кузнец с горой заказов"),
		TRADE_REGION_KINGSFIELD = list("деревенская кузница", "изготовитель сельхозинвентаря", "местный коваль"),
	)

/datum/standing_order/demand_smithing/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_IRON_INGOT] = rand(8, 14)
	if(prob(70))
		mix[TRADE_GOOD_COPPER_INGOT] = rand(5, 10)
	return mix

/datum/standing_order/demand_smithing/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - КУЗНЕЧНЫЕ ПОСТАВКИ"

/datum/standing_order/demand_smithing/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] запрашивает слитки для работ на месяц вперед."
	return "Кузница в регионе [region.name] заказывает слитки для обеспечения работ на месяц вперед."


// ============================================================================
// demand_construction - masons + carpenters, merged
// ============================================================================
/datum/standing_order/demand_construction
	var/list/project_by_region = list(
		TRADE_REGION_BLEAKCOAST = list("укрепление портовой стены", "ремонт берегового гарнизона"),
		TRADE_REGION_NORTHFORT = list("расширение цитадели пограничного гарнизона", "восстановление сторожевой башни"),
		TRADE_REGION_HEARTFELT = list("реставрация собора", "расширение графской залы"),
		TRADE_REGION_KINGSFIELD = list("дорожные работы в рыночном городе", "расширение зернохранилища"),
		TRADE_REGION_DAFTSMARCH = list("укрепление шахтного ствола", "расширение литейной мастерской"),
		TRADE_REGION_ROSAWOOD = list("восстановление лесопилки", "ремонт торгового тракта"),
		TRADE_REGION_ROCKHILL = list("восстановление террасной стены", "расширение давильни"),
		TRADE_REGION_BLACKHOLT = list("восстановление башни после неудачного эксперимента", "восстановление внешнего святилища"),
		TRADE_REGION_SALTWICK = list("восстановление солеварни", "укрепление причалов"),
	)

/datum/standing_order/demand_construction/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_STONE] = rand(40, 70)
	if(prob(70))
		mix[TRADE_GOOD_WOOD] = rand(12, 25)
	if(prob(50))
		mix[TRADE_GOOD_IRON_INGOT] = rand(3, 7)
	return mix

/datum/standing_order/demand_construction/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ЗАКАЗ НА СТРОИТЕЛЬСТВО"

/datum/standing_order/demand_construction/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] срочно требует строительные материалы."
	return "Строителям в регионе [region.name] требуются камень, древесина и скобяные изделия."


// ============================================================================
// demand_exotic - wizards / alchemists
// ============================================================================
/datum/standing_order/demand_exotic
	var/list/project_by_region = list(
		TRADE_REGION_BLACKHOLT = list("ковен чародеев", "отшельник, закупающий реагенты", "странно бледный аристократ с научными интересами"),
		TRADE_REGION_ROSAWOOD = list("круг друидов", "лесной отшельник", "странствующая лесная ведьма"),
	)

/datum/standing_order/demand_exotic/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_DENDOR_ESSENCE] = rand(3, 6)
	if(prob(60))
		mix[TRADE_GOOD_SILK] = rand(8, 15)
	if(prob(60))
		mix[TRADE_GOOD_VISCERA] = rand(8, 15)
	return mix

/datum/standing_order/demand_exotic/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - МАГИЧЕСКИЙ ЗАКАЗ"

/datum/standing_order/demand_exotic/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] требует экзотические реагенты без малейшего промедления."
	return "Тайное сообщество в регионе [region.name] щедро платит за экзотические реагенты."


// ============================================================================
// demand_fishery - fishmongers, salting houses
// ============================================================================
/datum/standing_order/demand_fishery
	var/list/project_by_region = list(
		TRADE_REGION_SALTWICK = list("гильдия рыботорговцев", "засольщик, заваленный заказами", "прибрежный заготовитель"),
		TRADE_REGION_BLEAKCOAST = list("снабжение судовой команды", "экипаж каперов", "портовая стража"),
		TRADE_REGION_KINGSFIELD = list("рыночный рыботорговец", "деревенский заготовщик", "странствующий торговец рыбой"),
	)

/datum/standing_order/demand_fishery/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_FISH_FILET] = rand(15, 25)
	mix[TRADE_GOOD_SALT] = rand(8, 15)
	return mix

/datum/standing_order/demand_fishery/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ЗАКАЗ РЫБАКА"

/datum/standing_order/demand_fishery/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] выставил заказ на поставку рыбы и соли."
	return "Рыбная лавка в регионе [region.name] закупает рыбу и соль."


// ============================================================================
// demand_orchard - chefs, apothecaries
// ============================================================================
/datum/standing_order/demand_orchard
	var/list/project_by_region = list(
		TRADE_REGION_ROCKHILL = list("урожай мастера садов", "долинный аптекарь", "сидровая давильня"),
		TRADE_REGION_KINGSFIELD = list("рыночный заготовитель", "деревенский аптекарь", "странствующий травник"),
		TRADE_REGION_HEARTFELT = list("раздача милостыни в часовне", "гарнизонный аптекарь", "госпитальер, закупающийся в дорогу"),
	)

/datum/standing_order/demand_orchard/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_APPLE] = rand(25, 45)
	if(prob(70))
		mix[TRADE_GOOD_JACKSBERRY] = rand(15, 28)
	if(prob(60))
		mix[TRADE_GOOD_CALENDULA] = rand(5, 12)
	return mix

/datum/standing_order/demand_orchard/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ЗАКАЗ САДОВ"

/datum/standing_order/demand_orchard/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] запрашивает садовую продукцию и лечебную календулу."
	return "Заготовщик или аптекарь в регионе [region.name] закупает садовые товары."

// ============================================================================
// urgent - emergency requisition spawned by a shortage economic event.
// Carries a weakref to its source event; item mix and payout are set by
// SSeconomy.spawn_urgent_for_event() from the event's affected_goods.
// ============================================================================
/datum/standing_order/urgent
	var/datum/weakref/source_event_ref

/datum/standing_order/urgent/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] -  СРОЧНЫЙ ЗАКАЗ"

/datum/standing_order/urgent/generate_description(datum/economic_region/region)
	var/list/buyers = list("Местная знать", "Купеческий консорциум", "Старейшины гильдии", "Отчаявшийся горожанин", "Местные магнаты")
	var/buyer = pick(buyers)
	var/datum/economic_event/E = source_event_ref?.resolve()
	if(E)
		return "Регион [region.name] страдает от бедствия: «[E.name]». [buyer] готовы выплатить щедрую премию за помощь в разрешении этого кризиса."
	return "[buyer] в регионе [region.name] объявили о чрезвычайном сборе ресурсов."

// ============================================================================
// demand_equipment_armaments - finished weapons for a garrison
// ============================================================================
/datum/standing_order/demand_equipment_armaments
	roll_weight = 3
	var/list/project_by_region = list(
		TRADE_REGION_BLEAKCOAST = list("a privateer captain outfitting", "a corsair's company", "a harbor watch armsmaster"),
		TRADE_REGION_NORTHFORT = list("a frontier garrison", "a watch sergeant outfitting", "a band of border irregulars"),
		TRADE_REGION_HEARTFELT = list("the count's retinue", "a local mercenary band", "a warband outfitting for the road"),
		TRADE_REGION_KINGSFIELD = list("a market armsmaster", "a knight-errant outfitting", "a back-room arms-broker"),
	)
	var/list/one_ingot_pool = list(
		TRADE_GOOD_STEEL_ARMING_SWORD,
		TRADE_GOOD_STEEL_SHORTSWORD,
		TRADE_GOOD_STEEL_FALCHION,
		TRADE_GOOD_STEEL_MESSER,
		TRADE_GOOD_STEEL_SABRE,
		TRADE_GOOD_STEEL_MACE,
		TRADE_GOOD_STEEL_FLANGED_MACE,
		TRADE_GOOD_STEEL_FLAIL,
	)
	var/list/two_ingot_pool = list(
		TRADE_GOOD_STEEL_LONGSWORD,
		TRADE_GOOD_STEEL_BROADSWORD,
		TRADE_GOOD_STEEL_WARHAMMER,
		TRADE_GOOD_STEEL_BATTLEAXE,
		TRADE_GOOD_HURLBAT,
	)

/datum/standing_order/demand_equipment_armaments/generate_item_mix()
	var/list/mix = list()
	var/primary_one = pick(one_ingot_pool)
	mix[primary_one] = rand(3, 5)
	if(prob(55))
		var/secondary_two = pick(two_ingot_pool)
		mix[secondary_two] = rand(1, 2)
	// Bows are cheap and plentiful — garrison archer lines want quivers of them.
	if(prob(55))
		mix[TRADE_GOOD_RECURVE_BOW] = rand(3, 6)
	return mix

/datum/standing_order/demand_equipment_armaments/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ОРУЖЕЙНЫЙ ЗАКАЗ"

/datum/standing_order/demand_equipment_armaments/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] требует готовое оружие; доставить на склад."
	return "Гарнизону в регионе [region.name] требуется готовое оружие; доставить на склад."


// ============================================================================
// demand_equipment_armor_heavy - finished metallic harness for a garrison
// (smith-fulfillable, no tailor goods required)
// ============================================================================
/datum/standing_order/demand_equipment_armor_heavy
	roll_weight = 3
	var/list/project_by_region = list(
		TRADE_REGION_BLEAKCOAST = list("снаряжение капитана каперов", "ватага корсаров", "оружейник портовой стражи"),
		TRADE_REGION_NORTHFORT = list("пограничный гарнизон", "сержант дозора, пополняющий снаряжение", "отряд пограничного ополчения"),
		TRADE_REGION_HEARTFELT = list("свита графа", "местный отряд наёмников", "боевой отряд, собирающийся в поход"),
		TRADE_REGION_KINGSFIELD = list("рыночный оружейник", "снаряжение странствующего рыцаря", "подпольный торговец оружием"),
	)
	var/list/chain_pool = list(
		TRADE_GOOD_STEEL_CHAINMAIL,
		TRADE_GOOD_STEEL_HAUBERK,
		TRADE_GOOD_BRIGANDINE,
		TRADE_GOOD_BRIGANDINE_HEAVY,
	)
	var/list/plate_pool = list(
		TRADE_GOOD_STEEL_CUIRASS,
		TRADE_GOOD_STEEL_COATPLATES,
		TRADE_GOOD_STEEL_HALFPLATE,
		TRADE_GOOD_STEEL_FULLPLATE,
	)
	var/list/helm_pool = list(
		TRADE_GOOD_STEEL_HELM_KNIGHT,
		TRADE_GOOD_STEEL_HELM_BASCINET,
		TRADE_GOOD_STEEL_HELM_KETTLE,
	)
	var/list/extremity_pool = list(
		TRADE_GOOD_STEEL_MASK,
		TRADE_GOOD_CHAIN_GLOVES,
		TRADE_GOOD_PLATE_GAUNTLETS,
		TRADE_GOOD_STEEL_PLATE_LEGS,
	)

/datum/standing_order/demand_equipment_armor_heavy/generate_item_mix()
	var/list/mix = list()
	// Armor orders stay small in qty — a garrison outfits a handful of soldiers per order,
	// not a whole company. Payout per piece is high enough that 1-2 units is valuable.
	var/chain_or_plate = prob(60) ? chain_pool : plate_pool
	var/core = pick(chain_or_plate)
	mix[core] = rand(1, 2)
	if(prob(65))
		var/helm = pick(helm_pool)
		mix[helm] = rand(1, 2)
	if(prob(50))
		var/extremity = pick(extremity_pool)
		mix[extremity] = rand(1, 3)
	return mix

/datum/standing_order/demand_equipment_armor_heavy/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ЗАКАЗ НА ДОСПЕХИ"

/datum/standing_order/demand_equipment_armor_heavy/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] требует готовый латный гарнитур; доставить на склад."
	return "Гарнизону в регионе [region.name] требуется готовый латный гарнитур; доставить на склад."


// ============================================================================
// demand_equipment_armor_light - finished light/leather kit for a company
// (tailor-fulfillable, no smith goods required). Mixes finished gambesons,
// hardened-leather pieces, and a small bundle of cured leather + cloth raw
// stock — orders that the tailor and the leatherworker can cover end-to-end
// without the smithy.
// ============================================================================
/datum/standing_order/demand_equipment_armor_light
	roll_weight = 3
	var/list/project_by_region = list(
		TRADE_REGION_BLEAKCOAST = list("портовая стража", "сбор берегового ополчения", "снаряжение ватаги корсаров"),
		TRADE_REGION_NORTHFORT = list("сержант дозора, пополняющий снаряжение", "отряд пограничного ополчения", "призыв пограничных резервистов"),
		TRADE_REGION_HEARTFELT = list("группа странствующих егерей", "пешие сержанты графа", "местное братство авантюристов"),
		TRADE_REGION_KINGSFIELD = list("сельское ополчение", "рыночная рота", "снаряжение капитана йоменов"),
	)
	var/list/body_pool = list(
		TRADE_GOOD_PADDED_GAMBESON,
		TRADE_GOOD_HEAVY_LEATHER_COAT,
	)

/datum/standing_order/demand_equipment_armor_light/generate_item_mix()
	var/list/mix = list()
	var/primary_body = pick(body_pool)
	mix[primary_body] = rand(2, 3)
	if(prob(55))
		// The other body piece, so a single order can include both gambesons and coats.
		var/list/secondary_pool = body_pool - primary_body
		if(length(secondary_pool))
			mix[pick(secondary_pool)] = rand(1, 2)
	if(prob(65))
		mix[TRADE_GOOD_HARDENED_LEATHER_HELMET] = rand(1, 2)
	if(prob(50))
		mix[TRADE_GOOD_HARDENED_LEATHER_GORGET] = rand(1, 2)
	if(prob(45))
		mix[TRADE_GOOD_HEAVY_LEATHER_GLOVES] = rand(1, 3)
	if(prob(50))
		mix[TRADE_GOOD_CURED_LEATHER] = rand(4, 8)
	if(prob(40))
		mix[TRADE_GOOD_CLOTH] = rand(4, 8)
	return mix

/datum/standing_order/demand_equipment_armor_light/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - РОТНЫЕ ТУНИКИ"

/datum/standing_order/demand_equipment_armor_light/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] требует шитое снаряжение и доспехи из вареной кожи; доставить на склад."
	return "Роте в регионе [region.name] требуется шитое снаряжение и доспехи из вареной кожи; доставить на склад."


// ============================================================================
// demand_salt - bulk salt requisition for the salting-houses
// Only ever rolls for Saltwick (producer) and Kingsfield (major consumer).
// ============================================================================
/datum/standing_order/demand_salt
	var/list/project_by_region = list(
		TRADE_REGION_SALTWICK = list("оптовый заказ мастера засола", "расширение засолочного цеха", "гильдия заготовщиков"),
		TRADE_REGION_KINGSFIELD = list("рыночный заготовщик", "деревенская коптильня", "пополнение запасов придорожных лоточников"),
	)

/datum/standing_order/demand_salt/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_SALT] = rand(30, 55)
	return mix

/datum/standing_order/demand_salt/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ЗАКАЗ СОЛИ"

/datum/standing_order/demand_salt/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] запрашивает соль в больших объёмах для заготовки мяса и рыбы."
	return "Заготовители в регионе [region.name] нуждаются в крупных поставках соли."


// ============================================================================
// demand_victualling_fleet - Saltwick fishing fleet's ration stores
// ============================================================================
/datum/standing_order/demand_victualling_fleet
	roll_weight = 2

/datum/standing_order/demand_victualling_fleet/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_GRAIN] = rand(20, 35)
	mix[TRADE_GOOD_DRIED_FISH] = rand(4, 7)
	if(prob(70))
		mix[TRADE_GOOD_MEAT] = rand(5, 10)
	if(prob(60))
		mix[TRADE_GOOD_CHEESE] = rand(4, 8)
	return mix

/datum/standing_order/demand_victualling_fleet/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ПРОВИЗИЯ ДЛЯ ФЛОТА"

/datum/standing_order/demand_victualling_fleet/generate_description(datum/economic_region/region)
	var/list/flavors = list(
		"The fishing fleet at [region.name] lays in stores for the season's run.",
		"The wharvesmen at [region.name] need victuals for a month at sea.",
		"A captain at [region.name] takes on stores before his vessel sails.",
	)
	return pick(flavors)


// ============================================================================
// demand_victualling_garrison - preserved rations for the garrisons
// ============================================================================
/datum/standing_order/demand_victualling_garrison
	roll_weight = 2
	var/list/project_by_region = list(
		TRADE_REGION_NORTHFORT = list("a frontier garrison", "a watch sergeant restocking", "a keep's quartermaster"),
		TRADE_REGION_BLEAKCOAST = list("a ship's company victualling", "a coastal garrison's larder", "a privateer's crew"),
		TRADE_REGION_HEARTFELT = list("the count's retinue", "a roving warden party", "a local adventuring fellowship"),
	)

/datum/standing_order/demand_victualling_garrison/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_SALUMOI] = rand(4, 7)
	if(prob(70))
		mix[TRADE_GOOD_SAUSAGE] = rand(4, 7)
	if(prob(70))
		mix[TRADE_GOOD_GRAIN] = rand(15, 25)
	if(prob(50))
		mix[TRADE_GOOD_CHEESE] = rand(4, 8)
	return mix

/datum/standing_order/demand_victualling_garrison/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ПРОВИЗИЯ ДЛЯ ГАРНИЗОНА"

/datum/standing_order/demand_victualling_garrison/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] at [region.name] calls for preserved rations that will last the garrison."
	return "A garrison at [region.name] lays in preserved rations for the next rotation."


// ============================================================================
// demand_victualling_mines - Daftsmarch miners' long-shift provisions
// ============================================================================
/datum/standing_order/demand_victualling_mines
	roll_weight = 2

/datum/standing_order/demand_victualling_mines/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_SALUMOI] = rand(4, 7)
	if(prob(70))
		mix[TRADE_GOOD_OATS] = rand(15, 25)
	if(prob(55))
		mix[TRADE_GOOD_SAUSAGE] = rand(4, 7)
	if(prob(45))
		mix[TRADE_GOOD_BUTTER] = rand(2, 4)
	return mix

/datum/standing_order/demand_victualling_mines/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ШАХТЕРНАЯ ПРОВИЗИЯ"

/datum/standing_order/demand_victualling_mines/generate_description(datum/economic_region/region)
	var/list/flavors = list(
		"The foremen at [region.name] feed the miners through the long night-shifts underground.",
		"The mineworks at [region.name] need stout fare to see their crews through the week.",
		"A shift-boss at [region.name] lays in dry goods that will not spoil in the shafts.",
	)
	return pick(flavors)


// ============================================================================
// demand_alchemical - finished potions for a chapel infirmary, conclave, or watch
// Delivered to the warehouse: any container holding the right reagent at the right
// volume satisfies a unit. Matched containers are consumed in full.
// ============================================================================
/datum/standing_order/demand_alchemical
	roll_weight = 3
	var/list/project_by_region = list(
		TRADE_REGION_HEARTFELT = list("a chapel infirmary", "a hospitaller buying for the road", "a garrison surgeon"),
		TRADE_REGION_BLACKHOLT = list("a wizards' coven", "a hermit reagent-buyer", "an oddly red-eyed aristocrat"),
		TRADE_REGION_BLEAKCOAST = list("a galley's surgeon", "a privateer's crew laying in stores", "a coastal garrison's apothecary"),
		TRADE_REGION_NORTHFORT = list("a frontier surgeon", "a watch sergeant restocking", "a band of border irregulars"),
		TRADE_REGION_KINGSFIELD = list("a market apothecary", "a village healer", "a travelling herbalist"),
	)
	// Mana lives in the premium pool only - keeping it in both used to let a premium roll
	// overwrite the larger primary qty when the same id was picked twice.
	var/list/medicinal_pool = list(
		TRADE_GOOD_HEALTH_POTION,
		TRADE_GOOD_STAM_POTION,
		TRADE_GOOD_ANTIDOTE_POTION,
	)
	var/list/premium_pool = list(
		TRADE_GOOD_STRONG_HEALTH_POTION,
		TRADE_GOOD_STRONG_MANA_POTION,
		TRADE_GOOD_STRONG_STAM_POTION,
		TRADE_GOOD_STRONG_ANTIDOTE_POTION,
		TRADE_GOOD_MANA_POTION,
	)

/datum/standing_order/demand_alchemical/generate_item_mix()
	var/list/mix = list()
	var/primary = pick(medicinal_pool)
	mix[primary] = rand(4, 8)
	if(prob(60))
		var/premium = pick(premium_pool)
		// max() guard so a colliding pick can never downgrade a larger earlier qty.
		mix[premium] = max(mix[premium] || 0, rand(3, 6))
	return mix

/datum/standing_order/demand_alchemical/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ЗАКАЗ АПОТЕКАРИЯ"

/datum/standing_order/demand_alchemical/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] требует готовые зелья; оставить на складе."
	return "Аптекарь в регионе [region.name] щедро заплатит за готовые зелья, оставленные на складе."

// ============================================================================
// demand_alchemical_warband - elite buff-potion order for adventurers, the conclave,
// and chosen retinues. Stat-buff potions plus a backbone of strong-* support potions.
// ============================================================================
/datum/standing_order/demand_alchemical_warband
	roll_weight = 1
	var/list/project_by_region = list(
		TRADE_REGION_BLACKHOLT = list("a wizards' coven", "a battle-mage's hireling outfit", "a sun-starved aristocrat's hunting party"),
		TRADE_REGION_HEARTFELT = list("the count's chosen retinue", "a temple's champions", "a roving warden party"),
		TRADE_REGION_KINGSFIELD = list("a knight-errants' convocation", "a mercenary captain's warband", "a noble's hunting party"),
		TRADE_REGION_NORTHFORT = list("a frontier strike-band", "a watch sergeant's chosen", "a local adventuring fellowship"),
	)
	var/list/buff_pool = list(
		TRADE_GOOD_STRENGTH_POTION,
		TRADE_GOOD_PERCEPTION_POTION,
		TRADE_GOOD_INTELLIGENCE_POTION,
		TRADE_GOOD_SPEED_POTION,
	)
	var/list/support_pool = list(
		TRADE_GOOD_STRONG_HEALTH_POTION,
		TRADE_GOOD_STRONG_MANA_POTION,
		TRADE_GOOD_STRONG_STAM_POTION,
		TRADE_GOOD_STRONG_ANTIDOTE_POTION,
	)

/datum/standing_order/demand_alchemical_warband/generate_item_mix()
	var/list/mix = list()
	var/buff_primary = pick(buff_pool)
	mix[buff_primary] = rand(2, 3)
	if(prob(55))
		var/buff_secondary = pick(buff_pool)
		mix[buff_secondary] = max(mix[buff_secondary] || 0, rand(2, 3))
	var/support = pick(support_pool)
	mix[support] = max(mix[support] || 0, rand(2, 3))
	return mix

/datum/standing_order/demand_alchemical_warband/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ПРИПАСЫ БОЕВОГО ОТРЯДА"

/datum/standing_order/demand_alchemical_warband/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] at [region.name] commissions draughts of stat and strong potion."
	return "An elite party at [region.name] commissions draughts of stat and strong potion."


// ============================================================================
// demand_birthday_gift - a named noble's name-day gift basket
// ============================================================================
/datum/standing_order/demand_birthday_gift
	roll_weight = 2
	var/list/celebrants_by_region = list(
		TRADE_REGION_KINGSFIELD = list(
			"Lady Marisol of Cherrybrook",
			"Lord Berenger the Younger",
			"Dame Vesalia Sundermark",
			"Sir Aldwin of Aubergrove",
		),
		TRADE_REGION_ROCKHILL = list(
			"Lord Hadrius Vespermill",
			"Lady Aurinde Greengable",
		),
		TRADE_REGION_HEARTFELT = list(
			"Count Eduard Harlause",
			"Sir Ardent of the March",
		),
		TRADE_REGION_ROSAWOOD = list("Lady Sylvarine Briarmoss"),
		TRADE_REGION_DAFTSMARCH = list("Lord Korgrad of Pickleridge"),
		TRADE_REGION_BLEAKCOAST = list("Lord Captain Vesarion of Saltreef"),
		TRADE_REGION_BLACKHOLT = list("Huntsmarshal Ostran"),
	)
	var/list/jewelry_pool = list(
		TRADE_GOOD_AMBER_RING,
		TRADE_GOOD_GOLD_RING,
		TRADE_GOOD_AMBER_AMULET,
		TRADE_GOOD_JADE_AMULET,
	)
	var/list/garment_pool = list(
		TRADE_GOOD_NOBLECOAT,
		TRADE_GOOD_SILK_TUNIC,
		TRADE_GOOD_SEASONAL_GOWN,
	)

/datum/standing_order/demand_birthday_gift/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_SILK] = rand(3, 6)
	mix[TRADE_GOOD_JACKSBERRY] = rand(8, 14)
	if(prob(70))
		var/exotic = pick(TRADE_GOOD_LEMON, TRADE_GOOD_LIME, TRADE_GOOD_TANGERINE, TRADE_GOOD_PLUM)
		mix[exotic] = rand(3, 6)
	if(prob(70))
		var/jewel = pick(jewelry_pool)
		mix[jewel] = 1
	if(prob(60))
		var/garment = pick(garment_pool)
		mix[garment] = 1
	return mix

/datum/standing_order/demand_birthday_gift/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ПОДАРОК НА ИМЕНИНЫ"

/datum/standing_order/demand_birthday_gift/generate_description(datum/economic_region/region)
	var/list/celebrants = celebrants_by_region[region.region_id]
	if(length(celebrants))
		return "A name-day approaches for [pick(celebrants)] of [region.name]. Their household commissions a fitting tribute."
	return "A noble of [region.name] keeps a name-day. Their household commissions a fitting tribute."


// ============================================================================
// demand_great_feast - heavy butter + meat feast spread, 1/3 chance Lord Harlause
// ============================================================================
/datum/standing_order/demand_great_feast
	roll_weight = 2
	var/list/feast_for_by_region = list(
		TRADE_REGION_KINGSFIELD = list("a market town's harvest feast", "the manor of a country knight", "a wedding banquet"),
		TRADE_REGION_HEARTFELT = list("the count's high table", "a chapter feast of the march guard"),
		TRADE_REGION_BLEAKCOAST = list("a sea-lord's high table", "a captains' banquet aboard the flagship", "a privateer's homecoming feast"),
		TRADE_REGION_NORTHFORT = list("the garrison's midwinter feast", "a watchcommander's table"),
		TRADE_REGION_ROCKHILL = list("the orchard-masters' harvest hall", "a press-house celebration"),
	)

/datum/standing_order/demand_great_feast/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_BUTTER] = rand(8, 15)
	mix[TRADE_GOOD_GRAIN] = rand(30, 50)
	mix[TRADE_GOOD_MEAT] = rand(15, 25)
	mix[TRADE_GOOD_CHEESE] = rand(8, 15)
	if(prob(70))
		var/fruit = pick(TRADE_GOOD_APPLE, TRADE_GOOD_PEAR, TRADE_GOOD_JACKSBERRY)
		mix[fruit] = rand(8, 14)
	if(prob(50))
		mix[TRADE_GOOD_POULTRY] = rand(5, 10)
	if(prob(40))
		mix[TRADE_GOOD_PORK] = rand(5, 10)
	return mix

/datum/standing_order/demand_great_feast/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ВЕЛИКИЙ ПИР"

/datum/standing_order/demand_great_feast/generate_description(datum/economic_region/region)
	if(prob(33))
		return "Lord Harlause sets the table at [region.name]. His house calls for butter, beef, and bread."
	var/list/feasts = feast_for_by_region[region.region_id]
	if(length(feasts))
		return "[capitalize(pick(feasts))] at [region.name] calls for butter, beef, and bread."
	return "A great feast at [region.name] calls for butter, beef, and bread."


// ============================================================================
// demand_frontier_gear - finished light/medium kit for the wardens and watch
// ============================================================================
/datum/standing_order/demand_frontier_gear
	roll_weight = 3
	var/list/project_by_region = list(
		TRADE_REGION_NORTHFORT = list("a watch sergeant outfitting", "a band of border irregulars", "a frontier reservist call-up"),
		TRADE_REGION_BLEAKCOAST = list("the harbor watch", "a coastal patrol mustering", "a privateer's crew outfitting"),
		TRADE_REGION_HEARTFELT = list("a roving warden party", "a temple's guard", "a local adventuring fellowship"),
		TRADE_REGION_KINGSFIELD = list("a country sheriff's posse", "a local muster", "a yeoman captain outfitting"),
	)
	var/list/body_pool = list(
		TRADE_GOOD_PADDED_GAMBESON,
		TRADE_GOOD_HEAVY_LEATHER_COAT,
	)

/datum/standing_order/demand_frontier_gear/generate_item_mix()
	var/list/mix = list()
	mix[pick(body_pool)] = rand(2, 4)
	if(prob(70))
		mix[TRADE_GOOD_HARDENED_LEATHER_HELMET] = rand(2, 4)
	if(prob(55))
		mix[TRADE_GOOD_HEAVY_LEATHER_GLOVES] = rand(2, 4)
	if(prob(45))
		mix[TRADE_GOOD_RECURVE_BOW] = rand(3, 6)
	return mix

/datum/standing_order/demand_frontier_gear/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ПОГРАНИЧНЫЙ НАБОР ГАРНИЗОНА"

/datum/standing_order/demand_frontier_gear/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] at [region.name] requires light kit fit for irregular service."
	return "A frontier muster at [region.name] requires light kit for the watch."


// ============================================================================
// demand_court_finery - finished tailoring for the court and its lesser houses
// ============================================================================
/datum/standing_order/demand_court_finery
	roll_weight = 2
	var/list/project_by_region = list(
		TRADE_REGION_KINGSFIELD = list("a noble household's wardrobe", "a court tailor's commission", "a market tailor"),
		TRADE_REGION_HEARTFELT = list("the count's wardrobe", "a noble investiture", "a wedding-bound house"),
		TRADE_REGION_ROCKHILL = list("a country estate's spring wardrobe", "a noble's name-day finery", "a sun-shy aristocrat's seasonal fitting"),
	)
	var/list/finery_pool = list(
		TRADE_GOOD_NOBLECOAT,
		TRADE_GOOD_SILK_TUNIC,
		TRADE_GOOD_SEASONAL_GOWN,
		TRADE_GOOD_MAID_DRESS,
	)

/datum/standing_order/demand_court_finery/generate_item_mix()
	var/list/mix = list()
	mix[pick(finery_pool)] = rand(2, 4)
	if(prob(50))
		var/second = pick(finery_pool)
		mix[second] = rand(1, 3)
	if(prob(20))
		mix[TRADE_GOOD_ROYAL_DRESS] = 1
	return mix

/datum/standing_order/demand_court_finery/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ЗНАТНЫЙ ЗАКАЗ УКРАШЕНИЙ"

/datum/standing_order/demand_court_finery/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] at [region.name] commissions finished tailoring for the season."
	return "A noble household at [region.name] commissions finished tailoring."


// ============================================================================
// demand_fine_joinery - wood + leather + iron + cloth, joiner's commission
// ============================================================================
/datum/standing_order/demand_fine_joinery
	var/list/project_by_region = list(
		TRADE_REGION_KINGSFIELD = list("a country estate's joiner", "a manor house refurnish", "a temple's furnishings order"),
		TRADE_REGION_ROSAWOOD = list("a master joiner's workshop", "a roadside furniture maker"),
		TRADE_REGION_ROCKHILL = list("an orchard estate's joiner", "a press-house refit"),
		TRADE_REGION_HEARTFELT = list("the count's hall furnishings", "a garrison hall refit"),
	)

/datum/standing_order/demand_fine_joinery/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_WOOD] = rand(15, 28)
	mix[TRADE_GOOD_CLOTH] = rand(6, 12)
	if(prob(70))
		mix[TRADE_GOOD_IRON_INGOT] = rand(3, 6)
	if(prob(55))
		mix[TRADE_GOOD_CURED_LEATHER] = rand(4, 8)
	return mix

/datum/standing_order/demand_fine_joinery/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - КОМИССИЯ СТОЛЯРА"

/datum/standing_order/demand_fine_joinery/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в [region.name] требует базовых материалов - дерево, ткань, и железо."
	return "A joiner at [region.name] requires materials for fine furnishings."


// ============================================================================
// demand_artificery - mixed engineering bundle: glass, copper, tin, coal, mess kit
// ============================================================================
/datum/standing_order/demand_artificery
	roll_weight = 2
	var/list/project_by_region = list(
		TRADE_REGION_DAFTSMARCH = list("the artificers' guild", "a master smith's workshop", "a foundry-master's commission"),
		TRADE_REGION_KINGSFIELD = list("a court artificer's workshop", "a guild engineer's workshop", "a back-alley contraption maker"),
		TRADE_REGION_BLACKHOLT = list("a coven's contraption shop", "an arcane engineer's workshop", "a hermit tinkerer's bulk order"),
		TRADE_REGION_NORTHFORT = list("a garrison's engineer", "a siege-engineer at the keep", "a frontier sapper outfitting"),
	)

/datum/standing_order/demand_artificery/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_COPPER_INGOT] = rand(6, 12)
	mix[TRADE_GOOD_TIN_INGOT] = rand(4, 8)
	mix[TRADE_GOOD_COAL] = rand(8, 14)
	if(prob(70))
		mix[TRADE_GOOD_GLASS_BATCH] = rand(3, 6)
	if(prob(45))
		mix[TRADE_GOOD_MESS_KIT] = rand(2, 4)
	return mix

/datum/standing_order/demand_artificery/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - МАСТЕРСКАЯ РЕМЕСЛИНИКА"

/datum/standing_order/demand_artificery/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] at [region.name] requires bronze-stock and tin for the next batch."
	return "An artificer at [region.name] is buying bronze-stock and tin."


// ============================================================================
// demand_jewelry - jeweler's stocking order, mixed rings and amulets
// ============================================================================
/datum/standing_order/demand_jewelry
	roll_weight = 2
	var/list/project_by_region = list(
		TRADE_REGION_KINGSFIELD = list("a court jeweler", "a master goldsmith", "a noble household's wardrobe"),
		TRADE_REGION_HEARTFELT = list("the count's jeweler", "a temple reliquary's commission", "a wedding-bound house"),
		TRADE_REGION_ROCKHILL = list("a country estate's jeweler", "a name-day finery commission", "a sun-shy aristocrat's heirloom resetting"),
	)
	var/list/jewelry_pool = list(
		TRADE_GOOD_AMBER_RING,
		TRADE_GOOD_GOLD_RING,
		TRADE_GOOD_EMERALD_RING,
		TRADE_GOOD_AMBER_AMULET,
		TRADE_GOOD_JADE_AMULET,
	)

/datum/standing_order/demand_jewelry/generate_item_mix()
	var/list/mix = list()
	mix[pick(jewelry_pool)] = rand(2, 4)
	if(prob(60))
		var/second = pick(jewelry_pool)
		mix[second] = rand(1, 3)
	if(prob(15))
		mix[TRADE_GOOD_DIAMOND_RING] = 1
	return mix

/datum/standing_order/demand_jewelry/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ЮВЕЛИРНАЯ КОМИССИЯ"

/datum/standing_order/demand_jewelry/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] at [region.name] requires finished rings and amulets for their stock."
	return "A jeweler at [region.name] is buying finished rings and amulets."


// ============================================================================
// demand_prosthetic_run - chapel/infirmary order: prosthetics + healing potions
// ============================================================================
/datum/standing_order/demand_prosthetic_run
	roll_weight = 2
	var/list/project_by_region = list(
		TRADE_REGION_HEARTFELT = list("a chapel infirmary", "a hospitaller's wounded-house", "a battlefield surgeon's bulk order"),
		TRADE_REGION_NORTHFORT = list("a frontier surgeon", "a garrison infirmary", "a band of border irregulars come back broken"),
		TRADE_REGION_BLEAKCOAST = list("a galley's surgeon", "a harbor wounded-house", "a privateer's crew limping in"),
	)

/datum/standing_order/demand_prosthetic_run/generate_item_mix()
	var/list/mix = list()
	var/primary_prosthetic = pick(TRADE_GOOD_BRONZE_PROSTHETIC, TRADE_GOOD_IRON_PROSTHETIC)
	mix[primary_prosthetic] = rand(2, 3)
	if(prob(35))
		mix[TRADE_GOOD_STEEL_PROSTHETIC] = 1
	mix[TRADE_GOOD_HEALTH_POTION] = rand(4, 7)
	if(prob(60))
		mix[TRADE_GOOD_CURED_LEATHER] = rand(4, 8)
	return mix

/datum/standing_order/demand_prosthetic_run/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - ЗАКАЗ ЛАЗАРЕТА"

/datum/standing_order/demand_prosthetic_run/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] принимает множество раненых — требуются протезы и лечебные снадобья."
	return "Лазарет в регионе [region.name] оказывает помощь раненым солдатам и паломникам."


// ============================================================================
// demand_artificed_panoply - rare premium order: artificed plate + voltic gauntlets
// ============================================================================
/datum/standing_order/demand_artificed_panoply
	roll_weight = 1
	var/list/project_by_region = list(
		TRADE_REGION_KINGSFIELD = list("a duke's master-of-arms", "a knight-artificer's commission", "a tournament-bound champion"),
		TRADE_REGION_DAFTSMARCH = list("a master smith's signature contract", "a foundry-master's masterpiece", "a guild's exhibition piece"),
		TRADE_REGION_HEARTFELT = list("the count's chosen champion", "a knightly investiture", "a roving warden captain"),
	)

/datum/standing_order/demand_artificed_panoply/generate_item_mix()
	var/list/mix = list()
	mix[TRADE_GOOD_ARTIFICED_HALFPLATE] = 1
	if(prob(55))
		mix[TRADE_GOOD_VOLTIC_GAUNTLETS] = 1
	mix[TRADE_GOOD_STEEL_INGOT] = rand(8, 14)
	if(prob(50))
		mix[TRADE_GOOD_GOLD_INGOT] = rand(2, 4)
	return mix

/datum/standing_order/demand_artificed_panoply/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - АРТЕФАКТНЫЙ ПАНОПЛИЙ"

/datum/standing_order/demand_artificed_panoply/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] в регионе [region.name] заказывает паноплий из артефактных лат. За шедевр платят цену шедевра."
	return "Покровитель в регионе [region.name] заказывает паноплий из артефактных лат. За шедевр платят цену шедевра."


// ============================================================================
// demand_tournament_supply - single fat composite order, deliberately challenging
// ============================================================================
/datum/standing_order/demand_tournament_supply
	roll_weight = 2
	var/list/project_by_region = list(
		TRADE_REGION_KINGSFIELD = list("the Tournament of the Three Hills", "the lists at Cherrybrook", "a knight-errants' convocation"),
		TRADE_REGION_HEARTFELT = list("the March Tourney", "the count's lists at Heartfelt"),
		TRADE_REGION_ROCKHILL = list("the Orchard Lists", "a midsummer tourney at Vespermill"),
	)
	var/list/weapon_pool = list(
		TRADE_GOOD_STEEL_ARMING_SWORD,
		TRADE_GOOD_STEEL_LONGSWORD,
		TRADE_GOOD_STEEL_MACE,
		TRADE_GOOD_STEEL_SABRE,
	)
	var/list/armor_pool = list(
		TRADE_GOOD_STEEL_CHAINMAIL,
		TRADE_GOOD_STEEL_HAUBERK,
		TRADE_GOOD_BRIGANDINE,
	)

/datum/standing_order/demand_tournament_supply/generate_item_mix()
	var/list/mix = list()
	mix[pick(weapon_pool)] = rand(3, 5)
	mix[pick(armor_pool)] = rand(2, 3)
	mix[TRADE_GOOD_HEALTH_POTION] = rand(6, 10)
	mix[TRADE_GOOD_MANA_POTION] = rand(3, 5)
	mix[TRADE_GOOD_GRAIN] = rand(20, 35)
	mix[TRADE_GOOD_MEAT] = rand(10, 18)
	mix[TRADE_GOOD_BUTTER] = rand(5, 10)
	if(prob(60))
		mix[TRADE_GOOD_NOBLECOAT] = rand(1, 2)
	if(prob(50))
		mix[TRADE_GOOD_RECURVE_BOW] = rand(3, 5)
	return mix

/datum/standing_order/demand_tournament_supply/generate_name(datum/economic_region/region)
	return "[uppertext(region.name)] - СНАБЖЕНИЕ ТУРНИРА"

/datum/standing_order/demand_tournament_supply/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	if(length(projects))
		return "[capitalize(pick(projects))] at [region.name] requires arms, armor, draughts, and feast-fare. The patrons pay accordingly."
	return "A great tournament at [region.name] requires arms, armor, draughts, and feast-fare. The patrons pay accordingly."


// ============================================================================
// demand_arcane_commission - enchantment scrolls commissioned by NON-wizard regions.
// Blackholt is the producer (the conclave) - the demand fires elsewhere, paying the
// Crown to broker. Rolls one of three tiers, weighted toward routine basic-tier orders.
// ============================================================================
/datum/standing_order/demand_arcane_commission
	roll_weight = 2
	var/list/project_by_region = list(
		TRADE_REGION_HEARTFELT = list("a temple's bookbinder", "a knightly house outfitting", "a hospitaller buying for the road"),
		TRADE_REGION_ROCKHILL = list("a viscount's library", "a country estate's curio collector", "an oddly pale-skinned aristocrat with academic interests"),
		TRADE_REGION_KINGSFIELD = list("a knight-errant outfitting for the road", "a guild's bulk order", "a market wand-seller"),
		TRADE_REGION_NORTHFORT = list("a frontier scout-captain", "a band of border irregulars", "a local adventuring fellowship"),
	)
	/// Tier the order rolled. Set in generate_item_mix and read by name/description.
	var/rolled_tier = "basic"

/datum/standing_order/demand_arcane_commission/generate_item_mix()
	var/list/mix = list()
	var/roll = rand(1, 100)
	if(roll <= 55)
		rolled_tier = "basic"
		mix[TRADE_GOOD_ENCHSCROLL_BASIC] = rand(3, 6)
	else if(roll <= 85)
		rolled_tier = "superior"
		mix[TRADE_GOOD_ENCHSCROLL_SUPERIOR] = rand(2, 4)
	else
		rolled_tier = "greater"
		mix[TRADE_GOOD_ENCHSCROLL_GREATER] = rand(1, 3)
	return mix

/datum/standing_order/demand_arcane_commission/generate_name(datum/economic_region/region)
	switch(rolled_tier)
		if("superior")
			return "[uppertext(region.name)] - SUPERIOR ARCANA"
		if("greater")
			return "[uppertext(region.name)] - GREATER ARCANA"
		else
			return "[uppertext(region.name)] - ARCANE COMMISSION"

/datum/standing_order/demand_arcane_commission/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	var/patron = length(projects) ? capitalize(pick(projects)) : "A patron"
	switch(rolled_tier)
		if("superior")
			return "[patron] at [region.name] commissions superior enchantment scrolls - fulfilled at the warehouse, any scrolls will serve."
		if("greater")
			return "[patron] at [region.name] commissions greater enchantment scrolls - fulfilled at the warehouse - any types will serve."
		else
			return "[patron] at [region.name] commissions basic enchantment scrolls - any school of magic, sealed at the warehouse."


/datum/standing_order/demand_trophy_heads
	roll_weight = 1
	var/list/project_by_region = list(
		TRADE_REGION_HEARTFELT = list("the count's manor hall", "a marcher lord's gallery", "a heralds' lodge"),
		TRADE_REGION_ROCKHILL = list("a hunt-master's trophy hall", "the master-of-hounds at Vespermill", "a viscount's trophy room"),
	)
	/// Variant the order rolled. Set in generate_item_mix and read by generate_description.
	var/rolled_variant = "minotaur"

/datum/standing_order/demand_trophy_heads/generate_item_mix()
	var/list/mix = list()
	var/roll = rand(1, 100)
	if(roll <= 30)
		// White Stag — singular, no other heads. The bearer must trigger the boss spawn.
		rolled_variant = "white_stag"
		mix[TRADE_GOOD_TROPHY_WHITE_STAG] = 1
	else if(roll <= 65)
		// Minotaur + a couple of direbears.
		rolled_variant = "minotaur"
		mix[TRADE_GOOD_TROPHY_MINOTAUR] = rand(3, 6)
		if(prob(60))
			mix[TRADE_GOOD_TROPHY_DIREBEAR] = rand(1, 2)
	else
		// Regular troll heads only — exact-type match excludes axe/cave subtypes.
		rolled_variant = "troll"
		mix[TRADE_GOOD_TROPHY_TROLL] = rand(5, 6)
	return mix

/datum/standing_order/demand_trophy_heads/generate_name(datum/economic_region/region)
	switch(rolled_variant)
		if("white_stag")
			return "[uppertext(region.name)] - WHITE STAG TROPHY"
		if("troll")
			return "[uppertext(region.name)] - TROLL HEADS"
		else
			return "[uppertext(region.name)] - MANOR TROPHIES"

/datum/standing_order/demand_trophy_heads/generate_description(datum/economic_region/region)
	var/list/projects = project_by_region[region.region_id]
	var/patron = length(projects) ? capitalize(pick(projects)) : "A noble house"
	switch(rolled_variant)
		if("white_stag")
			return "[patron] at [region.name] would mount the White Stag's head above their hearth. None other will do."
		if("troll")
			return "[patron] at [region.name] would line their hall with troll heads - a warning to any who would test the marches."
		else
			return "[patron] at [region.name] commissions trophies for their gallery - heads of the wild brought to heel."
