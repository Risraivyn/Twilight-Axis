#ifndef subtypesof
#define subtypesof(typepath) (typesof(typepath) - typepath)
#endif

GLOBAL_LIST_INIT(dream_events, init_dream_events())

/proc/init_dream_events()
	var/list/L = list()
	for(var/path in subtypesof(/datum/dream_event))
		L[path] = new path()
	return L

/datum/dream_event
	var/name = "Базовое событие"
	var/is_positive = TRUE

/datum/dream_event/proc/can_trigger(mob/living/carbon/human/H)
	return TRUE

/datum/dream_event/proc/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	return

/datum/dream_event/proc/on_wake(mob/living/carbon/human/H, datum/sleep_adv/SA)
	return


//          ПОЛОЖИТЕЛЬНЫЕ СОБЫТИЯ

/datum/dream_event/positive/bogwalker
	name = "Дар Трясины"
	is_positive = TRUE

/datum/dream_event/positive/bogwalker/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_BOGWALKER)

/datum/dream_event/positive/bogwalker/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_BOGWALKER, TRAIT_GENERIC)
	to_chat(H, span_nicegreen("Шепот трясины наполняет мою голову. Болото признало меня своим..."))

/datum/dream_event/positive/leaper
	name = "Сновидение о полете"
	is_positive = TRUE

/datum/dream_event/positive/leaper/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_LEAPER)

/datum/dream_event/positive/leaper/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_LEAPER, TRAIT_GENERIC)
	to_chat(H, span_nicegreen("Мне снилось, что я лечу над верхушками деревьев. Мои ноги полны небывалой легкости!"))


/datum/dream_event/positive/webwalker
	name = "Нити Ткача"
	is_positive = TRUE

/datum/dream_event/positive/webwalker/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_WEBWALK)

/datum/dream_event/positive/webwalker/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_WEBWALK, TRAIT_GENERIC)
	to_chat(H, span_nicegreen("Я вижу во сне тончайшие шелковые нити и ступаю по ним, не застревая."))

/datum/dream_event/positive/cure_addiction
	name = "Отрезвление разума"
	is_positive = TRUE

/datum/dream_event/positive/cure_addiction/can_trigger(mob/living/carbon/human/H)
	for(var/datum/charflaw/addiction/A in H.charflaws)
		return TRUE
	return FALSE

/datum/dream_event/positive/cure_addiction/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	var/list/active_vices = list()
	for(var/datum/charflaw/addiction/A in H.charflaws)
		active_vices += A
		
	if(length(active_vices))
		var/datum/charflaw/addiction/chosen_vice = pick(active_vices)
		to_chat(H, span_nicegreen("Я вижу яркую вспышку чистого разума. Моя тяга к пороку <b>[chosen_vice.name]</b> безвозвратно угасает!"))
		H.charflaws.Remove(chosen_vice)
		qdel(chosen_vice)

/datum/dream_event/positive/dead_nose
	name = "Мертвый нос"
	is_positive = TRUE

/datum/dream_event/positive/dead_nose/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_NOSTINK)

/datum/dream_event/positive/dead_nose/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_NOSTINK, TRAIT_GENERIC)
	to_chat(H, span_nicegreen("Мне снится удушливое облако тлена, но я больше не чувствую его вони. Мой нос онемел."))

/datum/dream_event/positive/cautious_fisher
	name = "Осторожный рыбак"
	is_positive = TRUE

/datum/dream_event/positive/cautious_fisher/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_CAUTIOUS_FISHER)

/datum/dream_event/positive/cautious_fisher/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_CAUTIOUS_FISHER, TRAIT_GENERIC)
	to_chat(H, span_nicegreen("Я вижу во сне тихую речную гладь. Теперь я знаю, как не тревожить тех, кто обитает на самом дне..."))

/datum/dream_event/positive/seed_know
	name = "Познание семян"
	is_positive = TRUE

/datum/dream_event/positive/seed_know/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_SEEDKNOW)

/datum/dream_event/positive/seed_know/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_SEEDKNOW, TRAIT_GENERIC)
	to_chat(H, span_nicegreen("Мне снятся бескрайние золотые поля. Сквозь землю я вижу и понимаю суть каждого семени."))

/datum/dream_event/positive/royal_servant
	name = "Придворная проницательность"
	is_positive = TRUE

/datum/dream_event/positive/royal_servant/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_ROYALSERVANT)

/datum/dream_event/positive/royal_servant/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_ROYALSERVANT, TRAIT_GENERIC)
	to_chat(H, span_nicegreen("Мне снится роскошный пир в замке. Я отчетливо запоминаю капризные вкусы и предпочтения господ."))

