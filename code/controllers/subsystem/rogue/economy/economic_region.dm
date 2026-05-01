GLOBAL_LIST_INIT(economic_regions, init_economic_regions())

/proc/init_economic_regions()
	var/list/result = list()
	for(var/datum/economic_region/er as anything in subtypesof(/datum/economic_region))
		var/datum/economic_region/instance = new er()
		if(!instance.region_id)
			continue
		result[instance.region_id] = instance
	return result

/datum/economic_region
	var/region_id
	var/name
	/// Italicized one-liner shown beneath the region name in the Lore Primer's
	/// AZURIA'S REGIONS section. The steward UI ignores it; only `description` shows there.
	var/subtitle = ""
	var/description = ""
	var/list/produces = list()
	var/list/demands = list()
	var/list/possible_standing_order_types = list()
	var/associated_marker_id
	var/is_region_blockaded = FALSE
	/// Null = this region cannot be blockaded.
	var/threat_region_id

	var/list/produces_today = list()
	var/list/demands_today = list()

	/// -1 = never cleared. Otherwise the cooldown window runs from this day.
	var/day_last_cleared = -1

/datum/economic_region/New()
	. = ..()
	produces_today = produces.Copy()
	demands_today = demands.Copy()
	if(!associated_marker_id)
		associated_marker_id = "[region_id]_blockade"

