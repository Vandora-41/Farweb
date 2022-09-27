///////////////////////////////////////
//Contents: Ladders, Hatches, Stairs.//
///////////////////////////////////////

/obj/multiz
	icon = 'icons/obj/structures.dmi'
	density = 0
	opacity = 0
	anchored = 1

	CanPass(obj/mover, turf/source, height, airflow)
		return airflow || !density


/obj/multiz/ladder
	icon_state = "ladderdown"
	name = "ladder"
	desc = "A ladder.  You climb up and down it."

	var/d_state = 1
	var/obj/multiz/target

	New()
		ladder_list.Add(src)
		. = ..()

	proc/connect()
		if(icon_state == "ladderdown") // the upper will connect to the lower
			d_state = 1
			var/turf/controllerlocation = locate(1, 1, z)
			for(var/obj/effect/landmark/zcontroller/controller in controllerlocation)
				if(controller.down)
					var/turf/below = locate(src.x, src.y, controller.down_target)
					for(var/obj/multiz/ladder/L in below)
						if(L.icon_state == "ladderup")
							target = L
							L.target = src
							d_state = 0
							break
		return

/*	ex_act(severity)
		switch(severity)
			if(1.0)
				if(icon_state == "ladderup" && prob(10))
					Destroy()
			if(2.0)
				if(prob(50))
					Destroy()
			if(3.0)
				Destroy()
		return*/

	Destroy()
		spawn(1)
			if(target && icon_state == "ladderdown")
				del target
		return ..()

	attack_paw(var/mob/M)
		return attack_hand(M)

/*	attackby(obj/item/C as obj, mob/user as mob)
		(..)

 construction commented out for balance concerns
		if (!target && istype(C, /obj/item/stack/rods))
			var/turf/controllerlocation = locate(1, 1, z)
			var/found = 0
			var/obj/item/stack/rods/S = C
			if(S.amount < 2)
				user << "You dont have enough rods to finish the ladder."
				return
			for(var/obj/effect/landmark/zcontroller/controller in controllerlocation)
				if(controller.down)
					found = 1
					var/turf/below = locate(src.x, src.y, controller.down_target)
					var/blocked = 0
					for(var/atom/A in below.contents)
						if(A.density)
							blocked = 1
							break
					if(!blocked && !istype(below, /turf/simulated/wall))
						var/obj/multiz/ladder/X = new /obj/multiz/ladder(below)
						S.amount = S.amount - 2
						if(S.amount == 0) S.Destroy()
						X.icon_state = "ladderup"
						connect()
						user << "You finish the ladder."
					else
						user << "The area below is blocked."
			if(!found)
				user << "You cant build a ladder down there."
			return

		else if  (icon_state == "ladderdown" && d_state == 0 && istype(C, /obj/item/weapon/wrench))
			user << "<span class='notice'>You start loosening the anchoring bolts which secure the ladder to the frame.</span>"
			playsound(src.loc, 'sound/items/Ratchet.ogg', 100, 1)

			sleep(30)
			if(!user || !C)	return

			src.d_state = 1
			if(target)
				var/obj/item/stack/rods/R = new /obj/item/stack/rods(target.loc)
				R.amount = 2
				target.Destroy()

				user << "<span class='notice'>You remove the bolts anchoring the ladder.</span>"
			return

		else if  (icon_state == "ladderdown" && d_state == 1 && istype(C, /obj/item/weapon/weldingtool) )
			var/obj/item/weapon/weldingtool/WT = C
			if( WT.remove_fuel(0,user) )

				user << "<span class='notice'>You begin to remove the ladder.</span>"
				playsound(src.loc, 'sound/items/Welder.ogg', 100, 1)

				sleep(60)
				if(!user || !WT || !WT.isOn())	return

				var/obj/item/stack/sheet/metal/S = new /obj/item/stack/sheet/metal( src )
				S.amount = 2
				user << "<span class='notice'>You remove the ladder and close the hole.</span>"
				Destroy()
			else
				user << "<span class='notice'>You need more welding fuel to complete this task.</span>"
			return

		else
			src.attack_hand(user)
			return*/

	attack_hand(var/mob/M)
		var/turf/T = target.loc
		if(M.a_intent == "grab")		// && get_dist(M, src) <= 1
			var/atom/movable/chosen
			var/list/avaluable_contents
			avaluable_contents = new/list()
			for(var/obj/C in T.contents)
				if(!C.anchored)
					avaluable_contents.Add(C)
			for(var/mob/living/carbon/X in T.contents)
				if(!X.buckled)
					avaluable_contents.Add(X)
			chosen = input("What would you like to pull [src.icon_state == "ladderup" ? "down" : "up"]?", "Cross-ladder Pull", null) as obj|mob in avaluable_contents
			if(chosen)
				M.visible_message("\blue \The [M] starts pulling [chosen] [src.icon_state == "ladderup" ? "down" : "up"] \the [src]!", "\blue You start pulling [chosen] [src.icon_state == "ladderup"  ? "down" : "up"] \the [src]!", "You hear some grunting, and clanging of a metal ladder being used.")
				if(iscarbon(chosen))
					to_chat(chosen, "\red A hand appears from \the [src] and starts pulling you inside!")
				if(do_after(M, 50))
					if(chosen.loc == T)
						chosen.Move(src.loc)
						M.visible_message("\blue \The [M] pulls [chosen] [src.icon_state == "ladderup" ? "down" : "up"] \the [src]!", "\blue You pull [chosen] [src.icon_state == "ladderup"  ? "down" : "up"] \the [src]!", "You hear some grunting, and clanging of a metal ladder being used.")
						return
					else
						to_chat(M, "\red \The [chosen] moved out of range!")
						return
				else
					return

		if(!target || !istype(target.loc, /turf))
			to_chat(M, "\ red The ladder is incomplete and can't be climbed.")
		else
			var/blocked = 0
			for(var/atom/A in T.contents)
				if(A.density && !istype(A, /mob))
					blocked = 1
					break
			if(blocked || istype(T, /turf/simulated/wall))
				to_chat(M, "\red Something is blocking the ladder.")
			else
				M.visible_message("<b>[M.name]</b> starts to climb [src.icon_state == "ladderup" ? "up" : "down"] \the [src]!")
				playsound(src, 'sound/lfwbsounds/ladder.ogg', 70, 1)
				if(do_after(M, 15))
					M.Move(target.loc)

	attackby(obj/item/weapon/W as obj, mob/M as mob)
		if (istype(W, /obj/item/weapon/grab) && get_dist(src,M)<2)
			var/obj/item/weapon/grab/G = W
			if(G.state >= 2)
				if(!target || !istype(target.loc, /turf))
					to_chat(M,"\red The ladder is incomplete and can't be climbed.")
					return
				var/turf/T = target.loc
				var/blocked = 0
				for(var/atom/A in T.contents)
					if(A.density && !istype(A, /mob))
						blocked = 1
						break
				if(blocked || istype(T, /turf/simulated/wall))
					to_chat(M,"\red Something is blocking the ladder.")
				else
					M.visible_message("\blue \The [M] puts [G.affecting] [src.icon_state == "ladderup" ? "up" : "down"] \the [src]!", "\blue You put [G.affecting] [src.icon_state == "ladderup"  ? "up" : "down"] \the [src]!", "You hear some grunting, and clanging of a metal ladder being used.")
					G.affecting.Move(target.loc)
					qdel(W)



