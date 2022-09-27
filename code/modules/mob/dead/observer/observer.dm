var/list/NOIRLIST = list(0.3,0.3,0.3,0,\
			 			 0.3,0.3,0.3,0,\
						 0.3,0.3,0.3,0,\
						 0.0,0.0,0.0,1,)

var/siegereinforcements = 0
var/list/siegelist = list()

/mob/dead/observer
	name = "wraith"
	desc = "A lost shadow on the limbo." //jinkies!
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghost"
	layer = 4

	stat = DEAD
	density = 0
	canmove = 0
	blinded = 0
	anchored = 1	//  don't get pushed around
	invisibility = INVISIBILITY_OBSERVER
	var/can_reenter_corpse
	var/datum/hud/living/carbon/hud = null // hud
	var/bootime = 0
	var/started_as_observer //This variable is set to 1 when you enter the game as an observer.
							//If you died in the game and are a ghsot - this will remain as null.
							//Note that this is not a reliable way to determine if admins started as observers, since they change mobs a lot.
	var/has_enabled_antagHUD = 0
	var/medHUD = 0
	var/antagHUD = 0
	var/latepartied = FALSE
	universal_speak = 1
	var/wraith_pain = 0
	var/in_hell = FALSE
	var/atom/movable/following = null
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE

/mob/dead/observer/Stat()
	if(client?.current_button == "note" && client.statpanel_loaded == TRUE)
		client.newtext(noteUpdate())

/mob/dead/observer/proc/Sendtohell()
	if(in_hell)
		return
	for(var/obj/effect/landmark/L in landmarks_list)
		if (L.name == "Hell")
			src.forceMove(L.loc)
	wraith_pain = 0
	in_hell = TRUE
	src?.client?.color = "#ed7a72"
	src << sound('sound/music/ghostloop.ogg', repeat = 1, wait = 0, volume = src?.client?.prefs?.music_volume, channel = 12)

/mob/dead/observer/New(mob/body)
	//sight |= SEE_TURFS | SEE_MOBS | SEE_OBJS | SEE_SELF
	see_invisible = SEE_INVISIBLE_OBSERVER
	see_in_dark = 100
	//verbs += /mob/dead/observer/proc/dead_tele
	src.add_filter_effects()
	stat = DEAD
	var/turf/T
	if(ismob(body))
		T = get_turf(body)				//Where is the body located?
		attack_log = body.attack_log	//preserve our attack logs by copying them to our ghost

		if (ishuman(body))
			var/mob/living/carbon/human/H = body
			icon = H.stand_icon
			overlays = H.overlays_standing
		else
			icon = body.icon
			icon_state = body.icon_state
			overlays = body.overlays

		alpha = 127

		gender = body.gender
		if(body.mind && body.mind.name)
			name = body.mind.name
		else
			if(body.real_name)
				name = body.real_name
			else
				if(gender == MALE)
					name = capitalize(pick(first_names_male)) + " " + capitalize(pick(last_names))
				else
					name = capitalize(pick(first_names_female)) + " " + capitalize(pick(last_names))

		mind = body.mind	//we don't transfer the mind but we keep a reference to it.

	if(!T)	T = pick(latejoin)			//Safety in case we cannot find the body's position
	loc = T

	if(!name)							//To prevent nameless ghosts
		name = capitalize(pick(first_names_male)) + " " + capitalize(pick(last_names))
	real_name = name
	..()


/mob/proc/add_overlay_wraith()
	clear_fullscreen("dob")
	overlay_fullscreen("ghost", /obj/screen/fullscreen/wraithoverlay, 1)

/mob/proc/add_overlay_dreamer()
	overlay_fullscreen("dreamer", /obj/screen/fullscreen/dreamer, rand(1,8))


/mob/dead/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	return 1
/*
Transfer_mind is there to check if mob is being deleted/not going to have a body.
Works together with spawning an observer, noted above.
*/
/obj/structure/wraith_pain
	name = "pain"
	density = 0
	opacity = 0
	icon = 'icons/mob/mob.dmi'
	icon_state = "pain"
	anchored = 1
	layer = 4
	appearance_flags = NO_CLIENT_COLOR
	invisibility = INVISIBILITY_OBSERVER