/datum/economic_region/kingsfield
	region_id = TRADE_REGION_KINGSFIELD
	name = "Кингсфилд"
	subtitle = "Королевский Домен, Сердце Азурии"
	description = "Королевские владения герцога Азурии и его самое ценное достояние после самого Лазурного Пика. Полоса земли в десять миль вдоль южного берега реки Азур, ставшая домом для десятков сельскохозяйственных поселений, деревень и рыночных городков. Земли здесь богаты, а людей — в избытке. Это житница Азурии, производящая большую часть зерна, мяса и молочных продуктов, которые ежедневно ввозятся в Лазурный Пик и перепродаются с выгодой. Многие жители столицы держат здесь свои поместья. Герцог, владея большей частью земли напрямую, претендует на десятину от всей продукции региона, и не менее четверти с земель, принадлежащих Короне, что делает этот регион жизненно важным для королевской казны."
	threat_region_id = THREAT_REGION_AZURE_BASIN
	produces = list(
		TRADE_GOOD_GRAIN = TG_SUPPLY_LOCAL_GRAIN,
		TRADE_GOOD_OATS = TG_SUPPLY_FOREIGN_GRAIN,
		TRADE_GOOD_RICE = TG_SUPPLY_FOREIGN_GRAIN,
		TRADE_GOOD_MEAT = TG_SUPPLY_MEAT_BULK,
		TRADE_GOOD_PORK = TG_SUPPLY_MEAT_STAPLE,
		TRADE_GOOD_POULTRY = TG_SUPPLY_MEAT_STAPLE,
		TRADE_GOOD_RABBIT = TG_SUPPLY_MEAT_STAPLE,
		TRADE_GOOD_EGG = TG_SUPPLY_MEAT_BULK,
		TRADE_GOOD_BUTTER = TG_SUPPLY_MEAT_STAPLE,
		TRADE_GOOD_CHEESE = TG_SUPPLY_MEAT_STAPLE,
		TRADE_GOOD_FAT = TG_SUPPLY_MEAT_STAPLE,
		TRADE_GOOD_TALLOW = TG_SUPPLY_MEAT_STAPLE,
		TRADE_GOOD_CABBAGE = TG_SUPPLY_COMMON_VEG,
		TRADE_GOOD_POTATO = TG_SUPPLY_COMMON_VEG,
		TRADE_GOOD_ONION = TG_SUPPLY_COMMON_VEG,
		TRADE_GOOD_CARROT = TG_SUPPLY_COMMON_VEG,
		TRADE_GOOD_TURNIP = TG_SUPPLY_COMMON_VEG,
		TRADE_GOOD_PUMPKIN = 2, // literal: trickle supply, not a staple
	)
	demands = list(
		TRADE_GOOD_PUMPKIN = 2, // literal: small local appetite for eating
		TRADE_GOOD_IRON_INGOT = TG_DEMAND_REFINED_INGOTS,
		TRADE_GOOD_CLOTH = TG_DEMAND_CLOTH,
		TRADE_GOOD_SALT = TG_DEMAND_SALT,
		TRADE_GOOD_IRON_ORE = TG_DEMAND_IRON,
		TRADE_GOOD_COPPER_ORE = TG_DEMAND_TIN_BRONZE,
		TRADE_GOOD_TIN_ORE = TG_DEMAND_TIN_BRONZE,
		TRADE_GOOD_COAL = TG_DEMAND_CHEAP_RAW_MAT,
		TRADE_GOOD_STONE = TG_DEMAND_CHEAP_RAW_MAT,
		TRADE_GOOD_CLAY = TG_DEMAND_CHEAP_RAW_MAT,
		TRADE_GOOD_CINNABAR = TG_DEMAND_PRECIOUS_METAL,
		TRADE_GOOD_GOLD_ORE = TG_DEMAND_PRECIOUS_METAL,
		TRADE_GOOD_SILK = TG_DEMAND_SILK,
		TRADE_GOOD_CALENDULA = TG_DEMAND_SPECIALTY_HERB,
		TRADE_GOOD_POPPY = TG_DEMAND_SPECIALTY_HERB,
		TRADE_GOOD_DENDOR_ESSENCE = 1, // literal: deliberately scarce, not category-bound
		TRADE_GOOD_VISCERA = TG_DEMAND_SPECIALTY_HERB,
		TRADE_GOOD_HIDE = TG_DEMAND_LEATHER,
		TRADE_GOOD_FUR = TG_DEMAND_LEATHER,
		TRADE_GOOD_CURED_LEATHER = TG_DEMAND_LEATHER,
		TRADE_GOOD_WOOD = TG_DEMAND_CHEAP_RAW_MAT,
		TRADE_GOOD_FIBERS = TG_DEMAND_CLOTH,
		TRADE_GOOD_GLASS_BATCH = TG_DEMAND_GLASS,
		TRADE_GOOD_TOPER = TG_DEMAND_GEM,
		TRADE_GOOD_GEMERALD = TG_DEMAND_GEM,
		TRADE_GOOD_FISH_FILET = TG_DEMAND_FISH_BULK,
		TRADE_GOOD_FISH_MINCE = TG_DEMAND_FISH_BULK,
		TRADE_GOOD_SALMON = TG_DEMAND_FISH_SPECIALTY,
		TRADE_GOOD_COD = TG_DEMAND_FISH_SPECIALTY,
		TRADE_GOOD_CRAB = TG_DEMAND_FISH_SPECIALTY,
		TRADE_GOOD_BASS = TG_DEMAND_FISH_SPECIALTY,
		TRADE_GOOD_CARP = TG_DEMAND_FISH_SPECIALTY,
		TRADE_GOOD_SOLE = TG_DEMAND_FISH_SPECIALTY,
		TRADE_GOOD_CLAM = TG_DEMAND_FISH_SPECIALTY,
		TRADE_GOOD_LOBSTER = TG_DEMAND_FISH_SPECIALTY,
		TRADE_GOOD_SHRIMP = TG_DEMAND_FISH_SPECIALTY,
	)

