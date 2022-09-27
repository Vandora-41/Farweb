//These procs handle putting s tuff in your hand. It's probably best to use these rather than setting l_hand = ...etc
//as they handle all relevant stuff like adding it to the player's screen and updating their overlays.

//Returns the thing in our active hand
/mob/proc/get_active_hand()
	if(issilicon(src))
		if(isrobot(src))
			if(src:module_active)
				return src:module_active
	else
		if(hand)	return l_hand
		else		return r_hand

/mob/proc/get_other_hand()
	if(issilicon(src))
		if(isrobot(src))
			if(src:module_active)
				return src:module_active
	else
		if(hand)	return r_hand
		else		return l_hand

//Returns the thing in our inactive hand
/mob/proc/get_inactive_hand()
	if(hand)	return r_hand
	else		return l_hand

//Puts the item into your l_hand if possible and calls all necessary triggers/updates. returns 1 on success.
/mob/proc/put_in_l_hand(var/obj/item/W)
	if(!istype(W))		return 0
	if(!l_hand)
		W.loc = src		//TODO: move to equipped?
		l_hand = W
		W.layer = 20	//TODO: move to equipped?
		W.plane = 30
		W.appearance_flags |= NO_CLIENT_COLOR

//		l_hand.screen_loc = ui_lhand
		W.equipped(src,slot_l_hand)
		if(client)	client.screen |= W
		if(pulling == W) stop_pulling()
		update_inv_l_hand()
		return 1
	return 0

//Puts the item into your r_hand if possible and calls all necessary triggers/updates. returns 1 on success.
/mob/proc/put_in_r_hand(var/obj/item/W)
	if(!istype(W))		return 0
	if(!r_hand)
		W.loc = src
		r_hand = W
		W.layer = 20
		W.plane = 30
		W.appearance_flags |= NO_CLIENT_COLOR

//		r_hand.screen_loc = ui_rhand
		W.equipped(src,slot_r_hand)
		if(client)	client.screen |= W
		if(pulling == W) stop_pulling()
		update_inv_r_hand()
		return 1
	return 0

//Puts the item into our active hand if possible. returns 1 on success.
/mob/proc/put_in_active_hand(var/obj/item/W)
	hud_used?.add_inventory_overlay()
	if(hand)	return put_in_l_hand(W)
	else		return put_in_r_hand(W)

//Puts the item into our inactive hand if possible. returns 1 on success.
/mob/proc/put_in_inactive_hand(var/obj/item/W)
	hud_used.add_inventory_overlay()
	if(hand)	return put_in_r_hand(W)
	else		return put_in_l_hand(W)

/mob/proc/vamp_check(var/obj/item/W)
	if(!ishuman(src))
		return FALSE
	var/mob/living/carbon/human/H = src
	var/vamp_hand = H.l_hand ? "l_hand" : "r_hand" //I hate this so much.
	if(H.isVampire)
		if(W.silver && !H.gloves)
			if(vamp_hand)
				to_chat(H, pick("<span class='combatglow'><b>GET THIS OUT OF HERE!</b></span>", "<span class='combatglow'><b>ACCURSED SILVER!</b></span>", "<span class='combatglow'><b>IT BURNS! IT BURNS!</b></span>"))
				H.drop_from_inventory(H.get_active_hand())
				H.apply_damage(rand(5, 10), BRUTE, vamp_hand)
				H.flash_pain()
				H.rotate_plane(1)
				return TRUE
	return FALSE

//Puts the item our active hand if possible. Failing that it tries our inactive hand. Returns 1 on success.
//If both fail it drops it on the floor and returns 0.
//This is probably the main one you need to know :)
/mob/proc/put_in_hands(var/obj/item/W)
	if(!W)		return 0
	if(vamp_check(W))
		return 0
	if(put_in_active_hand(W))
		update_inv_l_hand()
		update_inv_r_hand()
		return 1
	else if(put_in_inactive_hand(W))
		update_inv_l_hand()
		update_inv_r_hand()
		return 1
	else
		W.loc = get_turf(src)
		W.layer = initial(W.layer)
		W.plane = initial(W.plane)
		W.appearance_flags = initial(W.appearance_flags)

		W.dropped()
		return 0
	hud_used?.add_inventory_overlay()


/mob/proc/drop_item_v()		//this is dumb.
	if(stat == CONSCIOUS && isturf(loc))
		return drop_item()
	return 0


/mob/proc/drop_from_inventory(var/obj/item/W)
	if(W)
		if(istype(W, /mob))
			return
		if(client)	client.screen -= W
		u_equip(W)
		if(!W) return 1 // self destroying objects (tk, grabs)
		W.layer = initial(W.layer)
		W.plane = initial(W.plane)
		W.appearance_flags = initial(W.appearance_flags)

		W.loc = loc

		var/turf/T = get_turf(loc)
		if(isturf(T))
			T.Entered(W)

		W.dropped(src)
		hud_used?.add_inventory_overlay()
		update_icons()
		return 1
	return 0