/obj/structure/Destroy()
	loc = null
	qdel(reagents)
	reagents = null

/obj/structure/wraith_pain/Crossed(mob/dead/observer/O)
	if(istype(O, /mob/dead/observer))
		var/multiplier = 1
		if(ticker?.eof?.id == "ghostpower")
			multiplier = 3
		O.wraith_pain += 5 * multiplier
		to_chat(O, "<spanclass='jogtowalk'>5 Pain collected.</span>")
		O << sound('sound/spectre/w_consume.ogg', repeat = 0, wait = 0, volume = 70, channel = 25)
		qdel(src)
		return

/mob/dead/observer/Life()
	..()
	if(!loc) return
	if(!client) return 0


	if(client.images.len)
		for(var/image/hud in client.images)
			if(copytext(hud.icon_state,1,4) == "hud")
				client.images.Remove(hud)
	if(antagHUD)
		var/list/target_list = list()
		for(var/mob/living/target in oview(src))
			if( target.mind&&(target.mind.special_role||issilicon(target)) )
				target_list += target
		if(target_list.len)
			assess_targets(target_list, src)
	if(medHUD)
		process_medHUD(src)


// Direct copied from medical HUD glasses proc, used to determine what health bar to put over the targets head.
/mob/dead/proc/RoundHealth(var/health)
	switch(health)
		if(100 to INFINITY)
			return "health100"
		if(70 to 100)
			return "health80"
		if(50 to 70)
			return "health60"
		if(30 to 50)
			return "health40"
		if(18 to 30)
			return "health25"
		if(5 to 18)
			return "health10"
		if(1 to 5)
			return "health1"
		if(-99 to 0)
			return "health0"
		else
			return "health-100"
	return "0"


// Pretty much a direct copy of Medical HUD stuff, except will show ill if they are ill instead of also checking for known illnesses.

/mob/dead/proc/process_medHUD(var/mob/M)
	var/client/C = M.client
	var/image/holder
	for(var/mob/living/carbon/human/patient in oview(M))
		var/foundVirus = 0
		if(patient.virus2.len)
			foundVirus = 1
		if(!C) return
		holder = patient.hud_list[HEALTH_HUD]
		if(patient.stat == 2)
			holder.icon_state = "hudhealth-100"
		else
			holder.icon_state = "hud[RoundHealth(patient.health)]"
		C.images += holder

		holder = patient.hud_list[STATUS_HUD]
		if(patient.stat == 2)
			holder.icon_state = "huddead"
		else if(patient.status_flags & XENO_HOST)
			holder.icon_state = "hudxeno"
		else if(foundVirus)
			holder.icon_state = "hudill"
		else
			holder.icon_state = "hudhealthy"

		C.images += holder


/mob/dead/proc/assess_targets(list/target_list, mob/dead/observer/U)
	var/icon/tempHud = 'icons/mob/hud.dmi'
	for(var/mob/living/target in target_list)
		if(iscarbon(target))
			switch(target.mind.special_role)
				if("traitor","Syndicate")
					U.client.images += image(tempHud,target,"hudsyndicate")
				if("Revolutionary")
					U.client.images += image(tempHud,target,"hudrevolutionary")
				if("Head Revolutionary")
					U.client.images += image(tempHud,target,"hudheadrevolutionary")
				if("Cultist")
					U.client.images += image(tempHud,target,"hudcultist")
				if("Changeling")
					U.client.images += image(tempHud,target,"hudchangeling")
				if("Wizard","Fake Wizard")
					U.client.images += image(tempHud,target,"hudwizard")
				if("Hunter","Sentinel","Drone","Queen")
					U.client.images += image(tempHud,target,"hudalien")
				if("Death Commando")
					U.client.images += image(tempHud,target,"huddeathsquad")
				if("Ninja")
					U.client.images += image(tempHud,target,"hudninja")
				else//If we don't know what role they have but they have one.
					U.client.images += image(tempHud,target,"hudunknown1")
		else if(issilicon(target))//If the silicon mob has no law datum, no inherent laws, or a law zero, add them to the hud.
			var/mob/living/silicon/silicon_target = target
			if(!silicon_target.laws||(silicon_target.laws&&(silicon_target.laws.zeroth||!silicon_target.laws.inherent.len))||silicon_target.mind.special_role=="traitor")
				if(isrobot(silicon_target))//Different icons for robutts and AI.
					U.client.images += image(tempHud,silicon_target,"hudmalborg")
				else
					U.client.images += image(tempHud,silicon_target,"hudmalai")
	return 1