/datum/economic_region/rosawood
	region_id = TRADE_REGION_ROSAWOOD
	name = "Розавуд"
	subtitle = "Эльфийский анклав, Лес Холодного побережья"
	description = "Последний вассал Азурии, которым всё ещё правит эльфийский лорд, и где эльфы составляют большинство населения. Эльфийский анклав на полуострове к северу от горы Декапитация, граничащий с узкой полосой бесплодных прибрежных лесов, известных как Южный Розавуд. Доступ сюда в основном осуществляется по морю. Лес экспортируется с южной окраины. В графстве необычно, почти магически холодно, а вегетационный период длится едва ли три месяца в году. Жители кормятся урожаем, собранным за эти три месяца, дополняя его рыбой из северного моря. Сухопутный путь через перевалы ниже Декапитации проходим, но медленен и опасен из-за разбойников «Черного Дуба». Сами эльфы предпочитают, чтобы так оно и оставалось. Поговаривают, что прекрасные белые плащи графа Розавуда сотканы так же, как и плащи наемников Черного Дуба, которых Корона едва терпит. Граф всегда поспешно отрицает любые обвинения в сговоре, и Корона так и не нашла доказательств обратного."
	threat_region_id = THREAT_REGION_AZURE_GROVE
	produces = list(
		TRADE_GOOD_WOOD = TG_SUPPLY_CHEAP_RAW_MAT,
		TRADE_GOOD_FIBERS = TG_SUPPLY_FIBERS,
		TRADE_GOOD_HIDE = TG_SUPPLY_LEATHER,
		TRADE_GOOD_FUR = TG_SUPPLY_LEATHER,
		TRADE_GOOD_CURED_LEATHER = TG_SUPPLY_LEATHER,
	)
	demands = list(
		TRADE_GOOD_IRON_INGOT = TG_DEMAND_REFINED_INGOTS,
		TRADE_GOOD_GRAIN = TG_DEMAND_LOCAL_GRAIN,
		TRADE_GOOD_SALT = TG_DEMAND_SALT,
	)

/datum/economic_region/rockhill
	region_id = TRADE_REGION_ROCKHILL
	name = "Рокхилл"
	subtitle = "Сады, Виноделы и Травники Хребта"
	description = "Скопление садов и аптекарских огородов к северу от Азурии, укрытое горным хребтом, который делает климат здесь гораздо мягче, чем должен быть. Холмистая местность графства плохо подходит для зерна, но идеальна для плодовых деревьев. Вина и настойки Рокхилла славятся по всей Азурии. Это тихое, причудливое сельскохозяйственное графство, усеянное дворянскими поместьями. Яблочный бренди Рокхилла — самый подделываемый напиток в королевстве. Каждая вторая таверна от Мрачного побережья до Хартфелта утверждает, что подает его, но, пожалуй, лишь треть говорит правду. Графство также известно своими загородными усадьбами: почти три четверти благородных домов королевства владеют здесь хотя бы одним поместьем."
	threat_region_id = THREAT_REGION_MOUNT_DECAP
	produces = list(
		TRADE_GOOD_APPLE = TG_SUPPLY_LOCAL_FRUIT,
		TRADE_GOOD_PEAR = TG_SUPPLY_LOCAL_FRUIT,
		TRADE_GOOD_JACKSBERRY = TG_SUPPLY_LOCAL_FRUIT,
		TRADE_GOOD_CALENDULA = TG_SUPPLY_SPECIALTY_HERB,
		TRADE_GOOD_POPPY = TG_SUPPLY_SPECIALTY_HERB,
	)
	demands = list(
		TRADE_GOOD_GLASS_BATCH = TG_DEMAND_GLASS,
		TRADE_GOOD_CLOTH = TG_DEMAND_CLOTH,
		TRADE_GOOD_SILK = TG_DEMAND_SILK,
		TRADE_GOOD_GRAIN = TG_DEMAND_LOCAL_GRAIN,
		TRADE_GOOD_CLAY = TG_DEMAND_CHEAP_RAW_MAT,
	)