/mob/proc/transfer_equiped_item_to(var/obj/item/W, var/new_loc)
	if(W)
		if(istype(W, /mob))
			return
		if(client)	client.screen -= W
		u_equip(W)
		if(!W) return 1 // self destroying objects (tk, grabs)
		W.layer = initial(W.layer)
		W.plane = initial(W.plane)
		W.appearance_flags = initial(W.appearance_flags)

		W.loc = new_loc
		var/turf/T = get_turf(new_loc)
		if(isturf(T))
			T.Entered(W)
		hud_used?.add_inventory_overlay()
		update_icons()
		return 1
	return 0

//Drops the item in our left hand
/mob/proc/drop_l_hand(var/atom/Target)
	if(l_hand)
		if(client)	client.screen -= l_hand
		l_hand.layer = initial(l_hand.layer)
		l_hand.plane = initial(l_hand.plane)
		l_hand.appearance_flags = initial(l_hand.appearance_flags)


		if(Target)	l_hand.loc = Target.loc
		else		l_hand.loc = loc

		var/turf/T = get_turf(loc)
		if(isturf(T))
			T.Entered(l_hand)

		l_hand.dropped(src)
		l_hand = null
		update_inv_l_hand()
		src.update_inv_back()
		return 1
	return 0

//Drops the item in our right hand
/mob/proc/drop_r_hand(var/atom/Target)
	if(r_hand)
		if(client)	client.screen -= r_hand
		r_hand.layer = initial(r_hand.layer)
		r_hand.plane = initial(r_hand.plane)
		r_hand.appearance_flags = initial(r_hand.appearance_flags)



		if(Target)	r_hand.loc = Target.loc
		else		r_hand.loc = loc

		var/turf/T = get_turf(Target)
		if(istype(T))
			T.Entered(r_hand)

		r_hand.dropped(src)
		r_hand = null
		update_inv_r_hand()
		src.update_inv_back()
		return 1
	return 0