/mob/proc/ghostize(var/can_reenter_corpse = 1)
	if(key)
		var/mob/dead/observer/ghost = new(src)	//Transfer safety to observer spawning proc.
		ghost.can_reenter_corpse = can_reenter_corpse
		ghost.timeofdeath = src.timeofdeath //BS12 EDIT
		ghost.key = key
		add_overlay_wraith()
		ghost.add_overlay_wraith()
		ghost << sound(pick('sound/lfwbambi/ghosted1.ogg','sound/lfwbambimusic/geist.ogg','sound/lfwbambi/ghosted4.ogg','sound/lfwbambi/ghosted2.ogg'), repeat = 0, wait = 0, volume =  src?.client?.prefs?.music_volume, channel = 12)
		ghost << sound(null, repeat = 0, wait = 0, volume =  0, channel = 9) // remove the ambience
		ghost << sound(null, repeat = 0, wait = 0, volume = 0, channel = 2)
		ghost << sound(null, repeat = 1, wait = 0, volume = 70, channel = 4)
/*
		if(ghost.client)
			if(!ghost.client.holder && !config.antag_hud_allowed)		// For new ghosts we remove the verb from even showing up if it's not allowed.
				ghost.verbs -= /mob/dead/observer/verb/toggle_antagHUD	// Poor guys, don't know what they are missing!
*/
		spawn(5)
			to_chat(ghost, "\n<div class='firstdivmood'><div class='moodbox'><span class='graytext'>Your adventures are not over. You may join a Late Party or soulbreaker squad.</span>\n<span class='feedback'><a href='?src=\ref[src];action=joinlateparty'>1. I agree.</a></span>\n<span class='feedback'><a href='?src=\ref[src];action=rejlateparty'>2. I refuse.</a></span></div></div>")
			ghost.lateparty()

		if(ticker && ticker.current_state == GAME_STATE_PLAYING && master_mode == "inspector")
			to_chat(src, "\n<div class='firstdivmood'><div class='moodbox'><span class='graytext'>You may join as the Inspector or his bodyguard.</span>\n<span class='feedback'><a href='?src=\ref[src];acao=joininspectree'>1. I want to.</a></span>\n<span class='feedback'><a href='?src=\ref[src];acao=nao'>2. I'll pass.</a></span></div></div>")

		if(ghost.client && !ghost.client.holder)
			animate(ghost.client, color = NOIRLIST, time = 10)
		return ghost

/*
This is the proc mobs get to turn into a ghost. Forked from ghostize due to compatibility issues.
*/
/client/Topic(href, href_list, hsrc)
	..()
	switch(href_list["action"])
		if("joinlateparty")
			if(istype(src.mob, /mob/dead))
				var/mob/dead/observer/O = src.mob
				O.lateparty()

/mob/living/proc/ghost()
	set category = "dead"
	set name = "Wraith"
	set desc = "Wraith"
	if(!ishuman(src))
		if(stat == DEAD)
			ghostize(1)
	else
		if(ishuman(src))
			var/mob/living/carbon/human/H = src
			if(H.stat == DEAD)
				if(H.time_since_death < 60)
					var/timertt = 60 - H.time_since_death
					to_chat(src, "<span class='bluetext'>[timertt] seconds before peace.</span>")
					return
				else
					if(src.becoming_zombie)
						to_chat(src, "You're preparing to walk again.")
						return
					else
						ghostize(1)
	return