/datum/economic_region/daftsmarch
	region_id = TRADE_REGION_DAFTSMARCH
	/datum/economic_region/daftsmarch
	name = "Дафтсмарч"
	subtitle = "Шахтерская Марка, Руды Гор"
	description = "Графство Дафтсмарч — сердце горнодобывающей промышленности Азурии, длинная полоса земли, прилегающая к южному подножию горы Декапитация. Здесь добывается большая часть сырой руды и соли, от которых зависит королевство. Работа оплачивается хорошо, а жилы изобильны. Но Дафтсмарч расположен неуютно близко к руинам Тарихеи и различным обитателям Подземелья. Опасность, исходящая от дроу и им подобных — постоянная угроза; многие из них видят в Дафтсмарче удобный источник рабов. Но рудные жилы здесь слишком богаты, и Корона не желает их бросать, посылая авантюристов, наемников и гарнизон на битву с обитателями Подземелья, чтобы держать их в страхе."
	threat_region_id = THREAT_REGION_UNDERDARK
	produces = list(
		TRADE_GOOD_IRON_ORE = TG_SUPPLY_IRON,
		TRADE_GOOD_COPPER_ORE = TG_SUPPLY_TIN_BRONZE,
		TRADE_GOOD_TIN_ORE = TG_SUPPLY_TIN_BRONZE,
		TRADE_GOOD_STONE = TG_SUPPLY_CHEAP_RAW_MAT,
		TRADE_GOOD_COAL = TG_SUPPLY_IRON,
		TRADE_GOOD_CINNABAR = TG_SUPPLY_PRECIOUS_METAL,
		TRADE_GOOD_GOLD_ORE = TG_SUPPLY_PRECIOUS_METAL,
		TRADE_GOOD_SALT = TG_SUPPLY_SALT,
		TRADE_GOOD_GLASS_BATCH = TG_SUPPLY_GLASS,
	)
	demands = list(
		TRADE_GOOD_GRAIN = TG_DEMAND_LOCAL_GRAIN,
		TRADE_GOOD_MEAT = TG_DEMAND_MEAT_BULK,
		TRADE_GOOD_CLOTH = TG_DEMAND_CLOTH,
	)

/datum/economic_region/blackholt
	region_id = TRADE_REGION_BLACKHOLT
	name = "Блэкхолт"
	subtitle = "Край Болот, Домен Охотничьего Маршала"
	description = "Поселение на южной окраине Терробога, часть Королевского Домена. Это единственное место, которое Герцог никогда не посещает лично, поручая управление доверенному придворному — Охотничьему Маршалу Блэкхолта. Поселение раскинулось между самим болотом и неосушенными топями на его краю. Местные научились выживать за счет необычных, а по слухам — благословленных Сайдоном даров болота: шелка местных мотыльков, потрохов болотных тварей и редкой Эссенции Дендора, за которую травники и маги платят баснословные деньги. Блэкхолт — мрачное и функциональное место. Туда не переезжают добровольно. Там просто оказываются."
	threat_region_id = THREAT_REGION_AZURE_GROVE
	produces = list(
		TRADE_GOOD_SILK = TG_SUPPLY_SILK,
		TRADE_GOOD_VISCERA = TG_SUPPLY_SPECIALTY_HERB,
		TRADE_GOOD_DENDOR_ESSENCE = 1, // literal: deliberately scarce, not category-bound
		TRADE_GOOD_CALENDULA = TG_SUPPLY_SPECIALTY_HERB,
		TRADE_GOOD_CLAY = TG_SUPPLY_CHEAP_RAW_MAT,
		TRADE_GOOD_HIDE = 2, // literal: bog-game byproduct, backup supply if Rosawood is blockaded
	)
	demands = list(
		TRADE_GOOD_IRON_INGOT = TG_DEMAND_REFINED_INGOTS,
		TRADE_GOOD_CLOTH = TG_DEMAND_CLOTH,
	)

