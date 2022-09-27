/datum/organ/external/proc/add_pain(var/number)
	src.painLW += number

/datum/organ/external/proc/remove_pain(var/number)
	src.painLW -= number

/mob/living/carbon/human/proc/feel_pain_check() //Check if they can feel pain at all. Add whatever other pain chems or special cases here please.
	if(stat == DEAD) // Use this instead of writing your own huge ass fucking list.
		return FALSE
	if(iszombie(src))
		return FALSE
	if(ismonster(src))
		return FALSE
	if(consyte)
		return FALSE
	if(analgesic)
		return FALSE
	if(status_flags & STATUS_NO_PAIN)
		return FALSE
	if(species && species.flags & NO_PAIN)
		return FALSE
	if(reagents.has_reagent("dentrine"))
		return FALSE
	if(reagents.has_reagent("morphine"))
		return FALSE
	if(reagents.has_reagent("heroin"))
		return FALSE
	if(reagents.has_reagent("oxycodone"))
		return FALSE
	if(reagents.has_reagent("tramadol"))
		return FALSE
	return TRUE

/mob/living/carbon/human/var
	painLWThresold = 100

/mob/living/carbon/proc/get_pain()
	if(!ishuman(src)) return 0
	var/mob/living/carbon/human/H = src
	var/totaldor = null
	if(!H.feel_pain_check())
		return 0
	for(var/datum/organ/external/E in H.organs)
		totaldor += E.painLW
	if(totaldor>0) return totaldor
	else return 0


/mob/living/carbon/human/proc/handle_painLW()
	var/dolor = get_pain()
	if(!dolor)
		return
	var/AmounttoLose = 0
	//Comicao, why the fuck does get_pain() not by default return 0 if you don't feel pain?
	if(feel_pain_check() && dolor >= (70 + my_stats.get_stat(STAT_HT)*2))
		tryingtosleep = FALSE
	if(sleeping && (tryingtosleep || death_door))
		AmounttoLose = 6
	else
		var/amount = 1
		if(eye_closed == TRUE)
			amount = 2
		AmounttoLose = 0.14 * amount

	if(src.stat == DEAD)
		AmounttoLose = 0

	for(var/datum/organ/external/E in organs)
		if(E.painLW-AmounttoLose <= 0)
			E.painLW = 0
			continue
		if(E.painLW-AmounttoLose > 0)
			E.painLW -= AmounttoLose


//med em geral

/mob/living/carbon/human/proc/death_door()
	if(death_door) return
	to_chat(src, "<span class='hugepain'><b>You're knockin' on death's door!</b></span>")
	eye_blurry = max(eye_blurry-3, 0)
	blinded = 1
	death_door = 1
	src.updateStatPanel()


/mob/living/carbon/human/proc/undeath_door()
	if(!death_door) return
	death_door = 0
	src.updateStatPanel()


/mob/living/carbon/human/proc/can_death_door(var/argumento = 1)
	if(death_door && argumento)return

	if(species && species.name == "Zombie")return

	if(species && istype(species, /datum/species/human/alien))return

	if(isVampire)return

	return 1



/mob/living/carbon/human/proc/handle_knock()
	//O QUE MATA: ~FALTA DE AR, DOR(ATAQUE CARDIACO), ATAQUE CARDÍACO, ~CHOQUE HIPOVOLÊMICO, INFECÇÕES, ARRITMIA
	var/morte_temporizador = 660 //1 minuto ate morrer pq os outros tira 60
	if(src.death_door==0 && src.can_death_door())
		if(handle_pulse() == PULSE_NONE && ((!iszombie(src)) && (src.mind && !src.mind.changeling))) //this is awful.
			death_door()
			morte_temporizador -= 60

		var/datum/organ/internal/heart/HE = (locate() in internal_organs)
		if(HE)
			if(HE.stopped_working)
				morte_temporizador -= 120
				death_door()

		var/blood_volume = round(vessel.get_reagent_amount("blood"))
		switch(blood_volume)
			if(0 to BLOOD_VOLUME_SURVIVE)
				morte_temporizador -= 60
				death_door()


		if(getOxyLoss() > 60)
			death_door()
			morte_temporizador -= 60

		if(src.death_door)
			spawn(morte_temporizador)// ja deu a cota porra
				if(src.death_door)//so pra ver se vai morrer mesmo
					src.death()