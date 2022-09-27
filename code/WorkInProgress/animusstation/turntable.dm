#define TURNTABLE_CHANNEL 10


/mob/var/datum/hear_music/hear_music
#define NONE_MUSIC 0
#define UPLOADING 1
#define PLAYING 2

/datum/hear_music
	var/mob/target = null
	//var/sound/sound
	var/status = NONE_MUSIC
	var/stop = 0

	proc/play(sound/S)
		status = NONE_MUSIC
		if(!target)
			return
		if(!S)
			return
		status = UPLOADING
		target << browse_rsc(S)
		//sound = S
		if(target.hear_music != src)
			qdel(src)
		if(!stop)
			target << S
			status = PLAYING
		else
			qdel(src)

	proc/stop()
		if(!target)
			return
		if(status == PLAYING)
			var/sound/S = sound(null)
			S.channel = 10
			S.wait = 1
			target << S
			qdel(src)
		else if(status == UPLOADING)
			stop = 1
		target.hear_music = null


/mob/var/sound/music

/datum/turntable_soundtrack
	var/f_name
	var/name
	var/path
	var/probability = 100

/obj/machinery/party/turntable
	name = "Jukebox"
	desc = "A jukebox is a partially automated music-playing device, usually a coin-operated machine, that will play a patron's selection from self-contained media."
	icon = 'icons/effects/lasers2.dmi'
	icon_state = "Jukebox7"
	var/obj/item/weapon/disk/music/disk
	var/playing = 0
	var/datum/turntable_soundtrack/track = null
	var/volume = 100
	var/list/turntable_soundtracks = list()
	anchored = 1
	density = 1
	var/sound_id
	var/datum/sound_token/sound_token
	var/done = 0

/obj/machinery/party/turntable/New()
	..()
	sound_id = "[type]_[sequential_id(type)]"

/obj/machinery/party/turntable/New()
	..()
	for(var/obj/machinery/party/turntable/TT) // NO WAY
		if(TT != src)
			qdel(src)
	turntable_soundtracks = list()
	spawn(10 SECONDS)
		for(var/mob/living/carbon/human/H in mob_list)
			if(findtext(H.real_name, "White") || findtext(H.real_name, "Heisenberg"))
				var/datum/turntable_soundtrack/D = new()
				D.f_name = "D"
				D.name = "LZ "
				D.path = 'sound/turntable/out-of-my-territory.ogg'
				turntable_soundtracks.Add(D)

	for(var/i in typesof(/datum/turntable_soundtrack) - /datum/turntable_soundtrack)
		var/datum/turntable_soundtrack/D = new i()
		if(D.path)
			if(prob(D.probability))
				turntable_soundtracks.Add(D)


/obj/machinery/party/turntable/attackby(obj/O, mob/user)
	if(istype(O, /obj/item/weapon/disk/music) && !disk)
		var/obj/item/weapon/disk/music/M = O
		if(M.bloqueado)
			to_chat(user, "The disk is blocked.")
			return
		user.drop_item()
		O.loc = src
		disk = O
		attack_hand(user)


/obj/machinery/party/turntable/attack_paw(user as mob)
	return src.attack_hand(user)