/datum/dream_event/positive/good_writer
	name = "Писательский талант"
	is_positive = TRUE

/datum/dream_event/positive/good_writer/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_GOODWRITER)

/datum/dream_event/positive/good_writer/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_GOODWRITER, TRAIT_GENERIC)
	to_chat(H, span_nicegreen("Я вижу во сне стройные ряды древних манускриптов. Моя рука теперь выводит чернила с поразительным изяществом."))

/datum/dream_event/positive/grave_robber
	name = "Расхититель могил"
	is_positive = TRUE

/datum/dream_event/positive/grave_robber/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_GRAVEROBBER)

/datum/dream_event/positive/grave_robber/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_GRAVEROBBER, TRAIT_GENERIC)
	to_chat(H, span_nicegreen("Холод могильных плит больше не страшит меня. Мой разум защищен от проклятий за осквернение покоя усопших."))

/datum/dream_event/positive/cave_dweller
	name = "Дитя гор"
	is_positive = TRUE

/datum/dream_event/positive/cave_dweller/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_CAVEDWELLER)

/datum/dream_event/positive/cave_dweller/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_CAVEDWELLER, TRAIT_GENERIC)
	to_chat(H, span_nicegreen("Бескрайняя тьма подземелий кажется мне родным домом. Мой разум спокоен, когда я нахожусь под землей."))

/datum/dream_event/positive/sharper_blades
	name = "Уход за лезвием"
	is_positive = TRUE

/datum/dream_event/positive/sharper_blades/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_SHARPER_BLADES)

/datum/dream_event/positive/sharper_blades/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_SHARPER_BLADES, TRAIT_GENERIC)
	to_chat(H, span_nicegreen("Я отчетливо вижу углы заточки стали во сне. Теперь мое холодное оружие будет держать лезвие гораздо дольше."))

/datum/dream_event/positive/tooth_fairy
	name = "Визит Зубной Феи"
	is_positive = TRUE

/datum/dream_event/positive/tooth_fairy/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	to_chat(H, span_nicegreen("Мне снится звон золотых монет и крошечные, мерцающие в темноте крылышки..."))

/datum/dream_event/positive/tooth_fairy/on_wake(mob/living/carbon/human/H, datum/sleep_adv/SA)
	var/turf/T = get_turf(H)
	if(T)
		var/obj/item/roguecoin/gold/pile/G = new(T)
		if(G)
			G.name = "Подарок Зубной Феи"
			G.desc = "Волшебная стопка монеток, странно зубы все на месте..."
			to_chat(H, span_nicegreen("Я открываю глаза и обнаруживаю под своей подушкой подарок! Неужели Зубная фея действительно существует?.."))

/datum/dream_event/positive/loot_cheap
	name = "Простая находка"
	is_positive = TRUE

/datum/dream_event/positive/loot_cheap/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	to_chat(H, span_nicegreen("Мне снится блеск старой бронзы и простых, но милых сердцу украшений..."))

/datum/dream_event/positive/loot_cheap/on_wake(mob/living/carbon/human/H, datum/sleep_adv/SA)
	var/turf/T = get_turf(H)
	if(T)
		var/spawner_path = pick(list(
			/obj/effect/spawner/lootdrop/cheap_clutter_spawner,
			/obj/effect/spawner/lootdrop/cheap_candle_spawner,
			/obj/effect/spawner/lootdrop/cheap_tableware_spawner,
			/obj/effect/spawner/lootdrop/cheap_jewelry_spawner
		))
		
		new spawner_path(T)
		to_chat(H, span_nicegreen("Я открываю глаза и замечаю, что на краю моей постели лежит какая-то вещица... Кажется, я захватил ее из сна."))

/datum/dream_event/positive/loot_valuable
	name = "Благородный дар"
	is_positive = TRUE

/datum/dream_event/positive/loot_valuable/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	to_chat(H, span_nicegreen("Мне снится сияние Нок она любит меня..."))

/datum/dream_event/positive/loot_valuable/on_wake(mob/living/carbon/human/H, datum/sleep_adv/SA)
	var/turf/T = get_turf(H)
	if(T)
		var/spawner_path = pick(list(
			/obj/effect/spawner/lootdrop/valuable_clutter_spawner,
			/obj/effect/spawner/lootdrop/valuable_candle_spawner,
			/obj/effect/spawner/lootdrop/valuable_tableware_spawner,
			/obj/effect/spawner/lootdrop/valuable_jewelry_spawner,
			/obj/effect/spawner/lootdrop/puzzlebox_rings
		))
		
		new spawner_path(T)
		
		to_chat(H, span_nicegreen("Я открываю глаза и вижу, что рядом лежит прекрасный дар сновидений... Какая чудесная находка!"))
		playsound(T, 'sound/magic/ahh2.ogg', 80, FALSE)


