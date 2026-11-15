GLOBAL_LIST_EMPTY(shadow_domain_centers)

/obj/effect/shadow_domain_center
	name = "shadow domain center"
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "x"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/in_use = FALSE

/obj/effect/shadow_domain_center/Initialize(mapload)
	. = ..()
	GLOB.shadow_domain_centers += src

/obj/effect/shadow_domain_center/Destroy()
	GLOB.shadow_domain_centers -= src
	return ..()


/datum/action/cooldown/spell/shadow_domain
	name = "Shadow Domain"
	desc = "Замирает на месте и разворачивает вокруг себя область тьмы радиусом 5, \
	оставляя за собой сгусток тьмы и перенося всех внутри в карманное измерение."
	button_icon = 'icons/mob/actions/roguespells.dmi'
	button_icon_state = "shieldsparkles"
	sound = 'sound/magic/whiteflame.ogg'
	spell_color = "#6a0dad"
	glow_intensity = GLOW_INTENSITY_HIGH

	click_to_activate = FALSE
	self_cast_possible = TRUE

	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = 40
	secondary_resource_type = SPELL_COST_ENERGY
	secondary_resource_cost = 200

	invocations = list("Tenebris Regnum!")
	invocation_type = INVOCATION_SHOUT

	charge_required = FALSE
	cooldown_time = 60 SECONDS

	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC | SPELL_REQUIRES_HUMAN

	var/domain_radius = 5
	var/domain_duration = 20 SECONDS

/datum/action/cooldown/spell/shadow_domain/cast(atom/cast_on)
	. = ..()
	var/mob/living/caster = owner
	if(!istype(caster))
		return FALSE

	var/turf/center = get_turf(caster)
	if(!center)
		return FALSE

	new /datum/shadow_domain(center, caster, domain_radius, domain_duration)
	return TRUE


/datum/shadow_domain
	var/turf/center
	var/datum/weakref/caster_ref
	var/radius = 5
	var/duration = 20 SECONDS

	var/obj/effect/shadow_domain_center/arena_marker
	var/turf/pocket_center
	var/obj/structure/domain_core/core_wall

	var/list/viewer_clients = list()
	var/image/circle_image
	var/list/tracked_mobs = list()
	var/list/domain_hazards = list()
	var/hazards_active = FALSE


/datum/shadow_domain/proc/cleanup_client_images()
	if(!circle_image)
		return
	for(var/client/C in viewer_clients)
		if(C)
			C.images -= circle_image
	circle_image = null

/datum/shadow_domain/proc/cleanup_hazards()
	hazards_active = FALSE
	for(var/obj/O in domain_hazards)
		if(!QDELETED(O))
			qdel(O)
	domain_hazards.Cut()

/datum/shadow_domain/New(turf/_center, mob/living/_caster, _radius = 5, _duration = 20 SECONDS)
	center = _center
	caster_ref = WEAKREF(_caster)
	radius = _radius
	duration = _duration
	INVOKE_ASYNC(src, PROC_REF(run_sequence))

/datum/shadow_domain/Destroy()
	cleanup_client_images()
	cleanup_hazards()
	if(arena_marker)
		arena_marker.in_use = FALSE
		arena_marker = null
	if(!QDELETED(core_wall))
		qdel(core_wall)
	center = null
	pocket_center = null
	viewer_clients.Cut()
	tracked_mobs.Cut()
	return ..()

/datum/shadow_domain/proc/find_free_arena()
	for(var/obj/effect/shadow_domain_center/M in GLOB.shadow_domain_centers)
		if(!QDELETED(M) && !M.in_use)
			return M
	return null