/mob/dead/observer/Move(NewLoc, direct)
	following = null
	..()

/mob/dead/observer/movement_delay()
	return 3

/mob/dead/observer/examine()
	if(usr)
		to_chat(usr, "[desc]")

/mob/dead/observer/can_use_hands()	return 0
/mob/dead/observer/is_active()		return 0
/mob/dead/observer/verb/reenter_corpse()
	set category = "dead"
	set name = "ReenterCorpse"
	set desc = "Re-enter Corpse"
	if(!client)
		return
	if(!(mind?.current))
		return
	if(!can_reenter_corpse)
		return
	if(mind.current.key && copytext(mind.current.key,1,2)!="@")	//makes sure we don't accidentally kick any clients"
		return
	mind.current.ajourn=0
	mind.current.key = key
	return 1

/mob/dead/observer/proc/ForceToHellRespawn()
	if(!client)
		log_game("[usr.key] AM failed due to disconnect.")
		return
	client.screen.Cut()
	if(!client)
		log_game("[usr.key] AM failed due to disconnect.")
		return
	var/mob/new_player/M = new /mob/new_player()
	if(!client)
		log_game("[usr.key] AM failed due to disconnect.")
		qdel(M)
		return
	src << sound(null, repeat = 1, wait = 0, 0, channel = 12)
	M.key = key
	M.old_key = key
	M.old_job = job
	M.client.color = null
	to_chat(M, "You have found peace.")
	M.unlock_medal("Ain't No Grave", 0, "Come back from the Limbo.", "8")
	return

var/list/usedremig = list()
/mob/dead/observer/verb/abandon_mob()
	set name = "GotoHell"
	set category = "dead"
	set desc = "Go to Hell"

	if(ticker?.mode.config_tag == "siege")
		client.screen.Cut()
		var/mob/new_player/M = new /mob/new_player()
		M.key = key
		M.old_key = key
		M.old_job = job
		M.client.color = null
		return

	else if(master_mode != "holywar" && master_mode != "minimig")
		if (!( abandon_allowed ))
			to_chat(src, "Respawn is disabled.")
			return
		if ((stat != 2 || !( ticker )))
			to_chat(src, "<B>You must be dead to use this!</B>")
			return
		if(remigrator.Find(ckey) && !usedremig.Find(ckey))
			usedremig += ckey
			client.screen.Cut()
			var/mob/new_player/M = new /mob/new_player()
			M.key = key
			M.old_key = key
			M.old_job = job
			M.client.color = null
			return
	//	if (ticker.mode.name == "meteor" || ticker.mode.name == "epidemic") //BS12 EDIT
	//		usr << "\blue Respawn is disabled for this roundtype."
	//		return
	//	else
		var/deathtime = world.time - src.timeofdeath
		var/deathtimeminutes = round(deathtime / 600)
		var/pluralcheck = "minute"
		if(deathtimeminutes == 0)
			pluralcheck = ""
		else if(deathtimeminutes == 1)
			pluralcheck = " [deathtimeminutes] minute and"
		else if(deathtimeminutes > 1)
			pluralcheck = " [deathtimeminutes] minutes and"
		var/deathtimeseconds = round((deathtime - deathtimeminutes * 600) / 10,1)
		usr << "You have been dead for [pluralcheck] [deathtimeseconds] seconds."

		if(mind.current)
			if(!mind.current.buried && mind.current.loc != /obj/structure/closet/coffin) //If our current body is destroyed (incinerator etc.) it copunts as buried
				to_chat(src, "Your body is not buried nor destroyed.")
				return
