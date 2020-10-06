/datum/computer_file/program/chemscan
	filename = "chemscan"
	filedesc = "ChEmScAn"
	program_icon_state = "air"
	extended_desc = "A program that reads chemical data using an installed sensor package and displays the results."
	size = 4
	tgui_id = "NtosChem"
	program_icon = "flask"
	///List of information relating to the scanned object or the reagent holder
	var/list/containerinfo
	///List that holds the target scan data, for when the scanner is used on a reagent holder.
	var/list/reagentslist
	///Error code for various issues with getting a proper scan.
	var/errorlevel
	///Whether to show the percentage bars as in relation to total container volume (absolute), or total reagent volume (relative).
	var/absolute_percentage = FALSE

/datum/computer_file/program/chemscan/run_program(mob/living/user)
	. = ..()
	if (!.)
		return
	containerinfo = list()
	reagentslist = list() //clearing this out for fresh startups
	errorlevel = ""

/datum/computer_file/program/chemscan/tap(atom/target, mob/living/user)
	if(ismob(target))
		return ..() //no scanning mobs, find another app for that
	if(!target.reagents)
		return ..() //no chems here, mate
	containerinfo = list()
	reagentslist = list()
	errorlevel = ""
	var/obj/item/computer_hardware/sensorpackage/sensors = computer?.get_modular_computer_part(MC_SENSORS)
	if(!sensors?.check_functionality())
		errorlevel = sensors? "error: SENSOR FAULT" : "error: \\hardware\\sensorpackage\\startup.bin -- FILE NOT FOUND"
		return
	if(!target.reagents.reagent_list.len)
		errorlevel = "No significant chemical signatures detected."
		return
	for(var/datum/reagent/chemical in target.reagents.reagent_list)
		var/list/cheminfo = list(
			name = chemical.name,
			volume = chemical.volume,
		)
		reagentslist += list(cheminfo)
	containerinfo["volume"] = target.reagents.maximum_volume
	containerinfo["usedvolume"] = target.reagents.total_volume
	containerinfo["temp"] = target.reagents.chem_temp
	return TRUE

/datum/computer_file/program/chemscan/ui_data(mob/user)
	var/list/data = get_header_data()
	data["reagentslist"] = list(reagentslist)
	data["containerinfo"] = list(containerinfo)
	data["errorlevel"] = errorlevel
	data["absolute_percentage"] = absolute_percentage

	return data

/datum/computer_file/program/chemscan/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("percentage")
			absolute_percentage = !absolute_percentage
			return
