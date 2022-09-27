/*
	Global associative list for caching humanoid icons.
	Index format m or f, followed by a string of 0 and 1 to represent bodyparts followed by husk fat hulk skeleton 1 or 0.
	TODO: Proper documentation
	icon_key is [species.race_key][g][husk][fat][hulk][skeleton][s_tone]
*/
var/global/list/human_icon_cache = list()
var/global/list/lhuman_icon_cache = list()

/proc/overlay_image(icon,icon_state,color,flags)
	var/image/ret = image(icon,icon_state)
	ret.color = color
	ret.appearance_flags = flags
	return ret

	///////////////////////
	//UPDATE_ICONS SYSTEM//
	///////////////////////


/*
Calling this  a system is perhaps a bit trumped up. It is essentially update_clothing dismantled into its
core parts. The key difference is that when we generate overlays we do not generate either lying or standing
versions. Instead, we generate both and store them in two fixed-length lists, both using the same list-index
(The indexes are in update_icons.dm): Each list for humans is (at the time of writing) of length 19.
This will hopefully be reduced as the system is refined.

	var/overlays_lying[19]			//For the lying down stance
	var/overlays_standing[19]		//For the standing stance

When we call update_icons, the 'lying' variable is checked and then the appropriate list is assigned to our overlays!
That in itself uses a tiny bit more memory (no more than all the ridiculous lists the game has already mind you).

On the other-hand, it should be very CPU cheap in comparison to the old system.
In the old system, we updated all our overlays every life() call, even if we were standing still inside a crate!
or dead!. 25ish overlays, all generated from scratch every second for every xeno/human/monkey and then applied.
More often than not update_clothing was being called a few times in addition to that! CPU was not the only issue,
all those icons had to be sent to every client. So really the cost was extremely cumulative. To the point where
update_clothing would frequently appear in the top 10 most CPU intensive procs during profiling.

Another feature of this new system is that our lists are indexed. This means we can update specific overlays!
So we only regenerate icons when we need them to be updated! This is the main saving for this system.

In practice this means that:
	everytime you fall over, we just switch between precompiled lists. Which is fast and cheap.
	Everytime you do something minor like take a pen out of your pocket, we only update the in-hand overlay
	etc...


There are several things that need to be remembered:

>	Whenever we do something that should cause an overlay to update (which doesn't use standard procs
	( i.e. you do something like l_hand = /obj/item/something new(src) )
	You will need to call the relevant update_inv_* proc:
		update_inv_head()
		update_inv_wear_suit()
		update_inv_gloves()
		update_inv_shoes()
		update_inv_w_uniform()
		update_inv_glasse()
		update_inv_l_hand()
		update_inv_r_hand()
		update_inv_belt()
		update_inv_wear_id()
		update_inv_ears()
		update_inv_s_store()
		update_inv_pockets()
		update_inv_back()
		update_inv_handcuffed()
		update_inv_wear_mask()

	All of these are named after the variable they update from. They are defined at the mob/ level like
	update_clothing was, so you won't cause undefined proc runtimes with usr.update_inv_wear_id() if the usr is a
	slime etc. Instead, it'll just return without doing any work. So no harm in calling it for slimes and such.


>	There are also these special cases:
		update_mutations()	//handles updating your appearance for certain mutations.  e.g TK head-glows
		update_mutantrace()	//handles updating your appearance after setting the mutantrace var
		UpdateDamageIcon()	//handles damage overlays for brute/burn damage //(will rename this when I geta round to it)
		update_body()	//Handles updating your mob's icon to reflect their gender/race/complexion etc
		update_hair()	//Handles updating your hair overlay (used to be update_face, but mouth and
																			...eyes were merged into update_body)
		update_targeted() // Updates the target overlay when someone points a gun at you

>	All of these procs update our overlays_lying and overlays_standing, and then call update_icons() by default.
	If you wish to update several overlays at once, you can set the argument to 0 to disable the update and call
	it manually:
		e.g.
		update_inv_head(0)
		update_inv_l_hand(0)
		update_inv_r_hand()		//<---calls update_icons()

	or equivillantly:
		update_inv_head(0)
		update_inv_l_hand(0)
		update_inv_r_hand(0)
		update_icons()

>	If you need to update all overlays you can use regenerate_icons(). it works exactly like update_clothing used to.

>	I reimplimented an old unused variable which was in the code called (coincidentally) var/update_icon
	It can be used as another method of triggering regenerate_icons(). It's basically a flag that when set to non-zero
	will call regenerate_icons() at the next life() call and then reset itself to 0.
	The idea behind it is icons are regenerated only once, even if multiple events requested it.

This system is confusing and is still a WIP. It's primary goal is speeding up the controls of the game whilst
reducing processing costs. So please bear with me while I iron out the kinks. It will be worth it, I promise.
If I can eventually free var/lying stuff from the life() process altogether, stuns/death/status stuff
will become less affected by lag-spikes and will be instantaneous! :3

If you have any questions/constructive-comments/bugs-to-report/or have a massivly devestated butt...
Please contact me on #coderbus IRC. ~Carn x
*/
//Human Underlays Indexes////////
#define U_BACK					1
#define U_L_HAND_LAYER			2 //Used for mainly for shields & twohanded weapons
#define U_R_HAND_LAYER			3
#define TOTAL_UNDERLAYS			3
//Human Overlays Indexes/////////
#define MUTANTRACE_LAYER		1      //TODO: make part of body?
#define MUTATIONS_LAYER			2
#define DAMAGE_LAYER			3
#define BODYHAIR_LAYER			4
#define PANTS_LAYER				5
#define UNIFORM_LAYER			6
#define ID_LAYER				7
#define SHOES_LAYER				8
#define EARS_LAYER				9
#define SUIT_LAYER				10
#define ABOVE_SUIT_LAYER		16
#define WRIST_R_LAYER			17
#define WRIST_L_LAYER			18
#define GLOVES_LAYER			19
#define GLASSES_LAYER			20
#define BELT_LAYER				21      //Possible make this an overlay of somethign required to wear a belt?
#define SUIT_STORE_LAYER		22
#define AMULET_LAYER			23
#define BACK_LAYER				24
#define BACK_LAYER_HALF			25
#define BACK2_LAYER				26
#define BACK2_LAYER_HALF		27
#define HAIR_LAYER				28      //TODO: make part of head layer?
#define BANDAGE_LAYER			29
#define FACEMASK_LAYER			30
#define HEAD_LAYER				31
#define HANDCUFF_LAYER			32
#define LEGCUFF_LAYER			33
#define L_HAND_LAYER			34
#define R_HAND_LAYER			35
#define TAIL_LAYER				36      //bs12 specific. this hack is probably gonna come back to haunt me
#define TARGETED_LAYER			37      //BS12: Layer for the target overlay from weapon targeting system
#define FIRE_LAYER				38      //If you're on fire
#define COLDBREATH_LAYER		39
#define SMELLING_LAYER			40
#define TYPINGINDICATOR_LAYER   41
#define USERLESS_LAYER			42
#define ARTERY_LAYER			43 //ARTERY_LAYER needs to be much lower. Around the DAMAGE_LAYER
#define HOOD_LAYER				44
#define AIMED_LAYER				45
#define BLOOD_LAYER				46
#define CHAT_LAYER				47
#define WATER_LAYER				48
#define RIPPLE_LAYER			49
#define TOTAL_LAYERS			49
//////////////////////////////////

/mob/living/carbon/human
	var/list/overlays_standing[TOTAL_LAYERS]
	var/list/overlays_lying[TOTAL_LAYERS]
	var/list/underlays_standing[TOTAL_UNDERLAYS]
	var/list/underlays_lying[TOTAL_UNDERLAYS]
	var/previous_damage_appearance // store what the body last looked like, so we only have to update it if something changed

//UPDATES OVERLAYS FROM OVERLAYS_LYING/OVERLAYS_STANDING
//this proc is messy as I was forced to include some old laggy cloaking code to it so that I don't break cloakers
//I'll work on removing that stuff by rewriting some of the cloaking stuff at a later date.
/mob/living/carbon/human/update_icons()
	update_hud()		//TODO: remove the need for this
	overlays.Cut()
	underlays.Cut()
	var/stealth = isStealth()
	if(stealth)
		if(lying)
			icon = 'icons/mob/mob.dmi'
			var/suffix = stealth == 2 ? "b" : ""
			icon_state = "cam[suffix]2"
			var/image/I	= overlays_lying[L_HAND_LAYER]
			if(istype(I))	overlays += I
			I 			= overlays_lying[R_HAND_LAYER]
			if(istype(I))	overlays += I
		else
			icon = 'icons/mob/mob.dmi'
			var/suffix = stealth == 2 ? "b" : ""
			icon_state = "cam[suffix]"
			var/image/I	= image(overlays_standing[L_HAND_LAYER],dir = SOUTH)
			if(istype(I))	overlays += I
			I 			= image(overlays_standing[R_HAND_LAYER],dir = SOUTH)
			if(istype(I))	overlays += I

	else
		icon = lying ? lying_icon : stand_icon
		icon_state = null
		if(!lying)
			for(var/image/I in overlays_standing)
				overlays += I
			for(var/image/I in underlays_standing)
				underlays += I
		else
			for(var/image/I in overlays_lying)
				overlays += I
			for(var/image/I in underlays_lying)
				underlays += I

	overlays_standing[USERLESS_LAYER]	= null

	//var/icon/shieldedicon
	if(hasActiveShield(0))
		overlays_standing[USERLESS_LAYER]	= image("icon" = 'icons/mob/clothing/secondary/belt.dmi', "icon_state" = "shield")

	update_transform()

/mob/living/carbon/human/proc/update_embedhit()
	return
	/*
	for(var/datum/organ/external/organ in src.organs) //Grab the organ holding the implant.
		for(var/obj/item/weapon/O in organ.implants)
			if(O)
				if(O.embedicon)
					overlays_standing[MUTATIONS_LAYER]	= image("icon" = 'icons/mob/items/human_stuck.dmi', "icon_state" = "[O.embed_dir][O.embedicon]")
					overlays_lying[MUTATIONS_LAYER]	= image("icon" = 'icons/mob/items/human_stuck.dmi', "icon_state" = "[O.embed_dir][O.embedicon]2")
				else
					overlays_standing[MUTATIONS_LAYER]	= null
					overlays_lying[MUTATIONS_LAYER] = null
			else
				overlays_standing[MUTATIONS_LAYER]	= null
				overlays_lying[MUTATIONS_LAYER] = null
*/
var/global/list/damage_icon_parts = list()

proc/get_damage_icon_part(damage_state, body_part, var/icon/dam_icon = 'icons/mob/dam_human.dmi')
	if(damage_icon_parts["[damage_state]/[body_part]/[dam_icon]"] == null)
		var/icon/DI = new /icon(dam_icon, damage_state)			// the damage icon for whole human
		DI.Blend(new /icon('icons/mob/dam_mask.dmi', body_part), ICON_MULTIPLY)		// mask with this organ's pixels
		damage_icon_parts["[damage_state]/[body_part]/[dam_icon]"] = DI
		return DI
	else
		return damage_icon_parts["[damage_state]/[body_part]/[dam_icon]"]

