/mob/living/simple_animal/hostile/syndicate
	name = "Syndicate Operative"
	desc = "Death to Nanotrasen."
	icon_state = "syndicate"
	icon_living = "syndicate"
	icon_dead = "syndicate_dead"
	icon_gib = "syndicate_gib"
	speak_chance = 0
	turns_per_move = 5
	response_help = "pokes the"
	response_disarm = "shoves the"
	response_harm = "hits the"
	speed = 4
	stop_automated_movement_when_pulled = 0
	maxHealth = 100
	health = 100
	harm_intent_damage = 5
	melee_damage_lower = 10
	melee_damage_upper = 10
	attacktext = "punches"
	a_intent = "harm"
	var/weapon1
	var/weapon2
	min_oxy = 5
	max_oxy = 0
	min_tox = 0
	max_tox = 1
	min_co2 = 0
	max_co2 = 5
	min_n2 = 0
	max_n2 = 0
	unsuitable_atoms_damage = 15
	wall_smash = 1
	faction = "syndicate"
	status_flags = CANPUSH

/mob/living/simple_animal/hostile/syndicate/Die()
	..()
	if(weapon1)
		new weapon1 (src.loc)
	if(weapon2)
		new weapon2 (src.loc)
	del src
	return

///////////////Sword and shield////////////

/mob/living/simple_animal/hostile/syndicate/melee
	melee_damage_lower = 20
	melee_damage_upper = 25
	icon_state = "syndicatemelee"
	icon_living = "syndicatemelee"
	weapon1 = /obj/item/weapon/melee/energy/sword/red
	attacktext = "slashes"
	status_flags = 0

/mob/living/simple_animal/hostile/syndicate/melee/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(O.force)
		if(prob(80))
			var/damage = O.force
			if (O.damtype == HALLOSS)
				damage = 0
			health -= damage
			visible_message("\red \b [src] has been attacked with the [O] by [user]. ")
		else
			visible_message("\red \b [src] blocks the [O] with its shield! ")
	else
		usr << "\red This weapon is ineffective, it does no damage."
		visible_message("\red [user] gently taps [src] with the [O]. ")


/mob/living/simple_animal/hostile/syndicate/melee/bullet_act(var/obj/item/projectile/Proj)
	if(!Proj)	return
	if(prob(65))
		src.health -= Proj.damage
	else
		visible_message("\red <B>[src] blocks [Proj] with its shield!</B>")
	return 0


/mob/living/simple_animal/hostile/syndicate/melee/space
	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0
	icon_state = "syndicatemeleespace"
	icon_living = "syndicatemeleespace"
	name = "Syndicate Commando"
	speed = 0

/mob/living/simple_animal/hostile/syndicate/melee/space/Process_Spacemove(var/check_drift = 0)
	return

/mob/living/simple_animal/hostile/syndicate/ranged
	ranged = 1
	rapid = 1
	icon_state = "syndicateranged"
	icon_living = "syndicateranged"
	casingtype = /obj/item/ammo_casing/a12mm
	projectilesound = 'sound/weapons/Gunshot_smg.ogg'
	projectiletype = /obj/item/projectile/bullet/midbullet2

/mob/living/simple_animal/hostile/syndicate/ranged/space
	icon_state = "syndicaterangedpsace"
	icon_living = "syndicaterangedpsace"
	name = "Syndicate Commando"
	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0
	speed = 0

/mob/living/simple_animal/hostile/syndicate/ranged/space/Process_Spacemove(var/check_drift = 0)
	return



/mob/living/simple_animal/hostile/viscerator
	name = "viscerator"
	desc = "A small, twin-bladed machine capable of inflicting very deadly lacerations."
	icon = 'icons/mob/critter.dmi'
	icon_state = "viscerator_attack"
	icon_living = "viscerator_attack"
	pass_flags = PASSTABLE
	health = 15
	maxHealth = 15
	melee_damage_lower = 15
	melee_damage_upper = 15
	attacktext = "cuts"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	faction = "syndicate"
	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0
	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread

	attackby(obj/item/weapon/W as obj, mob/user as mob)
		..()
		if(istype(W,/obj/item/weapon/crowbar/red))
			health -= 8
		s.set_up(3, 1, src)
		s.start()

/mob/living/simple_animal/hostile/viscerator/Life()
	..()
	if(health<0)
		Die()
		return
	if(FindTarget())
		var/Tg = PickTarget()
		if(Tg & CanAttack(Tg))
			MoveToTarget()

/mob/living/simple_animal/hostile/viscerator/Die()
	..()
	visible_message("\red <b>[src]</b> is smashed into pieces!")
	s.set_up(3, 1, src)
	s.start()

	new/obj/effect/decal/remains/robot(src.loc)
	qdel(src)
	return

/mob/living/simple_animal/hostile/viscerator/Bump(atom/A as mob|obj)

	var/damage = rand(15,25)
	custom_emote(1, "slashes at [A]")
	if(ishuman(A))
		var/mob/living/carbon/human/H = A
		var/dam_zone = pick("chest", "l_hand", "r_hand", "l_leg", "r_leg")
		var/datum/organ/external/affecting = H.get_organ(ran_zone(dam_zone))
		H.apply_damage(damage, BRUTE, affecting, H.run_armor_check(affecting, "melee"), sharp=1, edge=1)
	else if(isliving(A))
		var/mob/living/L = target
		L.adjustBruteLoss(damage)
		return L
	else if(istype(A,/obj/mecha))
		var/obj/mecha/M = target
		M.attack_animal(src)
		return M
	else if(istype(A,/obj/structure/window))
		var/obj/structure/window/W = A
		W.hit(5)
		return