/obj/machinery/party/turntable/attack_hand(mob/living/user as mob)
	if (..())
		return

	if(!done)
		for(var/mob/living/carbon/human/H in mob_list)
			if(findtext(H.real_name, "White") || findtext(H.real_name, "Heisenberg"))
				var/datum/turntable_soundtrack/D = new()
				D.f_name = "D"
				D.name = "LZ "
				D.path = 'sound/turntable/out-of-my-territory.ogg'
				turntable_soundtracks.Add(D)
		done = 1

	usr.set_machine(src)
	src.add_fingerprint(usr)

	var/t = "<body style='background-color:#0e0c0e; color: #5e1f26;'>"
	t += "<A href='?src=\ref[src];on=1'>On</A><br>"
	if(disk)
		t += "<A href='?src=\ref[src];eject=1'>Eject disk</A><br>"
	t += "<tr><td height='50' weight='50'></td><td height='50' weight='50'><A href='?src=\ref[src];off=1'><font color='red'>T</font><font color='lightgreen'>urn</font> <font color='red'>Off</font></A></td><td height='50' weight='50'></td></tr>"
	t += "<tr>"


	var/lastcolor = "red"
	for(var/i = 10; i <= 100; i += 10)
		t += "<A href='?src=\ref[src];set_volume=[i]'><font color='[lastcolor]'>[i]</font></A> "
		if(lastcolor == "red")
			lastcolor = "red"
		else
			lastcolor = "red"

	var/i = 0
	for(var/datum/turntable_soundtrack/D in turntable_soundtracks)
		t += "<td height='50' weight='50'><A href='?src=\ref[src];on=\ref[D]'><font color='maroon'>[D.f_name]</font><font color='[lastcolor]'>[D.name]</font></A></td>"
		i++
		if(i == 1)
			lastcolor = "red"
		else
			lastcolor = "red"
		if(i == 3)
			i = 0
			t += "</tr><tr>"

	if(disk)
		if(disk.data)
			t += "<td height='50' weight='50'><A href='?src=\ref[src];on=\ref[disk.data]'><font color='maroon'>[disk.data.f_name]</font><font color='[lastcolor]'>[disk.data.name]</font></A></td>"
		else
			t += "<td height='50' weight='50'><font color='maroon'>D</font><font color='[lastcolor]'>isk empty</font></td>"

	t += "</table></div></body>"
	user << browse(t, "window=turntable;size=450x150;can_resize=0")
	onclose(user, "turntable")
	return

/obj/machinery/party/turntable/power_change()
	turn_off()

/obj/machinery/party/turntable/Topic(href, href_list)
	if(..())
		return
	if(href_list["on"])
		turn_on(locate(href_list["on"]))

	else if(href_list["off"])
		turn_off()

	else if(href_list["set_volume"])
		set_volume(text2num(href_list["set_volume"]))

	else if(href_list["eject"])
		if(disk)
			disk.loc = src.loc
			if(disk.data && track == disk.data)
				turn_off()
				track = null
			disk = null

/obj/machinery/party/turntable/process()
	if(playing)
		update_sound()

/obj/machinery/party/turntable/proc/turn_on(var/datum/turntable_soundtrack/selected)
	if(playing)
		turn_off()
	if(selected)
		track = selected
	if(!track)
		return

	sound_token = sound_player.PlayLoopingSound(src, sound_id, track.path, volume = volume, range = 13, falloff = 3, prefer_mute = TRUE)

	var/area/A = get_area(src)
	for(var/area/RA in A.related)
		for(var/obj/machinery/party/lasermachine/L in RA)
			L.turnon()

	playing = 1

/obj/machinery/party/turntable/proc/turn_off()
	if(!playing)
		return
	sound_token = sound_player.PlayLoopingSound(src, sound_id, track.path, volume = 0, range = 13, falloff = 3, prefer_mute = TRUE)

	playing = 0
	var/area/A = get_area(src)
	for(var/area/RA in A.related)
		for(var/obj/machinery/party/lasermachine/L in RA)
			L.turnoff()

/obj/machinery/party/turntable/proc/set_volume(var/new_volume)
	volume = max(0, min(100, new_volume))
	if(playing)
		update_sound(1)

/obj/machinery/party/turntable/proc/update_sound(update = 0)
	return

/obj/machinery/party/turntable/proc/create_sound(mob/M)
	//var/area/A = get_area(src)
	//var/inRange = (get_area(M) in A.related)
	var/sound/S = sound(track.path)
	S.repeat = 1
	S.channel = TURNTABLE_CHANNEL
	S.falloff = 2
	S.wait = 0
	S.volume = 0
	S.status = 0 //SOUND_STREAM
	M.music = S
	M << S

