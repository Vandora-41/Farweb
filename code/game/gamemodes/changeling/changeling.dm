var/list/possible_changeling_IDs = list("Alpha","Beta","Gamma","Delta","Epsilon","Zeta","Eta","Theta","Iota","Kappa","Lambda","Mu","Nu","Xi","Omicron","Pi","Rho","Sigma","Tau","Upsilon","Phi","Chi","Psi","Omega")

/datum/game_mode
	var/list/datum/mind/changelings = list()


/datum/game_mode/changeling
	name = "The Society"
	config_tag = "changeling"
	restricted_jobs = list("Inquisitor")
	protected_jobs = list()
	required_players = 2
	required_players_secret = 4
	required_enemies = 1
	recommended_enemies = 4

	uplink_welcome = "Syndicate Uplink Console:"
	uplink_uses = 10

	var/const/prob_int_murder_target = 50 // intercept names the assassination target half the time
	var/const/prob_right_murder_target_l = 25 // lower bound on probability of naming right assassination target
	var/const/prob_right_murder_target_h = 50 // upper bound on probability of naimg the right assassination target

	var/const/prob_int_item = 50 // intercept names the theft target half the time
	var/const/prob_right_item_l = 25 // lower bound on probability of naming right theft target
	var/const/prob_right_item_h = 50 // upper bound on probability of naming the right theft target

	var/const/prob_int_sab_target = 50 // intercept names the sabotage target half the time
	var/const/prob_right_sab_target_l = 25 // lower bound on probability of naming right sabotage target
	var/const/prob_right_sab_target_h = 50 // upper bound on probability of naming right sabotage target

	var/const/prob_right_killer_l = 25 //lower bound on probability of naming the right operative
	var/const/prob_right_killer_h = 50 //upper bound on probability of naming the right operative
	var/const/prob_right_objective_l = 25 //lower bound on probability of determining the objective correctly
	var/const/prob_right_objective_h = 50 //upper bound on probability of determining the objective correctly

	var/const/waittime_l = 600 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 1800 //upper bound on time before intercept arrives (in tenths of seconds)

	var/changeling_amount = 4

/datum/game_mode/changeling/announce()
	world << "<B>Our quiet night is interrupted by aliens.</B>"

/datum/game_mode/changeling/can_start()
	for(var/mob/new_player/player in player_list)
		for(var/mob/new_player/player2 in player_list)
			for(var/mob/new_player/player3 in player_list)
				if(player.ready && player.client.work_chosen == "Baron" && player2.ready && player2.client.work_chosen == "Inquisitor"&& player3.ready && player3.client.work_chosen == "Bookkeeper")
					return 1
	return 0

/datum/game_mode/changeling/pre_setup()

	if(config.protect_roles_from_antagonist)
		restricted_jobs += protected_jobs

	var/list/datum/mind/possible_changelings = get_players_for_antag()

	for(var/datum/mind/player in possible_changelings)
		for(var/job in restricted_jobs)//Removing robots from the list
			if(player.assigned_role == job)
				possible_changelings -= player

	changeling_amount = 1 + round(num_players() / 10)

	if(possible_changelings.len>0)
		for(var/i = 0, i < changeling_amount, i++)
			if(!possible_changelings.len) break
			var/datum/mind/changeling = pick(possible_changelings)
			possible_changelings -= changeling
			changelings += changeling
			modePlayer += changelings
		return 1
	else
		return 0

/datum/game_mode/changeling/post_setup()
	for(var/datum/mind/changeling in changelings)
		grant_changeling_powers(changeling.current)
		changeling.special_role = "Changeling"
		forge_changeling_objectives(changeling)
		log_game("[changeling]([changeling?.key]) is now a THEY.")
		greet_changeling(changeling)

	..()
	return

/mob/living/carbon/human/proc/update_all_society_icons()
	if(src?.mind?.changeling)
		for(var/mob/living/carbon/human/HH in player_list)
			if(HH?.mind?.changeling)
				var/I = image('icons/mob/mob.dmi', loc = HH, icon_state = "changeling")
				if(src.client)
					src.client.images += I

