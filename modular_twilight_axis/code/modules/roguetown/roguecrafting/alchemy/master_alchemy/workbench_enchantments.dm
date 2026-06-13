/datum/magic_item/workbench
	name = "Уникальные чары верстака"
	description = "Описание эффекта."
	glow_color = "#e0aaff"
	
	var/cost = 100
	var/tier = 1
	var/icon_name = "magic"
	var/suffix = ""
	var/compatible_type = /obj/item
	abstract_type = /datum/magic_item/workbench

/datum/magic_item/workbench/leather_pads
	name = "Hardened Plates"
	description = "Навешивает укрепленные кожаные пластины, давая одежде легкую броню."
	glow_color = "#8b5a2b"
	cost = 150
	tier = 2
	icon_name = "shield"
	suffix = " of Hardened Plates"
	compatible_type = /obj/item/clothing

/datum/magic_item/workbench/leather_pads/on_apply(obj/item/clothing/C)
	. = ..()
	if(!istype(C))
		return

	C.armor = getArmor(arglist(ARMOR_LEATHER))
	C.max_integrity = ARMOR_INT_SIDE_HARDLEATHER
	C.obj_integrity = ARMOR_INT_SIDE_HARDLEATHER
	C.material_category = ARMOR_MAT_LEATHER
	C.armor_class = ARMOR_CLASS_LIGHT


/datum/magic_item/workbench/enchanted_maille
	name = "Weoven Maille"
	description = "Вплетает стальные кольца прямо в ткань, давая одежде среднюю броню."
	glow_color = "#708090"
	cost = 250
	tier = 3
	icon_name = "shield-halved"
	suffix = " of Weoven Maille"
	compatible_type = /obj/item/clothing

/datum/magic_item/workbench/enchanted_maille/on_apply(obj/item/clothing/C)
	. = ..()
	if(!istype(C))
		return

	C.armor = getArmor(arglist(ARMOR_MAILLE))

	C.max_integrity = ARMOR_INT_LEG_STEEL_CHAIN
	C.obj_integrity = ARMOR_INT_LEG_STEEL_CHAIN

	C.material_category = ARMOR_MAT_CHAINMAIL
	C.armor_class = ARMOR_CLASS_MEDIUM

/datum/magic_item/workbench/saddleborn_blessing
	name = "Saddleborn Blessing"
	description = "Наполняет украшение духом вольных степей, позволяя владельцу призвать верного скакуна (Saddleborn)."
	glow_color = "#c9b037"
	cost = 350
	tier = 4
	icon_name = "horse"
	suffix = " of Saddleborn"
	compatible_type = /obj/item/clothing/ring
	var/active_item = FALSE

/datum/magic_item/workbench/saddleborn_blessing/on_equip(obj/item/i, mob/living/user, slot)
	..()
	if(slot == ITEM_SLOT_HANDS)
		return
	if(!ishuman(user))
		return
	if(active_item)
		return
	active_item = TRUE

	var/mob/living/carbon/human/H = user
	ADD_TRAIT(H, TRAIT_EQUESTRIAN, "[type]")
	H.adjust_skillrank(/datum/skill/misc/riding, 1, TRUE)
	
	if(!H.saddleborn_mount)
		if(!H.HasSpell(/obj/effect/proc_holder/spell/self/choose_riding_virtue_mount))
			H.AddSpell(new /obj/effect/proc_holder/spell/self/choose_riding_virtue_mount)
	else
		H.AddSpell(new /obj/effect/proc_holder/spell/self/saddleborn/sendaway)
		H.AddSpell(new /obj/effect/proc_holder/spell/self/saddleborn/whistle)

	to_chat(H, span_notice("Надев [i], вы чувствуете непреодолимую тягу к верховой езде и далеким странствиям!"))

/datum/magic_item/workbench/saddleborn_blessing/on_drop(obj/item/i, mob/living/user)
	..()
	if(!ishuman(user))
		return
	if(active_item)
		active_item = FALSE
		
		var/mob/living/carbon/human/H = user
		REMOVE_TRAIT(H, TRAIT_EQUESTRIAN, "[type]")
		H.adjust_skillrank(/datum/skill/misc/riding, -1, TRUE)
		
		H.RemoveSpell(/obj/effect/proc_holder/spell/self/choose_riding_virtue_mount)
		H.RemoveSpell(/obj/effect/proc_holder/spell/self/saddleborn/sendaway)
		H.RemoveSpell(/obj/effect/proc_holder/spell/self/saddleborn/whistle)
		to_chat(H, span_notice("Связь с вашим скакуном ослабевает, когда вы снимаете [i]."))

/datum/magic_item/workbench/sleuth_insight
	name = "Sleuth's Insight"
	description = "Временно наделяет владельца чутьем и хваткой первоклассного сыщика."
	glow_color = "#4a5d6e"
	cost = 200
	tier = 3
	icon_name = "binoculars"
	suffix = " of the Sleuth"
	compatible_type = /obj/item/clothing
	var/active_item = FALSE

/datum/magic_item/workbench/sleuth_insight/on_equip(obj/item/i, mob/living/user, slot)
	..()
	if(slot == ITEM_SLOT_HANDS)
		return
	if(!ishuman(user))
		return
	if(active_item)
		return
	active_item = TRUE
	var/mob/living/carbon/human/H = user
	ADD_TRAIT(H, TRAIT_SLEUTH, "[type]")
	H.adjust_skillrank(/datum/skill/misc/tracking, 2, TRUE)
	to_chat(H, span_notice("Надев [i], вы начинаете подмечать малейшие детали окружения, скрытые от глаз обывателей."))

/datum/magic_item/workbench/sleuth_insight/on_drop(obj/item/i, mob/living/user)
	..()
	if(!ishuman(user))
		return
	if(active_item)
		active_item = FALSE
		var/mob/living/carbon/human/H = user
		REMOVE_TRAIT(H, TRAIT_SLEUTH, "[type]")
		H.adjust_skillrank(/datum/skill/misc/tracking, -2, TRUE)
		to_chat(H, span_notice("Ваше обостренное внимание к деталям ослабевает."))