/obj/machinery/party/mixer
	name = "mixer"
	desc = "A mixing board for mixing music"
	icon = 'icons/effects/lasers2.dmi'
	icon_state = "mixer"
	density = 0
	anchored = 1

/obj/machinery/party/lasermachine
	name = "laser machine"
	desc = "A laser machine that shoots lasers."
	icon = 'icons/effects/lasers2.dmi'
	icon_state = "lasermachine"
	anchored = 1
	var/mirrored = 0

/obj/effect/laser2
	name = "laser"
	desc = "A laser..."
	icon = 'icons/effects/lasers2.dmi'
	icon_state = "laserred1"
	anchored = 1
	layer = 4

/obj/machinery/party/lasermachine/proc/turnon()
	var/wall = 0
	var/cycle = 1
	var/area/A = get_area(src)
	var/X = 1
	var/Y = 0
	if(mirrored == 0)
		while(wall == 0)
			if(cycle == 1)
				var/obj/effect/laser2/F = new/obj/effect/laser2(src)
				F.x = src.x+X
				F.y = src.y+Y
				F.z = src.z
				F.icon_state = "laserred1"
				var/area/AA = get_area(F)
				var/turf/T = get_turf(F)
				if(T.density == 1 || AA.name != A.name)
					qdel(F)
					return
				cycle++
				if(cycle > 3)
					cycle = 1
				X++
			if(cycle == 2)
				var/obj/effect/laser2/F = new/obj/effect/laser2(src)
				F.x = src.x+X
				F.y = src.y+Y
				F.z = src.z
				F.icon_state = "laserred2"
				var/area/AA = get_area(F)
				var/turf/T = get_turf(F)
				if(T.density == 1 || AA.name != A.name)
					qdel(F)
					return
				cycle++
				if(cycle > 3)
					cycle = 1
				Y++
			if(cycle == 3)
				var/obj/effect/laser2/F = new/obj/effect/laser2(src)
				F.x = src.x+X
				F.y = src.y+Y
				F.z = src.z
				F.icon_state = "laserred3"
				var/area/AA = get_area(F)
				var/turf/T = get_turf(F)
				if(T.density == 1 || AA.name != A.name)
					qdel(F)
					return
				cycle++
				if(cycle > 3)
					cycle = 1
				X++
	if(mirrored == 1)
		while(wall == 0)
			if(cycle == 1)
				var/obj/effect/laser2/F = new/obj/effect/laser2(src)
				F.x = src.x+X
				F.y = src.y-Y
				F.z = src.z
				F.icon_state = "laserred1m"
				var/area/AA = get_area(F)
				var/turf/T = get_turf(F)
				if(T.density == 1 || AA.name != A.name)
					qdel(F)
					return
				cycle++
				if(cycle > 3)
					cycle = 1
				Y++
			if(cycle == 2)
				var/obj/effect/laser2/F = new/obj/effect/laser2(src)
				F.x = src.x+X
				F.y = src.y-Y
				F.z = src.z
				F.icon_state = "laserred2m"
				var/area/AA = get_area(F)
				var/turf/T = get_turf(F)
				if(T.density == 1 || AA.name != A.name)
					qdel(F)
					return
				cycle++
				if(cycle > 3)
					cycle = 1
				X++
			if(cycle == 3)
				var/obj/effect/laser2/F = new/obj/effect/laser2(src)
				F.x = src.x+X
				F.y = src.y-Y
				F.z = src.z
				F.icon_state = "laserred3m"
				var/area/AA = get_area(F)
				var/turf/T = get_turf(F)
				if(T.density == 1 || AA.name != A.name)
					qdel(F)
					return
				cycle++
				if(cycle > 3)
					cycle = 1
				X++



/obj/machinery/party/lasermachine/proc/turnoff()
	var/area/A = src.loc.loc
	for(var/area/RA in A.related)
		for(var/obj/effect/laser2/F in RA)
			qdel(F)