/mob/living/carbon/human/proc/UpdateArteryIcon(var/update_icons=1)
	if(istype(src, /mob/living/carbon/human/monster) || src.species.name == "Skeleton")
		overlays_standing[ARTERY_LAYER]	= null
		overlays_lying[ARTERY_LAYER]	= null
		return

	var/icon/artery_icon = 'icons/mob/flesh/human_bleeding_male.dmi'
	var/image/standing_image = image('icons/mob/human.dmi',"blank")
	var/image/lying_image = image('icons/mob/human.dmi',"blank")

	if(src.gender == "male")
		artery_icon = 'icons/mob/flesh/human_bleeding_male.dmi'
	if(src.gender == "female")
		artery_icon = 'icons/mob/flesh/human_bleeding_female.dmi'
	if(src.isChild())
		artery_icon = 'icons/mob/flesh/human_bleeding_child.dmi'
	if(src.species.name == "midget")
		artery_icon = 'icons/mob/flesh/human_bleeding_midget.dmi'
	if(FAT in src.mutations)
		artery_icon = 'icons/mob/flesh/human_bleeding_fat.dmi'

	var/bleeding = pulse == PULSE_NONE ? "0" : "1" //I'll just set it to pulse for now, change to DEAD if this doesn't work.

	for(var/datum/organ/external/O in organs)
		if(O.status & ORGAN_ARTERY)
			if(O.sprite_dependent_for_artery && O.parent.status & ORGAN_DESTROYED) continue
			O.update_icon()
			var/icon/DI = new /icon(artery_icon, "[O.iconsdamage]_s[bleeding]")
			var/icon/DIL = new /icon(artery_icon, "[O.iconsdamage]_l[bleeding]")
			standing_image.overlays += DI
			lying_image.overlays += DIL

	overlays_standing[ARTERY_LAYER]	= standing_image
	overlays_lying[ARTERY_LAYER]	= lying_image
	UpdateDamageIcon()

	if(update_icons)   update_icons()
	return

/mob/living/carbon/human/proc/UpdateBandageIcon(var/update_icons=1)
	if(istype(src, /mob/living/carbon/human/monster))
		return

	var/icon/bandage_icon
	if(src.species.name == "Skeleton")
		overlays_standing[BANDAGE_LAYER]	= null
		overlays_lying[BANDAGE_LAYER]		= null
		return
	var/image/standing_image = image('icons/mob/human.dmi',"blank")
	var/image/lying_image = image('icons/mob/human.dmi',"blank")

	if(src.gender == "male")
		bandage_icon = 'icons/mob/flesh/bandaid_male.dmi'
	if(src.gender == "female")
		bandage_icon = 'icons/mob/flesh/bandaid_female.dmi'
	if(src.isChild())
		bandage_icon = 'icons/mob/flesh/bandaid_child.dmi'
	if(src.species.name == "midget")
		bandage_icon = 'icons/mob/flesh/bandaid_midget.dmi'
	if(FAT in src.mutations)
		bandage_icon = 'icons/mob/flesh/bandaid_fat.dmi'

	for(var/datum/organ/external/O in organs)
		if(O.status & ORGAN_DESTROYED) continue
		if(O.bandaged)
			O.update_icon()
			var/icon/DI = new /icon(bandage_icon, "[O.iconsdamage]_s")
			var/icon/DIL = new /icon(bandage_icon, "[O.iconsdamage]_l")
			var/list/L = list()
			L.Add(ReadRGB(O.bandaged.color))
			if(L[1] &&  L[2] && L[3])
				DI.Blend(rgb(L[1], L[2], L[3]), ICON_MULTIPLY)
				DIL.Blend(rgb(L[1], L[2], L[3]), ICON_MULTIPLY)
			standing_image.overlays += DI
			lying_image.overlays += DIL

	overlays_standing[BANDAGE_LAYER]	= standing_image
	overlays_lying[BANDAGE_LAYER]	= lying_image

	UpdateDamageIcon()

	if(update_icons)   update_icons()
	return


//DAMAGE OVERLAYS
//constructs damage icon for each organ from mask * damage field and saves it in our overlays_ lists
/mob/living/carbon/human/UpdateDamageIcon(var/update_icons=1)
	// first check whether something actually changed about damage appearance
	if(istype(src, /mob/living/carbon/human/monster))
		return
	if(istype(src?.species, /datum/species/human/alien))
		return

	var/damage_appearance = ""

	for(var/datum/organ/external/O in organs)
		if(O.status & ORGAN_DESTROYED) damage_appearance += "d"
		else
			damage_appearance += O.damage_state

	//update_bloody_wounds()

	if(damage_appearance == previous_damage_appearance)
		// nothing to do here
		return

	var/icon/damage_icon = 'icons/mob/dam_human.dmi'
	if(src.species.name == "Zombie")
		damage_icon = null
		return
	if(src.species)
		damage_icon = src.species.damage_icon

	previous_damage_appearance = damage_appearance

	var/icon/standing = new /icon(damage_icon, "00")


	var/image/standing_image = new /image("icon" = standing)
	var/image/lying_image = new /image("icon" = standing)
	if(src.gender == "male")
		damage_icon = 'icons/mob/dam_human.dmi'
	if(src.gender == "female")
		damage_icon = 'icons/mob/dam_female.dmi'
	if(src.isChild())
		damage_icon = 'icons/mob/dam_child.dmi'
	if(src.species.name == "midget")
		damage_icon = 'icons/mob/dam_midget.dmi'
	if(FAT in src.mutations)
		damage_icon = 'icons/mob/dam_fat.dmi'
	if(src.species.name == "Skeleton")
		damage_icon = null

	var/datum/organ/external/head/orgao = organs_by_name["head"]
	// blend the individual damage states with our icons
	for(var/datum/organ/external/O in organs)
		if(!(O.status & ORGAN_DESTROYED))
			O.update_icon()
			if(O.damage_state == "00") continue
			if(O.head_icon_needed && orgao.status & ORGAN_DESTROYED) continue //boca face e throat fazem overlay de dano de cabeça mas nao devem aparecer se o maluco nao tem cabeça
			if(O.name == "head" && orgao.headwrenched)
				var/icon/DI = new /icon(damage_icon, "[O.iconsdamage]_[O.damage_state]")
				var/icon/LDI = new /icon(damage_icon, "[O.iconsdamage]2_[O.damage_state]")
				var/image/I = image(DI, dir = turn(src.dir, 180))
				var/image/LI = image(LDI, dir = turn(src.dir, 180))
				standing_image.overlays += I
				lying_image.overlays += LI
			var/icon/DI = new /icon(damage_icon, "[O.iconsdamage]_[O.damage_state]")
			var/icon/LDI = new /icon(damage_icon, "[O.iconsdamage]2_[O.damage_state]")

			standing_image.overlays += DI
			lying_image.overlays += LDI



	overlays_standing[DAMAGE_LAYER]			= standing_image
	overlays_lying[DAMAGE_LAYER]			= lying_image

	if(update_icons)   update_icons()
	UpdateArteryIcon()
	UpdateBandageIcon()
	update_above()

/mob/living/carbon/human/update_fire()

	if(on_fire)
		var/image/I = image("icon"='icons/mob/flesh/burnmotherfucker.dmi', "icon_state"="fire_s", "layer"=FLY_LAYER)
		var/image/IL = image("icon"='icons/mob/flesh/burnmotherfucker.dmi', "icon_state"="fire_l", "layer"=FLY_LAYER)
		I.override = 1
		IL.override = 1
		overlays_standing[FIRE_LAYER] = I
		overlays_lying[FIRE_LAYER] = IL
	else
		overlays_standing[FIRE_LAYER] = null
		overlays_lying[FIRE_LAYER] = null
	update_icons()
/*
/mob/living/carbon/human/proc/update_bloody_wounds(var/update_icons=1)
	set background = 1
	var/ipsilon = 1
	var/xis = 7
	var/list/pixelsX = list()
	var/list/pixelsY = list()
	var/list/maskColours = list()
	var/woundsNumber = 0
	var/g = "bodymask"
	if(gender == MALE)
		g = "bodymask"
	if(gender == FEMALE)
		g = "bodymask_female"
	if(FAT in src.mutations)
		g = "bodymask_fat"
	if(isChild(src))
		g = "bodymask_child"
	if(ismonster(src))
		return
	var/image/standing_image = new /image("icon" = 'icons/mob/woundsplus.dmi')
	var/icon/DI = new /icon('icons/mob/woundsplus.dmi')
	for(var/datum/organ/external/E in bad_external_organs)
		if(E.status & ORGAN_BLEEDING)
			woundsNumber++
			maskColours.Add(E.mask_color)
	if(woundsNumber == 0)
		return
	for(xis = 7; xis <= 26; xis++)
		//to_chat(world, "[xis]")
		if(DI.GetPixel(x=xis, y=ipsilon, icon_state = "[g]", dir=src.dir, frame=1, moving=0) in maskColours)
			//to_chat(world, "ACHOU")
			pixelsX.Add(xis-2)
			pixelsY.Add(ipsilon-7)
		if(xis == 26)
			xis = 1
			ipsilon++
			//to_chat(world, "[ipsilon]")
			if(ipsilon == 30)
				ipsilon = 1
				break
			//world << "X = [xis], Y = [ipsilon]" BASICAMENTE FICA X31 e Y32 E FODASE KKKKKKKKKKKKKKK

	//to_chat(world, "WOUNDS: [woundsNumber]")

	for(var/i = 1; i <= woundsNumber; i++)
		var/tiroState = "bullet_[dir_to_text(src.dir)]"
		if(resting)
			tiroState = "bullet_[dir_to_text(src.dir)]_lying"
		var/icon/tiro = new('woundsplus.dmi', "[tiroState]")
		if(!pixelsX.len) return
		if(!pixelsY.len) return
		tiro.Shift(EAST, pick(pixelsX)) // shift the icon four pixels
		tiro.Shift(NORTH, pick(pixelsY)) // shift the icon four pixels
		DI.Blend(tiro, ICON_OVERLAY)
		//to_chat(world, "[i]")

	standing_image.overlays += DI

	overlays_standing[BLOOD_LAYER] = null
	overlays_standing[BLOOD_LAYER] = standing_image
*/

