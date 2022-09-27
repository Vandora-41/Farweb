/obj/structure/table_frame
	name = "table frame"
	desc = "Four metal legs with four framing rods for a table. You could easily pass through this."
	icon = 'icons/obj/structures.dmi'
	icon_state = "table_frame"
	density = 0
	anchored = 0
	layer = 2.8
	var/framestack = /obj/item/stack/sheet/metal
	var/framestackamount = 1

/obj/structure/table_frame/attackby(var/obj/item/I, mob/user, params)
	if(istype(I, /obj/item/weapon/wrench))
		user << "<span class='notice'>You start disassembling [src]...</span>"
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
		if(do_after(user, 30))
			for(var/i = 1, i <= framestackamount, i++)
				new framestack(get_turf(src))
			qdel(src)
			return
	if(istype(I, /obj/item/stack/sheet/plasteel))
		var/obj/item/stack/sheet/plasteel/P = I
		user << "<span class='notice'>You start adding [P] to [src]...</span>"
		if(do_after(user, 50))
			new /obj/structure/table/reinforced(src.loc)
			qdel(src)
			P.use(1)
			return
	if(istype(I, /obj/item/stack/sheet/metal))
		var/obj/item/stack/sheet/metal/M = I
		user << "<span class='notice'>You start adding [M] to [src]...</span>"
		if(do_after(user, 20))
			new /obj/structure/table(src.loc)
			qdel(src)
			M.use(1)
			return
	if(istype(I, /obj/item/stack/sheet/glass))
		var/obj/item/stack/sheet/glass/G = I
		user << "<span class='notice'>You start adding [G] to [src]...</span>"
		if(do_after(user, 20))
			new /obj/structure/table/glass(src.loc)
			qdel(src)
			G.use(1)
			return