/datum/economic_region/saltwick
	region_id = TRADE_REGION_SALTWICK
	name = "Солтвик"
	subtitle = "Прибрежный город, Рыбные промыслы Королевства"
	description = "Поселение к юго-востоку от Лазурного Пика, примерно в дне езды. Расположенный на побережье, город был основан сначала выходцами из Хаммерхолда, а позже — переселенцами из южного Гронна. Город резко разделен на две части: коптильни и соляные фермы, принадлежащие в основном дворфам и выходцам из Хаммерхолда, в то время как потомки гроннцев составляют большинство рыбаков и моряков. Эти две группы редко вступают в браки и часто спорят, но живут в одном городе в относительной гармонии. Конечно, здесь живут не только они — в Солтвике много тех, кому не повезло в жизни, или кто просто ищет работу. Соль ввозится из Дафтсмарча, используется для консервации рыбы, пойманной местными рыбаками, а затем экспортируется по всей Азурии и Псайдонии."
	threat_region_id = THREAT_REGION_AZUREAN_COAST
	produces = list(
		TRADE_GOOD_FISH_FILET = TG_SUPPLY_FISH_BULK,
		TRADE_GOOD_FISH_MINCE = TG_SUPPLY_FISH_MINCE,
		TRADE_GOOD_SALMON = TG_SUPPLY_FISH_SPECIALTY,
		TRADE_GOOD_COD = TG_SUPPLY_FISH_SPECIALTY,
		TRADE_GOOD_CRAB = TG_SUPPLY_FISH_SPECIALTY,
		TRADE_GOOD_BASS = TG_SUPPLY_FISH_SPECIALTY,
		TRADE_GOOD_CARP = TG_SUPPLY_FISH_SPECIALTY,
		TRADE_GOOD_SOLE = TG_SUPPLY_FISH_SPECIALTY,
		TRADE_GOOD_CLAM = TG_SUPPLY_FISH_SPECIALTY,
		TRADE_GOOD_LOBSTER = TG_SUPPLY_FISH_SPECIALTY,
		TRADE_GOOD_SHRIMP = TG_SUPPLY_FISH_SPECIALTY,
	)
	demands = list(
		TRADE_GOOD_SALT = TG_DEMAND_SALT,
		TRADE_GOOD_FIBERS = TG_DEMAND_CLOTH,
		TRADE_GOOD_CLOTH = TG_DEMAND_CLOTH,
		TRADE_GOOD_WOOD = TG_DEMAND_CHEAP_RAW_MAT,
		TRADE_GOOD_IRON_INGOT = TG_DEMAND_REFINED_INGOTS,
		TRADE_GOOD_PUMPKIN = 2, // literal: small local appetite for eating
	)

/datum/economic_region/bleakcoast
	region_id = TRADE_REGION_BLEAKCOAST
	name = "Мрачное побережье"
	subtitle = "Морская марка Мрачных островов, Пиратский архипелаг"
	description = "Также известен как Морская марка Мрачных островов. Гряда скалистых выступов, которые, по преданию, возникли, когда комета Сайона упала рядом с Терробогом, вытолкнув острова из самого моря. Архипелаг насчитывает сотни островов, что делает навигацию вдоль побережья Азурии чрезвычайно опасной. То, чего островам не хватает в плодородии, они восполняют дарами моря. Косяки рыб в скалистых мелководьях кормят тысячи людей. Но эти богатства не для жителей островов. Острова кишат пиратами — печально известными Налетчиками Мрачных островов, которые охотятся на любого торговца или рыбака, рискнувшего отойти далеко от берега. Герцогство содержит здесь несколько гарнизонов, а раз в два поколения предпринимает разорение островов, сжигая и засыпая солью каждое невоенное поселение. Безрезультатно. Через поколение пираты всегда возвращаются, ибо торговля здесь прибыльна, а пиратство — еще прибыльнее."
	threat_region_id = THREAT_REGION_AZUREAN_COAST
	produces = list()
	demands = list(
		TRADE_GOOD_STEEL_INGOT = TG_DEMAND_REFINED_INGOTS,
		TRADE_GOOD_IRON_INGOT = TG_DEMAND_REFINED_INGOTS,
		TRADE_GOOD_CLOTH = TG_DEMAND_CLOTH,
		TRADE_GOOD_MEAT = TG_DEMAND_MEAT_BULK,
		TRADE_GOOD_PORK = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_POULTRY = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_EGG = TG_DEMAND_MEAT_BULK,
		TRADE_GOOD_FAT = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_TALLOW = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_GRAIN = TG_DEMAND_LOCAL_GRAIN,
		TRADE_GOOD_OATS = TG_DEMAND_LOCAL_GRAIN,
		TRADE_GOOD_RICE = TG_DEMAND_LOCAL_GRAIN,
		TRADE_GOOD_POTATO = TG_DEMAND_COMMON_VEG,
		TRADE_GOOD_ONION = TG_DEMAND_COMMON_VEG,
		TRADE_GOOD_CARROT = TG_DEMAND_COMMON_VEG,
		TRADE_GOOD_TURNIP = TG_DEMAND_COMMON_VEG,
		TRADE_GOOD_CABBAGE = TG_DEMAND_COMMON_VEG,
		TRADE_GOOD_APPLE = TG_DEMAND_LOCAL_FRUIT,
		TRADE_GOOD_PEAR = TG_DEMAND_LOCAL_FRUIT,
		TRADE_GOOD_JACKSBERRY = TG_DEMAND_LOCAL_FRUIT,
		TRADE_GOOD_CURED_LEATHER = TG_DEMAND_LEATHER,
		TRADE_GOOD_HIDE = TG_DEMAND_LEATHER,
	)