/datum/shadow_domain/proc/run_sequence()
	set waitfor = FALSE

	var/mob/living/caster = caster_ref?.resolve()
	if(!center || QDELETED(caster))
		qdel(src)
		return

	for(var/mob/M in viewers(radius + 7, center))
		if(M.client)
			viewer_clients += M.client

	var/expand_time = 1.6 SECONDS
	var/pre_teleport_pause = 0.6 SECONDS
	var/total_freeze = expand_time + pre_teleport_pause + 0.3 SECONDS

	caster.Immobilize(total_freeze, ignore_canstun = TRUE)
	caster.tempfixeye = TRUE
	caster.nodirchange = TRUE

	circle_image = image('icons/effects/96x96.dmi', center, "void_blink_in", ABOVE_NORMAL_TURF_LAYER)
	circle_image.alpha = 0
	circle_image.pixel_x = -32
	circle_image.pixel_y = -32

	var/matrix/start_M = matrix()
	start_M.Scale(0.33)
	circle_image.transform = start_M

	for(var/client/C in viewer_clients)
		if(C)
			C.images += circle_image

	var/matrix/end_M = matrix()
	end_M.Scale((radius * 2 + 1) * 32 / 96)
	animate(circle_image, alpha = 235, transform = end_M, time = expand_time, easing = SINE_EASING | EASE_OUT)

	sleep(expand_time + pre_teleport_pause)

	if(!QDELETED(caster))
		caster.SetImmobilized(0, ignore_canstun = TRUE)
		caster.tempfixeye = FALSE
		caster.nodirchange = FALSE

	arena_marker = find_free_arena()
	if(!arena_marker)
		if(!QDELETED(caster))
			to_chat(caster, span_warning("Не найден свободный маркер /obj/effect/shadow_domain_center!"))
		collapse_into_core()
		addtimer(CALLBACK(src, PROC_REF(eject_and_close)), duration)
		return

	arena_marker.in_use = TRUE
	pocket_center = get_turf(arena_marker)

	for(var/mob/living/M in range(radius, center))
		if(cheap_hypotenuse(M.x, M.y, center.x, center.y) > radius)
			continue

		var/dx = M.x - center.x
		var/dy = M.y - center.y
		var/turf/dest_T = locate(pocket_center.x + dx, pocket_center.y + dy, pocket_center.z)
		if(!dest_T || dest_T.density)
			dest_T = pocket_center

		tracked_mobs += WEAKREF(M)
		M.forceMove(dest_T)
		animate_teleport_in(M)

	spawn_domain_hazards(caster)
	collapse_into_core()
	addtimer(CALLBACK(src, PROC_REF(eject_and_close)), duration)

/datum/shadow_domain/proc/animate_teleport_in(mob/living/M)
	var/old_alpha = M.alpha
	M.alpha = 0
	animate(M, alpha = old_alpha, time = 0.3 SECONDS, easing = SINE_EASING | EASE_OUT)

/datum/shadow_domain/proc/collapse_into_core()
	set waitfor = FALSE

	core_wall = new /obj/structure/domain_core(center)

	if(circle_image)
		var/matrix/shrink = matrix()
		shrink.Scale(0.1)
		animate(circle_image, alpha = 0, transform = shrink, time = 0.35 SECONDS, easing = SINE_EASING | EASE_IN)
		sleep(0.4 SECONDS)
		cleanup_client_images()

/datum/shadow_domain/proc/eject_and_close()
	if(!QDELETED(core_wall))
		core_wall.density = FALSE

	var/list/exit_turfs = list()
	for(var/turf/T in orange(1, center))
		if(!T.density)
			exit_turfs += T
	if(!length(exit_turfs))
		exit_turfs += center

	for(var/datum/weakref/W as anything in tracked_mobs)
		var/mob/living/M = W.resolve()
		if(QDELETED(M))
			continue

		var/turf/exit_T = pick(exit_turfs)
		var/dx = (center.x - exit_T.x) * 32
		var/dy = (center.y - exit_T.y) * 32
		M.forceMove(exit_T)
		M.pixel_x += dx
		M.pixel_y += dy
		M.alpha = 0
		animate(M, pixel_x = 0, pixel_y = 0, alpha = 255, time = 0.3 SECONDS, easing = SINE_EASING | EASE_OUT)

	if(arena_marker)
		arena_marker.in_use = FALSE
		arena_marker = null

	if(!QDELETED(core_wall))
		core_wall.fade_out()
		core_wall = null
	cleanup_hazards()
	QDEL_IN(src, 0.5 SECONDS)


