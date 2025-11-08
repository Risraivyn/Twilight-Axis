#define TRAIT_CLERGY "Decem Dii Vult"
#define TRAIT_FIREARMS_MARKSMAN "Expert Gunslinger" // They keep saying firearms are too easy to level up. Unlocks Master and Legendary Firearms.

/datum/controller/subsystem/job/Initialize(timeofday)
	GLOB.roguetraits += list(TRAIT_CLERGY = span_notice("I am a member of local clergy, sworn to defend the House of the Ten. My oath empowers me when within the Temple's walls, or near my spiritual guide, the Bishop."),)
	GLOB.roguetraits += list(TRAIT_FIREARMS_MARKSMAN = span_greentext("I'm an experienced gunslinger, and have spent many years learning to shoot firearms accurately over great distances. Firearms can progress to Legendary levels."),)
	. = ..()