/*
		if (deathtime < 6000)
			to_chat(src, "You must wait 10 minutes to escape from the limbo!")
			return
*/
		log_game("[usr.name]/[usr.key] used abandon mob.")

		to_chat(src, " <B>Make sure to play a different personality!</B>")
		src << sound(null, repeat = 1, wait = 0, volume = src?.client?.prefs?.music_volume, channel = 12)

		if(!client)
			log_game("[usr.key] AM failed due to disconnect.")
			return
		client.screen.Cut()
		if(!client)
			log_game("[usr.key] AM failed due to disconnect.")
			return

		var/mob/new_player/M = new /mob/new_player()
		if(!client)
			log_game("[usr.key] AM failed due to disconnect.")
			qdel(M)
			return

		M.key = key
		M.old_key = key
		M.old_job = job
		M.client.color = null
	else
		if ((stat != 2 || !( ticker )))
			usr << "\blue <B>You must be dead to use this!</B>"
			return
		var/deathtime = world.time - src.timeofdeath
		var/deathtimeminutes = round(deathtime / 600)
		var/pluralcheck = "minute"
		if(deathtimeminutes == 0)
			pluralcheck = ""
		else if(deathtimeminutes == 1)
			pluralcheck = " [deathtimeminutes] minute and"
		else if(deathtimeminutes > 1)
			pluralcheck = " [deathtimeminutes] minutes and"
		var/deathtimeseconds = round((deathtime - deathtimeminutes * 600) / 10,1)
		to_chat(usr, "You have been dead for[pluralcheck] [deathtimeseconds] seconds.")

		if (deathtime < 1200)
			to_chat(usr, "You must wait 2 minutes to escape from the limbo!")
			return
		to_chat(usr, "<B>Make sure to play a different soldier!</B>")
		client.screen.Cut()
		var/mob/new_player/M = new /mob/new_player()
		M.key = key
		M.old_key = key
		M.old_job = job
		M.client.color = null
	return
/*
/mob/dead/observer/verb/toggle_medHUD()
	set category = "Ghost"
	set name = "Toggle MedicHUD"
	set desc = "Toggles Medical HUD allowing you to see how everyone is doing"
	if(!client)
		return
	if(medHUD)
		medHUD = 0
		src << "\blue <B>Medical HUD Disabled</B>"
	else
		medHUD = 1
		src << "\blue <B>Medical HUD Enabled</B>"
*/
/*
/mob/dead/observer/verb/toggle_antagHUD()
	set category = "Ghost"
	set name = "Toggle AntagHUD"
	set desc = "Toggles AntagHUD allowing you to see who is the antagonist"
	if(!config.antag_hud_allowed && !client.holder)
		src << "\red Admins have disabled this for this round."
		return
	if(!client)
		return
	var/mob/dead/observer/M = src
	if(jobban_isbanned(M, "AntagHUD"))
		src << "\red <B>You have been banned from using this feature</B>"
		return
	if(config.antag_hud_restricted && !M.has_enabled_antagHUD &&!client.holder)
		var/response = alert(src, "If you turn this on, you will not be able to take any part in the round.","Are you sure you want to turn this feature on?","Yes","No")
		if(response == "No") return
		M.can_reenter_corpse = 0
	if(!M.has_enabled_antagHUD && !client.holder)
		M.has_enabled_antagHUD = 1
	if(M.antagHUD)
		M.antagHUD = 0
		src << "\blue <B>AntagHUD Disabled</B>"
	else
		M.antagHUD = 1
		src << "\blue <B>AntagHUD Enabled</B>"
*/
/mob/dead/observer/proc/dead_tele()
	set category = "Wraith"
	set name = "Teleport"
	set desc= "Teleport to a location"
	if(!istype(usr, /mob/dead/observer))
		usr << "Not when you're not dead!"
		return
	usr.verbs -= /mob/dead/observer/proc/dead_tele
	spawn(30)
		usr.verbs += /mob/dead/observer/proc/dead_tele
	var/A
	A = input("Area to jump to", "BOOYEA", A) as null|anything in ghostteleportlocs
	var/area/thearea = ghostteleportlocs[A]
	if(!thearea)	return

	var/list/L = list()
	for(var/turf/T in get_area_turfs(thearea.type))
		L+=T

	if(!L || !L.len)
		usr << "No area available."

	following = null
	usr.loc = pick(L)

