/obj/item/computer_hardware/handheld_scanner_cradle
	name = "scanner cradle"
	desc = "A cradle for handheld scanners, intended to be installed onto modular consoles."
	icon_state = "scanner_cradle_empty"
	w_class = WEIGHT_CLASS_NORMAL
	device_type = MC_SCANNER_CRADLE
	expansion_hw = TRUE

	var/obj/item/handheld_scanner/stored_scanner = null

/obj/item/computer_hardware/handheld_scanner_cradle/Initialize()
	. = ..()
	stored_scanner = new /obj/item/handheld_scanner(src)
	update_icon()

/obj/item/computer_hardware/handheld_scanner_cradle/on_install(obj/item/modular_computer/M, mob/living/user = null)
	. = ..()
	if(stored_scanner)
		if(holder && (stored_scanner.synced_console |= holder))
			stored_scanner.sync(holder)
			to_chat(user, "The sync light on the [stored_scanner] blinks twice.")

/obj/item/computer_hardware/handheld_scanner_cradle/update_icon()
	if(stored_scanner)
		icon_state = "scanner_cradle_full"
	else
		icon_state = "scanner_cradle_empty"
	return ..()

/obj/item/computer_hardware/handheld_scanner_cradle/attackby(obj/item/thing, mob/living/user)
	try_insert(thing, user)
	return ..()

/obj/item/computer_hardware/handheld_scanner_cradle/try_insert(obj/item/thing, mob/living/user)
	if(istype(thing, /obj/item/handheld_scanner) && !stored_scanner)
		if(user && !user.temporarilyRemoveItemFromInventory(thing))
			return
		thing.forceMove(src)
		stored_scanner = thing
		to_chat(user, "You return the [thing] to the cradle.")
		if(holder && (stored_scanner.synced_console |= holder))
			stored_scanner.sync(holder)
			to_chat(user, "The sync light on the [stored_scanner] blinks twice.")
		update_icon()
		return
	return ..()

/obj/item/computer_hardware/handheld_scanner_cradle/attack_self(mob/user)
	if(stored_scanner)
		if(!user.put_in_hands(stored_scanner))
			stored_scanner.forceMove(loc)
		stored_scanner = null
		update_icon()
		return
	return ..()

/obj/item/computer_hardware/handheld_scanner_cradle/can_quick_eject()
	return stored_scanner || ..()

/obj/item/computer_hardware/handheld_scanner_cradle/try_eject(mob/living/user = null)
	if(!user || !holder.Adjacent(user) || !user.put_in_hands(stored_scanner))
		stored_scanner.forceMove(loc)
	stored_scanner = null
	update_icon()
	return


/obj/item/handheld_scanner
	name = "handheld scanner"
	desc = "A tool that allows the user to scan an item and transmit the data back to a console. Emulates tablet or laptop scanning."
	icon = 'icons/obj/module.dmi'
	icon_state = "hand_scanner"
	w_class = WEIGHT_CLASS_TINY
	var/obj/item/modular_computer/synced_console

/**
 * Syncs the scanner to the console.
 *
 * Assigns the `synced_console` var to hold a ref to the console
 * in question, and sets up a listener to clear this ref in the
 * event that the console is deleted. Clearing the ref helps
 * avoid costly hard-deletes.
 */
/obj/item/handheld_scanner/proc/sync(var/obj/item/modular_computer/console)
	UnregisterSignal(COMSIG_PARENT_QDELETING, .proc/clear_sync)
	synced_console = console
	RegisterSignal(synced_console, COMSIG_PARENT_QDELETING, .proc/clear_sync) //Kill the ref, avoid a harddel

/obj/item/handheld_scanner/proc/clear_sync()
	synced_console = null

/obj/item/handheld_scanner/pre_attack_secondary(atom/A, mob/living/user, params)
	if(synced_console?.active_program?.tap(A, user, params))
		user.do_attack_animation(A) //Emulate this animation since we kill the attack in four lines
		playsound(loc, 'sound/weapons/tap.ogg', get_clamped_volume(), TRUE, -1) //Likewise for the tap sound
		addtimer(CALLBACK(src, .proc/play_ping), 0.5 SECONDS, TIMER_UNIQUE) //Slightly delayed ping to indicate success
		addtimer(CALLBACK(synced_console, .proc/play_ping), 0.5 SECONDS, TIMER_UNIQUE) //And one for the console
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/**
 * Plays a ping sound.
 *
 * Timers runtime if you try to make them call playsound. Yep.
 */
/obj/item/handheld_scanner/proc/play_ping()
	playsound(loc, 'sound/machines/ping.ogg', get_clamped_volume(), FALSE, -1)
