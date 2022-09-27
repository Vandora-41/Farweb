// Alien larva are quite simple.
/mob/living/carbon/alien/Life()

	set invisibility = 0
	set background = 1

	if (monkeyizing)	return
	if(!loc)			return

	..()

	if(stat != DEAD)
		evolve_time = max(0, evolve_time-2)
		if(evolve_time == 0)
			var/mob/living/carbon/human/new_xeno = new(src.loc)
			new_xeno.vice = pick(VicesList)
			if(src.client)
				src.mind.transfer_to(new_xeno)
			new_xeno.gender = MALE
			new_xeno.age = rand(30,45)
			new_xeno.real_name  = "Alien"
			new_xeno.name = "Alien"
			new_xeno.voice_name = "Alien"
			new_xeno.h_style = random_hair_style(gender = new_xeno.gender, species = "Human")
			new_xeno.f_style = random_facial_hair_style(gender = new_xeno.gender, species = "Human")
			new_xeno.updateStatPanel()
			new_xeno.update_icons()
			new_xeno.FuncArea()
			var/area/A = get_area(new_xeno)
			A.Entered(new_xeno)
			new_xeno.create_kg()
			new_xeno.set_species("Alien")
			new_xeno.add_perk(/datum/perk/illiterate)
			playsound(src.loc, pick('sound/webbers/alien_turn.ogg','sound/webbers/alien_turn2.ogg', 'sound/webbers/alien_turn3.ogg'), 60, 1)
			qdel(src)

	blinded = null

	if(loc)
		handle_environment(loc.return_air())

	//Status updates, death etc.
	handle_regular_status_updates()
	update_canmove()
	update_icons()

	if(client)
		handle_regular_hud_updates()

/mob/living/carbon/alien/proc/handle_regular_status_updates()

	if(status_flags & GODMODE)	return 0

	if(stat == DEAD)
		blinded = 1
		silent = 0
	else
		updatehealth()

		if(health <= 0)
			death()
			blinded = 1
			silent = 0
			return 1

		if(paralysis)
			AdjustParalysis(-1)
			blinded = 1
			stat = UNCONSCIOUS
			if(halloss > 0)
				adjustHalLoss(-3)
		else if(sleeping)

			adjustHalLoss(-3)
			if (mind)
				if((mind.active && client != null) || immune_to_ssd)
					sleeping = max(sleeping-1, 0)
			blinded = 1
			stat = UNCONSCIOUS

		else if(resting)
			if(halloss > 0)
				adjustHalLoss(-3)

		else
			stat = CONSCIOUS
			if(halloss > 0)
				adjustHalLoss(-1)

		// Eyes and blindness.
		if(!has_eyes())
			eye_blind =  1
			blinded =    1
			eye_blurry = 1
		else if(eye_blind)
			eye_blind =  max(eye_blind-1,0)
			blinded =    1
		else if(eye_blurry)
			eye_blurry = max(eye_blurry-1, 0)

		//Ears
		if(sdisabilities & DEAF)	//disabled-deaf, doesn't get better on its own
			ear_deaf = max(ear_deaf, 1)
		else if(ear_deaf)			//deafness, heals slowly over time
			ear_deaf = max(ear_deaf-1, 0)
			ear_damage = max(ear_damage-0.05, 0)

		update_icons()

	return 1

/mob/living/carbon/alien/proc/handle_regular_hud_updates()

	if (stat == 2 || (XRAY in src.mutations))
		sight |= SEE_TURFS
		sight |= SEE_MOBS
		sight |= SEE_OBJS
		see_in_dark = 8
		see_invisible = SEE_INVISIBLE_LEVEL_TWO
	else if (stat != 2)
		sight &= ~SEE_TURFS
		sight &= ~SEE_MOBS
		sight &= ~SEE_OBJS
		see_in_dark = 2
		see_invisible = SEE_INVISIBLE_LIVING

	if (healths)
		if (stat != 2)
			switch(health)
				if(100 to INFINITY)
					healths.icon_state = "health0"
				if(80 to 100)
					healths.icon_state = "health1"
				if(60 to 80)
					healths.icon_state = "health2"
				if(40 to 60)
					healths.icon_state = "health3"
				if(20 to 40)
					healths.icon_state = "health4"
				if(0 to 20)
					healths.icon_state = "health5"
				else
					healths.icon_state = "health6"
		else
			healths.icon_state = "health7"

	if(pullin)
		pullin.icon_state = "pull[pulling ? 1 : 0]"

	if (client)
		client.screen.Remove(global_hud.blurry,global_hud.druggy,global_hud.vimpaired)
/*
	if ((blind && stat != 2))
		if ((blinded))
			blind.layer = 18
		else
			blind.layer = 0
			if (disabilities & NEARSIGHTED)
				client.screen += global_hud.vimpaired
			if (eye_blurry)
				client.screen += global_hud.blurry
			if (druggy)
				client.screen += global_hud.druggy
*/
	handle_hud_vision()

	if (stat != 2)
		if (machine)
			if (!( machine.check_eye(src) ))
				reset_view(null)
		else
			if(client && !client.adminobs)
				reset_view(null)

	return 1

/mob/living/carbon/alien/proc/handle_environment(var/datum/gas_mixture/environment)
	// Both alien subtypes survive in vaccum and suffer in high temperatures,
	// so I'll just define this once, for both (see radiation comment above)
	if(!environment) return

	if(environment.temperature > (T0C+66))
		adjustFireLoss((environment.temperature - (T0C+66))/5) // Might be too high, check in testing.
		if (fire) fire.icon_state = "fire2"
		if(prob(20))
			src << "\red You feel a searing heat!"
	else
		if (fire) fire.icon_state = "fire0"