//          ОТРИЦАТЕЛЬНЫЕ СОБЫТИЯ

/datum/dream_event/negative/wake_pig
	name = "Трюфельная свинья под боком"
	is_positive = FALSE

/datum/dream_event/negative/wake_pig/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	to_chat(H, span_warning("Сквозь туман дремоты я слышу настойчивое хрюканье и сопение..."))

/datum/dream_event/negative/wake_pig/on_wake(mob/living/carbon/human/H, datum/sleep_adv/SA)
	var/turf/T = get_turf(H)
	if(T)
		var/mob/living/simple_animal/hostile/retaliate/rogue/trufflepig/P = new(T)
		if(P)
			P.name = "Сонная свинья"
			to_chat(H, span_warning("Я открываю глаза и обнаруживаю, что делю постель с... трюфельной свиньей?! Хрю!"))
			playsound(T, pick('modular/Creechers/sound/pig1.ogg', 'modular/Creechers/sound/pig2.ogg'), 100, TRUE, -1)

/datum/dream_event/negative/loose_straps
	name = "Сон о распадающихся ремнях"
	is_positive = FALSE

/datum/dream_event/negative/loose_straps/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_ARMOR_BREAK)

/datum/dream_event/negative/loose_straps/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_ARMOR_BREAK, TRAIT_GENERIC)
	to_chat(H, span_boldred("Мне снится кошмар, в котором доспехи душат меня, а их пряжки со звоном лопаются..."))

/datum/dream_event/negative/vice_alcoholic
	name = "Тяга к бутылке"
	is_positive = FALSE

/datum/dream_event/negative/vice_alcoholic/can_trigger(mob/living/carbon/human/H)
	return !H.has_flaw(/datum/charflaw/addiction/alcoholic)

/datum/dream_event/negative/vice_alcoholic/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	var/datum/charflaw/added_flaw = new /datum/charflaw/addiction/alcoholic()
	H.charflaws.Add(added_flaw)
	added_flaw.on_mob_creation(H)
	to_chat(H, span_boldred("Сухость во рту преследует меня во сне. Я просыпаюсь с непреодолимым желанием сделать глоток алкоголя..."))

/datum/dream_event/negative/vice_smoker
	name = "Тяга к табаку"
	is_positive = FALSE

/datum/dream_event/negative/vice_smoker/can_trigger(mob/living/carbon/human/H)
	return !H.has_flaw(/datum/charflaw/addiction/smoker)

/datum/dream_event/negative/vice_smoker/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	var/datum/charflaw/added_flaw = new /datum/charflaw/addiction/smoker()
	H.charflaws.Add(added_flaw)
	added_flaw.on_mob_creation(H)
	to_chat(H, span_boldred("Мои легкие во сне наполняются серым удушливым дымом. Я жажду хорошей затяжки..."))

/datum/dream_event/negative/vice_sadist
	name = "Тяга к чужой боли"
	is_positive = FALSE

/datum/dream_event/negative/vice_sadist/can_trigger(mob/living/carbon/human/H)
	return !H.has_flaw(/datum/charflaw/addiction/sadist)

/datum/dream_event/negative/vice_sadist/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	var/datum/charflaw/added_flaw = new /datum/charflaw/addiction/sadist()
	H.charflaws.Add(added_flaw)
	added_flaw.on_mob_creation(H)
	to_chat(H, span_boldred("Мне снятся предсмертные хрипы и муки моих врагов... Я чувствую, что только страдания других вернут мне покой."))

/datum/dream_event/negative/jesterphobia
	name = "Шутофобия"
	is_positive = FALSE

/datum/dream_event/negative/jesterphobia/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_JESTERPHOBIA)

/datum/dream_event/negative/jesterphobia/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_JESTERPHOBIA, TRAIT_GENERIC)
	to_chat(H, span_boldred("Жуткий оскал разрисованного лица и звон бубенцов преследуют меня во сне... Я безумно боюсь шутов."))

/datum/dream_event/negative/annoying_voice
	name = "Раздражающий голос"
	is_positive = FALSE

/datum/dream_event/negative/annoying_voice/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_COMICSANS)

/datum/dream_event/negative/annoying_voice/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_COMICSANS, TRAIT_GENERIC)
	to_chat(H, span_boldred("Я пытаюсь закричать во сне, но вместо этого издаю нелепый, раздражающий писк. Мой голос изменился..."))