//BASE MOB SPRITE
/mob/living/carbon/human/proc/update_body(var/update_icons=1)
	var/necrosis_color_mod = rgb(164,32,32)

	var/husk = (HUSK in src.mutations)
	var/fat = (FAT in src.mutations)
	var/hulk = (HULK in src.mutations)
	var/skeleton = (SKELETON in src.mutations)

	var/g = (gender == FEMALE ? "f" : "m")

	var/has_head = 0
	var/brain_showing = 0

	//CACHING: Generate an index key from visible bodyparts.
	//0 = destroyed, 1 = normal, 2 = robotic, 3 = necrotic.

	//Create a new, blank icon for our mob to use.
	if(stand_icon)
		qdel(stand_icon)
		qdel(lying_icon)

	UpdateArteryIcon()
	UpdateBandageIcon()

	stand_icon = new(species && species.icon_template ? species.icon_template : 'icons/mob/human.dmi',"blank")
	lying_icon = new(species && species.icon_template ? species.icon_template : 'icons/mob/human.dmi',"blank")

	var/icon_key = "[species.race_key][g][s_tone]"
	for(var/datum/organ/external/part in organs)
		var/datum/organ/external/head/E = get_organ("head")
		if(istype(part,/datum/organ/external/head) && !(part.status & ORGAN_DESTROYED))
			has_head = 1
			var/datum/organ/external/head/head = part
			if(head.brained==1)
				brain_showing = 1
			else brain_showing = 0

		if(part.status & ORGAN_DESTROYED)
			icon_key = "[icon_key]0"
		else if(part.status & ORGAN_ROBOT)
			icon_key = "[icon_key]2"
		else if(part.status & ORGAN_DEAD)
			icon_key = "[icon_key]3"
		else if(E && E.headwrenched)
			icon_key = "[icon_key]4"
		else if(part.lfwblockedicon && lifeweb_locked)
			icon_key = "[icon_key]5"
		else if(zombie)
			icon_key = "[icon_key]6"
		else if(pale)
			icon_key = "[icon_key]7"
		else
			icon_key = "[icon_key]1"

	var/datum/organ/external/M = get_organ("mouth")
	icon_key = "[icon_key][husk ? 1 : 0][fat ? 1 : 0][hulk ? 1 : 0][skeleton ? 1 : 0][(gender == FEMALE && age >= 60) ? 1 : 0][(M.status & ORGAN_DESTROYED) ? 1 : 0][s_tone]"
	bodyhair()
	var/icon/base_icon
	var/icon/lbase_icon
	if(human_icon_cache[icon_key] && lifeweb_locked == FALSE && QUEMLIGA == FALSE)
		//Icon is cached, use existing icon.
		base_icon = human_icon_cache[icon_key]
		lbase_icon = lhuman_icon_cache[icon_key]

		//log_debug("Retrieved cached mob icon ([icon_key] \icon[human_icon_cache[icon_key]]) for [src].")

	else

	//BEGIN CACHED ICON GENERATION.

		// Why don't we just make skeletons/shadows/golems a species? ~Z
		var/race_icon =   (skeleton ? 'icons/mob/human_races/r_skeleton.dmi' : species.icobase)
		var/deform_icon = (skeleton ? 'icons/mob/human_races/r_skeleton.dmi' : species.icobase)

		//Robotic limbs are handled in get_icon() so all we worry about are missing or dead limbs.
		//No icon stored, so we need to start with a basic one.
		var/datum/organ/external/chest = get_organ("chest")
		base_icon = chest.get_icon(race_icon,deform_icon,g,fat,lifeweb_locked)
		lbase_icon = chest.get_icon(race_icon,deform_icon,g,fat,lifeweb_locked,TRUE)

		if(chest && zombie)
			base_icon.ColorTone(necrosis_color_mod)
			base_icon.SetIntensity(0.7)
			lbase_icon.ColorTone(necrosis_color_mod)
			lbase_icon.SetIntensity(0.7)

		if(chest && pale && !skeleton && !ismonster(src) && !istype(src.species, /datum/species/human/alien))
			base_icon.ColorTone(rgb(32,32,164))
			base_icon.SetIntensity(0.7)
			lbase_icon.ColorTone(rgb(32,32,164))
			lbase_icon.SetIntensity(0.7)

		if(chest.status & ORGAN_DEAD)
			base_icon.ColorTone(necrosis_color_mod)
			base_icon.SetIntensity(0.7)
			lbase_icon.ColorTone(necrosis_color_mod)
			lbase_icon.SetIntensity(0.7)


		for(var/datum/organ/external/part in organs)
			if(part.no_draw)
				continue
			var/icon/temp = draw_bodypart(part,FALSE)//Hold the bodypart icon for processing.
			var/icon/ltemp = draw_bodypart(part,TRUE)
			if(!temp || !ltemp)
				continue


			//That part makes left and right legs drawn topmost and lowermost when human looks WEST or EAST
			//And no change in rendering for other parts (they icon_position is 0, so goes to 'else' part)
			if(part.icon_position&(LEFT|RIGHT))
				var/icon/temp2 = new('icons/mob/human.dmi',"blank")

				temp2.Insert(new/icon(temp,dir=NORTH),dir=NORTH)
				temp2.Insert(new/icon(temp,dir=SOUTH),dir=SOUTH)

				if(!(part.icon_position & LEFT))
					temp2.Insert(new/icon(temp,dir=EAST),dir=EAST)

				if(!(part.icon_position & RIGHT))
					temp2.Insert(new/icon(temp,dir=WEST),dir=WEST)
				base_icon.Blend(temp2, ICON_OVERLAY)

				if(part.icon_position & LEFT)
					temp2.Insert(new/icon(temp,dir=EAST),dir=EAST)

				if(part.icon_position & RIGHT)
					temp2.Insert(new/icon(temp,dir=WEST),dir=WEST)
				base_icon.Blend(temp2, ICON_UNDERLAY)

			else
				base_icon.Blend(temp, ICON_OVERLAY)
			lbase_icon.Blend(ltemp, ICON_OVERLAY)

		var/list/after_blends = bodypart_blends(base_icon,lbase_icon)
		base_icon = after_blends[1]
		lbase_icon = after_blends[2]
		lhuman_icon_cache[icon_key] = lbase_icon
		human_icon_cache[icon_key] = base_icon

		//log_debug("Generated new cached mob icon ([icon_key] \icon[human_icon_cache[icon_key]]) for [src]. [human_icon_cache.len] cached mob icons.")

	//END CACHED ICON GENERATION.
	lying_icon.Blend(lbase_icon,ICON_OVERLAY)
	stand_icon.Blend(base_icon,ICON_OVERLAY)

	//Skin colour. Not in cache because highly variable (and relatively benign).
	if (species.flags & HAS_SKIN_COLOR)
		stand_icon.Blend(rgb(0, 0, 0), ICON_ADD)
		lying_icon.Blend(rgb(0, 0, 0), ICON_ADD)

	if(has_head)
		//Eyes
		var/datum/organ/external/head/E = get_organ("head")
		var/icon/eye_icon = 'icons/mob/human.dmi'
		var/icon/face_icon = 'icons/mob/flesh/human_face.dmi'
		if(gender == FEMALE && !(FAT in mutations))
			if(E.headwrenched)
				face_icon = 'icons/mob/flesh/human_face_f2.dmi'
				eye_icon = 'icons/mob/flesh/human_face_f2.dmi'
			else
				face_icon = 'icons/mob/flesh/human_face_f.dmi'
				eye_icon = 'icons/mob/flesh/human_face_f.dmi'
		else if (E.headwrenched)
			face_icon = 'icons/mob/flesh/human_face2.dmi'
			eye_icon = 'icons/mob/flesh/human_face2.dmi'

		if(!skeleton && !ismonster(src) && !istype(src.species, /datum/species/human/alien))
			if(DeadEyes)
				var/icon/eyes = new/icon(eye_icon, "[species.eyes]_s")
				var/icon/leyes = new/icon(eye_icon, "[species.eyes]_l")
				eyes.Blend(rgb(255, 255,255), ICON_MULTIPLY)
				leyes.Blend(rgb(255, 255,255), ICON_MULTIPLY)
				stand_icon.Blend(eyes, ICON_OVERLAY)
				lying_icon.Blend(leyes, ICON_OVERLAY)
			else
				var/icon/eyes = new/icon(eye_icon, "[species.eyes]_s")
				var/icon/leyes = new/icon(eye_icon, "[species.eyes]_l")
				eyes.Blend(rgb(r_eyes, g_eyes, b_eyes), ICON_MULTIPLY)
				leyes.Blend(rgb(r_eyes, g_eyes, b_eyes), ICON_MULTIPLY)
				stand_icon.Blend(eyes, ICON_OVERLAY)
				lying_icon.Blend(leyes, ICON_OVERLAY)
		if(ExposedFang || special && special == "youlooksick")
			var/icon/fangs = new/icon(face_icon, "fangs")
			var/icon/lfangs = new/icon(face_icon, "fangs_l")
			stand_icon.Blend(fangs, ICON_OVERLAY)
			lying_icon.Blend(lfangs, ICON_OVERLAY)
		if(!skeleton && !ismonster(src) && !istype(src.species, /datum/species/human/alien))
			var/icon/mouth = new/icon(face_icon, "mouth_s")
			var/icon/lmouth = new/icon(face_icon, "mouth_l")
			mouth.Blend(rgb(s_tone, s_tone, s_tone), ICON_ADD)
			lmouth.Blend(rgb(s_tone, s_tone, s_tone), ICON_ADD)
			stand_icon.Blend(mouth, ICON_OVERLAY)
			lying_icon.Blend(mouth, ICON_OVERLAY)

		//Mouth	(lipstick!)
		if(lip_style && (species && species.flags & HAS_LIPS))	//skeletons are allowed to wear lipstick no matter what you think, agouri.
			stand_icon.Blend(new/icon('icons/mob/human_face.dmi', "lips_[lip_style]_s"), ICON_OVERLAY)

		//Brain showing
		if(brain_showing)
			var/braindam_icon = 'icons/mob/dam_human.dmi'
			if(src.species)
				braindam_icon = src.species.damage_icon
			stand_icon.Blend(new/icon(braindam_icon, "brain"), ICON_OVERLAY)
			lying_icon.Blend(new/icon(braindam_icon, "brain2"), ICON_OVERLAY)

	//Underwear
	if(underwear >0 && underwear < 12 && species.flags & HAS_UNDERWEAR)
		if(!fat && !skeleton)
			stand_icon.Blend(new /icon('icons/mob/human.dmi', "underwear[underwear]_[g]_s"), ICON_OVERLAY)

/*	if(undershirt>0 && undershirt < 5 && species.flags & HAS_UNDERWEAR)
		stand_icon.Blend(new /icon('icons/mob/human.dmi', "undershirt[undershirt]_s"), ICON_OVERLAY)
*/
	if(update_icons)
		update_icons()

	//tail
	src.update_above(0)
	update_tail_showing(0)

mob/living/carbon/human/proc/bodypart_blends(var/icon/base_icon, var/icon/lbase_icon)
	var/husk_color_mod = rgb(96,88,80)
	var/hulk_color_mod = rgb(48,224,40)

	var/husk = (HUSK in src.mutations)
	var/hulk = (HULK in src.mutations)
	var/skeleton = (SKELETON in src.mutations)
	var/race_icon =   (skeleton ? 'icons/mob/human_races/r_skeleton.dmi' : species.icobase)

	if(!skeleton)
		if(husk)
			base_icon.ColorTone(husk_color_mod)
			lbase_icon.ColorTone(husk_color_mod)
		else if(hulk)
			var/list/tone = ReadRGB(hulk_color_mod)
			base_icon.MapColors(rgb(tone[1],0,0),rgb(0,tone[2],0),rgb(0,0,tone[3]))
			lbase_icon.MapColors(rgb(tone[1],0,0),rgb(0,tone[2],0),rgb(0,0,tone[3]))

	//Handle husk overlay.
	if(husk)
		var/icon/mask = new(base_icon)
		var/icon/husk_over = new(race_icon,"overlay_husk")
		mask.MapColors(0,0,0,1, 0,0,0,1, 0,0,0,1, 0,0,0,1, 0,0,0,0)
		husk_over.Blend(mask, ICON_ADD)
		base_icon.Blend(husk_over, ICON_OVERLAY)
		lbase_icon.Blend(husk_over, ICON_OVERLAY)


	//Skin tone.
	if(!husk && !hulk)
		if(species.flags & HAS_SKIN_TONE)
			if(s_tone >= 0)
				base_icon.Blend(rgb(s_tone, s_tone, s_tone), ICON_ADD)
				lbase_icon.Blend(rgb(s_tone, s_tone, s_tone), ICON_ADD)
			else
				base_icon.Blend(rgb(-s_tone,  -s_tone,  -s_tone), ICON_SUBTRACT)
				lbase_icon.Blend(rgb(-s_tone,  -s_tone,  -s_tone), ICON_SUBTRACT)

	return list(base_icon,lbase_icon)

/mob/living/carbon/human/proc/draw_bodypart(var/datum/organ/external/part,var/lying = FALSE)
	var/fat = (FAT in src.mutations)
	var/skeleton = (SKELETON in src.mutations)
	var/race_icon =   (skeleton ? 'icons/mob/human_races/r_skeleton.dmi' : species.icobase)
	var/deform_icon = (skeleton ? 'icons/mob/human_races/r_skeleton.dmi' : species.icobase)
	var/necrosis_color_mod = rgb(164,32,32)
	if(fat && istype(src.species,/datum/species/skinless))
		race_icon = 'icons/mob/flesh/subhuman_fat.dmi'
	var/g = (gender == FEMALE ? "f" : "m")
	var/icon/temp
	if(part.status & ORGAN_DESTROYED || part.no_draw)
		return

	temp = part.get_icon(race_icon,deform_icon,g,fat,lifeweb_locked,lying)

	if(part && zombie)
		temp.ColorTone(necrosis_color_mod)
		temp.SetIntensity(0.7)

	if(part && pale && !skeleton && !ismonster(src) && !istype(src.species, /datum/species/human/alien) && !istype(src, /mob/living/carbon/human/skinless))
		temp.ColorTone(rgb(32,32,164))
		temp.SetIntensity(0.7)

	if(part.status & ORGAN_DEAD)
		temp.ColorTone(necrosis_color_mod)
		temp.SetIntensity(0.7)
	return temp

/*
You might ask why I created this massive awful proc instead of just using multiple overlays. The reason is because we can only show one thing at once.
If you draw the arms, sleeves and suit arms at once, there are clipping issues.
*/
/mob/living/carbon/human/proc/update_above(var/update_icons=1)
	var/icon/above = icon('icons/mob/human.dmi',"blank")
	var/icon/abovel = icon('icons/mob/human.dmi',"blank")
	var/damage_icon
	if(src.gender == "male")
		damage_icon = 'icons/mob/dam_human.dmi'
	if(src.gender == "female")
		damage_icon = 'icons/mob/dam_female.dmi'
	if(src.isChild())
		damage_icon = 'icons/mob/dam_child.dmi'
	if(src.species.name == "midget")
		damage_icon = 'icons/mob/dam_midget.dmi'
	if(FAT in src.mutations)
		damage_icon = 'icons/mob/dam_fat.dmi'
	if(src.species.name == "Skeleton")
		damage_icon = null

	var/list/datum/organ/external/parts = list(get_organ("l_arm"),get_organ("r_arm"),get_organ("l_hand"),get_organ("r_hand"))
	if(wear_suit || w_uniform)
		if((wear_suit?:body_parts_covered & ARM_LEFT))
			parts -= get_organ("l_arm")
		if((wear_suit?:body_parts_covered & ARM_RIGHT))
			parts -= get_organ("r_arm")

	for(var/datum/organ/external/part in parts)
		var/icon/temp = draw_bodypart(part,FALSE)//Hold the bodypart icon for processing.
		var/icon/ltemp = draw_bodypart(part,TRUE)
		if(!temp || !ltemp)
			continue
		var/icon/DI = new /icon(damage_icon, "[part.iconsdamage]_[part.damage_state]")
		var/icon/LDI = new /icon(damage_icon, "[part.iconsdamage]2_[part.damage_state]")
		temp.Blend(DI, ICON_OVERLAY)
		ltemp.Blend(LDI, ICON_OVERLAY)
		if(part.above_layer)//If we should render to the above layer
			var/icon/temp1 = new('icons/mob/human.dmi',"blank")
			if(part.above_layer == RIGHT)
				temp1.Insert(new/icon(temp,dir=EAST),dir=EAST)
				temp.Insert(new/icon('icons/mob/human.dmi',"blank"),dir=EAST)
			if(part.above_layer == LEFT)
				temp1.Insert(new/icon(temp,dir=WEST),dir=WEST)
				temp.Insert(new/icon('icons/mob/human.dmi',"blank"),dir=WEST)
			above.Blend(temp1, ICON_OVERLAY)
		else
			above.Blend(temp,ICON_OVERLAY)
		abovel.Blend(ltemp,ICON_OVERLAY)

	var/list/after_blends = bodypart_blends(above,abovel)
	above = after_blends[1]
	abovel = after_blends[2]

	if(w_uniform && istype(w_uniform, /obj/item/clothing/under))
		var/list/dirs = list("left" = 1,"right" = 1)
		if((wear_suit?:body_parts_covered & ARM_LEFT) && wear_suit?:hide_uniform_sleeves)
			dirs["left"] = 0
		if((wear_suit?:body_parts_covered & ARM_RIGHT) && wear_suit?:hide_uniform_sleeves)
			dirs["right"] = 0
		if(dirs["right"] || dirs["left"])
			var/icon/I = w_uniform:update_sleeves(src,FALSE,dirs)
			var/icon/IL = w_uniform:update_sleeves(src,TRUE,dirs)
			I = w_uniform:add_color(I)
			IL = w_uniform:add_color(IL)
			var/icon/OI= w_uniform:update_overclothes(src,ARMS,FALSE,dirs)
			var/icon/OIL = w_uniform:update_overclothes(src,ARMS,TRUE,dirs)
			if(OI && OIL)
				I.Blend(OI, ICON_OVERLAY)
				IL.Blend(OIL, ICON_OVERLAY)
			if(I && IL)
				above.Blend(I, ICON_OVERLAY)
				abovel.Blend(IL, ICON_OVERLAY)

	if(wear_suit && istype(wear_suit, /obj/item/clothing/suit) )
		var/icon/I = wear_suit:update_above(src)
		var/icon/IL = wear_suit:update_above(src,TRUE)
		if(I && IL)
			above.Blend(I, ICON_OVERLAY)
			abovel.Blend(IL, ICON_OVERLAY)

	overlays_standing[ABOVE_SUIT_LAYER] = image(above)
	overlays_lying[ABOVE_SUIT_LAYER] = image(abovel)



//HAIR OVERLAY
/mob/living/carbon/human/proc/update_hair(var/update_icons=1)
	//Reset our hair
	overlays_standing[HAIR_LAYER]	= null
	overlays_lying[HAIR_LAYER]	= null

	var/datum/organ/external/head/head_organ = get_organ("head")
	if( !head_organ || (head_organ.status & ORGAN_DESTROYED) )
		if(update_icons)   update_icons()
		return

	//masks and helmets can obscure our hair.
	if( (head && (head.flags & BLOCKHAIR)) || (wear_mask && (wear_mask.flags & BLOCKHAIR)))
		if(update_icons)   update_icons()
		return

	if(wear_suit && istype(wear_suit, /obj/item/clothing/suit/hood))
		var/obj/item/clothing/suit/hood/HOOD = src.wear_suit
		if(HOOD.hooded)
			if(update_icons)  update_icons()
			return
	//base icons
	var/icon/face_standing = new /icon('icons/mob/flesh/old/human_face_old.dmi',"bald_s")
	var/icon/face_lying  = new /icon('icons/mob/flesh/old/human_f_face_old.dmi',"bald_s")
	var/standing_icon = ""
	var/lying_icon = ""
	if(gender == FEMALE)
		standing_icon = 'icons/mob/flesh/old/human_f_face_old.dmi'
		lying_icon = 'icons/mob/flesh/old/human_f_face_old.dmi'
	else
		standing_icon ='icons/mob/flesh/old/human_face_old.dmi'
		lying_icon = 'icons/mob/flesh/old/human_face_old.dmi'
	var/datum/organ/external/head/E = get_organ("head")
	var/ls = E.headwrenched ? "l2" : "l"
	if(f_style)
		var/datum/sprite_accessory/facial_hair_style = facial_hair_styles_list[f_style]
		if(facial_hair_style && src?.species?.name in facial_hair_style.species_allowed)
			var/icon/facial_s = new/icon("icon" = standing_icon, "icon_state" = "[facial_hair_style.icon_state]_s")
			var/icon/facial_l = new/icon("icon" = lying_icon, "icon_state" = "[facial_hair_style.icon_state]_[ls]")
			if(facial_hair_style.do_colouration)
				facial_s.Blend(rgb(r_facial, g_facial, b_facial), ICON_ADD)
				facial_l.Blend(rgb(r_facial, g_facial, b_facial), ICON_ADD)

			face_standing.Blend(facial_s, ICON_OVERLAY)
			face_lying.Blend(facial_l, ICON_OVERLAY)

	if(d_style)
		var/datum/sprite_accessory/facial_detail = facial_details_list[d_style]
		if(facial_detail && src?.species.name in facial_detail?.species_allowed)
			var/icon/detail_s = new/icon("icon" = 'icons/mob/flesh/old/human_detail_old.dmi', "icon_state" = "[facial_detail.icon_state]_s")
			var/icon/detail_l = new/icon("icon" = 'icons/mob/flesh/old/human_detail_old.dmi', "icon_state" = "[facial_detail.icon_state]_[ls]")
			if(facial_detail.do_colouration)
				detail_s.Blend(rgb(r_detail, g_detail, b_detail), ICON_ADD)
				detail_l.Blend(rgb(r_detail, g_detail, b_detail), ICON_ADD)

			face_standing.Blend(detail_s, ICON_OVERLAY)
			face_lying.Blend(detail_l, ICON_OVERLAY)

	if(wear_suit && istype(wear_suit, /obj/item/clothing/suit/storage/vest/goodhood))
		var/obj/item/clothing/suit/storage/vest/goodhood/HOOD = wear_suit
		if(!HOOD.hoodon)
			if(h_style && !(head && (head.flags & BLOCKHEADHAIR)))
				var/datum/sprite_accessory/hair_style = hair_styles_list[h_style]
				if(hair_style && src.species.name in hair_style?.species_allowed)
					var/icon/hair_s = new/icon("icon" = standing_icon, "icon_state" = "[hair_style.icon_state]_s")
					var/icon/hair_l = new/icon("icon" = lying_icon, "icon_state" = "[hair_style.icon_state]_[ls]")
					if(hair_style.do_colouration)
						hair_s.Blend(rgb(r_hair, g_hair, b_hair), ICON_ADD)
						hair_l.Blend(rgb(r_hair, g_hair, b_hair), ICON_ADD)

					face_standing.Blend(hair_s, ICON_OVERLAY)
					face_lying.Blend(hair_l, ICON_OVERLAY)
	else
		if(h_style && !(head && (head.flags & BLOCKHEADHAIR)))
			var/datum/sprite_accessory/hair_style = hair_styles_list[h_style]
			if(hair_style && src.species.name in hair_style?.species_allowed)
				var/icon/hair_s = new/icon("icon" = standing_icon, "icon_state" = "[hair_style.icon_state]_s")
				var/icon/hair_l = new/icon("icon" = lying_icon, "icon_state" = "[hair_style.icon_state]_[ls]")
				if(hair_style.do_colouration)
					hair_s.Blend(rgb(r_hair, g_hair, b_hair), ICON_ADD)
					hair_l.Blend(rgb(r_hair, g_hair, b_hair), ICON_ADD)

				face_standing.Blend(hair_s, ICON_OVERLAY)
				face_lying.Blend(hair_l, ICON_OVERLAY)

	if(E.headwrenched)
		overlays_standing[HAIR_LAYER]	= image(face_standing, dir = turn(src.dir, 180))
		overlays_lying[HAIR_LAYER]	= image(face_lying)
		if(update_icons)   update_icons()
		return

	overlays_standing[HAIR_LAYER]	= image(face_standing)
	overlays_lying[HAIR_LAYER]	= image(face_lying)

	if(update_icons)   update_icons()

/mob/living/carbon/human/update_mutations(var/update_icons=1)
	var/fat
	if(FAT in mutations)
		fat = "fat"

	var/image/standing	= image("icon" = 'icons/effects/genetics.dmi')
	var/add_image = 0
	var/g = "m"
	if(gender == FEMALE)	g = "f"
	for(var/datum/dna/gene/gene in dna_genes)
		if(!gene.block)
			continue
		if(gene.is_active(src))
			var/underlay=gene.OnDrawUnderlays(src,g,fat)
			if(underlay)
				standing.underlays += underlay
				add_image = 1
	for(var/mut in mutations)
		switch(mut)
			/*
			if(HULK)
				if(fat)
					standing.underlays	+= "hulk_[fat]_s"
				else
					standing.underlays	+= "hulk_[g]_s"
				add_image = 1
			if(COLD_RESISTANCE)
				standing.underlays	+= "fire[fat]_s"
				add_image = 1
			if(TK)
				standing.underlays	+= "telekinesishead[fat]_s"
				add_image = 1
			*/
			if(LASER)
				standing.overlays	+= "lasereyes_s"
				add_image = 1
	if(add_image)
		overlays_standing[MUTATIONS_LAYER]	= standing
	else
		overlays_standing[MUTATIONS_LAYER]	= null
	if(update_icons)   update_icons()


/mob/living/carbon/human/proc/update_mutantrace(var/update_icons=1)
	var/fat

	if( FAT in mutations )
		fat = "fat"

	if(dna)
		switch(dna.mutantrace)
			if("golem","slime","shadow","adamantine")
				overlays_standing[MUTANTRACE_LAYER]	= image("icon" = 'icons/effects/genetics.dmi', "icon_state" = "[dna.mutantrace][fat]_[gender]_s")
			else
				overlays_standing[MUTANTRACE_LAYER]	= null

	if(!dna || !(dna.mutantrace in list("golem","metroid")))
		update_body(0)

	update_hair(0)
	if(update_icons)   update_icons()

//Call when target overlay should be added/removed
/mob/living/carbon/human/update_targeted(var/update_icons=1)
	if (targeted_by && target_locked)
		overlays_standing[TARGETED_LAYER]	= target_locked
	else if (!targeted_by && target_locked)
		qdel(target_locked)
	if (!targeted_by)
		overlays_standing[TARGETED_LAYER]	= null
	if(update_icons)		update_icons()


/* --------------------------------------- */
//For legacy support.
/mob/living/carbon/human/regenerate_icons()
	..()
	if(monkeyizing)		return
	update_mutations(0)
	update_mutantrace(0)
	update_inv_w_uniform(0)
	update_inv_wear_id(0)
	update_inv_gloves(0)
	update_inv_glasses(0)
	update_inv_ears(0)
	update_inv_shoes(0)
	update_inv_s_store(0)
	update_wrist_r(0)
	update_wrist_l(0)
	update_amulet(0)
	update_back2(0)
	update_inv_wear_mask(0)
	update_inv_head(0)
	update_inv_belt(0)
	update_inv_back(0)
	update_inv_wear_suit(0)
	update_inv_r_hand(0)
	update_inv_l_hand(0)
	update_inv_handcuffed(0)
	update_inv_legcuffed(0)
	update_inv_pockets(0)
	update_fire()
	UpdateDamageIcon()
	UpdateArteryIcon()
	UpdateBandageIcon()
	update_transform()
	//Hud Stuff
	update_hud()

/* --------------------------------------- */
//vvvvvv UPDATE_INV PROCS vvvvvv




/mob/living/carbon/human/proc/update_pants(var/update_icons=1)
	if(w_uniform && istype(w_uniform, /obj/item/clothing/under))
		var/icon/I = w_uniform:update_pants(src)
		var/icon/IL = w_uniform:update_pants(src,TRUE)
		I = w_uniform:add_color(I)
		IL = w_uniform:add_color(IL)
		var/icon/overcloth = w_uniform:update_overclothes(src,LEGS)
		var/icon/lovercloth = w_uniform:update_overclothes(src,LEGS,TRUE)
		if(overcloth)
			I.Blend(overcloth, ICON_OVERLAY)
			IL.Blend(lovercloth, ICON_OVERLAY)
		overlays_standing[PANTS_LAYER] = image(I)
		overlays_lying[PANTS_LAYER] = image(IL)
	if(update_icons)	update_icons()


/mob/living/carbon/human/update_inv_w_uniform(var/update_icons=1)
	if(w_uniform && istype(w_uniform, /obj/item/clothing/under) )
		var/image/standing
		var/image/lying
		w_uniform.screen_loc = get_slot_loc("iclothing")
		var/t_color = w_uniform.item_color
		if(!t_color)		t_color = icon_state
		var/icon/stand	= w_uniform:update_body(src)
		var/icon/lie	= w_uniform:update_body(src,TRUE)
		stand = w_uniform:add_color(stand)
		lie = w_uniform:add_color(lie)

		var/icon/overcloth = w_uniform:update_overclothes(src,UPPER_TORSO)
		var/icon/lovercloth = w_uniform:update_overclothes(src,UPPER_TORSO,TRUE)
		if(overcloth)
			stand.Blend(overcloth, ICON_OVERLAY)
			lie.Blend(lovercloth, ICON_OVERLAY)
		standing = image(stand)
		lying = image(lie)
		if(w_uniform.blood_DNA)
			var/image/bloodsies	= image("icon" = 'icons/effects/blood.dmi', "icon_state" = "uniformblood")
			var/image/lbloodsies	= image("icon" = 'icons/effects/blood.dmi', "icon_state" = "uniformblood2")
			if(isChild(src))
				bloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "uniformblood")
				lbloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "2uniformblood")
			bloodsies.color		= w_uniform.blood_color
			lbloodsies.color		= w_uniform.blood_color
			standing.overlays	+= bloodsies
			lying.overlays	+= lbloodsies

	//	if(w_uniform:hastie)	//WE CHECKED THE TYPE ABOVE. THIS REALLY SHOULD BE FINE.
		//	var/tie_color = w_uniform:hastie.item_color
		//	if(!tie_color) tie_color = w_uniform:hastie.icon_state
		//	standing.overlays	+= image("icon" = 'icons/mob/ties.dmi', "icon_state" = "[tie_color]")
			//var/image/miglay	= icon("icon" = 'icons/mob/uniform.dmi', "icon_state" = "migover")
			//overlays_standing[ID_LAYER] = miglay
		overlays_standing[UNIFORM_LAYER]	= standing
		overlays_lying[UNIFORM_LAYER]		= lying
		src.update_above(0)
		src.update_pants(0)
	else
		overlays_standing[UNIFORM_LAYER]	= null
		overlays_standing[PANTS_LAYER]		= null
		overlays_lying[UNIFORM_LAYER]		= null
		overlays_lying[PANTS_LAYER]			= null
		src.update_above(0)
		// Automatically drop anything in store / id / belt if you're not wearing a uniform.	//CHECK IF NECESARRY
		for( var/obj/item/thing in list(r_store, l_store, belt, s_store) )						//
			if(thing)																			//
				u_equip(thing)																	//
				if (client)																		//
					client.screen -= thing														//
																								//
				if (thing)																		//
					thing.loc = loc																//
					thing.dropped(src)															//
					thing.layer = initial(thing.layer)
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_inv_wear_id(var/update_icons=1)
	if(wear_id)
		wear_id.screen_loc = get_slot_loc("id")	//TODO
		/*
		if(w_uniform && w_uniform:displays_id)
			overlays_standing[ID_LAYER]	= image("icon" = 'icons/mob/mob.dmi', "icon_state" = "id")
		else
			overlays_standing[ID_LAYER]	= null
	else
		overlays_standing[ID_LAYER]	= null
	*/
	if(update_icons)   update_icons()

/mob/living/carbon/human/proc/update_surgery(var/update_icons=1)
	for(var/datum/organ/external/chest/affecting in src.organs)
		if(affecting)
			if(affecting.dissected)
				overlays_standing[TAIL_LAYER]	= image("icon" = 'icons/obj/surgery.dmi', "icon_state" = "dissected4_s")
				overlays_lying[TAIL_LAYER]		= image("icon" = 'icons/obj/surgery.dmi', "icon_state" = "dissected4_l")
			else if(affecting.open == 2)
				overlays_standing[TAIL_LAYER]	= image("icon" = 'icons/obj/surgery.dmi', "icon_state" = "dissected2_s")
				overlays_lying[TAIL_LAYER]		= image("icon" = 'icons/obj/surgery.dmi', "icon_state" = "dissected2_l")
			else if(affecting.open >= 3)
				overlays_standing[TAIL_LAYER]	= image("icon" = 'icons/obj/surgery.dmi', "icon_state" = "dissected3_s")
				overlays_lying[TAIL_LAYER]		= image("icon" = 'icons/obj/surgery.dmi', "icon_state" = "dissected3_l")
			else if(affecting.open)
				overlays_standing[TAIL_LAYER]	= image("icon" = 'icons/obj/surgery.dmi', "icon_state" = "dissected1_s")
				overlays_lying[TAIL_LAYER]		= image("icon" = 'icons/obj/surgery.dmi', "icon_state" = "dissected1_l")
			else
				overlays_standing[TAIL_LAYER]	= null
				overlays_lying[TAIL_LAYER]		= null
		else
			overlays_standing[TAIL_LAYER]	= null
			overlays_lying[TAIL_LAYER]		= null
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_inv_gloves(var/update_icons=1)
	var/image/standing = image('icons/mob/human.dmi',"blank")
	var/image/lying = image('icons/mob/human.dmi',"blank")
	if(gloves)
		var/t_state = gloves.item_state
		if(!t_state)	t_state = gloves.icon_state
		var/datum/organ/external/HL = get_organ("l_hand")
		var/datum/organ/external/HR = get_organ("r_hand")
		var/hands = 'icons/mob/clothing/secondary/hands.dmi'
		if(gender == FEMALE && !(FAT in mutations))
			hands = 'icons/mob/clothing/secondary/hands_f.dmi'
		else if (FAT in mutations)
			hands = 'icons/mob/clothing/secondary/hands_fat.dmi'

		var/icon/sgloves = new('icons/mob/human.dmi',"blank")
		var/icon/lgloves = new('icons/mob/human.dmi',"blank")
		if(HR && !(HR.status & ORGAN_DESTROYED))
			sgloves.Blend(new/icon(hands,"[t_state]_rhand"),ICON_OVERLAY)
			lgloves.Blend(new/icon(hands,"[t_state]2_rhand"),ICON_OVERLAY)
		if(HL && !(HL.status & ORGAN_DESTROYED))
			sgloves.Blend(new/icon(hands,"[t_state]_lhand"),ICON_OVERLAY)
			lgloves.Blend(new/icon(hands,"[t_state]2_lhand"),ICON_OVERLAY)
		standing = image(sgloves)
		lying = image(lgloves)

		if(gloves.blood_DNA)
			var/image/bloodsies	= image("icon" = 'icons/effects/blood.dmi', "icon_state" = "bloodyhands")
			var/image/lbloodsies	= image("icon" = 'icons/effects/blood.dmi', "icon_state" = "bloodyhands2")
			if(isChild(src))
				bloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "bloodyhands")
				lbloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "bloodyhands2")
			bloodsies.color = gloves.blood_color
			lbloodsies.color = gloves.blood_color
			standing.overlays	+= bloodsies
			lying.overlays	+= lbloodsies
		gloves.screen_loc = get_slot_loc("gloves")
		overlays_standing[GLOVES_LAYER]	= standing
		overlays_lying[GLOVES_LAYER]	= lying
	else
		if(blood_DNA)
			var/image/bloodsies	= image("icon" = 'icons/effects/blood.dmi', "icon_state" = "bloodyhands")
			var/image/lbloodsies	= image("icon" = 'icons/effects/blood.dmi', "icon_state" = "bloodyhands2")
			if(isChild(src))
				bloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "bloodyhands")
				lbloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "bloodyhands2")
			bloodsies.color = hand_blood_color
			lbloodsies.color = hand_blood_color
			standing.overlays	+= bloodsies
			lying.overlays	+= lbloodsies
			overlays_standing[GLOVES_LAYER]	= standing
			overlays_lying[GLOVES_LAYER]	= lying
		else
			overlays_standing[GLOVES_LAYER]	= null
			overlays_lying[GLOVES_LAYER]	= null
	if(update_icons)   update_icons()