/*	hatch
		icon_state = "hatchdown"
		name = "hatch"
		desc = "A hatch. You climb down it, and it will automatically seal against pressure loss behind you."
		top_icon_state = "hatchdown"
		var/top_icon_state_open = "hatchdown-open"
		var/top_icon_state_close = "hatchdown-close"

		bottom_icon_state = "ladderup"

		var/image/green_overlay
		var/image/red_overlay

		var/active = 0

		New()
			. = ..()
			red_overlay = image(icon, "red-ladderlight")
			green_overlay = image(icon, "green-ladderlight")

		attack_hand(var/mob/M)

			if(!target || !istype(target.loc, /turf))
				del src

			if(active)
				M << "That [src] is being used."
				return // It is a tiny airlock, only one at a time.

			active = 1
			var/obj/multiz/ladder/hatch/top_hatch = target
			var/obj/multiz/ladder/hatch/bottom_hatch = src
			if(icon_state == top_icon_state)
				top_hatch = src
				bottom_hatch = target

			flick(top_icon_state_open, top_hatch)
			bottom_hatch.overlays += green_overlay

			spawn(7)
				if(!target || !istype(target.loc, /turf))
					del src
				if(M.z == z && get_dist(src,M) <= 1)
					var/list/adjacent_to_me = global_adjacent_z_levels["[z]"]
					M.visible_message("\blue \The [M] scurries [target.z == adjacent_to_me["up"] ? "up" : "down"] \the [src]!", "You scramble [target.z == adjacent_to_me["up"] ? "up" : "down"] \the [src]!", "You hear some grunting, and a hatch sealing.")
					M.Move(target.loc)
				flick(top_icon_state_close,top_hatch)
				bottom_hatch.overlays -= green_overlay
				bottom_hatch.overlays += red_overlay

				spawn(7)
					top_hatch.icon_state = top_icon_state
					bottom_hatch.overlays -= red_overlay
					active = 0*/