/datum/game_mode/proc/forge_changeling_objectives(var/datum/mind/changeling)
	//OBJECTIVES - Always absorb 5 genomes, plus random traitor objectives.
	//If they have two objectives as well as absorb, they must survive rather than escape
	//No escape alone because changelings aren't suited for it and it'd probably just lead to rampant robusting
	//If it seems like they'd be able to do it in play, add a 10% chance to have to escape alone

	var/datum/objective/absorb/absorb_objective = new
	absorb_objective.owner = changeling
	absorb_objective.gen_amount_goal(2, 3)
	changeling.objectives += absorb_objective

	var/datum/objective/assassinate/kill_objective = new
	kill_objective.owner = changeling
	kill_objective.find_target()
	changeling.objectives += kill_objective

	var/datum/objective/steal/steal_objective = new
	steal_objective.owner = changeling
	steal_objective.find_target()
	changeling.objectives += steal_objective


	switch(rand(1,100))
		if(1 to 80)
			if (!(locate(/datum/objective/escape) in changeling.objectives))
				var/datum/objective/escape/escape_objective = new
				escape_objective.owner = changeling
				changeling.objectives += escape_objective
		else
			if (!(locate(/datum/objective/survive) in changeling.objectives))
				var/datum/objective/survive/survive_objective = new
				survive_objective.owner = changeling
				changeling.objectives += survive_objective
	return

