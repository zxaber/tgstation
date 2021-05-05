/datum/computer_file/program/chemscan
	filename = "react"
	filedesc = "React"
	category = PROGRAM_CATEGORY_MEDI
	program_icon_state = "air"
	extended_desc = "Scans for reagents and displays the found information. Requires a reagent sensor package."
	size = 4
	tgui_id = "NtosChem"
	program_icon = "flask"
	var/list/reagent_info = list()
	var/list/container_info = list()

/datum/computer_file/program/chemscan/run_program(mob/living/user)
	. = ..()
	if (!.)
		return
	if(!computer?.get_modular_computer_part(MC_SENSORS)) //Giving a clue to users why the program isn't updating scans.
		to_chat(user, "<span class='warning'>\The [computer] flashes an error: \"hardware\\sensorpackage\\startup.bin -- file not found\".</span>")

/datum/computer_file/program/chemscan/tap(atom/A, mob/living/user, params)
	var/obj/item/computer_hardware/sensorpackage/sensors = computer?.get_modular_computer_part(MC_SENSORS)
	if(!sensors || sensors.check_functionality())
		to_chat(world, "DEBUG -- No sensor, return FALSE")
		return FALSE
	if(isnull(A.reagents) || !A.reagents.reagent_list.len)
		to_chat(world, "DEBUG -- Target has no reagents, return FALSE")
		return FALSE

	reagent_info = list()
	container_info = list()

	for(var/datum/reagent/chem in A.reagents.reagent_list)
		var/list/new_entry = list(
			name = chem.name,
			color = chem.color,
			volume = chem.volume)
		reagent_info += new_entry

	container_info = list(
		maximum_volume = A.reagents.maximum_volume,
		reagent_volume = A.reagents.total_volume,
		ph = A.reagents.ph)
	return TRUE

/datum/computer_file/program/chemscan/ui_data(mob/user)
	var/list/data = get_header_data()
	data["reagent_info"] = reagent_info
	data["container_info"] = container_info
	return data

/datum/computer_file/program/chemscan/ui_act(action, list/params)
	. = ..()
	if(.)
		return
