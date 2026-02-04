#define DUNGEON_STAGE_EXPANSION 1
#define DUNGEON_STAGE_CLEANUP 2

SUBSYSTEM_DEF(dungeon_generator)

	name = "Dungeon Generator"
	init_order = INIT_ORDER_DUNGEON
	runlevels = RUNLEVEL_GAME | RUNLEVEL_INIT | RUNLEVEL_LOBBY
	wait = 1 SECONDS

	var/list/parent_types = list()
	var/list/templates_by_category = list() 
	var/list/markers = list() 
	var/list/placed_count = list()

	var/required_entries = 1
	var/created_since_entry = 0
	var/unlinked_dungeon_length = 0

	var/list/failed_markers = list() 
	var/generation_stage = DUNGEON_STAGE_EXPANSION
	var/cleanup_attempts = 0
	var/max_cleanup_steps = 100 

/datum/controller/subsystem/dungeon_generator/Initialize(start_timeofday)
	unlinked_dungeon_length = length(GLOB.unlinked_dungeon_entries)
	
	
	for(var/datum/map_template/dungeon/path in subtypesof(/datum/map_template/dungeon))
		if(is_abstract(path)) continue
		var/weight = initial(path.type_weight)
		if(weight) parent_types[path] = weight

	
	for(var/path in subtypesof(/datum/map_template/dungeon))
		if(is_abstract(path)) continue
		var/datum/map_template/dungeon/T = new path
		
		var/list/categories = list(/datum/map_template/dungeon) 
		if(istype(T, /datum/map_template/dungeon/room)) categories += /datum/map_template/dungeon/room
		if(istype(T, /datum/map_template/dungeon/hallway)) categories += /datum/map_template/dungeon/hallway
		if(istype(T, /datum/map_template/dungeon/rest)) categories += /datum/map_template/dungeon/rest
		if(istype(T, /datum/map_template/dungeon/entry)) categories += /datum/map_template/dungeon/entry

		for(var/cat in categories)
			if(!templates_by_category[cat])
				templates_by_category[cat] = list()
			templates_by_category[cat] += T

	return ..()

/datum/controller/subsystem/dungeon_generator/fire(resumed)
	if(generation_stage == DUNGEON_STAGE_EXPANSION)
		if(length(markers))
			process_markers(limit = 15)
		else
			
			if(length(failed_markers))
				generation_stage = DUNGEON_STAGE_CLEANUP
				
			return
	
	if(generation_stage == DUNGEON_STAGE_CLEANUP)
		if(!length(failed_markers) || cleanup_attempts >= max_cleanup_steps)
			
			generation_stage = DUNGEON_STAGE_EXPANSION 
			cleanup_attempts = 0
			return

		process_failed_markers(limit = 10)
		cleanup_attempts++

/datum/controller/subsystem/dungeon_generator/proc/process_failed_markers(limit)
	var/processed = 0
	while(length(failed_markers) && processed < limit)
		var/obj/effect/dungeon_directional_helper/helper = failed_markers[failed_markers.len]
		failed_markers.len--

		if(helper && !QDELETED(helper))
			var/turf/origin = get_turf(helper)
			var/turf/target_turf = get_step(origin, helper.dir)

			
			if(try_spawn_filler(helper.dir, target_turf))
				
				qdel(helper)
			else
				
				qdel(helper)
		
		processed++

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

/datum/controller/subsystem/dungeon_generator/proc/find_soulmate(direction, turf/origin, obj/effect/dungeon_directional_helper/helper)
	var/turf/target_turf = get_step(origin, direction)
	var/entries_placed = placed_count[/datum/map_template/dungeon/entry] || 0
	if(!target_turf || !is_void(target_turf))
		return FALSE 

	var/picked_category = pickweight(parent_types)


	if(entries_placed < required_entries && unlinked_dungeon_length > 0)
		if(created_since_entry > 70 || prob(created_since_entry))
			picked_category = /datum/map_template/dungeon/entry


	if(try_spawn_template(picked_category, direction, target_turf))
		return TRUE 

	if(try_spawn_template(/datum/map_template/dungeon, direction, target_turf))
		return TRUE 

	return FALSE 

/datum/controller/subsystem/dungeon_generator/proc/try_spawn_template(category, direction, turf/target_turf)
	var/opp_dir = reverse_direction(direction)
	var/target_z = target_turf.z
	
	var/list/candidates = templates_by_category[category]
	if(!length(candidates))
		return FALSE
	
	candidates = shuffle(candidates.Copy())
	var/entries_placed = placed_count[/datum/map_template/dungeon/entry] || 0
	
	for(var/datum/map_template/dungeon/T in candidates)

		if(!T.mappath)
			continue

		var/offset = T.get_dir_offset(opp_dir)
		if(offset == null)
			continue

		if(entries_placed >= required_entries && istype(T, /datum/map_template/dungeon/entry))
			continue

		var/spawn_x = target_turf.x
		var/spawn_y = target_turf.y
		
		switch(direction)
			if(NORTH)
				spawn_x -= offset
			if(SOUTH)
				spawn_x -= offset
				spawn_y -= (T.height - 1)
			if(EAST)
				spawn_y -= offset
			if(WEST)
				spawn_x -= (T.width - 1)
				spawn_y -= offset


		if(spawn_x < 1 || spawn_y < 1 || (spawn_x + T.width - 1) > world.maxx || (spawn_y + T.height - 1) > world.maxy)
			continue

		var/turf/start_turf = locate(spawn_x, spawn_y, target_z)
		

		if(!start_turf || start_turf.z != target_z)
			continue
		
		if(can_place(T, start_turf))
			if(T.load(start_turf))
				on_template_placed(T)
				return TRUE
	return FALSE

/datum/controller/subsystem/dungeon_generator/proc/try_spawn_filler(direction, turf/target_turf)
	var/list/all_templates = templates_by_category[/datum/map_template/dungeon]
	
	if(!all_templates)
		return FALSE


	var/list/shuffled_candidates = shuffle(all_templates.Copy())
	
	for(var/datum/map_template/dungeon/T in shuffled_candidates)
		if(T.width > 7 || T.height > 7) continue
		
	

/datum/controller/subsystem/dungeon_generator/proc/can_place(datum/map_template/dungeon/T, turf/start_T)
	if(!start_T) return FALSE

	var/target_z = start_T.z
	var/end_x = start_T.x + T.width - 1
	var/end_y = start_T.y + T.height - 1
	

	if(start_T.x < 1 || start_T.y < 1 || end_x > world.maxx || end_y > world.maxy)
		return FALSE


	var/turf/upper_right_corner = locate(end_x, end_y, target_z)
	if(!upper_right_corner || upper_right_corner.z != target_z)
		return FALSE 


	for(var/turf/test in block(start_T, upper_right_corner))
		if(test.z != target_z || !is_void(test))
			return FALSE
			
	return TRUE

/datum/controller/subsystem/dungeon_generator/proc/is_void(turf/T)
	if(!T) return FALSE
	
	if(istype(T, /turf/closed/dungeon_void) || istype(T, /turf/closed/mineral/rogue/bedrock))
		return TRUE
	return FALSE

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