/*
/obj/multiz/stairs
	name = "Stairs"
	desc = "Stairs.  You walk up and down them."
	icon_state = "rampbottom"
	var/obj/multiz/stairs/connected
	var/turf/target

	New()
		..()
		var/turf/cl= locate(1, 1, src.z)
		for(var/obj/effect/landmark/zcontroller/c in cl)
			if(c.up)
				var/turf/O = locate(src.x, src.y, c.up_target)
				if(istype(O, /turf/space))
					O.ChangeTurf(/turf/simulated/floor/open)

		spawn(1)
			for(var/dir in cardinal)
				var/turf/T = get_step(src.loc,dir)
				for(var/obj/multiz/stairs/S in T)
					if(S && S.icon_state == "rampbottom" && !S.connected)
						S.dir = dir
						src.dir = dir
						S.connected = src
						src.connected = S
						src.icon_state = "ramptop"
						src.density = 1
						var/turf/controllerlocation = locate(1, 1, src.z)
						for(var/obj/effect/landmark/zcontroller/controller in controllerlocation)
							if(controller.up)
								var/turf/above = locate(src.x, src.y, controller.up_target)
								if(istype(above,/turf/space) || istype(above,/turf/simulated/floor/open))
									src.target = above
						break
				if(target)
					break

	Bumped(var/atom/movable/M)
		if(connected && target && istype(src, /obj/multiz/stairs) && locate(/obj/multiz/stairs) in M.loc)
			var/obj/multiz/stairs/Con = locate(/obj/multiz/stairs) in M.loc
			if(Con == src.connected) //make sure the atom enters from the approriate lower stairs tile
				M.Move(target)
		return
*/


//Spizjeno by guap


/obj/multiz
	icon = 'icons/obj/structures.dmi'
	density = 0
	opacity = 0
	anchored = 1
	var/istop = 1

	CanPass(obj/mover, turf/source, height, airflow)
		return airflow || !density

/obj/multiz/proc/targetZ()
	return src.z + (istop ? 1 : -1)


/obj/multiz/stairs
	name = "Stairs"
	desc = "Stairs.  You walk up and down them."
	icon_state = "ramptop"
	layer = 2.4
	flammable = 0

/obj/multiz/stairs/enter/bottom
	istop = 0
	icon_state = "rampbottom"

/obj/multiz/stairs/enter/New()
	..()
	src.icon_state = ""

/obj/multiz/stairs/active
	density = 1
	opacity = 0
	icon_state = "rampbottom"

/obj/multiz/stairs/active/wood
	icon_state = "wramp"

/obj/multiz/stairs/active/caveramp
	icon_state = "caveramp"

/obj/multiz/stairs/active/Bumped(var/atom/movable/M)
	if(!M.gravitydep)
		return
	if(istype(src, /obj/multiz/stairs/active/bottom) && !locate(/obj/multiz/stairs/enter) in M.loc)
		return //If on bottom, only let them go up stairs if they've moved to the entry tile first.
	//If it's the top, they can fall down just fine.
	if(ismob(M) && M:client)
		M:client.moving = 1
	var/turf/T = locate(M.x, M.y, targetZ())
	if(!T) return;
	M.forceMove(locate(src.x, src.y, targetZ()))
	if(isliving(M))
		var/mob/living/L = M
		if(L.pulling)
			L.pulling.forceMove(locate(src.x, src.y, targetZ()))
		if(L.client)
			if(istype(src, /obj/multiz/stairs/active/bottom))
				to_chat(L,"<i>You climb down the stairs.</i>")
			else
				to_chat(L,"<i>You climb up the stairs.</i>")
	if (ismob(M) && M:client)
		M:client.moving = 0

/obj/multiz/stairs/active/Click()
	if(!istype(usr,/mob/dead/observer))
		return ..()
	usr.client.moving = 1
	usr.Move(locate(src.x, src.y, targetZ()))
	usr.client.moving = 0

/obj/multiz/stairs/active/bottom
	istop = 0
	opacity = 0
	icon_state = "ramptop"

/obj/multiz/stairs/active/bottom/wood
	icon_state = "wramp"

/obj/multiz/stairs/active/bottom/caveramp
	icon_state = "caveramp"

/obj/multiz/attack_tk(mob/user as mob)
	return