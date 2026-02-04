#define STAGE_EXPANSION 1
#define STAGE_CLEANUP 2

SUBSYSTEM_DEF(dungeon_generator)
	name = "Dungeon Generator"
	init_order = INIT_ORDER_DUNGEON
	runlevels = RUNLEVEL_GAME | RUNLEVEL_INIT | RUNLEVEL_LOBBY
	wait = 1 SECONDS

	var/list/parent_types = list()
	var/list/templates_by_category = list() 
	var/list/markers = list() 
	var/list/failed_markers = list() 
	var/list/placed_count = list()

	var/generation_stage = STAGE_EXPANSION
	var/required_entries = 1 
	var/created_since_entry = 0
	var/unlinked_dungeon_length = 0

/datum/controller/subsystem/dungeon_generator/Initialize(start_timeofday)
	unlinked_dungeon_length = length(GLOB.unlinked_dungeon_entries)
	
	
	for(var/path in subtypesof(/datum/map_template/dungeon))
		var/datum/map_template/dungeon/path_type = path
		if(initial(path_type.abstract_type) == path) continue
		
		var/weight = initial(path_type.type_weight)
		if(weight)
			parent_types[path] = weight

		var/datum/map_template/dungeon/T = new path
		if(!T.mappath) continue

		
		if(!templates_by_category[/datum/map_template/dungeon])
			templates_by_category[/datum/map_template/dungeon] = list()
		templates_by_category[/datum/map_template/dungeon] += T

		if(istype(T, /datum/map_template/dungeon/room))
			if(!templates_by_category[/datum/map_template/dungeon/room])
				templates_by_category[/datum/map_template/dungeon/room] = list()
			templates_by_category[/datum/map_template/dungeon/room] += T

		if(istype(T, /datum/map_template/dungeon/hallway))
			if(!templates_by_category[/datum/map_template/dungeon/hallway])
				templates_by_category[/datum/map_template/dungeon/hallway] = list()
			templates_by_category[/datum/map_template/dungeon/hallway] += T

		if(istype(T, /datum/map_template/dungeon/entry))
			if(!templates_by_category[/datum/map_template/dungeon/entry])
				templates_by_category[/datum/map_template/dungeon/entry] = list()
			templates_by_category[/datum/map_template/dungeon/entry] += T

	
	var/entry_count = length(templates_by_category[/datum/map_template/dungeon/entry])
	world.log << "Dungeon Generator: Инициализация. Найдено входов: [entry_count]"

	
	addtimer(CALLBACK(src, .proc/spawn_initial_room), 5 SECONDS)
	return ..()

/datum/controller/subsystem/dungeon_generator/fire(resumed)
	if(generation_stage == STAGE_EXPANSION)
		if(length(markers))
			process_markers(15)
		else if(length(failed_markers))
			generation_stage = STAGE_CLEANUP
		return

	if(generation_stage == STAGE_CLEANUP)
		if(length(failed_markers))
			process_failed_markers(10)
		else
			generation_stage = STAGE_EXPANSION

/datum/controller/subsystem/dungeon_generator/proc/spawn_initial_room()
	var/target_z = 6
	var/turf/center = locate(world.maxx / 2, world.maxy / 2, target_z)
	if(!center) 
		world.log << "Dungeon Error: Не найден центр карты на Z [target_z]"
		return

	var/list/entries = templates_by_category[/datum/map_template/dungeon/entry]
	if(!length(entries)) 
		world.log << "Dungeon Error: Список ENTRY пуст!"
		return

	var/datum/map_template/dungeon/entry_tile = pick(entries)
	var/spawn_x = center.x - round(entry_tile.width / 2)
	var/spawn_y = center.y - round(entry_tile.height / 2)
	var/turf/start_turf = locate(spawn_x, spawn_y, target_z)
	
	if(start_turf && entry_tile.load(start_turf))
		world.log << "Dungeon Success: Вход [entry_tile.name] заспавнен!"
		on_template_placed(entry_tile)

/datum/controller/subsystem/dungeon_generator/proc/process_markers(limit)
	var/processed = 0
	while(length(markers) && processed < limit)
		var/obj/effect/dungeon_directional_helper/helper = markers[markers.len]
		markers.len--
		if(helper && !QDELETED(helper))
			var/turf/T = get_turf(helper)
			if(!find_soulmate(helper.dir, T, helper))
				failed_markers |= helper
		processed++

/datum/controller/subsystem/dungeon_generator/proc/process_failed_markers(limit)
	var/processed = 0
	while(length(failed_markers) && processed < limit)
		var/obj/effect/dungeon_directional_helper/helper = failed_markers[failed_markers.len]
		failed_markers.len--
		if(helper && !QDELETED(helper))
			var/turf/T = get_turf(helper)
			try_spawn_filler(helper.dir, T)
			qdel(helper)
		processed++

