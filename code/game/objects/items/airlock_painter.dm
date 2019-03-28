/obj/item/airlock_painter
	name = "airlock painter"
	desc = "An advanced autopainter preprogrammed with several paintjobs for airlocks. Use it on an airlock during or after construction to change the paintjob."
	icon = 'icons/obj/objects.dmi'
	icon_state = "paint sprayer"
	item_state = "paint sprayer"

	w_class = WEIGHT_CLASS_SMALL

	materials = list(MAT_METAL=50, MAT_GLASS=50)

	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	usesound = 'sound/effects/spray2.ogg'

	var/obj/item/toner/ink = null
	var/selection = null

/obj/item/airlock_painter/Initialize()
	. = ..()
	ink = new /obj/item/toner(src)

//This proc doesn't just check if the painter can be used, but also uses it.
//Only call this if you are certain that the painter will be used right after this check!
/obj/item/airlock_painter/proc/use_paint(mob/user)
	if(can_use(user))
		ink.charges--
		playsound(src.loc, 'sound/effects/spray2.ogg', 50, 1)
		return 1
	else
		return 0

//This proc only checks if the painter can be used.
//Call this if you don't want the painter to be used right after this check, for example
//because you're expecting user input.
/obj/item/airlock_painter/proc/can_use(mob/user)
	if(!ink)
		to_chat(user, "<span class='notice'>There is no toner cartridge installed in [src]!</span>")
		return 0
	else if(ink.charges < 1)
		to_chat(user, "<span class='notice'>[src] is out of ink!</span>")
		return 0
	else
		return 1

/obj/item/airlock_painter/suicide_act(mob/user)
	var/obj/item/organ/lungs/L = user.getorganslot(ORGAN_SLOT_LUNGS)

	if(can_use(user) && L)
		user.visible_message("<span class='suicide'>[user] is inhaling toner from [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
		use(user)

		// Once you've inhaled the toner, you throw up your lungs
		// and then die.

		// Find out if there is an open turf in front of us,
		// and if not, pick the turf we are standing on.
		var/turf/T = get_step(get_turf(src), user.dir)
		if(!isopenturf(T))
			T = get_turf(src)

		// they managed to lose their lungs between then and
		// now. Good job.
		if(!L)
			return OXYLOSS

		L.Remove(user)

		// make some colorful reagent, and apply it to the lungs
		L.create_reagents(10)
		L.reagents.add_reagent("colorful_reagent", 10)
		L.reagents.reaction(L, TOUCH, 1)

		// TODO maybe add some colorful vomit?

		user.visible_message("<span class='suicide'>[user] vomits out [user.p_their()] [L]!</span>")
		playsound(user.loc, 'sound/effects/splat.ogg', 50, 1)

		L.forceMove(T)

		return (TOXLOSS|OXYLOSS)
	else if(can_use(user) && !L)
		user.visible_message("<span class='suicide'>[user] is spraying toner on [user.p_them()]self from [src]! It looks like [user.p_theyre()] trying to commit suicide.</span>")
		user.reagents.add_reagent("colorful_reagent", 1)
		user.reagents.reaction(user, TOUCH, 1)
		return TOXLOSS

	else
		user.visible_message("<span class='suicide'>[user] is trying to inhale toner from [src]! It might be a suicide attempt if [src] had any toner.</span>")
		return SHAME


/obj/item/airlock_painter/examine(mob/user)
	..()
	if(!ink)
		to_chat(user, "<span class='notice'>It doesn't have a toner cartridge installed.</span>")
		return
	var/ink_level = "high"
	if(ink.charges < 1)
		ink_level = "empty"
	else if((ink.charges/ink.max_charges) <= 0.25) //25%
		ink_level = "low"
	else if((ink.charges/ink.max_charges) > 1) //Over 100% (admin var edit)
		ink_level = "dangerously high"
	to_chat(user, "<span class='notice'>Its ink levels look [ink_level].</span>")


/obj/item/airlock_painter/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/toner))
		if(ink)
			to_chat(user, "<span class='notice'>[src] already contains \a [ink].</span>")
			return
		if(!user.transferItemToLoc(W, src))
			return
		to_chat(user, "<span class='notice'>You install [W] into [src].</span>")
		ink = W
		playsound(src.loc, 'sound/machines/click.ogg', 50, 1)
		return
	if(istype(W, /obj/item/screwdriver))
		var/L = loc
		var/N = /obj/item/airlock_painter
		forceMove(get_turf(src))
		if (istype(src, /obj/item/airlock_painter/tile_painter))
			N = new /obj/item/airlock_painter(L, 1)
		else
			N = new /obj/item/airlock_painter/tile_painter(L, 1)
