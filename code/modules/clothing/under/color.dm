/obj/item/clothing/under/rank/migrant
	name = "clothes"
	desc = ""
	icon_state = "migrant"
	item_state = "migrant"
	item_color = "migrant"
	var/maincolor
	var/secondcolor
	flags = FPRINT | TABLEPASS
	var/mig_icon = "emigrant"
	update_icon(var/mob/living/carbon/human/user)
		var/image/stateover
		stateover = image("icon" = 'icons/obj/clothing/uniforms.dmi', "icon_state" = "migrant_o")
		stateover.color = secondcolor
		src.color = maincolor
		src.overlays += stateover

/obj/item/clothing/under/rank/migrant/bum/New()
	..()
	maincolor = "#874949"
	secondcolor = "#0a0303"
	update_icon()

/obj/item/clothing/under/rank/migrant/baroness/New()
	..()
	maincolor = "#242323"
	secondcolor = "#808080"
	update_icon()

/obj/item/clothing/under/rank/migrant/pusher/New()
	..()
	maincolor = "#121110"
	secondcolor = "#2a3d3a"
	update_icon()

/obj/item/clothing/under/rank/migrant/add_color(var/icon/I)
	I.Blend(maincolor, ICON_MULTIPLY)
	return I

/obj/item/clothing/under/rank/migrant/update_overclothes(var/mob/living/carbon/human/H, var/part, var/lying = FALSE, var/list/dirs)
	var/s = lying ? "l" : "s"
	var/base = null
	var/icon/I = icon('icons/mob/human.dmi',"blank")
	if(FAT in H.mutations)
		base	= icon('icons/mob/clothing/overclothes_fat.dmi')
	else if(H.gender == FEMALE)
		base	= icon('icons/mob/clothing/overclothes_female.dmi')
	else
		base	= icon('icons/mob/clothing/overclothes_male2.dmi')
	if(part == UPPER_TORSO)
		var/B = icon(base,icon_state = "[mig_icon]_body_[s]")
		I.Blend(B,ICON_OVERLAY)
	if(part == ARMS)
		if((body_parts_covered & ARM_LEFT) && dirs["left"])
			var/chunk = icon(base,icon_state = "[mig_icon]_l_arm_[s]")
			I.Blend(chunk,ICON_OVERLAY)
	if(part == LEGS)
		if((body_parts_covered & LEG_RIGHT) && !pants_down)
			var/chunk = icon(base,icon_state = "[mig_icon]_r_leg_[s]")
			I.Blend(chunk,ICON_OVERLAY)
	I.Blend(secondcolor, ICON_MULTIPLY)
	return I
