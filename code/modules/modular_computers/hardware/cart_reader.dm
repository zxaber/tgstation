/obj/item/computer_hardware/hard_drive/cart_reader
	name = "cartridge reader"
	desc = "A module capable of reading read-only data cartridges."
	power_usage = 100 //W
	icon_state = "card_mini"
	critical = FALSE
	w_class = WEIGHT_CLASS_SMALL
	device_type = MC_CART
	expansion_hw = TRUE
	max_capacity = INFINITY //stored files are on ROM carts, so let's not bog down with this

	var/obj/item/cartridge/stored_cart = null

/obj/item/computer_hardware/hard_drive/cart_reader/install_default_programs()
	return

/obj/item/computer_hardware/hard_drive/cart_reader/on_remove(obj/item/modular_computer/MC, mob/user)
	return

/obj/item/computer_hardware/hard_drive/cart_reader/handle_atom_del(atom/A)
	if(A == stored_cart)
		try_eject(0, null, TRUE)
	. = ..()

/obj/item/computer_hardware/hard_drive/cart_reader/examine(mob/user)
	. = ..()
	if(stored_cart)
		. += "There appears to be a data cartridge loaded. There appears to be a pinhole protecting a manual eject button. A screwdriver could probably press it."

/obj/item/computer_hardware/hard_drive/cart_reader/try_insert(obj/item/object, mob/living/user = null)
	if(!holder)
		return FALSE

	if(!istype(object, /obj/item/cartridge))
		return FALSE

	if(stored_cart)
		to_chat(user, "<span class='warning'>You try to insert \the [object] into \the [src], but the slot is occupied.</span>")
		return FALSE
	if(user && !user.transferItemToLoc(object, src))
		return FALSE

	stored_cart = object
	to_chat(user, "<span class='notice'>You insert \the [stored_cart] into \the [src].</span>")

	for(var/datum/computer_file/program/app in stored_cart)
		store_file(app)

	return TRUE


/obj/item/computer_hardware/hard_drive/cart_reader/try_eject(mob/living/user = null)
	if(!stored_cart)
		to_chat(user, "<span class='warning'>There is no card in \the [src].</span>")
		return FALSE

	if(stored_cart)
		to_chat(user, "<span class='notice'>You remove [stored_cart] from [src].</span>")
		if(user)
			user.put_in_hands(stored_cart)
		else
			stored_cart.forceMove(drop_location())
		for(var/datum/computer_file/program/app in stored_cart)
			if(app.program_state)
				app.kill_program()
			app.holder = null
			remove_file(app)
		stored_cart = null
		return TRUE
	return FALSE

/obj/item/computer_hardware/hard_drive/cart_reader/attackby(obj/item/object, mob/living/user)
	if(..())
		return
	if(object.tool_behaviour == TOOL_SCREWDRIVER)
		to_chat(user, "<span class='notice'>You press down on the manual eject button with \the [object].</span>")
		try_eject(user)
		return

/obj/item/computer_hardware/hard_drive/cart_reader/unremovable
	removable = FALSE