/mob/dead/observer/verb/boo()
	set category = "Wraith"
	set name = "Flick the Lights"
	set desc= "Scare your crew members because of boredom!"

	if(bootime > world.time) return
	var/obj/machinery/light/L = locate(/obj/machinery/light) in view(1, src)
	if(L)
		L.flicker()
		bootime = world.time + 600
		return
	//Maybe in the future we can add more <i>spooky</i> code here!
	return


/mob/dead/observer/memory()
	set hidden = 1
	src << "\red You are dead! You have no mind to store memory!"

/mob/dead/observer/add_memory()
	set hidden = 1
	src << "\red You are dead! You have no mind to store memory!"
/*
/mob/dead/observer/verb/analyze_air()
	set name = "Analyze Air"
	set category = "Ghost"

	if(!istype(usr, /mob/dead/observer)) return

	// Shamelessly copied from the Gas Analyzers
	if (!( istype(usr.loc, /turf) ))
		return

	var/datum/gas_mixture/environment = usr.loc.return_air()

	var/pressure = environment.return_pressure()
	var/total_moles = environment.total_moles

	src << "\blue <B>Results:</B>"
	if(abs(pressure - ONE_ATMOSPHERE) < 10)
		src << "\blue Pressure: [round(pressure,0.1)] kPa"
	else
		src << "\red Pressure: [round(pressure,0.1)] kPa"
	if(total_moles)
		for(var/g in environment.gas)
			src << "\blue [gas_data.name[g]]: [round((environment.gas[g] / total_moles) * 100)]% ([round(environment.gas[g], 0.01)] moles)"
		src << "\blue Temperature: [round(environment.temperature-T0C,0.1)]&deg;C"
		src << "\blue Heat Capacity: [round(environment.heat_capacity(),0.1)]"
*/

/mob/dead/observer/verb/toggle_darkness()
	set name = "ToggleDarkness"
	set desc = "Shroud Thickness"
	set category = "dead"

	if (see_invisible == SEE_INVISIBLE_OBSERVER_NOLIGHTING)
		see_invisible = SEE_INVISIBLE_OBSERVER
	else
		see_invisible = SEE_INVISIBLE_OBSERVER_NOLIGHTING