/obj/structure/domain_core
	name = "shadow monolith"
	desc = "Сгусток тьмы, скрывающий карманное измерение."
	icon = 'icons/turf/roguewall.dmi'
	icon_state = "blocker"
	color = "#08000f"
	density = TRUE
	opacity = TRUE
	anchored = TRUE

/obj/structure/domain_core/Initialize(mapload)
	. = ..()
	alpha = 0
	var/matrix/M = matrix()
	M.Scale(1.6)
	transform = M
	animate(src, alpha = 255, transform = matrix(), time = 0.3 SECONDS, easing = SINE_EASING | EASE_OUT)

/obj/structure/domain_core/proc/fade_out()
	density = FALSE
	opacity = FALSE
	var/matrix/M = matrix()
	M.Scale(0.1)
	animate(src, alpha = 0, transform = M, time = 0.35 SECONDS, easing = SINE_EASING | EASE_IN)
	QDEL_IN(src, 0.4 SECONDS)

/datum/shadow_domain/proc/spawn_domain_hazards(mob/living/caster)
	if(!pocket_center)
		return
	hazards_active = TRUE

	var/list/free_turfs = list()
	for(var/turf/T in orange(radius - 1, pocket_center))
		if(!T.density)
			free_turfs += T

	var/crystal_count = min(3, length(free_turfs))
	for(var/i in 1 to crystal_count)
		var/turf/CT = pick_n_take(free_turfs)
		var/obj/structure/domain_crystal/C = new(CT, caster)
		domain_hazards += C

	INVOKE_ASYNC(src, PROC_REF(lava_hazard_loop), caster)

/datum/shadow_domain/proc/lava_hazard_loop(mob/living/caster)
	set waitfor = FALSE
	while(hazards_active && !QDELETED(src) && pocket_center)
		sleep(3.5 SECONDS)
		if(!hazards_active || QDELETED(src))
			break

		var/list/targets = list()
		for(var/datum/weakref/W as anything in tracked_mobs)
			var/mob/living/M = W.resolve()
			if(!QDELETED(M) && M != caster && M.stat != DEAD && get_dist(M, pocket_center) <= radius)
				targets += get_turf(M)

		var/list/arena_turfs = list()
		for(var/turf/T in range(radius - 1, pocket_center))
			if(!T.density)
				arena_turfs += T

		while(length(targets) < 4 && length(arena_turfs))
			targets |= pick_n_take(arena_turfs)

		for(var/turf/LT in targets)
			var/obj/effect/domain_lava/L = new(LT, caster)
			domain_hazards += L

/obj/structure/domain_crystal
	name = "abyssal crystal"
	desc = "Пульсирующий кристалл бездны. Нацеливается на чужаков."
	icon = 'icons/turf/roguewall.dmi'
	icon_state = "stonehole"
	color = "#9932cc"
	density = TRUE
	anchored = TRUE
	light_outer_range = 3
	light_color = "#9932cc"

	var/datum/weakref/caster_ref
	var/fire_cooldown = 2.5 SECONDS
	var/next_fire = 0

/obj/structure/domain_crystal/Initialize(mapload, mob/living/new_caster)
	. = ..()
	if(new_caster)
		caster_ref = WEAKREF(new_caster)

	alpha = 0
	pixel_y = -16
	var/matrix/M = matrix()
	M.Scale(0.2, 0.2)
	transform = M

	animate(src, alpha = 255, pixel_y = 0, transform = matrix(), time = 0.4 SECONDS, easing = SINE_EASING | EASE_OUT)
	addtimer(CALLBACK(src, PROC_REF(start_hovering)), 0.45 SECONDS)

	next_fire = world.time + 1.5 SECONDS
	START_PROCESSING(SSobj, src)

/obj/structure/domain_crystal/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/domain_crystal/proc/start_hovering()
	if(QDELETED(src))
		return
	animate(src, pixel_y = 5, time = 0.8 SECONDS, easing = SINE_EASING, loop = -1)
	animate(pixel_y = 0, time = 0.8 SECONDS, easing = SINE_EASING)