//		if(!ink)
//			N.ink = null
//		else
//			N.ink = ink
		qdel(src)
		return

	else
		return ..()

/obj/item/airlock_painter/attack_self(mob/user)
	if(user.client.keys_held["Alt"])
		if(ink)
			playsound(src.loc, 'sound/machines/click.ogg', 50, 1)
			ink.forceMove(user.drop_location())
			user.put_in_hands(ink)
			to_chat(user, "<span class='notice'>You remove [ink] from [src].</span>")
			ink = null
		return

/obj/item/airlock_painter/tile_painter
	name = "floor tile painter"
	desc = "An advanced autopainter preprogrammed with several paintjobs for floor tiles."
	var/obj/effect/turf_decal/decalset = null
	var/decaldirect = null
	var/decalsketchpad = null //this variable is just reused a lot...

/obj/item/airlock_painter/tile_painter/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/item/airlock_painter/tile_painter/proc/get_decal_image(decal_type, decaldir)
	var/obj/machinery/door/airlock/proto = "/obj/effect/turf_decal/"
	var/ic = initial(proto.icon)
	var/mutable_appearance/MA = mutable_appearance(ic, decal_type)
//	if(!initial(proto.glass))
//		MA.overlays += "fill_closed"
	//Not scaling these down to button size because they look horrible then, instead just bumping up radius.
	return MA

