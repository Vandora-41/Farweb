/*
 * Contents:
 *		Welding mask
 *		Cakehat
 *		Ushanka
 *		Pumpkin head
 *		Kitty ears
 *
 */

/*
 * Welding mask
 */
/obj/item/clothing/head/welding
	name = "welding helmet"
	desc = "A head-mounted face cover designed to protect the wearer completely from space-arc eye."
	icon_state = "welding"
	flags = (FPRINT | TABLEPASS | HEADCOVERSEYES | HEADCOVERSMOUTH)
	item_state = "welding"
	m_amt = 3000
	g_amt = 1000
	var/up = 0
	armor = list(melee = 10, bullet = 0, laser = 0,energy = 0, bomb = 0, bio = 0, rad = 0)
	flags_inv = (HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE)
	icon_action_button = "action_welding"
	siemens_coefficient = 0.9

/obj/item/clothing/head/welding/attack_self()
	toggle()


/obj/item/clothing/head/welding/verb/toggle()
	set category = "Object"
	set name = "Adjust welding mask"
	set src in usr

	if(usr.canmove && !usr.stat && !usr.restrained())
		if(src.up)
			src.up = !src.up
			src.flags |= (HEADCOVERSEYES | HEADCOVERSMOUTH)
			flags_inv |= (HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE)
			icon_state = initial(icon_state)
			usr << "You flip the [src] down to protect your eyes."
		else
			src.up = !src.up
			src.flags &= ~(HEADCOVERSEYES | HEADCOVERSMOUTH)
			flags_inv &= ~(HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE)
			icon_state = "[initial(icon_state)]up"
			usr << "You push the [src] up out of your face."
		usr.update_inv_head()	//so our mob-overlays update


/*
 * Cakehat
 */
/obj/item/clothing/head/cakehat
	name = "cake-hat"
	desc = "It's tasty looking!"
	icon_state = "cake0"
	flags = FPRINT|TABLEPASS|HEADCOVERSEYES
	var/onfire = 0.0
	var/status = 0
	var/fire_resist = T0C+1300	//this is the max temp it can stand before you start to cook. although it might not burn away, you take damage
	var/processing = 0 //I dont think this is used anywhere.

/obj/item/clothing/head/cakehat/process()
	if(!onfire)
		processing_objects.Remove(src)
		return

	var/turf/location = src.loc
	if(istype(location, /mob/))
		var/mob/living/carbon/human/M = location
		if(M.l_hand == src || M.r_hand == src || M.head == src)
			location = M.loc

	if (istype(location, /turf))
		location.hotspot_expose(700, 1)

/obj/item/clothing/head/cakehat/attack_self(mob/user as mob)
	if(status > 1)	return
	src.onfire = !( src.onfire )
	if (src.onfire)
		src.force = 3
		src.damtype = "fire"
		src.icon_state = "cake1"
		processing_objects.Add(src)
	else
		src.force = null
		src.damtype = "brute"
		src.icon_state = "cake0"
	return


/*
 * Ushanka
 */
/obj/item/clothing/head/ushanka
	name = "ushanka"
	icon_state = "ushankadown"
	item_state = "ushankadown"
	flags_inv = HIDEEARS
	armor = list(melee = 20, bullet = 0, laser = 0,energy = 0, bomb = 0, bio = 0, rad = 0)
	item_worth = 3
	var/down = TRUE
	var/patterniconname = "ushanka"

/obj/item/clothing/head/ushanka/nushanka
	icon_state = "nushankadown"
	item_state = "nushankadown"
	patterniconname = "nushanka"

/obj/item/clothing/head/ushanka/soviet
	icon_state = "sovietushankadown"
	item_state = "sovietushankadown"
	patterniconname = "sovietushanka"

/obj/item/clothing/head/ushanka/attack_self(mob/user as mob)
	if(down)
		down = FALSE
		src.icon_state = "[patterniconname]up"
		src.item_state = "[patterniconname]up"
		to_chat(user, "You raise the ear flaps on the ushanka.")
		return
	else
		src.icon_state = "[patterniconname]down"
		src.item_state = "[patterniconname]down"
		to_chat(user, "You lower the ear flaps on the ushanka.")
		down = TRUE
		return

/obj/item/clothing/head/ushanka/RightClick()
	attack_self(usr)

/*
 * Pumpkin head
 */
/obj/item/clothing/head/pumpkinhead
	name = "carved pumpkin"
	desc = "A jack o' lantern! Believed to ward off evil spirits."
	icon_state = "pumpkin"//Could stand to be renamed
	item_state = "pumpkin"
	item_color = "pumpkin"
	flags = FPRINT | TABLEPASS | HEADCOVERSEYES | HEADCOVERSMOUTH | BLOCKHAIR
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE