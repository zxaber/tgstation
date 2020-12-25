/datum/computer_file/program/aicontrol
	filename = "aicontrol"
	filedesc = "AIControl"
	extended_desc = "A built-in app for cyborg self-management and diagnostics."
	ui_header = "robotact.gif"
	program_icon_state = "command"
	requires_ntnet = FALSE
	transfer_access = null
	available_on_ntnet = FALSE
	unsendable = TRUE
	undeletable = TRUE
	usage_flags = PROGRAM_TABLET
	size = 5
	tgui_id = "NtosAiControl"
	program_icon = "terminal"
	///A typed reference to the computer, specifying the ai tablet type
	var/obj/item/modular_computer/tablet/integrated/ai/tablet
	///Contains a REF of the selected borg, for the more info section
	var/selectedborg
	///Contains a REF of the borg selected in the log view section
	var/selectedlog

/datum/computer_file/program/aicontrol/Destroy()
	tablet = null
	return ..()

/datum/computer_file/program/aicontrol/run_program(mob/living/user)
	if(!istype(computer, /obj/item/modular_computer/tablet/integrated/ai))
		to_chat(user, "<span class='warning'>A warning flashes across \the [computer]: Device Incompatible.</span>")
		return FALSE
	. = ..()
	if(.)
		tablet = computer
		if(tablet.device_theme == "syndicate")
			program_icon_state = "command-syndicate"
		return TRUE
	return FALSE

/datum/computer_file/program/aicontrol/ui_data(mob/user)
	var/list/data = get_header_data()
	if(!isAI(user) || user != tablet.host)
		return data
	var/mob/living/silicon/ai/AIuser = tablet.host

	data["name"] = AIuser.name
	data["integ"] = (100 + AIuser.health) / 2 //add 100 and divide by 2 because mob health goes from -100 to 100.
	data["battery"] = isturf(AIuser.loc) ? AIuser.battery : "--"
	data["shellcount"] = LAZYLEN(GLOB.available_ai_shells)

	data["selectedborg"] = selectedborg
	data["cyborgs"] = list()
	for(var/mob/living/silicon/robot/borg in AIuser.connected_robots)
		if(borg.connected_ai != AIuser)
			stack_trace("A cyborg [borg.name] has a master AI set as [borg.connected_ai] but was found in AI [AIuser]'s borg list.")
			AIuser.connected_robots -= borg
			continue

		//var/list/upgrade
		//for(var/obj/item/borg/upgrade/addon in borg.upgrades)
		//	upgrade += "\[[addon.name]\] "

		var/list/cyborg_data = list(
			name = borg.name,
			designation = borg.designation,
			locked_down = borg.lockcharge,
			status = borg.stat == DEAD,
			shell = borg.shell,
			ref = REF(borg)
		)
		data["cyborgs"] += list(cyborg_data)

		if(REF(borg) == selectedborg) //Some extra things that only show up in the more info pane that we don't need to collect from every borg
			var/list/upgrade
			for(var/obj/item/borg/upgrade/addon in borg.upgrades)
				upgrade += "[addon.name],"
			data["cyborgextended"]= list(
				name = borg.name,
				designation = borg.designation,
				status = borg.stat == DEAD ? "UNRESPONSIVE" : borg.lockcharge ? "LOCKED DOWN" : "ONLINE",
				charge = borg.cell ? round(borg.cell.percent()) : "CELL NOT FOUND",
				upgrades = upgrade
			)
			//data["cyborgextended"] += list(cyborg_extended)

	return data

/datum/computer_file/program/aicontrol/ui_static_data(mob/user)
	var/list/data = list()
	if(!iscyborg(user))
		return data
	var/mob/living/silicon/ai/AIuser = user

	data["name"] = AIuser.name
	data["laws"] = AIuser.laws.get_law_list(TRUE, TRUE, FALSE)
	data["logbook"] = list()
	data["log"] = list()

	for(var/mob/living/silicon/robot/borg in tablet.logbook)
		var/borg_ref = REF(borg)
		var/borg_selected = FALSE
		if(borg_ref == selectedlog)
			data["log"] = tablet.logbook[borg]
			borg_selected = TRUE

		var/borg_online = FALSE
		if(borg && istype(borg) && borg.connected_ai == AIuser && borg.stat != DEAD)
			borg_online = TRUE

		var/list/logbook = list(
			ref = REF(borg),
			name = tablet.logbook[borg][0],
			selected = borg_selected,
			online = borg_online
		)
		data["logbook"] += logbook
	return data

/datum/computer_file/program/aicontrol/ui_act(action, params)
	. = ..()
	if(.)
		return
	var/mob/living/silicon/ai/AIuser = usr

	switch(action)
		if("changecore")
			AIuser.pick_icon()

		if("togglebolts")
			AIuser.toggle_anchor()

		if("setmonitors")
			AIuser.ai_statuschange()

		if("viewImage")
			AIuser.aicamera?.viewpictures(usr)

		if("lawchannel")
			if(AIuser.incapacitated())
				return
			AIuser.set_autosay()

		if("borgselect")
			selectedborg = params["ref"]

		if("logselect")
			selectedlog = params["log"]


/*
	var/mob/living/silicon/robot/borgo = tablet.borgo

	switch(action)
		if("coverunlock")
			if(borgo.locked)
				borgo.locked = FALSE
				borgo.update_icons()
				if(borgo.emagged)
					borgo.logevent("Ch√•v√is cover lock has been [borgo.locked ? "engaged" : "released"]") //"The cover interface glitches out for a split second"
				else
					borgo.logevent("Chassis cover lock has been [borgo.locked ? "engaged" : "released"]")

		if("lawchannel")
			borgo.set_autosay()

		if("lawstate")
			borgo.checklaws()

		if("alertPower")
			if(borgo.stat == CONSCIOUS)
				if(!borgo.cell || !borgo.cell.charge)
					borgo.visible_message("<span class='notice'>The power warning light on <span class='name'>[borgo]</span> flashes urgently.</span>", \
						"You announce you are operating in low power mode.")
					playsound(borgo, 'sound/machines/buzz-two.ogg', 50, FALSE)

		if("toggleSensors")
			borgo.toggle_sensors()

		if("viewImage")
			if(borgo.connected_ai)
				borgo.connected_ai.aicamera?.viewpictures(usr)
			else
				borgo.aicamera?.viewpictures(usr)

		if("printImage")
			var/obj/item/camera/siliconcam/robot_camera/borgcam = borgo.aicamera
			borgcam?.borgprint(usr)

		if("toggleThrusters")
			borgo.toggle_ionpulse()

		if("lampIntensity")
			borgo.lamp_intensity = params["ref"]
			borgo.toggle_headlamp(FALSE, TRUE) */

/**
  * Forces a full update of the UI, if currently open.
  *
  * Forces an update that includes refreshing ui_static_data. Called by
  * law changes and borg log additions.
  */
/datum/computer_file/program/aicontrol/proc/force_full_update()
	if(tablet)
		var/datum/tgui/active_ui = SStgui.get_open_ui(tablet.AI, src)
		if(active_ui)
			active_ui.send_full_update()
