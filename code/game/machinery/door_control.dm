/obj/machinery/door_control
	name = "remote door-control"
	desc = "It controls doors, remotely."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "doorctrl0"
	desc = "A remote control-switch for a door."
	power_channel = ENVIRON
	var/id = null
	var/range = 10
	var/normaldoorcontrol = 0
	var/desiredstate = 0 // Zero is closed, 1 is open.
	var/specialfunctions = 1
	/*
	Bitflag, 	1= open
				2= idscan,
				4= bolts
				8= shock
				16= door safties

	*/

	var/exposedwires = 0
	var/wires = 3
	plane = 21
	/*
	Bitflag,	1=checkID
				2=Network Access
	*/

	anchored = 1.0
	use_power = 1
	idle_power_usage = 2
	active_power_usage = 4

/obj/machinery/door_control/attack_ai(mob/user as mob)
	if(wires & 2)
		return src.attack_hand(user)
	else
		user << "Error, no route to host."

/obj/machinery/door_control/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/door_control/attackby(obj/item/weapon/W, mob/user as mob)
	/* For later implementation
	if (istype(W, /obj/item/weapon/screwdriver))
	{
		if(wiresexposed)
			icon_state = "doorctrl0"
			wiresexposed = 0

		else
			icon_state = "doorctrl-open"
			wiresexposed = 1

		return
	}
	*/
	if(istype(W, /obj/item/device/detective_scanner))
		return
	if(istype(W, /obj/item/weapon/card/emag))
		req_access = list()
		req_one_access = list()
		playsound(src.loc, "sparks", 100, 1)
	return src.attack_hand(user)

/obj/machinery/door_control/attack_hand(mob/user as mob)
	src.add_fingerprint(usr)
	if(stat & (NOPOWER|BROKEN))
		return

	if(!allowed(user) && (wires & 1))
		user << "\red Access Denied"
		flick("doorctrl-denied",src)
		return

	use_power(5)
	icon_state = "doorctrl1"
	add_fingerprint(user)

	if(normaldoorcontrol)
		for(var/obj/machinery/door/airlock/D in range(range))
			if(D.id_tag == src.id)
				if(specialfunctions & OPEN)
					if (D.density)
						spawn(0)
							D.open()
							return
					else
						spawn(0)
							D.close()
							return
				if(desiredstate == 1)
					if(specialfunctions & IDSCAN)
						D.aiDisabledIdScanner = 1
					if(specialfunctions & BOLTS)
						D.locked = 1
						D.update_icon()
					if(specialfunctions & SHOCK)
						D.secondsElectrified = -1
					if(specialfunctions & SAFE)
						D.safe = 0
				else
					if(specialfunctions & IDSCAN)
						D.aiDisabledIdScanner = 0
					if(specialfunctions & BOLTS)
						if(!D.isWireCut(4) && D.arePowerSystemsOn())
							D.locked = 0
							D.update_icon()
					if(specialfunctions & SHOCK)
						D.secondsElectrified = 0
					if(specialfunctions & SAFE)
						D.safe = 1

	else
		for(var/obj/machinery/door/poddoor/M in range(10))
			if (M.id == src.id)
				if (M.density)
					spawn( 0 )
						M.open()
						return
				else
					spawn( 0 )
						M.close()
						return

	desiredstate = !desiredstate
	spawn(15)
		if(!(stat & NOPOWER))
			icon_state = "doorctrl0"

/obj/machinery/door_control/power_change()
	..()
	if(stat & NOPOWER)
		icon_state = "doorctrl-p"
	else
		icon_state = "doorctrl0"

/obj/machinery/driver_button/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/driver_button/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/driver_button/attackby(obj/item/weapon/W, mob/user as mob)

	if(istype(W, /obj/item/device/detective_scanner))
		return
	return src.attack_hand(user)

/obj/machinery/driver_button/attack_hand(mob/user as mob)

	src.add_fingerprint(usr)
	if(stat & (NOPOWER|BROKEN))
		return
	if(active)
		return
	add_fingerprint(user)

	use_power(5)

	active = 1
	icon_state = "launcheract"


	for(var/obj/structure/stool/bed/chair/e_chair/M in world)
		if (M.id == src.id)
			spawn(0)
				if(!M.on)
					usr << "<span class='notice'>You switch [src] on, and activate it.</span>"
					M.on = 1
				else
					usr << "<span class='notice'>You activate [src].</span>"
				M.shock()
				return

	for(var/obj/machinery/door/poddoor/M in world)
		if (M.id == src.id)
			spawn( 0 )
				M.open()
				return

	sleep(20)

	for(var/obj/machinery/mass_driver/M in world)
		if(M.id == src.id)
			M.drive()

	sleep(50)

	for(var/obj/machinery/door/poddoor/M in world)
		if (M.id == src.id)
			spawn( 0 )
				M.close()
				return

	icon_state = "launcherbtt"
	active = 0

	return


/obj/machinery/door_control/vent_control
	name = "Remote Vent Control"
	icon_state = "leverbig00"
	desc = "A heavy hydraulic control switch for the core vents. Pushing it towards the reactor opens the vents, pulling it away from the reactor closes the vents."
	var/icon_toggled = "leverbig01"
	var/icon_normal = "leverbig0"
	var/toggled = "0"
	use_power = 0

	proc/update_state()
		if(toggled == "1")
			icon_state = icon_toggled
		else
			icon_state = icon_normal
		return

/obj/machinery/door_control/vent_control/power_change()
	return


/obj/machinery/door_control/vent_control/attack_ai(mob/user as mob)
	if (in_range(src, user) && get_dist(src, user) <= 1 && istype(user, /mob/living/silicon/robot))
		src.attack_hand(user)
		return
	else
		user << "This switch is operated by hydraulics, you cannot use it remotely."
		return	//lolno
	return	//just in case

/obj/machinery/door_control/attack_paw(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/door_control/vent_control/attack_hand(mob/user as mob)
	if(stat & (NOPOWER|BROKEN))
		return

	playsound(src.loc, 'sound/machines/warning-buzzer.ogg', 75)

	var/obj/item/device/radio/a = new /obj/item/device/radio(null)
	a.autosay("CORE VENTS CYCLING", "Core control computer")

	if(toggled == "1")
		toggled = "0"
	else
		toggled = "1"

	update_state()

	for(var/obj/machinery/door/poddoor/M in world)
		if (M.id == src.id)
			if (M.density)
				spawn( 0 )
					M.open()
					return
			else
				spawn( 0 )
					M.close()
					return

	src.add_fingerprint(usr)
	icon_state = icon_normal + toggled
	spawn(1 * tick_multiplier)
	return