/datum/economic_region/northfort
	region_id = TRADE_REGION_NORTHFORT
	name = "Нортфорт"
	subtitle = "Пограничный форт, Стража Северного пути"
	description = "Укрепленный замок на северном подступе к Азурии, на единственном прямом сухопутном пути с севера. Настолько экономически бесполезен, насколько может быть бесполезен форт — то есть абсолютно. Корона кормит его только потому, что без него граница между Гренцельхофтом и Азурией станет предметом для обсуждения."
	threat_region_id = THREAT_REGION_MOUNT_DECAP
	produces = list()
	demands = list(
		TRADE_GOOD_IRON_INGOT = TG_DEMAND_REFINED_INGOTS,
		TRADE_GOOD_STEEL_INGOT = TG_DEMAND_REFINED_INGOTS,
		TRADE_GOOD_FUR = TG_DEMAND_LEATHER,
		TRADE_GOOD_HIDE = TG_DEMAND_LEATHER,
		TRADE_GOOD_CURED_LEATHER = TG_DEMAND_LEATHER,
		TRADE_GOOD_CLOTH = TG_DEMAND_CLOTH,
		TRADE_GOOD_GRAIN = TG_DEMAND_LOCAL_GRAIN,
		TRADE_GOOD_OATS = TG_DEMAND_LOCAL_GRAIN,
		TRADE_GOOD_MEAT = TG_DEMAND_MEAT_BULK,
		TRADE_GOOD_PORK = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_POULTRY = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_BUTTER = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_CHEESE = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_FAT = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_TALLOW = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_EGG = TG_DEMAND_MEAT_BULK,
		TRADE_GOOD_POTATO = TG_DEMAND_COMMON_VEG,
		TRADE_GOOD_TURNIP = TG_DEMAND_COMMON_VEG,
		TRADE_GOOD_CARROT = TG_DEMAND_COMMON_VEG,
		TRADE_GOOD_CABBAGE = TG_DEMAND_COMMON_VEG,
		TRADE_GOOD_ONION = TG_DEMAND_COMMON_VEG,
		TRADE_GOOD_SALT = TG_DEMAND_SALT,
		TRADE_GOOD_COAL = TG_DEMAND_CHEAP_RAW_MAT,
		TRADE_GOOD_CLAY = TG_DEMAND_CHEAP_RAW_MAT,
	)

/datum/economic_region/heartfelt
	region_id = TRADE_REGION_HEARTFELT
	name = "Хартфелт"
	subtitle = "Пограничье, Величайший Вассал Азурии"
	description = "Графство Хартфелт — самый могущественный вассал Азурии, занимающий почти всю западную границу. Графу Хартфелта всегда предоставлялась значительная свобода в сборе доходов и содержании армии, ибо если Хартфелт падет, сердце Азурии окажется беззащитным. Его оборона финансируется за счет сети поместий и угодий, разбросанных по всей Азурии за пределами самого графства. Но любой правитель Азурии знает, что для него нет большей угрозы, чем тот, кто называет себя величайшим защитником короны."
	threat_region_id = THREAT_REGION_AZURE_GROVE
	produces = list()
	demands = list(
		TRADE_GOOD_STEEL_INGOT = TG_DEMAND_REFINED_INGOTS,
		TRADE_GOOD_IRON_INGOT = TG_DEMAND_REFINED_INGOTS,
		TRADE_GOOD_MEAT = TG_DEMAND_MEAT_BULK,
		TRADE_GOOD_POULTRY = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_RABBIT = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_CHEESE = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_BUTTER = TG_DEMAND_MEAT_STAPLE,
		TRADE_GOOD_EGG = TG_DEMAND_MEAT_BULK,
		TRADE_GOOD_GRAIN = TG_DEMAND_LOCAL_GRAIN,
		TRADE_GOOD_RICE = TG_DEMAND_LOCAL_GRAIN,
		TRADE_GOOD_APPLE = TG_DEMAND_LOCAL_FRUIT,
		TRADE_GOOD_PEAR = TG_DEMAND_LOCAL_FRUIT,
		TRADE_GOOD_JACKSBERRY = TG_DEMAND_LOCAL_FRUIT,
		TRADE_GOOD_CALENDULA = TG_DEMAND_SPECIALTY_HERB,
		TRADE_GOOD_POPPY = TG_DEMAND_SPECIALTY_HERB,
		TRADE_GOOD_CLOTH = TG_DEMAND_CLOTH,
		TRADE_GOOD_FIBERS = TG_DEMAND_CLOTH,
		TRADE_GOOD_CURED_LEATHER = TG_DEMAND_LEATHER,
		TRADE_GOOD_HIDE = TG_DEMAND_LEATHER,
		TRADE_GOOD_CLAY = TG_DEMAND_CHEAP_RAW_MAT,
	)