/datum/controller/subsystem/dungeon_generator/proc/find_soulmate(direction, turf/origin, obj/effect/dungeon_directional_helper/helper)
	var/turf/target_turf = get_step(origin, direction)
	if(!target_turf || !is_void(target_turf))
		return FALSE

	var/picked_category = pickweight(parent_types)
	
	if(try_spawn_template(picked_category, direction, target_turf) || try_spawn_template(/datum/map_template/dungeon, direction, target_turf))
		qdel(helper)
		return TRUE
	return FALSE

/datum/controller/subsystem/dungeon_generator/proc/try_spawn_template(category, direction, turf/target_turf)
	var/opp_dir = reverse_direction(direction)
	var/list/candidates = templates_by_category[category]
	if(!length(candidates)) return FALSE
	
	candidates = shuffle(candidates.Copy())
	var/entries_placed = placed_count[/datum/map_template/dungeon/entry] || 0

	for(var/datum/map_template/dungeon/T in candidates)
		var/offset = T.get_dir_offset(opp_dir)
		if(offset == null) continue
		if(entries_placed >= required_entries && istype(T, /datum/map_template/dungeon/entry)) continue

		var/spawn_x = target_turf.x
		var/spawn_y = target_turf.y
		if(direction == NORTH)
			spawn_x -= offset
		else if(direction == SOUTH)
			spawn_x -= offset
			spawn_y -= (T.height - 1)
		else if(direction == EAST)
			spawn_y -= offset
		else if(direction == WEST)
			spawn_x -= (T.width - 1)
			spawn_y -= offset

		if(spawn_x < 1 || spawn_y < 1 || (spawn_x + T.width - 1) > world.maxx || (spawn_y + T.height - 1) > world.maxy)
			continue

		var/turf/start_turf = locate(spawn_x, spawn_y, target_turf.z)
		if(can_place(T, start_turf))
			if(T.load(start_turf))
				on_template_placed(T)
				return TRUE
	return FALSE

/datum/controller/subsystem/dungeon_generator/proc/try_spawn_filler(direction, turf/target_turf)
	var/opp_dir = reverse_direction(direction)
	var/list/all_templates = templates_by_category[/datum/map_template/dungeon]
	for(var/datum/map_template/dungeon/T in shuffle(all_templates.Copy()))
		if(T.width > 7 || T.height > 7) continue 
		var/offset = T.get_dir_offset(opp_dir)
		if(offset == null) continue
		var/spawn_x = target_turf.x
		var/spawn_y = target_turf.y
		if(direction == NORTH)
			spawn_x -= offset
		else if(direction == SOUTH)
			spawn_x -= offset
			spawn_y -= (T.height - 1)
		else if(direction == EAST)
			spawn_y -= offset
		else if(direction == WEST)
			spawn_x -= (T.width - 1)
			spawn_y -= offset

		var/turf/start_turf = locate(spawn_x, spawn_y, target_turf.z)
		if(can_place(T, start_turf))
			if(T.load(start_turf))
				on_template_placed(T)
				return TRUE
	return FALSE

/datum/controller/subsystem/dungeon_generator/proc/can_place(datum/map_template/dungeon/T, turf/start_T)
	if(!start_T) return FALSE
	var/target_z = start_T.z
	var/end_x = start_T.x + T.width - 1
	var/end_y = start_T.y + T.height - 1
	var/turf/upper_right = locate(end_x, end_y, target_z)
	if(!upper_right || upper_right.z != target_z) return FALSE
	for(var/turf/test in block(start_T, upper_right))
		if(!is_void(test)) return FALSE
	return TRUE

/datum/controller/subsystem/dungeon_generator/proc/is_void(turf/T)
	if(!T) return FALSE
	
	if(istype(T, /turf/open/floor/rogue/hexstone)) 
		return TRUE
	return (istype(T, /turf/closed/dungeon_void) || istype(T, /turf/closed/mineral/rogue/bedrock))

/datum/controller/subsystem/dungeon_generator/proc/on_template_placed(datum/map_template/dungeon/T)
	placed_count[T.type]++
	created_since_entry++
	if(istype(T, /datum/map_template/dungeon/entry))
		created_since_entry = 0
		unlinked_dungeon_length--

/datum/controller/subsystem/dungeon_generator/proc/reverse_direction(dir)
	switch(dir)
		if(NORTH) return SOUTH
		if(SOUTH) return NORTH
		if(EAST)  return WEST
		if(WEST)  return EAST
	return dir

#undef STAGE_EXPANSION
#undef STAGE_CLEANUP
