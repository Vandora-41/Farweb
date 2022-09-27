/*
	run_armor_check(a,b)
	args
	a:def_zone - What part is getting hit, if null will check entire body
	b:attack_flag - What type of attack, bullet, laser, energy, melee

	Returns
	0 - no block
	1 - halfblock
	2 - fullblock
*/

/mob/living/carbon/human/proc/armorRollPenetration(var/forceDamage, var/obj/usedweapon, var/def_zone = 0, var/attack_flag = "melee")
	var/weaponsharp = usedweapon ? is_sharp(usedweapon) : 0
	var/weaponedge = usedweapon ? has_edge(usedweapon) : 0
	var/weaponisblunt = usedweapon ? usedweapon.isBlunts() : 1

	var/protection = getarmor(def_zone, attack_flag)
	var/proba = 25

	proba += protection

	if(weaponisblunt)
		proba /= 1.35
	if(weaponsharp)
		proba *= 1.5
	if(weaponedge)
		proba *= 1.25

	proba -= forceDamage / 2

	if(proba <= 0)
		return 0
	if(protection <= 20)
		proba = protection
	if(proba <= 0)
		proba = 5
	if(proba >= 100)
		proba = 90

	if(prob(proba/1.5))
		return 2 //PROTEGEU
	if(prob(proba))
		return 1 //SOFTEN!!
	return 0

/mob/living/proc/getarmor(var/def_zone, var/type)
	return 0


/mob/living/bullet_act(var/obj/item/projectile/P, var/def_zone)
	var/obj/item/weapon/cloaking_device/C = locate((/obj/item/weapon/cloaking_device) in src)
	if(C && C.active)
		C.attack_self(src)//Should shut it off
		update_icons()
		src << "\blue Your [C.name] was disrupted!"
		Stun(2)

	flash_weak_pain()

	if(istype(equipped(),/obj/item/device/assembly/signaler))
		var/obj/item/device/assembly/signaler/signaler = equipped()
		if(signaler.deadman && prob(80))
			src.visible_message("\red [src] triggers their deadman's switch!")
			signaler.signal()

	//Armor
	var/proj_sharp = is_sharp(P)
	var/proj_edge = has_edge(P)
	var/absorb = run_armor_check(def_zone, P.flag, P, proj_edge)
	if ((proj_sharp || proj_edge) && prob(getarmor(def_zone, P.flag)))
		proj_sharp = 0
		proj_edge = 0

	var/som = pick('sound/projectilesnew/blt_flesh1.ogg', 'sound/projectilesnew/blt_flesh2.ogg', 'sound/projectilesnew/blt_flesh3.ogg')
	playsound(src, som, 300, 1)

	if(!P.nodamage)
		apply_damage(P.damage, P.damage_type, def_zone, absorb, 0, P, sharp=proj_sharp, edge=proj_edge)
	P.on_hit(src, absorb, def_zone)
	return absorb


//this proc handles being hit by a thrown atom
/mob/living/hitby(atom/movable/AM as mob|obj,var/speed = 5)//Standardization and logging -Sieve
	if(istype(AM,/obj/))
		var/obj/O = AM
		var/dtype = BRUTE
		if(istype(O,/obj/item/weapon))
			var/obj/item/weapon/W = O
			dtype = W.damtype
		var/throw_damage = O.throwforce*(speed/5)

		var/miss_chance = 15
		if (O.throw_source)
			var/distance = get_dist(O.throw_source, loc)
			miss_chance = min(15*(distance-2), 0)

		if (prob(miss_chance))
			visible_message("<span class='combatsmaller'>\The [O] misses [src] narrowly!</span>")
			return

		src.visible_message("<span class='hitboldsmaller'>[src]</span> <span class='hitsmaller'>has been hit by [O].</span>")
		var/armor = run_armor_check(null, "melee", O)

		if(armor < 2)
			apply_damage(throw_damage, dtype, null, armor, is_sharp(O), has_edge(O), O)

		O.throwing = 0		//it hit, so stop moving

		if(ismob(O.thrower))
			var/mob/M = O.thrower
			var/client/assailant = M.client
			if(assailant)
				src.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been hit with a [O], thrown by [M.name] ([assailant.ckey])</font>")
				M.attack_log += text("\[[time_stamp()]\] <font color='red'>Hit [src.name] ([src.ckey]) with a thrown [O]</font>")
				if(!istype(src,/mob/living/simple_animal/mouse))
					msg_admin_attack("[src.name] ([src.ckey]) was hit by a [O], thrown by [M.name] ([assailant.ckey]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[src.x];Y=[src.y];Z=[src.z]'>JMP</a>)")

		// Begin BS12 momentum-transfer code.
		if(O.throw_source && speed >= 15)
			var/obj/item/weapon/W = O
			var/momentum = speed/2
			var/dir = get_dir(O.throw_source, src)

			visible_message("\red [src] staggers under the impact!","\red You stagger under the impact!")
			src.throw_at(get_edge_target_turf(src,dir),1,momentum)

			if(!W || !src) return

			if(W.sharp) //Projectile is suitable for pinning.
				//Handles embedding for non-humans and simple_animals.
				O.loc = src
				src.embedded += O

				var/turf/T = near_wall(dir,2)

				if(T)
					src.loc = T
					visible_message("<span class='warning'>[src] is pinned to the wall by [O]!</span>","<span class='warning'>You are pinned to the wall by [O]!</span>")
					src.anchored = 1
					src.pinned += O
					src.verbs += /mob/proc/yank_out_object


/mob/living/proc/near_wall(var/direction,var/distance=1)
	var/turf/T = get_step(get_turf(src),direction)
	var/turf/last_turf = src.loc
	var/i = 1

	while(i>0 && i<=distance)
		if(T.density) //Turf is a wall!
			return last_turf
		i++
		last_turf = T
		T = get_step(T,direction)

	return 0

// End BS12 momentum-transfer code.

//Mobs on Fire
/mob/living/proc/IgniteMob()
	if(fire_stacks > 0 && !on_fire)
		on_fire = 1

		update_fire()

/mob/living/proc/ExtinguishMob()
	if(on_fire)
		on_fire = 0
		fire_stacks = 0

		update_fire()

/mob/living/proc/update_fire()
	return

/mob/living/proc/adjust_fire_stacks(add_fire_stacks) //Adjusting the amount of fire_stacks we have on person
    fire_stacks = Clamp(fire_stacks + add_fire_stacks, min = -20, max = 20)

/mob/living/proc/handle_fire()
	if(fire_stacks < 0)
		fire_stacks++ //If we've doused ourselves in water to avoid fire, dry off slowly
		fire_stacks = min(0, fire_stacks)//So we dry ourselves back to default, nonflammable.
	if(!on_fire)
		return 1
	if(on_fire && (getFireLoss() >= 500))
		death()
		if(ishuman(src))
			var/mob/living/carbon/human/H = src
			H.makeSkeleton()
		ExtinguishMob()
		return
	var/datum/gas_mixture/G = loc.return_air() // Check if we're standing in an oxygenless environment
	if(G.gas["oxygen"] < 3)
		ExtinguishMob() //If there's no oxygen in the tile we're on, put out the fire
		return
	var/turf/location = get_turf(src)
	location.hotspot_expose(700, 50, 1)

/mob/living/fire_act()
	adjust_fire_stacks(0.5)
	IgniteMob()

//Mobs on Fire end