//Drops the item in our active hand.
/mob/proc/drop_item(var/atom/Target, var/sound = 1)
	if(sound)
		if(!istype(Target, /obj/structure/rack))
			make_item_drop_sound()
	if(istype(src, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = src
		var/obj/item/I = get_active_hand()
		if(H.malabares && H.malabares.icon_state == I.icon_state)
			qdel(H.malabares)
	if(hand)
		return drop_l_hand(Target)
	else		return drop_r_hand(Target)


/mob/proc/drop_item_vv(var/atom/Target, var/sound = 1)
	if(sound)
		make_item_drop_sound()
	if(hand)
		return drop_r_hand(Target)
	else		return drop_l_hand(Target)

/mob/proc/make_item_drop_sound()
	var/obj/item/I = get_active_hand()
	spawn(1)
		if(!I)
			return
		if(I.name)
			I.visible_message("<span class='passiveboldsmaller'>[capitalize(I.name)]</span> <span class='passivesmaller'>falls on \the [src.loc].</span>")
		if(I.drop_sound)
			playsound(I, I.drop_sound, 25, 0)
		if(istype(I, /obj/item/weapon/gun))//Snowflake check yeah, but I'm tired of people getting fucking shot when they pull their gun out from their inventory.
			var/obj/item/weapon/gun/G = I
			G.check_gun_safety(src)
		if(src?:loc?:liquid)
			src?:loc?:liquid?:update_atoms()
		src.update_inv_back()





//TODO: phase out this proc
/mob/proc/before_take_item(var/obj/item/W)	//TODO: what is this?
	W.loc = null
	W.layer = initial(W.layer)
	W.plane = initial(W.plane)
	W.appearance_flags = initial(appearance_flags)

	u_equip(W)
	hud_used.add_inventory_overlay()
	update_icons()
	return


/mob/proc/u_equip(W as obj)
	if (W == r_hand)
		r_hand = null
		update_inv_r_hand(0)
	else if (W == l_hand)
		l_hand = null
		update_inv_l_hand(0)
	else if (W == back)
		back = null
		update_inv_back(0)
	else if (W == wear_mask)
		wear_mask = null
		update_inv_wear_mask(0)
	return


//Attemps to remove an object on a mob.  Will not move it to another area or such, just removes from the mob.
/mob/proc/remove_from_mob(var/obj/O)
	src.u_equip(O)
	if (src.client)
		src.client.screen -= O
	O.layer = initial(O.layer)
	O.plane = initial(O.plane)
	O.appearance_flags = initial(O.appearance_flags)

	O.screen_loc = null
	if(hud_used)
		hud_used.add_inventory_overlay()
	return 1


//Outdated but still in use apparently. This should at least be a human proc.
/mob/proc/get_equipped_items()
	var/list/items = new/list()

	if(hasvar(src,"back")) if(src:back) items += src:back
	if(hasvar(src,"belt")) if(src:belt) items += src:belt
	if(hasvar(src,"l_ear")) if(src:l_ear) items += src:l_ear
	if(hasvar(src,"r_ear")) if(src:r_ear) items += src:r_ear
	if(hasvar(src,"glasses")) if(src:glasses) items += src:glasses
	if(hasvar(src,"gloves")) if(src:gloves) items += src:gloves
	if(hasvar(src,"head")) if(src:head) items += src:head
	if(hasvar(src,"shoes")) if(src:shoes) items += src:shoes
	if(hasvar(src,"wear_id")) if(src:wear_id) items += src:wear_id
	if(hasvar(src,"wear_mask")) if(src:wear_mask) items += src:wear_mask
	if(hasvar(src,"wear_suit")) if(src:wear_suit) items += src:wear_suit
//	if(hasvar(src,"w_radio")) if(src:w_radio) items += src:w_radio  commenting this out since headsets go on your ears now PLEASE DON'T BE MAD KEELIN
	if(hasvar(src,"w_uniform")) if(src:w_uniform) items += src:w_uniform

	//if(hasvar(src,"l_hand")) if(src:l_hand) items += src:l_hand
	//if(hasvar(src,"r_hand")) if(src:r_hand) items += src:r_hand

	return items

/** BS12's proc to get the item in the active hand. Couldn't find the /tg/ equivalent. **/
/mob/proc/equipped()
	if(issilicon(src))
		if(isrobot(src))
			if(src:module_active)
				return src:module_active
	else
		if (hand)
			return l_hand
		else
			return r_hand
		return

/mob/living/carbon/human/proc/equip_if_possible(obj/item/W, slot, del_on_fail = 1) // since byond doesn't seem to have pointers, this seems like the best way to do this :/
	//warning: icky code
	var/equipped = 0
	switch(slot)
		if(slot_back)
			if(!src.back)
				src.back = W
				equipped = 1
		if(slot_wear_mask)
			if(!src.wear_mask)
				src.wear_mask = W
				equipped = 1
		if(slot_handcuffed)
			if(!src.handcuffed)
				src.handcuffed = W
				equipped = 1
		if(slot_l_hand)
			if(!src.l_hand)
				src.l_hand = W
				equipped = 1
		if(slot_r_hand)
			if(!src.r_hand)
				src.r_hand = W
				equipped = 1
		if(slot_belt)
			if(!src.belt && src.w_uniform)
				src.belt = W
				equipped = 1
		if(slot_wear_id)
			if(!src.wear_id)
				src.wear_id = W
				equipped = 1
		if(slot_l_ear)
			if(!src.l_ear)
				src.l_ear = W
				equipped = 1
		if(slot_r_ear)
			if(!src.r_ear)
				src.r_ear = W
				equipped = 1
		if(slot_glasses)
			if(!src.glasses)
				src.glasses = W
				equipped = 1
		if(slot_gloves)
			if(!src.gloves)
				src.gloves = W
				equipped = 1
		if(slot_head)
			if(!src.head)
				src.head = W
				equipped = 1
		if(slot_shoes)
			if(!src.shoes)
				src.shoes = W
				equipped = 1
		if(slot_wear_suit)
			if(!src.wear_suit)
				src.wear_suit = W
				equipped = 1
		if(slot_w_uniform)
			if(!src.w_uniform)
				src.w_uniform = W
				equipped = 1
		if(slot_l_store)
			if(!src.l_store && src.w_uniform)
				src.l_store = W
				equipped = 1
		if(slot_r_store)
			if(!src.r_store && src.w_uniform)
				src.r_store = W
				equipped = 1
		if(slot_s_store)
			if(!src.s_store && src.wear_suit)
				src.s_store = W
				equipped = 1
		if(slot_wrist_r)
			if(!src.wrist_r)
				src.wrist_r = W
				equipped = 1
		if(slot_wrist_l)
			if(!src.wrist_l)
				src.wrist_l = W
				equipped = 1
		if(slot_amulet)
			if(!src.amulet)
				src.amulet = W
				equipped = 1
		if(slot_back2)
			if(!src.back2)
				src.back2 = W
				equipped = 1
		if(slot_in_backpack)
			if (src.back && istype(src.back, /obj/item/weapon/storage/backpack))
				var/obj/item/weapon/storage/backpack/B = src.back
				if(B.contents.len < B.storage_slots && W.w_class <= B.max_w_class)
					W.loc = B
					equipped = 1

	if(equipped)
		W.layer = 20
		W.plane = 30
		W.appearance_flags |= NO_CLIENT_COLOR
		if(src.back && W.loc != src.back)
			W.loc = src
	else
		if (del_on_fail)
			qdel(W)
	return equipped