/*
/mob/dead/observer/verb/become_mouse()
	set name = "Become mouse"
	set category = "Ghost"

	if(config.disable_player_mice)
		src << "<span class='warning'>Spawning as a mouse is currently disabled.</span>"
		return

	var/mob/dead/observer/M = usr
	if(config.antag_hud_restricted && M.has_enabled_antagHUD == 1)
		src << "<span class='warning'>antagHUD restrictions prevent you from spawning in as a mouse.</span>"
		return

	var/timedifference = world.time - client.time_died_as_mouse
	if(client.time_died_as_mouse && timedifference <= mouse_respawn_time * 600)
		var/timedifference_text
		timedifference_text = time2text(mouse_respawn_time * 600 - timedifference,"mm:ss")
		src << "<span class='warning'>You may only spawn again as a mouse more than [mouse_respawn_time] minutes after your death. You have [timedifference_text] left.</span>"
		return

	var/response = alert(src, "Are you -sure- you want to become a mouse?","Are you sure you want to squeek?","Squeek!","Nope!")
	if(response != "Squeek!") return  //Hit the wrong key...again.


	//find a viable mouse candidate
	var/mob/living/simple_animal/mouse/host
	var/obj/machinery/atmospherics/unary/vent_pump/vent_found
	var/list/found_vents = list()
	for(var/obj/machinery/atmospherics/unary/vent_pump/v in world)
		if(!v.welded && v.z == src.z)
			found_vents.Add(v)
	if(found_vents.len)
		vent_found = pick(found_vents)
		host = new /mob/living/simple_animal/mouse(vent_found.loc)
	else
		src << "<span class='warning'>Unable to find any unwelded vents to spawn mice at.</span>"

	if(host)
		if(config.uneducated_mice)
			host.universal_understand = 0
		host.ckey = src.ckey
		host << "<span class='info'>You are now a mouse. Try to avoid interaction with players, and do not give hints away that you are more than a simple rodent.</span>"

/mob/dead/observer/verb/view_manfiest()
	set name = "View Crew Manifest"
	set category = "Ghost"

	var/dat
	dat += "<h4>Crew Manifest</h4>"
	dat += data_core.get_manifest()

	src << browse(dat, "window=manifest;size=370x420;can_close=1")

//Used for drawing on walls with blood puddles as a spooky ghost.
*/
/*
/mob/dead/verb/bloody_doodle()

	set category = "Wraith"
	set name = "Write in blood"
	set desc = "If the round is sufficiently spooky, write a short message in blood on the floor or a wall. Remember, no IC in OOC or OOC in IC."

	if(!(config.cult_ghostwriter))
		src << "\red That verb is not currently permitted."
		return

	if (!src.stat)
		return

	if (usr != src)
		return 0 //something is terribly wrong

	var/ghosts_can_write
	if(ticker && ticker.mode.name == "cult")
		var/datum/game_mode/cult/C = ticker.mode
		if(C.cult.len > config.cult_ghostwriter_req_cultists)
			ghosts_can_write = 1

	if(!ghosts_can_write)
		src << "\red The veil is not thin enough for you to do that."
		return

	var/list/choices = list()
	for(var/obj/effect/decal/cleanable/blood/B in view(1,src))
		if(B.amount > 0)
			choices += B

	if(!choices.len)
		src << "<span class = 'warning'>There is no blood to use nearby.</span>"
		return

	var/obj/effect/decal/cleanable/blood/choice = input(src,"What blood would you like to use?") in null|choices

	var/direction = input(src,"Which way?","Tile selection") as anything in list("Here","North","South","East","West")
	var/turf/simulated/T = src.loc
	if (direction != "Here")
		T = get_step(T,text2dir(direction))

	if (!istype(T))
		src << "<span class='warning'>You cannot doodle there.</span>"
		return

	if(!choice || choice.amount == 0 || !(src.Adjacent(choice)))
		return

	var/doodle_color = (choice.basecolor) ? choice.basecolor : "#A10808"

	var/num_doodles = 0
	for (var/obj/effect/decal/cleanable/blood/writing/W in T)
		num_doodles++
	if (num_doodles > 4)
		src << "<span class='warning'>There is no space to write on!</span>"
		return

	var/max_length = 50

	var/message = stripped_input(src,"Write a message. It cannot be longer than [max_length] characters.","Blood writing", "")

	if (message)

		if (length(message) > max_length)
			message += "-"
			src << "<span class='warning'>You ran out of blood to write with!</span>"

		var/obj/effect/decal/cleanable/blood/writing/W = PoolOrNew(/obj/effect/decal/cleanable/blood/writing, T)
		W.basecolor = doodle_color
		W.update_icon()
		W.message = message
		W.add_hiddenprint(src)
		W.visible_message("\red Invisible fingers crudely paint something in blood on [T]...")
		*/
/*COISAS RANDOM DE GHOST.*/
/obj/machinery/door/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover, /mob/dead/observer))
		return 1
	. = ..()
/obj/machinery/door/CheckExit(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover, /mob/dead/observer))
		return 1
	. = ..()
/obj/structure/grille/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover, /mob/dead/observer))
		return 1
	. = ..()
/obj/structure/grille/CheckExit(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover, /mob/dead/observer))
		return 1
	. = ..()

/obj/structure/grille/reinforced/l/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover, /mob/dead/observer))
		return 1
	. = ..()
/obj/structure/grille/reinforced/l/CheckExit(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover, /mob/dead/observer))
		return 1
	. = ..()

/obj/structure/mineral_door/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover, /mob/dead/observer))
		return 1
	. = ..()

/obj/structure/mineral_door/CheckExit(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover, /mob/dead/observer))
		return 1
	. = ..()

/obj/structure/CheckExit(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover, /mob/dead/observer))
		return 1
	. = ..()