/datum/dream_event/negative/technophobe
	name = "Технофобия"
	is_positive = FALSE

/datum/dream_event/negative/technophobe/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_TECHNOPHOBE)

/datum/dream_event/negative/technophobe/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_TECHNOPHOBE, TRAIT_GENERIC)
	to_chat(H, span_boldred("Грохот шестеренок и холодный металл машин пугают меня во сне. Я презираю эти бездушные механизмы."))

/datum/dream_event/negative/limp_soldier
	name = "Половое бессилие"
	is_positive = FALSE

/datum/dream_event/negative/limp_soldier/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_LIMPDICK) && (H.gender == MALE)

/datum/dream_event/negative/limp_soldier/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_LIMPDICK, TRAIT_GENERIC)
	to_chat(H, span_boldred("Во сне я чувствую угасание мужской силы. Мой верный солдат отказывается вставать по тревоге..."))

/datum/dream_event/negative/colorblind
	name = "Потеря красок"
	is_positive = FALSE

/datum/dream_event/negative/colorblind/can_trigger(mob/living/carbon/human/H)
	return !H.has_flaw(/datum/charflaw/colorblind)

/datum/dream_event/negative/colorblind/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	var/datum/charflaw/added_flaw = new /datum/charflaw/colorblind()
	H.charflaws.Add(added_flaw)
	added_flaw.on_mob_creation(H)
	to_chat(H, span_boldred("Мир во сне стремительно тускнеет и теряет свои краски. Я просыпаюсь в мире, лишенном цвета..."))

/datum/dream_event/negative/clumsy
	name = "Неуклюжесть"
	is_positive = FALSE

/datum/dream_event/negative/clumsy/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_CLUMSY)

/datum/dream_event/negative/clumsy/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_CLUMSY, TRAIT_GENERIC)
	to_chat(H, span_boldred("Мои руки во сне не слушаются меня, а ноги заплетаются... Я просыпаюсь с ощущением жуткой неловкости."))

/datum/dream_event/negative/unseemly
	name = "Уродство лица"
	is_positive = FALSE

/datum/dream_event/negative/unseemly/can_trigger(mob/living/carbon/human/H)
	return !HAS_TRAIT(H, TRAIT_UNSEEMLY) && !HAS_TRAIT(H, TRAIT_BEAUTIFUL)

/datum/dream_event/negative/unseemly/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	ADD_TRAIT(H, TRAIT_UNSEEMLY, TRAIT_GENERIC)
	to_chat(H, span_boldred("Я смотрю во сне в зеркало и с криком отшатываюсь — моё лицо искажено уродством, вызывающим лишь отвращение у живых."))

/datum/dream_event/negative/ghost_visage
	name = "Ночной гость"
	is_positive = FALSE

/datum/dream_event/negative/ghost_visage/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	to_chat(H, span_boldred("Я чувствую, как сквозь сон чьи-то холодные невидимые пальцы тянутся к моему лицу..."))

/datum/dream_event/negative/ghost_visage/on_wake(mob/living/carbon/human/H, datum/sleep_adv/SA)
	var/turf/T = get_turf(H)
	if(T)
		to_chat(H, span_boldred("Я резко просыпаюсь от леденящего душу шепота у самого уха... Бледный призрачный силуэт зависает надо мной в воздухе и медленно растворяется в темноте!"))
		H.Dizzy(30)
		H.blur_eyes(6)
		H.add_stress(/datum/stressevent/terrible_dreams)

		playsound(T, 'sound/effects/ghost.ogg', 80, FALSE)

/datum/dream_event/negative/sleep_paralysis
	name = "Сонный паралич"
	is_positive = FALSE

/datum/dream_event/negative/sleep_paralysis/on_dream(mob/living/carbon/human/H, datum/sleep_adv/SA)
	to_chat(H, span_boldred("Тяжелая, холодная плита опускается на мою грудь. Я задыхаюсь..."))

/datum/dream_event/negative/sleep_paralysis/on_wake(mob/living/carbon/human/H, datum/sleep_adv/SA)
	var/turf/T = get_turf(H)
	to_chat(H, span_boldred("Я открываю глаза, но моё тело полностью сковано! Я не могу пошевелить даже пальцем... Из темного угла комнаты на меня пристально смотрят два тлеющих красных глаза. Через несколько секунд паралич отступает, а глаза растворяются в полумраке."))
	
	H.Immobilize(50)
	H.add_stress(/datum/stressevent/terrible_dreams)
	H.blur_eyes(5)
	playsound(T, 'sound/effects/ghost.ogg', 60, FALSE)