/obj/item/airlock_painter/tile_painter/attack_self(mob/user)
	. = ..()
	decaldirect = null

	var/list/decal_root = list(
	"Location Indicators" = get_decal_image("delivery", 0),
	"Warning Lines" = "/obj/effect/turf_decal/stripes/line",
	"Misc Labels" = "/obj/effect/turf_decal/caution")

	//Location Indicators section;
	var/list/li_colors = list(
	"Yellow" = "/obj/effect/turf_decal/delivery",
	"Red" = "/obj/effect/turf_decal/delivery/red",
	"White" = "/obj/effect/turf_decal/delivery/white")

	var/list/li_yellow = list(
	"Delivery" = "/obj/effect/turf_decal/delivery",
	"Bot" = "/obj/effect/turf_decal/bot",
	"Loading" = "/obj/effect/turf_decal/loading_area")

	var/list/li_y_loading = list(
	"North" = "/obj/effect/turf_decal/loading_area",
	"South" = "/obj/effect/turf_decal/loading_area",
	"East" = "/obj/effect/turf_decal/loading_area",
	"West" = "/obj/effect/turf_decal/loading_area")

	var/list/li_red = list(
	"Delivery" = "/obj/effect/turf_decal/delivery/red",
	"Bot" = "/obj/effect/turf_decal/bot_red",
	"Loading" = "/obj/effect/turf_decal/loading_area/red")

	var/list/li_r_loading = list(
	"North" = "/obj/effect/turf_decal/loading_area/red",
	"South" = "/obj/effect/turf_decal/loading_area/red",
	"East" = "/obj/effect/turf_decal/loading_area/red",
	"West" = "/obj/effect/turf_decal/loading_area/red")

	var/list/li_white = list(
	"Delivery" = "/obj/effect/turf_decal/delivery/white",
	"Bot" = "/obj/effect/turf_decal/bot_white",
	"Loading" = "/obj/effect/turf_decal/loading_area/white")

	var/list/li_w_loading = list(
	"North" = "/obj/effect/turf_decal/loading_area/white",
	"South" = "/obj/effect/turf_decal/loading_area/white",
	"East" = "/obj/effect/turf_decal/loading_area/white",
	"West" = "/obj/effect/turf_decal/loading_area/white")

	//Warning Lines section;
	var/list/wl_colors = list(
	"Yellow" = "/obj/effect/turf_decal/stripes/line",
	"Red" = "/obj/effect/turf_decal/stripes/red/line",
	"White" = "/obj/effect/turf_decal/stripes/white/line")

	var/list/wl_yellow = list(
	"Line" = "/obj/effect/turf_decal/stripes/line",
	"Corners" = "/obj/effect/turf_decal/stripes/corner",
	"End" = "/object/effect/turf_decal/stripes/end",
	"Box" = "/object/effect/turf_decal/stripes/box",
	"Filled" = "/object/effect/turf_decal/stripes/full")

	var/list/wl_y_line = list(
	"North" = "/obj/effect/turf_decal/stripes/line",
	"North East" = "/obj/effect/turf_decal/stripes/line",
	"East" = "/obj/effect/turf_decal/stripes/line",
	"South East" = "/obj/effect/turf_decal/stripes/line",
	"South" = "/obj/effect/turf_decal/stripes/line",
	"South West" = "/obj/effect/turf_decal/stripes/line",
	"West" = "/obj/effect/turf_decal/stripes/line",
	"North West" = "/obj/effect/turf_decal/stripes/line")

	var/list/wl_y_corner = list(
	"North East" = "/obj/effect/turf_decal/stripes/corner",
	"South East" = "/obj/effect/turf_decal/stripes/corner",
	"South West" = "/obj/effect/turf_decal/stripes/corner",
	"North West" = "/obj/effect/turf_decal/stripes/corner")

	var/list/wl_y_end = list(
	"North" = "/object/effect/turf_decal/stripes/end",
	"East" = "/object/effect/turf_decal/stripes/end",
	"South" = "/object/effect/turf_decal/stripes/end",
	"West" = "/object/effect/turf_decal/stripes/end")

	var/list/wl_red = list(
	"Line" = "/obj/effect/turf_decal/stripes/red/line",
	"Corners" = "/obj/effect/turf_decal/stripes/red/corner",
	"End" = "/object/effect/turf_decal/stripes/red/end",
	"Box" = "/object/effect/turf_decal/stripes/red/box",
	"Filled" = "/object/effect/turf_decal/stripes/red/full")

	var/list/wl_r_line = list(
	"North" = "/obj/effect/turf_decal/stripes/red/line",
	"North East" = "/obj/effect/turf_decal/stripes/red/line",
	"East" = "/obj/effect/turf_decal/stripes/red/line",
	"South East" = "/obj/effect/turf_decal/stripes/red/line",
	"South" = "/obj/effect/turf_decal/stripes/red/line",
	"South West" = "/obj/effect/turf_decal/stripes/red/line",
	"West" = "/obj/effect/turf_decal/stripes/red/line",
	"North West" = "/obj/effect/turf_decal/stripes/red/line")

	var/list/wl_r_corner = list(
	"North East" = "/obj/effect/turf_decal/stripes/red/corner",
	"South East" = "/obj/effect/turf_decal/stripes/red/corner",
	"South West" = "/obj/effect/turf_decal/stripes/red/corner",
	"North West" = "/obj/effect/turf_decal/stripes/red/corner")

	var/list/wl_r_end = list(
	"North" = "/object/effect/turf_decal/stripes/red/end",
	"East" = "/object/effect/turf_decal/stripes/red/end",
	"South" = "/object/effect/turf_decal/stripes/red/end",
	"West" = "/object/effect/turf_decal/stripes/red/end")

	var/list/wl_white = list(
	"Line" = "/obj/effect/turf_decal/stripes/white/line",
	"Corners" = "/obj/effect/turf_decal/stripes/white/corner",
	"End" = "/object/effect/turf_decal/stripes/white/end",
	"Box" = "/object/effect/turf_decal/stripes/white/box",
	"Filled" = "/object/effect/turf_decal/stripes/white/full")

	var/list/wl_w_line = list(
	"North" = "/obj/effect/turf_decal/stripes/white/line",
	"North East" = "/obj/effect/turf_decal/stripes/white/line",
	"East" = "/obj/effect/turf_decal/stripes/white/line",
	"South East" = "/obj/effect/turf_decal/stripes/white/line",
	"South" = "/obj/effect/turf_decal/stripes/white/line",
	"South West" = "/obj/effect/turf_decal/stripes/white/line",
	"West" = "/obj/effect/turf_decal/stripes/white/line",
	"North West" = "/obj/effect/turf_decal/stripes/white/line")

	var/list/wl_w_corner = list(
	"North East" = "/obj/effect/turf_decal/stripes/white/corner",
	"South East" = "/obj/effect/turf_decal/stripes/white/corner",
	"South West" = "/obj/effect/turf_decal/stripes/white/corner",
	"North West" = "/obj/effect/turf_decal/stripes/white/corner")

	var/list/wl_w_end = list(
	"North" = "/object/effect/turf_decal/stripes/white/end",
	"East" = "/object/effect/turf_decal/stripes/white/end",
	"South" = "/object/effect/turf_decal/stripes/white/end",
	"West" = "/object/effect/turf_decal/stripes/white/end")

	//Misc Label section;
	var/ml_colors = list(
	"Yellow" = "/obj/effect/turf_decal/caution",
	"Red" = "/obj/effect/turf_decal/caution/red",
	"White" = "/obj/effect/turf_decal/caution/white")

	var/ml_yellow = list(
	"Caution" = "/obj/effect/turf_decal/caution",
	"Stand Clear" = "/obj/effect/turf_decal/caution/stand_clear",
	"Arrows" = "/obj/effect/turf_decal/arrows")

	var/ml_y_caution = list(
	"North" = "/obj/effect/turf_decal/caution",
	"East" = "/obj/effect/turf_decal/caution",
	"South" = "/obj/effect/turf_decal/caution",
	"West" = "/obj/effect/turf_decal/caution")

	var/ml_y_standclear = list(
	"North" = "/obj/effect/turf_decal/caution/stand_clear",
	"East" = "/obj/effect/turf_decal/caution/stand_clear",
	"South" = "/obj/effect/turf_decal/caution/stand_clear",
	"West" = "/obj/effect/turf_decal/caution/stand_clear")

	var/ml_y_arrows = list(
	"North" = "/obj/effect/turf_decal/arrows",
	"East" = "/obj/effect/turf_decal/arrows",
	"South" = "/obj/effect/turf_decal/arrows",
	"West" = "/obj/effect/turf_decal/arrows")

	var/ml_red = list(
	"Caution" = "/obj/effect/turf_decal/caution/red",
	"Stand Clear" = "/obj/effect/turf_decal/caution/stand_clear/red",
	"Arrows" = "/obj/effect/turf_decal/arrows/red")

	var/ml_r_caution = list(
	"North" = "/obj/effect/turf_decal/caution/red",
	"East" = "/obj/effect/turf_decal/caution/red",
	"South" = "/obj/effect/turf_decal/caution/red",
	"West" = "/obj/effect/turf_decal/caution/red")

	var/ml_r_standclear = list(
	"North" = "/obj/effect/turf_decal/caution/stand_clear/red",
	"East" = "/obj/effect/turf_decal/caution/stand_clear/red",
	"South" = "/obj/effect/turf_decal/caution/stand_clear/red",
	"West" = "/obj/effect/turf_decal/caution/stand_clear/red")

	var/ml_r_arrows = list(
	"North" = "/obj/effect/turf_decal/arrows/red",
	"East" = "/obj/effect/turf_decal/arrows/red",
	"South" = "/obj/effect/turf_decal/arrows/red",
	"West" = "/obj/effect/turf_decal/arrows/red")

	var/ml_white = list(
	"Caution" = "/obj/effect/turf_decal/caution/white",
	"Stand Clear" = "/obj/effect/turf_decal/caution/stand_clear/white",
	"Arrows" = "/obj/effect/turf_decal/arrows/white")

	var/ml_w_caution = list(
	"North" = "/obj/effect/turf_decal/caution/white",
	"East" = "/obj/effect/turf_decal/caution/white",
	"South" = "/obj/effect/turf_decal/caution/white",
	"West" = "/obj/effect/turf_decal/caution/white")

	var/ml_w_standclear = list(
	"North" = "/obj/effect/turf_decal/caution/stand_clear/white",
	"East" = "/obj/effect/turf_decal/caution/stand_clear/white",
	"South" = "/obj/effect/turf_decal/caution/stand_clear/white",
	"West" = "/obj/effect/turf_decal/caution/stand_clear/white")

	var/ml_w_arrows = list(
	"North" = "/obj/effect/turf_decal/arrows/white",
	"East" = "/obj/effect/turf_decal/arrows/white",
	"South" = "/obj/effect/turf_decal/arrows/white",
	"West" = "/obj/effect/turf_decal/arrows/white")


	decalsketchpad = show_radial_menu(user, src, decal_root, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
	switch(decalsketchpad)
		if("Location Indicators")
			decalsketchpad = show_radial_menu(user, src, li_colors, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
			switch(decalsketchpad)
				if("Yellow")
					decalsketchpad = show_radial_menu(user, src, li_yellow, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
					switch(decalsketchpad)
						if("Delivery")
							decalset = "/obj/effect/turf_decal/delivery"
						if("Bot")
							decalset = "/obj/effect/turf_decal/bot"
						if("Loading")
							decalset = "/obj/effect/turf_decal/loading_area"
							decalsketchpad = show_radial_menu(user, src, li_y_loading, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = "1"
								if("South")
									decaldirect = "2"
								if("East")
									decaldirect = "4"
								if("West")
									decaldirect = "8"
				if("Red")
					decalsketchpad = show_radial_menu(user, src, li_red, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
					switch(decalsketchpad)
						if("Delivery")
							decalset = "/obj/effect/turf_decal/delivery/red"
						if("Bot")
							decalset = "/obj/effect/turf_decal/bot_red"
						if("Loading")
							decalset = "/obj/effect/turf_decal/loading_area/red"
							decalsketchpad = show_radial_menu(user, src, li_r_loading, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = "1"
								if("South")
									decaldirect = "2"
								if("East")
									decaldirect = "4"
								if("West")
									decaldirect = "8"
				if("White")
					decalsketchpad = show_radial_menu(user, src, li_white, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
					switch(decalsketchpad)
						if("Delivery")
							decalset = "/obj/effect/turf_decal/delivery/white"
						if("Bot")
							decalset = "/obj/effect/turf_decal/bot_white"
						if("Loading")
							decalset = "/obj/effect/turf_decal/loading_area/white"
							decalsketchpad = show_radial_menu(user, src, li_w_loading, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = "1"
								if("South")
									decaldirect = "2"
								if("East")
									decaldirect = "4"
								if("West")
									decaldirect = "8"
		if("Warning Lines")
			decalsketchpad = show_radial_menu(user, src, wl_colors, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
			switch(decalsketchpad)
				if("Yellow")
					decalsketchpad = show_radial_menu(user, src, wl_yellow, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
					switch(decalsketchpad)
						if("Line")
							decalset = "/obj/effect/turf_decal/stripes/line"
							decalsketchpad = show_radial_menu(user, src, wl_y_line, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = 1
								if("North East")
									decaldirect = 5
								if("East")
									decaldirect = 4
								if("South East")
									decaldirect = 6
								if("South")
									decaldirect = 2
								if("South West")
									decaldirect = 10
								if("West")
									decaldirect = 8
								if("North West")
									decaldirect = 11
						if("Corner")
							decalset = "/obj/effect/turf_decal/stripes/corner"
							decalsketchpad = show_radial_menu(user, src, wl_y_corner, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North East")
									decaldirect = 4
								if("South East")
									decaldirect = 2
								if("South West")
									decaldirect = 8
								if("North West")
									decaldirect = 1
						if("End")
							decalset = "/obj/effect/turf_decal/stripes/end"
							decalsketchpad = show_radial_menu(user, src, wl_y_end, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = 1
								if("South")
									decaldirect = 2
								if("East")
									decaldirect = 4
								if("West")
									decaldirect = 8
						if("Box")
							decalset = "/obj/effect/turf_decal/stripes/box"
						if("Filled")
							decalset = "/obj/effect/turf_decal/stripes/full"
				if("Red")
					decalsketchpad = show_radial_menu(user, src, wl_red, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
					switch(decalsketchpad)
						if("Line")
							decalset = "/obj/effect/turf_decal/stripes/red/line"
							decalsketchpad = show_radial_menu(user, src, wl_r_line, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = 1
								if("North East")
									decaldirect = 5
								if("East")
									decaldirect = 4
								if("South East")
									decaldirect = 6
								if("South")
									decaldirect = 2
								if("South West")
									decaldirect = 10
								if("West")
									decaldirect = 8
								if("North West")
									decaldirect = 11
						if("Corner")
							decalset = "/obj/effect/turf_decal/stripes/red/corner"
							decalsketchpad = show_radial_menu(user, src, wl_r_corner, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North East")
									decaldirect = 4
								if("South East")
									decaldirect = 2
								if("South West")
									decaldirect = 8
								if("North West")
									decaldirect = 1
						if("End")
							decalset = "/obj/effect/turf_decal/stripes/red/end"
							decalsketchpad = show_radial_menu(user, src, wl_r_end, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = 1
								if("South")
									decaldirect = 2
								if("East")
									decaldirect = 4
								if("West")
									decaldirect = 8
						if("Box")
							decalset = "/obj/effect/turf_decal/stripes/red/box"
						if("Filled")
							decalset = "/obj/effect/turf_decal/stripes/red/full"
				if("White")
					decalsketchpad = show_radial_menu(user, src, wl_white, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
					switch(decalsketchpad)
						if("Line")
							decalset = "/obj/effect/turf_decal/stripes/white/line"
							decalsketchpad = show_radial_menu(user, src, wl_w_line, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = 1
								if("North East")
									decaldirect = 5
								if("East")
									decaldirect = 4
								if("South East")
									decaldirect = 6
								if("South")
									decaldirect = 2
								if("South West")
									decaldirect = 10
								if("West")
									decaldirect = 8
								if("North West")
									decaldirect = 11
						if("Corner")
							decalset = "/obj/effect/turf_decal/stripes/white/corner"
							decalsketchpad = show_radial_menu(user, src, wl_w_corner, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North East")
									decaldirect = 4
								if("South East")
									decaldirect = 2
								if("South West")
									decaldirect = 8
								if("North West")
									decaldirect = 1
						if("End")
							decalset = "/obj/effect/turf_decal/stripes/white/end"
							decalsketchpad = show_radial_menu(user, src, wl_w_end, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = 1
								if("South")
									decaldirect = 2
								if("East")
									decaldirect = 4
								if("West")
									decaldirect = 8
						if("Box")
							decalset = "/obj/effect/turf_decal/stripes/white/box"
						if("Filled")
							decalset = "/obj/effect/turf_decal/stripes/white/full"
		if("Misc Labels")
			decalsketchpad = show_radial_menu(user, src, ml_colors, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
			switch(decalsketchpad)
				if("Yellow")
					decalsketchpad = show_radial_menu(user, src, ml_yellow, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
					switch(decalsketchpad)
						if("Caution")
							decalset = "/obj/effect/turf_decal/caution"
							decalsketchpad = show_radial_menu(user, src, ml_y_caution, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = "1"
								if("South")
									decaldirect = "2"
								if("East")
									decaldirect = "4"
								if("West")
									decaldirect = "8"
						if("Stand Clear")
							decalset = "/obj/effect/turf_decal/caution/stand_clear"
							decalsketchpad = show_radial_menu(user, src, ml_y_standclear, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = "1"
								if("South")
									decaldirect = "2"
								if("East")
									decaldirect = "4"
								if("West")
									decaldirect = "8"
						if("Arrows")
							decalset = "/obj/effect/turf_decal/arrows"
							decalsketchpad = show_radial_menu(user, src, ml_y_arrows, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = "1"
								if("South")
									decaldirect = "2"
								if("East")
									decaldirect = "4"
								if("West")
									decaldirect = "8"
				if("Red")
					decalsketchpad = show_radial_menu(user, src, ml_red, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
					switch(decalsketchpad)
						if("Caution")
							decalset = "/obj/effect/turf_decal/caution/red"
							decalsketchpad = show_radial_menu(user, src, ml_r_caution, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = "1"
								if("South")
									decaldirect = "2"
								if("East")
									decaldirect = "4"
								if("West")
									decaldirect = "8"
						if("Stand Clear")
							decalset = "/obj/effect/turf_decal/caution/stand_clear/red"
							decalsketchpad = show_radial_menu(user, src, ml_r_standclear, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = "1"
								if("South")
									decaldirect = "2"
								if("East")
									decaldirect = "4"
								if("West")
									decaldirect = "8"
						if("Arrows")
							decalset = "/obj/effect/turf_decal/arrows/red"
							decalsketchpad = show_radial_menu(user, src, ml_r_arrows, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = "1"
								if("South")
									decaldirect = "2"
								if("East")
									decaldirect = "4"
								if("West")
									decaldirect = "8"
				if("White")
					decalsketchpad = show_radial_menu(user, src, ml_white, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
					switch(decalsketchpad)
						if("Caution")
							decalset = "/obj/effect/turf_decal/caution/white"
							decalsketchpad = show_radial_menu(user, src, ml_w_caution, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = "1"
								if("South")
									decaldirect = "2"
								if("East")
									decaldirect = "4"
								if("West")
									decaldirect = "8"
						if("Stand Clear")
							decalset = "/obj/effect/turf_decal/caution/stand_clear/white"
							decalsketchpad = show_radial_menu(user, src, ml_w_standclear, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = "1"
								if("South")
									decaldirect = "2"
								if("East")
									decaldirect = "4"
								if("West")
									decaldirect = "8"
						if("Arrows")
							decalset = "/obj/effect/turf_decal/arrows/white"
							decalsketchpad = show_radial_menu(user, src, ml_w_arrows, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
							switch(decalsketchpad)
								if("North")
									decaldirect = "1"
								if("South")
									decaldirect = "2"
								if("East")
									decaldirect = "4"
								if("West")
									decaldirect = "8"


/obj/item/airlock_painter/tile_painter/proc/isValidSurface(surface)
	return istype(surface, /turf/open/floor)

/obj/item/airlock_painter/tile_painter/afterattack(atom/target, mob/user, proximity, params)
	. = ..()
	if(!proximity || !isturf(target) || !can_use(user) || !isValidSurface(target)) //!check_allowed_items(target))
		return

//	if(decaldirect)
//		new decalset{dir = decaldirect}(target, 1)
//	else
	new decalset(target, 1)
//	new /obj/effect/turf_decal/stripes/line{dir = 8}(target, 1)
//	var/N = new /obj/effect/turf_decal/stripes/line(target, 1)
//	N.dir = user.dir
	ink.charges--
	playsound(src.loc, 'sound/effects/spray2.ogg', 50, 1)