/mob/living/carbon/human/update_inv_glasses(var/update_icons=1)
	if(glasses)
		var/datum/organ/external/head/E = get_organ("head")
		if(E.headwrenched)
			overlays_standing[GLASSES_LAYER]	= image("icon" = ((glasses.icon_override) ? glasses.icon_override : 'icons/mob/clothing/secondary/eyes.dmi'), "icon_state" = "[glasses.icon_state]", dir = turn(src.dir, 180))
			overlays_lying[GLASSES_LAYER]	= null
		else
			overlays_standing[GLASSES_LAYER]	= image("icon" = ((glasses.icon_override) ? glasses.icon_override : 'icons/mob/clothing/secondary/eyes.dmi'), "icon_state" = "[glasses.icon_state]")
			overlays_lying[GLASSES_LAYER]	= image("icon" = ((glasses.icon_override) ? glasses.icon_override : 'icons/mob/clothing/secondary/eyes.dmi'), "icon_state" = "[glasses.icon_state]2")

	else
		overlays_standing[GLASSES_LAYER]	= null
		overlays_lying[GLASSES_LAYER]	= null
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_inv_ears(var/update_icons=1)
	if(l_ear || r_ear)
		if (gender == FEMALE && !(FAT in mutations))
			if(l_ear)
				overlays_standing[EARS_LAYER] = image("icon" = ((l_ear.icon_override) ? l_ear.icon_override : 'icons/mob/clothing/secondary/ears_f.dmi'), "icon_state" = "[l_ear.icon_state]")
				overlays_lying[EARS_LAYER] = image("icon" = ((l_ear.icon_override) ? l_ear.icon_override : 'icons/mob/clothing/secondary/ears_f.dmi'), "icon_state" = "[l_ear.icon_state]2")
			if(r_ear)
				overlays_standing[EARS_LAYER] = image("icon" = ((r_ear.icon_override) ? r_ear.icon_override : 'icons/mob/clothing/secondary/ears_f.dmi'), "icon_state" = "[r_ear.icon_state]")
				overlays_lying[EARS_LAYER] = image("icon" = ((r_ear.icon_override) ? r_ear.icon_override : 'icons/mob/clothing/secondary/ears_f.dmi'), "icon_state" = "[r_ear.icon_state]2")
		else
			if(l_ear)
				overlays_standing[EARS_LAYER] = image("icon" = ((l_ear.icon_override) ? l_ear.icon_override : 'icons/mob/clothing/secondary/ears.dmi'), "icon_state" = "[l_ear.icon_state]")
				overlays_lying[EARS_LAYER] = image("icon" = ((l_ear.icon_override) ? l_ear.icon_override : 'icons/mob/clothing/secondary/ears.dmi'), "icon_state" = "[l_ear.icon_state]2")
			if(r_ear)
				overlays_standing[EARS_LAYER] = image("icon" = ((r_ear.icon_override) ? r_ear.icon_override : 'icons/mob/clothing/secondary/ears.dmi'), "icon_state" = "[r_ear.icon_state]")
				overlays_lying[EARS_LAYER] = image("icon" = ((r_ear.icon_override) ? r_ear.icon_override : 'icons/mob/clothing/secondary/ears.dmi'), "icon_state" = "[r_ear.icon_state]2")
	else
		overlays_standing[EARS_LAYER]	= null
		overlays_lying[EARS_LAYER] = null
		clear_event("sheekos")
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_inv_shoes(var/update_icons=1)
	if(shoes)
		var/datum/organ/external/FL = get_organ("l_foot")
		var/datum/organ/external/FR = get_organ("r_foot")
		var/right_shoe = 'icons/mob/clothing/secondary/feet_right.dmi'
		var/left_shoe  = 'icons/mob/clothing/secondary/feet_left.dmi'
		if(gender == FEMALE && !(FAT in mutations) && !isChild())
			right_shoe = 'icons/mob/clothing/secondary/feet_f.dmi'
			left_shoe  = 'icons/mob/clothing/secondary/feet_f_left.dmi'

		var/icon/sshoes = new('icons/mob/human.dmi',"blank")
		var/icon/lshoes = new('icons/mob/human.dmi',"blank")
		if(FR && !(FR.status & ORGAN_DESTROYED))
			sshoes.Blend(new/icon(right_shoe,"[shoes.icon_state]"),ICON_OVERLAY)
			lshoes.Blend(new/icon(right_shoe,"[shoes.icon_state]2"),ICON_OVERLAY)
		if(FL && !(FL.status & ORGAN_DESTROYED))
			sshoes.Blend(new/icon(left_shoe,"[shoes.icon_state]"),ICON_OVERLAY)
			lshoes.Blend(new/icon(left_shoe,"[shoes.icon_state]2"),ICON_OVERLAY)
		var/image/standing = image(sshoes)
		var/image/lying = image(lshoes)
		if(shoes.blood_DNA)
			var/image/bloodsies = image("icon" = 'icons/effects/blood.dmi', "icon_state" = "shoeblood1")
			var/image/lbloodsies = image("icon" = 'icons/effects/blood.dmi', "icon_state" = "shoeblood12")
			if(isChild(src))
				bloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "shoeblood")
				lbloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "shoeblood2")
			bloodsies.color = shoes.blood_color
			lbloodsies.color = shoes.blood_color
			standing.overlays	+= bloodsies
			lying.overlays	+= lbloodsies
		overlays_standing[SHOES_LAYER]	= standing
		overlays_lying[SHOES_LAYER]	= lying
	else
		overlays_standing[SHOES_LAYER]		= null
		overlays_lying[SHOES_LAYER]	= null
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_inv_s_store(var/update_icons=1)
	if(s_store)
		var/t_state = s_store.item_state
		if(!t_state)	t_state = s_store.icon_state
		overlays_standing[SUIT_STORE_LAYER]	= image("icon" = 'icons/mob/clothing/secondary/belt2.dmi', "icon_state" = "[t_state]")
		overlays_lying[SUIT_STORE_LAYER]	= image("icon" = 'icons/mob/clothing/secondary/belt2.dmi', "icon_state" = "[t_state]2")
		s_store.screen_loc = get_slot_loc("sstore1")		//TODO
	else
		overlays_standing[SUIT_STORE_LAYER]	= null
		overlays_lying[SUIT_STORE_LAYER]	= null
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_wrist_r(var/update_icons=1)
	if(wrist_r)
		if(gender == FEMALE && !(FAT in mutations))
			overlays_standing[WRIST_R_LAYER]	= image("icon" = ((wrist_r.icon_override) ? wrist_r.icon_override : 'icons/mob/clothing/secondary/hands_f.dmi'), "icon_state" = "[wrist_r.item_state]_r")
			overlays_lying[WRIST_R_LAYER]	= image("icon" = ((wrist_r.icon_override) ? wrist_r.icon_override : 'icons/mob/clothing/secondary/hands_f.dmi'), "icon_state" = "[wrist_r.item_state]_r2")
		else
			overlays_standing[WRIST_R_LAYER]	= image("icon" = ((wrist_r.icon_override) ? wrist_r.icon_override : 'icons/mob/clothing/secondary/hands.dmi'), "icon_state" = "[wrist_r.item_state]_r")
			overlays_lying[WRIST_R_LAYER]	= image("icon" = ((wrist_r.icon_override) ? wrist_r.icon_override : 'icons/mob/clothing/secondary/hands.dmi'), "icon_state" = "[wrist_r.item_state]_r2")
	else
		overlays_standing[WRIST_R_LAYER]	= null
		overlays_lying[WRIST_R_LAYER]	= null
	if(istype(wrist_r, /obj/item/clothing/wrist/bracer))
		var/obj/item/clothing/wrist/bracer/B = wrist_r
		B.update_defense()
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_wrist_l(var/update_icons=1)
	if(wrist_l)
		if(gender == FEMALE && !(FAT in mutations))
			overlays_standing[WRIST_L_LAYER]	= image("icon" = ((wrist_l.icon_override) ? wrist_l.icon_override : 'icons/mob/clothing/secondary/hands_f.dmi'), "icon_state" = "[wrist_l.item_state]_l")
			overlays_lying[WRIST_L_LAYER]	= image("icon" = ((wrist_l.icon_override) ? wrist_l.icon_override : 'icons/mob/clothing/secondary/hands_f.dmi'), "icon_state" = "[wrist_l.item_state]_l2")
		else
			overlays_standing[WRIST_L_LAYER]	= image("icon" = ((wrist_l.icon_override) ? wrist_l.icon_override : 'icons/mob/clothing/secondary/hands.dmi'), "icon_state" = "[wrist_l.item_state]_l")
			overlays_lying[WRIST_L_LAYER]	= image("icon" = ((wrist_l.icon_override) ? wrist_l.icon_override : 'icons/mob/clothing/secondary/hands.dmi'), "icon_state" = "[wrist_l.item_state]_l2")
	else
		overlays_standing[WRIST_L_LAYER]	= null
		overlays_lying[WRIST_L_LAYER]	= null
	if(istype(wrist_l, /obj/item/clothing/wrist/bracer))
		var/obj/item/clothing/wrist/bracer/B = wrist_l
		B.update_defense()
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_amulet(var/update_icons=1)
	if(amulet)
		overlays_standing[AMULET_LAYER]	= image("icon" = ((amulet.icon_override) ? amulet.icon_override : 'icons/mob/clothing/secondary/amulet.dmi'), "icon_state" = "[amulet.icon_state]")
		overlays_lying[AMULET_LAYER]	= image("icon" = ((amulet.icon_override) ? amulet.icon_override : 'icons/mob/clothing/secondary/amulet.dmi'), "icon_state" = "[amulet.icon_state]2")
	else
		overlays_standing[AMULET_LAYER]	= null
		overlays_lying[AMULET_LAYER]	= null
		clear_event("godsave")
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_inv_head(var/update_icons=1)
	if(head)
		head.screen_loc = get_slot_loc("head")		//TODO
		var/icon/head_icon
		var/image/standing
		var/image/lying
		var/datum/organ/external/head/E = get_organ("head")
		if(E.headwrenched)
			head_icon = new/icon('icons/mob/clothing/secondary/head2.dmi')
		else
			head_icon = new/icon('icons/mob/clothing/secondary/head.dmi')
		standing	= image("icon" = head_icon, "icon_state" = "[head.icon_state]")
		lying	= image("icon" = head_icon, "icon_state" = "[head.icon_state]2")
		var/image/standing_image = image(standing)
		var/image/lying_image = image(lying)
		if(head:armor_layer)
			standing_image.overlays	+= image(head_icon, "icon_state" = "[head:armor_layer.icon_state]")
			lying_image.overlays	+= image(head_icon, "icon_state" = "[head:armor_layer.icon_state]2")
		if(head.blood_DNA)
			var/image/bloodsies = image("icon" = 'icons/effects/blood.dmi', "icon_state" = "helmetblood")
			var/image/lbloodsies = image("icon" = 'icons/effects/blood.dmi', "icon_state" = "helmetblood2")
			if(isChild(src))
				bloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "helmetblood")
				lbloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "helmetblood2")
			bloodsies.color = head.blood_color
			lbloodsies.color = head.blood_color
			standing_image.overlays	+= bloodsies
			lying_image.overlays	+= lbloodsies


		overlays_standing[HEAD_LAYER]	= standing_image
		overlays_lying[HEAD_LAYER]		= lying_image
	else
		overlays_standing[HEAD_LAYER]	= null
		overlays_lying[HEAD_LAYER]		= null
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_inv_belt(var/update_icons=1)
	if(belt)
		belt.screen_loc = get_slot_loc("belt")	//TODO
		var/t_state = belt.item_state
		if(istype(belt, /obj/item))
			var/obj/item/I = belt
			if(I.blood_suffix)
				t_state = initial(belt.item_state)

		if(!t_state)	t_state = belt.icon_state
		if(gender == FEMALE && !(FAT in mutations))
			overlays_standing[BELT_LAYER]	= image("icon" = ((belt.icon_override) ? belt.icon_override : 'icons/mob/clothing/secondary/belt_f.dmi'), "icon_state" = "[t_state]")
			overlays_lying[BELT_LAYER]	= image("icon" = ((belt.icon_override) ? belt.icon_override : 'icons/mob/clothing/secondary/belt_f.dmi'), "icon_state" = "[t_state]2")
		else
			overlays_standing[BELT_LAYER]	= image("icon" = ((belt.icon_override) ? belt.icon_override : 'icons/mob/clothing/secondary/belt.dmi'), "icon_state" = "[t_state]")
			overlays_lying[BELT_LAYER]	= image("icon" = ((belt.icon_override) ? belt.icon_override : 'icons/mob/clothing/secondary/belt.dmi'), "icon_state" = "[t_state]2")
	else
		overlays_standing[BELT_LAYER]	= null
		overlays_lying[BELT_LAYER]	= null
	if(update_icons)   update_icons()