/datum/economic_region/hagenwald
	region_id = TRADE_REGION_HAGENWALD
	name = "Хагенвальд"
	subtitle = "Промышленное сердце, Кузни Копписового леса"
	description = "Промышленное сердце Азурии, расположенное на северном склоне горы Декапитация. Сюда на мулах доставляют руду из Дафтсмарча для плавки и ковки. Хагенвальд производит почти каждый слиток железа, стали, меди и олова, используемый в королевстве — без его печей кузнецы Азурии были бы вынуждены работать с ломом. Богатство города построено на лесах, окружающих его с трех сторон: лес вырубают и восстанавливают поколениями, чтобы огонь в печах никогда не гас. Половина рабочих — выходцы из Гренцельхофта, привлеченные высокими заработками, а улицы здесь вечно серы от сажи. Корона держит здесь скрытый гарнизон."
	threat_region_id = THREAT_REGION_MOUNT_DECAP
	produces = list(
		TRADE_GOOD_IRON_INGOT = TG_SUPPLY_REFINED_INGOTS,
		TRADE_GOOD_STEEL_INGOT = TG_SUPPLY_REFINED_INGOTS,
		TRADE_GOOD_COPPER_INGOT = TG_SUPPLY_REFINED_INGOTS,
		TRADE_GOOD_TIN_INGOT = TG_SUPPLY_REFINED_INGOTS,
		TRADE_GOOD_COAL = TG_SUPPLY_IRON,
	)
	demands = list(
		TRADE_GOOD_IRON_ORE = TG_DEMAND_IRON,
		TRADE_GOOD_COPPER_ORE = TG_DEMAND_TIN_BRONZE,
		TRADE_GOOD_TIN_ORE = TG_DEMAND_TIN_BRONZE,
		TRADE_GOOD_WOOD = TG_DEMAND_CHEAP_RAW_MAT,
		TRADE_GOOD_GRAIN = TG_DEMAND_LOCAL_GRAIN,
		TRADE_GOOD_MEAT = TG_DEMAND_MEAT_BULK,
		TRADE_GOOD_SILK = TG_DEMAND_SILK,
	)

/// Builds the AZURIA'S REGIONS section of the Lore Primer from the economic_region datums,
/// so steward UI prose and primer prose stay in sync from a single source.
/proc/build_regions_primer_html()
	var/list/parts = list()
	parts += "<details>"
	parts += "<summary><strong><span style='font-size:130%'> РЕГИОНЫ АЗУРИИ </span></strong></summary>"
	parts += "<strong><span style='font-size:115%'> ВАССАЛЫ И ДОМЕНЫ </span></strong>"
	parts += "<br><br>"
	for(var/region_id in GLOB.economic_regions)
		var/datum/economic_region/region = GLOB.economic_regions[region_id]
		if(!region)
			continue
		parts += "<details>"
		parts += "<summary><strong> [uppertext(region.name)] </strong></summary>"
		parts += "<br>"
		if(region.subtitle)
			parts += "<em>[region.subtitle]</em>"
			parts += "<br><br>"
		parts += region.description
		parts += "<br>"
		parts += "</details>"
	parts += "<br><br>"
	parts += "</details>"
	return jointext(parts, "\n")