/obj/structure/domain_crystal/process()
	if(world.time < next_fire)
		return
	next_fire = world.time + fire_cooldown

	var/mob/living/caster = caster_ref?.resolve()
	var/mob/living/best_target
	var/best_dist = INFINITY

	for(var/mob/living/M in view(7, src))
		if(M == caster || M.stat == DEAD)
			continue
		var/d = get_dist(src, M)
		if(d < best_dist)
			best_dist = d
			best_target = M

	if(best_target)
		shoot_at(best_target, caster)

/obj/structure/domain_crystal/proc/shoot_at(mob/living/target, mob/living/caster)
	var/matrix/pulse = matrix()
	pulse.Scale(1.3)
	animate(src, transform = pulse, time = 0.1 SECONDS, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
	animate(transform = matrix(), time = 0.2 SECONDS, easing = SINE_EASING | EASE_IN)

	playsound(src, 'sound/magic/whiteflame.ogg', 50, TRUE)

	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return

	var/obj/effect/domain_bolt/B = new(get_turf(src))
	var/dx = (target_turf.x - x) * 32
	var/dy = (target_turf.y - y) * 32
	animate(B, pixel_x = dx, pixel_y = dy, time = 0.25 SECONDS, easing = LINEAR_EASING)
	QDEL_IN(B, 0.3 SECONDS)

	addtimer(CALLBACK(src, PROC_REF(impact_tile), target_turf, caster), 0.25 SECONDS)

/obj/structure/domain_crystal/proc/impact_tile(turf/T, mob/living/caster)
	if(!T)
		return
	for(var/mob/living/L in T)
		if(L == caster || L.stat == DEAD)
			continue
		if(istype(caster) && !QDELETED(caster))
			arcyne_strike(caster, L, null, 18, BODY_ZONE_CHEST, BCLASS_BURN, spell_name = "Abyssal Crystal", damage_type = BURN, skip_animation = TRUE, exact_zone = TRUE, SPELL_STRIKE_SCALING)
		else
			L.apply_damage(18, BURN, BODY_ZONE_CHEST)

/obj/effect/domain_bolt
	name = "abyssal bolt"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "void_blink_in"
	color = "#c040ff"
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/domain_bolt/Initialize(mapload)
	. = ..()
	var/matrix/M = matrix()
	M.Scale(0.25)
	transform = M
	pixel_x = -32
	pixel_y = -32

/obj/effect/domain_lava
	name = "unstable void"
	icon = 'icons/effects/fire.dmi'
	icon_state = "3"
	color = "#8a2be2"
	layer = ABOVE_NORMAL_TURF_LAYER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

	var/datum/weakref/caster_ref
	var/active = FALSE
	var/next_burn = 0

/obj/effect/domain_lava/Initialize(mapload, mob/living/new_caster)
	. = ..()
	if(new_caster)
		caster_ref = WEAKREF(new_caster)

	alpha = 80
	var/matrix/M = matrix()
	M.Scale(0.6)
	transform = M
	animate(src, alpha = 150, transform = matrix(), time = 0.4 SECONDS, loop = 3)

	addtimer(CALLBACK(src, PROC_REF(erupt)), 1.2 SECONDS)
	QDEL_IN(src, 4.5 SECONDS)

/obj/effect/domain_lava/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/domain_lava/proc/erupt()
	if(QDELETED(src))
		return
	active = TRUE
	animate(src)
	alpha = 230
	color = "#4b0082"
	set_light(2, 2, "#8a2be2")
	START_PROCESSING(SSobj, src)
	burn_turf()

/obj/effect/domain_lava/process()
	if(!active || world.time < next_burn)
		return
	next_burn = world.time + 0.8 SECONDS
	burn_turf()

/obj/effect/domain_lava/proc/burn_turf()
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/mob/living/caster = caster_ref?.resolve()
	for(var/mob/living/L in T)
		if(L == caster || L.stat == DEAD)
			continue
		if(istype(caster) && !QDELETED(caster))
			arcyne_strike(caster, L, null, 12, BODY_ZONE_CHEST, BCLASS_BURN, spell_name = "Abyssal Lava", damage_type = BURN, skip_animation = TRUE, exact_zone = TRUE, SPELL_STRIKE_SCALING)
		else
			L.apply_damage(12, BURN, BODY_ZONE_CHEST)