/mob/living/carbon/human/update_inv_wear_suit(var/update_icons=1)
	if( wear_suit && istype(wear_suit, /obj/item/clothing/suit) )	//TODO check this
		wear_suit.screen_loc = get_slot_loc("oclothing")	//TODO
		var/image/standing = ""
		var/image/lying =  null
		/*
		if(gender == FEMALE)
			standing = image("icon" = ((wear_suit.icon_override) ? wear_suit.icon_override : 'icons/mob/suit_f.dmi'), "icon_state" = "[wear_suit.icon_state]")
		if(gender == MALE)
			standing = image("icon" = ((wear_suit.icon_override) ? wear_suit.icon_override : 'icons/mob/suit.dmi'), "icon_state" = "[wear_suit.icon_state]")
		if(FAT in src.mutations)
			standing = image("icon" = ((wear_suit.icon_override) ? wear_suit.icon_override : 'icons/mob/suit_fat.dmi'), "icon_state" = "[wear_suit.icon_state]")
		*/
		var/list/standing_image = wear_suit:update_worn_icon(src)
		var/list/lying_image = wear_suit:update_worn_icon(src,1)
		standing = image(standing_image)
		lying = image(lying_image)

		if( istype(wear_suit, /obj/item/clothing/suit/straight_jacket) )
			drop_from_inventory(handcuffed)
			drop_l_hand()
			drop_r_hand()

		if(wear_suit.blood_DNA)
			var/obj/item/clothing/suit/S = wear_suit
			var/image/bloodsies = image("icon" = 'icons/effects/blood.dmi', "icon_state" = "[S.blood_overlay_type]blood")
			var/image/bloodsiesl = image("icon" = 'icons/effects/blood.dmi', "icon_state" = "[S.blood_overlay_type]2")
			if(isChild(src))
				bloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "[S.blood_overlay_type]blood")
				bloodsiesl	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "[S.blood_overlay_type]2")
			bloodsies.color = wear_suit.blood_color
			standing.overlays	+= bloodsies
			lying.overlays += bloodsiesl

		overlays_standing[SUIT_LAYER]		= standing
		overlays_lying[SUIT_LAYER]		= lying

		update_tail_showing(0)
		src.update_above(0)
	else
		overlays_standing[SUIT_LAYER]	= null
		overlays_lying[SUIT_LAYER]		= null
		update_tail_showing(0)
		src.update_above(0)

	if(update_icons)   update_icons()

/mob/living/carbon/human/update_inv_pockets(var/update_icons=1)
	if(l_store)			l_store.screen_loc = get_slot_loc("storage1")	//TODO
	if(r_store)			r_store.screen_loc = get_slot_loc("storage2")	//TODO
	if(update_icons)	update_icons()


/mob/living/carbon/human/update_inv_wear_mask(var/update_icons=1)
	if(wear_mask && ( istype(wear_mask, /obj/item/clothing/mask) || istype(wear_mask, /obj/item/clothing/tie) ) )
		wear_mask.screen_loc = get_slot_loc("mask")	//TODO
		var/icon/mask_icon
		var/image/standing
		var/image/lying
		var/datum/organ/external/head/E = get_organ("head")
		if(E.headwrenched)
			mask_icon = new/icon('icons/mob/clothing/secondary/mask2.dmi')
		else
			mask_icon = new/icon('icons/mob/clothing/secondary/mask.dmi')
		standing	= image("icon" = mask_icon, "icon_state" = "[wear_mask.icon_state]")
		lying	= image("icon" = mask_icon, "icon_state" = "[wear_mask.icon_state]2")
		var/image/standing_image = image(standing)
		var/image/lying_image = image(lying)
		if(wear_mask.blood_DNA)
			var/image/bloodsies = image("icon" = 'icons/effects/blood.dmi', "icon_state" = "maskblood")
			var/image/lbloodsies = image("icon" = 'icons/effects/blood.dmi', "icon_state" = "maskblood2")
			if(isChild(src))
				bloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "maskblood")
				lbloodsies	= image("icon" = 'icons/mob/human_races/child/blood_child.dmi', "icon_state" = "maskblood2")
			bloodsies.color = wear_mask.blood_color
			lbloodsies.color = wear_mask.blood_color
			standing_image.overlays	+= bloodsies
			lying_image.overlays	+= lbloodsies


		overlays_standing[FACEMASK_LAYER]	= standing_image
		overlays_lying[FACEMASK_LAYER]		= lying_image
	else
		overlays_standing[FACEMASK_LAYER]	= null
		overlays_lying[FACEMASK_LAYER]		= null
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_inv_back(var/update_icons=1)
	if(back)
		var/t_state = back.item_state ? back.item_state : back.icon_state
		back.screen_loc = get_slot_loc("back")	//TODO
		var/obj/item/weapon/storage/backpack/B
		if(istype(back, /obj/item/weapon/storage/backpack))
			B = back
		if(gender == FEMALE && !back.RightLeft)
			overlays_standing[BACK_LAYER]	= image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back_f.dmi'), "icon_state" = "[t_state]")
			overlays_lying[BACK_LAYER]	= image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back_f.dmi'), "icon_state" = "[t_state]2")
			if(B && B.diffcolor)
				overlays_standing[BACK_LAYER].color = B.diffcolor
				overlays_lying[BACK_LAYER].color = B.diffcolor
			underlays_standing[U_BACK] = null
			underlays_lying[U_BACK] = null
		else
			if(back.RightLeft)
				var/image/img_back	= image('icons/mob/human.dmi',"blank")
				var/image/uimg_back	= image('icons/mob/human.dmi',"blank")
				underlays_standing[U_BACK] = image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back.dmi'), "icon_state" = "[t_state]_under")
				underlays_lying[U_BACK] = image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back.dmi'), "icon_state" = "[t_state]_under2")
				if(r_hand || (FAT in mutations))
					img_back.overlays += image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back.dmi'), "icon_state" = "x[t_state]_right")
					uimg_back.overlays += image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back.dmi'), "icon_state" = "x[t_state]_right2")
				else
					img_back.overlays += image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back.dmi'), "icon_state" = "[t_state]_right")
					uimg_back.overlays += image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back.dmi'), "icon_state" = "[t_state]_right2")
				if(l_hand || (FAT in mutations))
					img_back.overlays += image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back.dmi'), "icon_state" = "x[t_state]_left")
					uimg_back.overlays += image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back.dmi'), "icon_state" = "x[t_state]_left2")
				else
					img_back.overlays += image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back.dmi'), "icon_state" = "[t_state]_left")
					uimg_back.overlays += image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back.dmi'), "icon_state" = "[t_state]_left2")
				overlays_standing[BACK_LAYER]	= img_back
				overlays_lying[BACK_LAYER]		= uimg_back
				if(update_icons) update_icons()
				return

			underlays_standing[U_BACK] = null
			underlays_lying[U_BACK] = null
			overlays_standing[BACK_LAYER]	= image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back.dmi'), "icon_state" = "[t_state]")
			overlays_lying[BACK_LAYER]	= image("icon" = ((back.icon_override) ? back.icon_override : 'icons/mob/items/back.dmi'), "icon_state" = "[t_state]2")
			if(B && B.diffcolor)
				overlays_standing[BACK_LAYER].color = B.diffcolor
				overlays_lying[BACK_LAYER].color = B.diffcolor
	else
		underlays_standing[U_BACK] = null
		underlays_lying[U_BACK] = null
		overlays_standing[BACK_LAYER]	= null
		overlays_lying[BACK_LAYER]	= null
		overlays_standing[BACK_LAYER_HALF]	= null
		overlays_lying[BACK_LAYER_HALF]	= null
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_back2(var/update_icons=1)

	if(back2 && back2.item_state)
		var/t_state = back2.item_state ? back2.item_state : back2.icon_state
		back2.screen_loc = get_slot_loc("back2")	//TODO
		overlays_standing[BACK2_LAYER]	= image("icon" = ((back2.icon_override) ? back2.icon_override : 'icons/mob/items/back2.dmi'), "icon_state" = "[t_state]")
		overlays_lying[BACK2_LAYER]	= image("icon" = ((back2.icon_override) ? back2.icon_override : 'icons/mob/items/back2.dmi'), "icon_state" = "[t_state]2")
	else
		overlays_standing[BACK2_LAYER]	= null
		overlays_lying[BACK2_LAYER]	= null
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_hud()	//TODO: do away with this if possible
	if(client)
		client.screen |= contents
		if(hud_used)
			hud_used.hidden_inventory_update() 	//Updates the screenloc of the items on the 'other' inventory bar


/mob/living/carbon/human/update_inv_handcuffed(var/update_icons=1)
	if(handcuffed)
		drop_r_hand()
		drop_l_hand()
		stop_pulling()	//TODO: should be handled elsewhere
		overlays_standing[HANDCUFF_LAYER]	= image("icon" = 'icons/mob/mob.dmi', "icon_state" = "handcuff1")
		overlays_lying[HANDCUFF_LAYER]	= image("icon" = 'icons/mob/mob.dmi', "icon_state" = "handcuff2")
	else
		overlays_standing[HANDCUFF_LAYER]	= null
		overlays_lying[HANDCUFF_LAYER]	= null
	if(update_icons)   update_icons()

/mob/living/carbon/human/update_inv_legcuffed(var/update_icons=1)
	if(legcuffed)
		overlays_standing[LEGCUFF_LAYER]	= image("icon" = 'icons/mob/mob.dmi', "icon_state" = "legcuff1")
		overlays_lying[LEGCUFF_LAYER]	= image("icon" = 'icons/mob/mob.dmi', "icon_state" = "legcuff2")
		if(src.m_intent != "walk")
			src.m_intent = "walk"
			if(src.hud_used && src.hud_used.move_intent)
				src.hud_used.move_intent.icon_state = "walking"

	else
		overlays_standing[LEGCUFF_LAYER]	= null
		overlays_lying[LEGCUFF_LAYER]	= null
	if(update_icons)   update_icons()