/datum/game_mode/proc/greet_changeling(var/datum/mind/changeling, var/you_are=1)
	if (you_are)
		to_chat(changeling.current, "<B>\red You are part of the society!</B>")
		changeling.current << sound('sound/music/changeling_intro.ogg', repeat = 0, wait = 0, volume = 100, channel = 10)
		changeling.current << sound('sound/music/the_collective.ogg', repeat = 0, wait = 0, volume = 80, channel = 3)
	to_chat(changeling.current, "<b>\red Use say \":g message\" to communicate with the society.</b>")
	to_chat(changeling.current, "<B>You must complete the following tasks:</B>")
	var/mob/living/carbon/human/H = changeling.current
	H.update_all_society_icons()
	if (changeling.current.mind)
		if (changeling.current.mind.assigned_role == "Clown")
			changeling.current << "You have evolved beyond your clownish nature, allowing you to wield weapons without harming yourself."
			changeling.current.mutations.Remove(CLUMSY)

	var/obj_count = 1
	for(var/datum/objective/objective in changeling.objectives)
		to_chat(changeling.current, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
		obj_count++
	return

/*/datum/game_mode/changeling/check_finished()
	var/changelings_alive = 0
	for(var/datum/mind/changeling in changelings)
		if(!istype(changeling.current,/mob/living/carbon))
			continue
		if(changeling.current.stat==2)
			continue
		changelings_alive++

	if (changelings_alive)
		changelingdeath = 0
		return ..()
	else
		if (!changelingdeath)
			changelingdeathtime = world.time
			changelingdeath = 1
		if(world.time-changelingdeathtime > TIME_TO_GET_REVIVED)
			return 1
		else
			return ..()
	return 0*/

/datum/game_mode/proc/grant_changeling_powers(mob/living/carbon/changeling_mob)
	if(!istype(changeling_mob))	return
	changeling_mob.make_changeling()
/*
/datum/game_mode/changeling/declare_completion()
	to_chat(world, "\n<span class='ricagames'>[vessel_name()] (Story #1)</span>")
	to_chat(world, "\n<span class='dreamershitbutitsbigasfuckanditsboldtoo'>			     Transfiguração</span>\n\n\n")
*/
/datum/game_mode/proc/auto_declare_completion_changeling()
	//to_chat(world, "\n<span class='ricagames'>[vessel_name()] (Story #1)</span>")
	//to_chat(world, "\n<span class='dreamershitbutitsbigasfuckanditsboldtoo'>			     Transfiguração</span>\n\n\n")
	if(changelings.len)
		var/text = "<FONT size = 2><B>Living parts of the Society::</B></FONT>"
		for(var/datum/mind/changeling in changelings)
			var/changelingwin = 1

			text += "<br>[changeling.key] was [changeling.name] ("
			if(changeling.current)
				if(changeling.current.stat == DEAD)
					text += "died"
				else
					text += "survived"
				if(changeling.current.real_name != changeling.name)
					text += " as [changeling.current.real_name]"
			else
				text += "body destroyed"
				changelingwin = 0
			text += ")"

			//Removed sanity if(changeling) because we -want- a runtime to inform us that the changelings list is incorrect and needs to be fixed.
			text += "<br><b>They ID:</b> [changeling.changeling.changelingID]."
			text += "<br><b>Victims Assimilated:</b> [changeling.changeling.absorbedcount]"

			if(changeling.objectives.len)
				var/count = 1
				for(var/datum/objective/objective in changeling.objectives)
					if(objective.check_completion())
						text += "<br><B>Objective #[count]</B>: [objective.explanation_text] <font color='green'><B>Success!</B></font>"
					else
						text += "<br><B>Objective #[count]</B>: [objective.explanation_text] <font color='red'>Fail.</font>"
						changelingwin = 0
					count++

			if(changelingwin)
				text += "<br><font color='green'><B>The society was successful!</B></font>"
			else
				text += "<br><font color='red'><B>The society has failed.</B></font>"

		to_chat(world, text)


	return 1

/*
/datum/game_mode/proc/auto_declare_completion_changeling()
	if(changelings.len)
		var/text = "<FONT size = 2><B>The changelings were:</B></FONT>"
		for(var/datum/mind/changeling in changelings)
			var/changelingwin = 1

			text += "<br>[changeling.key] was [changeling.name] ("
			if(changeling.current)
				if(changeling.current.stat == DEAD)
					text += "died"
				else
					text += "survived"
				if(changeling.current.real_name != changeling.name)
					text += " as [changeling.current.real_name]"
			else
				text += "body destroyed"
				changelingwin = 0
			text += ")"

			//Removed sanity if(changeling) because we -want- a runtime to inform us that the changelings list is incorrect and needs to be fixed.
			text += "<br><b>Changeling ID:</b> [changeling.changeling.changelingID]."
			text += "<br><b>Genomes Absorbed:</b> [changeling.changeling.absorbedcount]"

			if(changeling.objectives.len)
				var/count = 1
				for(var/datum/objective/objective in changeling.objectives)
					if(objective.check_completion())
						text += "<br><B>Objective #[count]</B>: [objective.explanation_text] <font color='green'><B>Success!</B></font>"
					else
						text += "<br><B>Objective #[count]</B>: [objective.explanation_text] <font color='red'>Fail.</font>"
						changelingwin = 0
					count++

			if(changelingwin)
				text += "<br><font color='green'><B>The changeling was successful!</B></font>"
			else
				text += "<br><font color='red'><B>The changeling has failed.</B></font>"

		world << text


	return 1
*/
/datum/changeling //stores changeling powers, changeling recharge thingie, changeling absorbed DNA and changeling ID (for changeling hivemind)
	var/list/absorbed_dna = list()
	var/absorbedcount = 0
	var/chem_charges = 20
	var/chem_recharge_rate = 0.5
	var/chem_storage = 50
	var/sting_range = 1
	var/changelingID = "Changeling"
	var/geneticdamage = 0
	var/isabsorbing = 0
	var/geneticpoints = 5
	var/purchasedpowers = list()
	var/mimicing = ""
	var/last_lump = 0
	var/lump_delay = 60 SECONDS

/datum/changeling/New(var/gender=FEMALE)
	..()
	var/honorific
	if(gender == FEMALE)	honorific = "Ms."
	else					honorific = "Mr."
	if(possible_changeling_IDs.len)
		changelingID = pick(possible_changeling_IDs)
		possible_changeling_IDs -= changelingID
		changelingID = "[honorific] [changelingID]"
	else
		changelingID = "[honorific] [rand(1,999)]"


/datum/changeling/proc/regenerate()
	chem_charges = min(max(0, chem_charges+chem_recharge_rate), chem_storage)
	geneticdamage = max(0, geneticdamage-1)


/datum/changeling/proc/GetDNA(var/dna_owner)
	var/datum/dna/chosen_dna
	for(var/datum/dna/DNA in absorbed_dna)
		if(dna_owner == DNA.real_name)
			chosen_dna = DNA
			break
	return chosen_dna