/mob/living/carbon/human/update_inv_r_hand(var/update_icons=1) //Fix huge items using ripple layer. That doesn't work. They should have a custom index and use the FLY_LAYER
	underlays_standing[U_R_HAND_LAYER] = null //null at start since some items don't use this.
	if(r_hand)
		r_hand.screen_loc = get_slot_loc("rhand")	//TODO
		var/t_state = r_hand.item_state
		if(!t_state)	t_state = r_hand.icon_state
		if(r_hand.wielded_icon && r_hand.wielded)
			overlays_standing[R_HAND_LAYER] = image("icon" = 'icons/mob/items/items_2hand.dmi', "icon_state" = "r_[t_state]")
			var/icon/I = new('icons/mob/items/items_2hand.dmi', "r_[t_state]")
			I.Turn(90)
			overlays_lying[R_HAND_LAYER] = image(I)
			if(r_hand.wielded_underlay)
				underlays_standing[U_R_HAND_LAYER] = image("icon" = 'icons/mob/items/items_2hand.dmi', "icon_state" = "r_[t_state]B")
		else
			if(r_hand.bigitem)
				overlays_standing[TOTAL_LAYERS] = image("icon" = 'icons/mob/items/hugeitems_righthand.dmi', "icon_state" = "[t_state]")
				var/icon/I = new('icons/mob/items/hugeitems_righthand.dmi', "[t_state]")
				I.Turn(90)
				overlays_lying[TOTAL_LAYERS] = image(I)
			else
				overlays_standing[R_HAND_LAYER] = image("icon" = 'icons/mob/items/items_righthand.dmi', "icon_state" = "[t_state]")
				overlays_lying[R_HAND_LAYER] = image("icon" = 'icons/mob/items/items_righthand2.dmi', "icon_state" = "[t_state]")
			if(r_hand.hand_underlay)
				underlays_standing[U_R_HAND_LAYER] = image("icon" = 'icons/mob/items/items_righthand.dmi', "icon_state" = "[t_state]_u")
		if (handcuffed) drop_l_hand()
	else
		underlays_standing[U_R_HAND_LAYER] = null
		overlays_standing[R_HAND_LAYER] = null
		overlays_lying[R_HAND_LAYER] = null
		overlays_standing[TOTAL_LAYERS] = null
	update_inv_back(0)
	if(update_icons)   update_icons()


/mob/living/carbon/human/update_inv_l_hand(var/update_icons=1) //Fix huge items using ripple layer. That doesn't work. They should have a custom index and use the FLY_LAYER
	underlays_standing[U_L_HAND_LAYER] = null //null at start since some items don't use this.
	if(l_hand)
		l_hand.screen_loc = get_slot_loc("lhand")	//TODO
		var/t_state = l_hand.item_state
		if(!t_state)	t_state = l_hand.icon_state
		if(l_hand.wielded_icon && l_hand.wielded)
			overlays_standing[L_HAND_LAYER] = image("icon" = 'icons/mob/items/items_2hand.dmi', "icon_state" = "l_[t_state]")
			var/icon/I = new('icons/mob/items/items_2hand.dmi', "l_[t_state]")
			I.Turn(90)
			overlays_lying[L_HAND_LAYER] = image(I)
			if(l_hand.wielded_underlay)
				underlays_standing[U_L_HAND_LAYER] = image("icon" = 'icons/mob/items/items_2hand.dmi', "icon_state" = "l_[t_state]B")
		else
			if(l_hand.bigitem)
				overlays_standing[TOTAL_LAYERS] = image("icon" = 'icons/mob/items/hugeitems_lefthand.dmi', "icon_state" = "[t_state]")
				var/icon/I = new('icons/mob/items/hugeitems_lefthand.dmi', "[t_state]")
				I.Turn(90)
				overlays_lying[TOTAL_LAYERS] = image(I)
			else
				overlays_standing[L_HAND_LAYER] = image("icon" = 'icons/mob/items/items_lefthand.dmi', "icon_state" = "[t_state]")
				overlays_lying[L_HAND_LAYER] = image("icon" = 'icons/mob/items/items_lefthand2.dmi', "icon_state" = "[t_state]")
			if(l_hand.hand_underlay)
				underlays_standing[U_L_HAND_LAYER] = image("icon" = 'icons/mob/items/items_lefthand.dmi', "icon_state" = "[t_state]_u")
		if (handcuffed) drop_l_hand()
	else
		underlays_standing[U_L_HAND_LAYER] = null
		overlays_standing[L_HAND_LAYER] = null
		overlays_lying[L_HAND_LAYER] = null
		overlays_standing[TOTAL_LAYERS] = null
	update_inv_back(0)
	if(update_icons)   update_icons()

/mob/living/carbon/human/proc/update_tail_showing(var/update_icons=1)
	overlays_standing[TAIL_LAYER] = null

	if(species.tail)
		if(!wear_suit || !(wear_suit.flags_inv & HIDETAIL) && !istype(wear_suit, /obj/item/clothing/suit/space))
			var/icon/tail_s = new/icon("icon" = 'icons/effects/species.dmi', "icon_state" = "[species.tail]_s")
//			tail_s.Blend(rgb(r_skin, g_skin, b_skin), ICON_ADD)

			overlays_standing[TAIL_LAYER]	= image(tail_s)

	if(update_icons)
		update_icons()

// Used mostly for creating head items
/mob/living/carbon/human/proc/generate_head_icon()
//gender no longer matters for the mouth, although there should probably be seperate base head icons.
//	var/g = "m"
//	if (gender == FEMALE)	g = "f"

	//base icons
	var/icon/head_icon = 'icons/mob/flesh/old/human_face_old.dmi'
	var/icon/face_lying		= new /icon('icons/mob/flesh/old/human_face_old.dmi',"bald_s")
	if(gender == FEMALE)
		head_icon = 'icons/mob/flesh/old/human_f_face_old.dmi'
	if(f_style)
		var/datum/sprite_accessory/facial_hair_style = facial_hair_styles_list[f_style]
		if(facial_hair_style)
			var/icon/facial_l = new/icon("icon" = head_icon, "icon_state" = "[facial_hair_style.icon_state]_s", dir = SOUTH)
			facial_l.Blend(rgb(r_facial, g_facial, b_facial), ICON_ADD)
			face_lying.Blend(facial_l, ICON_OVERLAY)

	if(h_style)
		var/datum/sprite_accessory/hair_style = hair_styles_list[h_style]
		if(hair_style)
			var/icon/hair_l = new/icon("icon" = head_icon, "icon_state" = "[hair_style.icon_state]_s", dir = SOUTH)
			hair_l.Blend(rgb(r_hair, g_hair, b_hair), ICON_ADD)
			face_lying.Blend(hair_l, ICON_OVERLAY)

	//Eyes
	// Note: These used to be in update_face(), and the fact they're here will make it difficult to create a disembodied head
	var/icon/eyes_l = new/icon('icons/mob/human.dmi', "eyes_s", dir = SOUTH)
	eyes_l.Blend(rgb(r_eyes, g_eyes, b_eyes), ICON_MULTIPLY)
	face_lying.Blend(eyes_l, ICON_OVERLAY)

	if(ExposedFang)
		var/icon/fangs = new/icon('icons/mob/flesh/old/human_face_old.dmi', "fangs", dir = SOUTH)
		face_lying.Blend(fangs, ICON_OVERLAY)


	var/image/face_lying_image = new /image(icon = face_lying)
	return face_lying_image

/mob/living/carbon/human/proc/add_coldbreath(var/update_icons=1)
	if(coldbreath)	return //We alreayd have coldbreath don't add it again.
	//if(wear_mask)	return //Don't need this if we're wearing a mask.
	if(stat == DEAD || wear_mask)//	return //Don't need this if we're dead
		overlays_standing[COLDBREATH_LAYER] = null
	var/image/standing = overlay_image('icons/mob/cold_breath.dmi', "breath")
	overlays_standing[COLDBREATH_LAYER] = standing
	coldbreath = TRUE

	if(update_icons)	update_icons()

/mob/living/carbon/human/proc/add_smelly(var/update_icons=1)
//	overlays_standing[SMELLING_LAYER] = null
	if(!smelly_vis)
		smelly_vis = new()
		smelly_vis.icon = 'icons/effects/life/effects.dmi'
		smelly_vis.icon_state = "smell"
		smelly_vis.name = ""
		smelly_vis.mouse_opacity = 0
		smelly_vis.vis_flags = 0
	if(vis_contents.Find(smelly_vis))
		return
	vis_contents += smelly_vis
//	overlays_standing[SMELLING_LAYER] = standing

//	if(update_icons)	update_icons()

/mob/living/carbon/human/proc/remove_smelly(var/update_icons=1)
	vis_contents -= smelly_vis
/*
	overlays_standing[SMELLING_LAYER] = null
	var/image/standing = null
	overlays_standing[SMELLING_LAYER] = standing

	if(update_icons)	update_icons()
	update_hair()
*/
/mob/living/carbon/human/proc/add_hood(var/update_icons=1)
	overlays_standing[HOOD_LAYER] = null
	var/image/standing = overlay_image('icons/mob/clothing/suit.dmi', "mortician-hood")
	overlays_standing[HOOD_LAYER] = standing

	if(update_icons)	update_icons()
	update_hair(1)
	return

/mob/living/carbon/human/proc/remove_hood(var/update_icons=1)
	overlays_standing[HOOD_LAYER] = null
	var/image/standing = null
	overlays_standing[HOOD_LAYER] = standing

	if(update_icons)	update_icons()
	update_hair(1)
	return

/mob/living/carbon/human/proc/add_aim(var/update_icons=1)
	overlays_standing[AIMED_LAYER] = null
	var/image/standing = overlay_image('icons/life/screen1.dmi', "target")
	overlays_standing[AIMED_LAYER] = standing

	if(update_icons)	update_icons()
	return

/mob/living/carbon/human/proc/remove_aim(var/update_icons=1)
	overlays_standing[AIMED_LAYER] = null
	var/image/standing = null
	overlays_standing[AIMED_LAYER] = standing

	if(update_icons)	update_icons()
	return


/mob/living/carbon/human/proc/bodyhair(var/update_icons=1)
	var/fat = (FAT in src.mutations)
	if(ismonster(src)) return
	overlays_standing[BODYHAIR_LAYER] = null
	overlays_lying[BODYHAIR_LAYER] = null
	if(species.name == "Human" && !fat)
		var/prefix = gender == FEMALE? "f" : ""
		var/image/standing = overlay_image('icons/mob/human_detail.dmi', "[prefix]bodyhair_s")
		var/image/lying = overlay_image('icons/mob/human_detail.dmi', "[prefix]bodyhair_l")
		standing.color = rgb(r_hair, g_hair, b_hair)
		lying.color = rgb(r_hair, g_hair, b_hair)
		overlays_standing[BODYHAIR_LAYER] = standing
		overlays_lying[BODYHAIR_LAYER] = lying

//Human Overlays Indexes/////////
#undef MUTANTRACE_LAYER
#undef MUTATIONS_LAYER
#undef DAMAGE_LAYER
#undef UNIFORM_LAYER
#undef ID_LAYER
#undef SHOES_LAYER
#undef GLOVES_LAYER
#undef EARS_LAYER
#undef SUIT_LAYER
#undef GLASSES_LAYER
#undef FACEMASK_LAYER
#undef BELT_LAYER
#undef SUIT_STORE_LAYER
#undef BACK_LAYER
#undef HAIR_LAYER
#undef HEAD_LAYER
#undef HANDCUFF_LAYER
#undef LEGCUFF_LAYER
#undef L_HAND_LAYER
#undef R_HAND_LAYER
#undef TAIL_LAYER
#undef TARGETED_LAYER
#undef TOTAL_LAYERS
#undef FIRE_LAYER

/mob/living/carbon/human/var/QUEMLIGA = 0

