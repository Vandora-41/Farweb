#define SOLID 1
#define LIQUID 2
#define GAS 3

#define REM REAGENTS_EFFECT_MULTIPLIER

/datum/reagent/nicotine
	name = "Nicotine"
	id = "nicotine"
	description = "Stun reduction per cycle, slight stamina regeneration buff. Overdoses become rapidly deadly."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 35
	addiction_threshold = 30

/datum/reagent/nicotine/on_mob_life(var/mob/living/carbon/human/M as mob)
	if(!M) M = holder.my_atom
	var/smoke_message = pick("You can just feel your lungs dying!", "You feel relaxed.", "You feel calmed.", "You feel the lung cancer forming.", "You feel the money you wasted.", "You feel like a space cowboy.", "You feel rugged.")
	if(M.vice == "Smoker")
		M.viceneed = 0
	if(prob(5))
		M << "<span class='notice'>[smoke_message]</span>"
	M.AdjustStunned(-1)
	M.AdjustWeakened(-1*REM)
	..()
	return

/datum/reagent/nicotine/overdose_process(var/mob/living/M as mob)
	if(prob(20))
		M << "You feel like you smoked too much."
	M.adjustToxLoss(1*REM)
	M.adjustOxyLoss(1*REM)
	..()
	return

/datum/reagent/maconha
	name = "Maconha"
	id = "maconha"
	description = "2Pac não morreu. 2Pac só sumiu sumiu tá por aí queimando mato que o homem branco proibiu."
	reagent_state = LIQUID
	color = "#558833" // rgb: 96, 165, 132
	overdose_threshold = 35
	addiction_threshold = 30
	var/valueAddIT
	var/valueAddST
	var/valueAddDX

/datum/reagent/maconha/on_mob_life(var/mob/living/carbon/human/M as mob)
	if(!M)
		M = holder.my_atom
	if(!istype(M))
		holder.remove_reagent(src.id, metabolization_rate)
		return
	if(first_life)
		first_life = FALSE
		if(M.special == "weedstrong")
			M.my_stats.add_mod("maconha", stat_list(ST = 2, HT = 1, DX = -2, IN = 3), time = 900)
		else
			M.my_stats.add_mod("maconha", stat_list(ST = 1, DX = -2, IN = 2), time = 900)



	var/smoke_message = pick("...I feel good.", "...I... Feel relaxed", "... Oh oh Oh! ...", "... Esse tal do mato ....")
	if(M.vice == "Pothead" || M.vice == "Smoker")
		M.viceneed = 0
	if(prob(5))
		to_chat(M, "<span class='dreamershitbutitsactuallypassivebutitactuallyisbigandbold'>[smoke_message]</span>")
	if(prob(10))
		M.emote(pick("laugh","giggle","nod"))
	M.AdjustStunned(-1)
	M.AdjustWeakened(-1*REM)
	M.add_event("weed", /datum/happiness_event/misc/weed)
	M.clear_event("vice")
	M.druggy = max(M.druggy, 15)
	if(!M.enmaconhado)
		M.enmaconhado = TRUE
		M.MAKONHA_DOIDO_DOIDO_DOIDO_DOIDO_DOIDO_MAKONHA()
	holder.remove_reagent(src.id, metabolization_rate)

/datum/reagent/maconha/on_remove(data)
	..()
	var/mob/living/carbon/human/M = holder?.my_atom
	if(!istype(M))
		return
	M.enmaconhado = 0
	for(var/obj/ripple_controller/R in M?.client?.screen)
		var/filter = R.get_filter("negors")
		animate(filter, size=0, time=10)
		del(R) //just to be ssure it will disappear

/datum/reagent/maconha/overdose_process(var/mob/living/M as mob)
	if(prob(20))
		to_chat(M, "You feel like you smoked too much.")
	M.adjustToxLoss(1*REM)
	M.adjustOxyLoss(1*REM)
	return ..()

/datum/reagent/crank
	name = "Crank"
	id = "crank"
	description = "2x stun reduction per cycle. Warms you up, makes you jittery as hell."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 20
	addiction_threshold = 10

/datum/reagent/crank/on_mob_life(var/mob/living/M as mob)
	if(!M) M = holder.my_atom
	var/high_message = pick("You feel jittery.", "You feel like you gotta go fast.", "You feel like you need to step it up.")
	if(prob(5))
		M << "<span class='notice'>[high_message]</span>"
	M.AdjustParalysis(-2)
	M.AdjustStunned(-2)
	M.AdjustWeakened(-2)
	..()
	return

/datum/reagent/crank/overdose_process(var/mob/living/M as mob)
	M.adjustBrainLoss(rand(1,10)*REM)
	M.adjustToxLoss(rand(1,10)*REM)
	M.adjustBruteLoss(rand(1,10)*REM)
	..()
	return

/datum/reagent/crank/addiction_act_stage1(var/mob/living/M as mob)
	M.adjustBrainLoss(rand(1,10)*REM)
	..()
	return

/datum/reagent/crank/addiction_act_stage2(var/mob/living/M as mob)
	M.adjustToxLoss(rand(1,10)*REM)
	..()
	return

/datum/reagent/crank/addiction_act_stage3(var/mob/living/M as mob)
	M.adjustBruteLoss(rand(1,10)*REM)
	..()
	return

/datum/reagent/crank/addiction_act_stage4(var/mob/living/M as mob)
	M.adjustBrainLoss(rand(1,10)*REM)
	M.adjustToxLoss(rand(1,10)*REM)
	M.adjustBruteLoss(rand(1,10)*REM)
	..()
	return

/datum/chemical_reaction/crank
	name = "Crank"
	id = "crank"
	result = "crank"
	required_reagents = list("diphenhydramine" = 1, "ammonia" = 1, "lithium" = 1, "sacid" = 1, "fuel" = 1)
	result_amount = 5
	mix_message = "The mixture violently reacts, leaving behind a few crystalline shards."
	required_temp = 390

/datum/reagent/krokodil
	name = "Krokodil"
	id = "krokodil"
	description = "Cools and calms you down, occasional BRAIN and TOX damage."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 20
	addiction_threshold = 15


/datum/reagent/krokodil/on_mob_life(var/mob/living/M as mob)
	if(!M) M = holder.my_atom
	var/high_message = pick("You feel calm.", "You feel collected.", "You feel like you need to relax.")
	if(prob(5))
		M << "<span class='notice'>[high_message]</span>"
	..()
	return

/datum/reagent/krokodil/overdose_process(var/mob/living/M as mob)
	if(prob(10))
		M.adjustBrainLoss(rand(1,5)*REM)
		M.adjustToxLoss(rand(1,5)*REM)
	..()
	return


/datum/reagent/krokodil/addiction_act_stage1(var/mob/living/M as mob)
	M.adjustBrainLoss(rand(1,5)*REM)
	M.adjustToxLoss(rand(1,5)*REM)
	..()
	return

/datum/reagent/krokodil/addiction_act_stage2(var/mob/living/M as mob)
	if(prob(25))
		M << "<span class='danger'>Your skin feels loose...</span>"
	..()
	return

/datum/reagent/krokodil/addiction_act_stage3(var/mob/living/M as mob)
	if(prob(25))
		M << "<span class='danger'>Your skin starts to peel away...</span>"
	M.adjustBruteLoss(3*REM)
	..()
	return

/datum/reagent/krokodil/addiction_act_stage4(var/mob/living/carbon/human/M as mob)
	if(!(SKELETON in M.mutations))
		M << "<span class='userdanger'>Your skin falls off! Holy shit!</span>"
		M.adjustBruteLoss(rand(50,80)*REM) // holy shit your skin just FELL THE FUCK OFF
		if(ishuman(M))
			var/mob/living/carbon/human/junkie = M
			junkie.makeSkeleton()
	else
		M.adjustBruteLoss(5*REM)
	..()
	return

/datum/chemical_reaction/krokodil
	name = "Krokodil"
	id = "krokodil"
	result = "krokodil"
	required_reagents = list("diphenhydramine" = 1, "morphine" = 1, "cleaner" = 1, "potassium" = 1, "phosphorus" = 1, "fuel" = 1)
	result_amount = 6
	mix_message = "The mixture dries into a pale blue powder."
	required_temp = 380

/datum/reagent/methamphetamine
	name = "Methamphetamine"
	id = "methamphetamine"
	description = "3x stun reduction per cycle, significant stamina regeneration buff, makes you really jittery, dramatically increases movement speed."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 20
	addiction_threshold = 10

/datum/reagent/methamphetamine/on_mob_life(var/mob/living/M as mob)
	if(!M) M = holder.my_atom
	var/high_message = pick("You feel hyper.", "You feel like you need to go faster.", "You feel like you can run the world.")
	if(prob(5))
		M << "<span class='notice'>[high_message]</span>"
	M.AdjustParalysis(-3)
	M.AdjustStunned(-3)
	M.AdjustWeakened(-3)
	M.AdjustWeakened(-3)
	M.status_flags |= GOTTAGOFAST
	M.Jitter(3)
	..()
	return

/datum/reagent/methamphetamine/overdose_process(var/mob/living/M as mob)
	if(M.canmove && !istype(M.loc, /turf/space))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	if(prob(33))
		var/obj/item/I = M.get_active_hand()
		if(I)
			M.drop_item()
	..()
	return

/datum/reagent/methamphetamine/addiction_act_stage1(var/mob/living/M as mob)
	M.Jitter(5)
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	..()
	return

/datum/reagent/methamphetamine/addiction_act_stage2(var/mob/living/M as mob)
	M.Jitter(10)
	M.Dizzy(10)
	if(prob(30))
		M.emote(pick("twitch","drool","moan"))
	..()
	return

/datum/reagent/methamphetamine/addiction_act_stage3(var/mob/living/M as mob)
	if(M.canmove && !istype(M.loc, /turf/space))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
	M.Jitter(15)
	M.Dizzy(15)
	if(prob(40))
		M.emote(pick("twitch","drool","moan"))
	..()
	return

/datum/reagent/methamphetamine/addiction_act_stage4(var/mob/living/carbon/human/M as mob)
	if(M.canmove && !istype(M.loc, /turf/space))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
	M.Jitter(20)
	M.Dizzy(20)
	M.adjustToxLoss(5)
	if(prob(50))
		M.emote(pick("twitch","drool","moan"))
	..()
	return

/datum/chemical_reaction/methamphetamine
	name = "methamphetamine"
	id = "methamphetamine"
	result = "methamphetamine"
	required_reagents = list("ephedrine" = 1, "iodine" = 1, "phosphorus" = 1, "hydrogen" = 1)
	result_amount = 4
	required_temp = 374

/datum/chemical_reaction/methamphetamine_two
	name = "methamphetamine_two"
	id = "methamphetamine_two"
	result = "methamphetamine"
	required_reagents = list("muriatic_acid" = 1, "caustic_soda" = 1, "hydrogen_chloride" = 1)
	result_amount = 3
	required_temp = 374

/datum/reagent/muriatic_acid
	name = "Muriatic Acid"
	id = "muriatic_acid"
	description = "Fuck me, we needed those cooks."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132

/datum/reagent/caustic_soda
	name = "Caustic Soda"
	id = "caustic_soda"
	description = "Fuck me, we needed those cooks."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132

/datum/reagent/hydrogen_chloride
	name = "Hydrogen Chloride"
	id = "hydrogen_chloride"
	description = "Fuck me, we needed those cooks."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132

/datum/chemical_reaction/muriatic_acid
	name = "muriatic_acid"
	id = "muriatic_acid"
	result = "muriatic_acid"
	required_reagents = list("mutadone" = 1, "sacid" = 1)
	result_amount = 2
	required_temp = 500

/datum/chemical_reaction/caustic_soda
	name = "caustic_soda"
	id = "caustic_soda"
	result = "caustic_soda"
	required_reagents = list("sacid" = 1, "cola" = 1)
	result_amount = 2
	required_temp = 500

/datum/chemical_reaction/hydrogen_chloride
	name = "hydrogen_chloride"
	id = "hydrogen_chloride"
	result = "hydrogen_chloride"
	required_reagents = list("hydrogen" = 1, "chlorine" = 1)
	result_amount = 2
	required_temp = 500

/datum/chemical_reaction/saltpetre
	name = "saltpetre"
	id = "saltpetre"
	result = "saltpetre"
	required_reagents = list("potassium" = 1, "nitrogen" = 1, "oxygen" = 3)
	result_amount = 3

/datum/reagent/saltpetre
	name = "Saltpetre"
	id = "saltpetre"
	description = "Volatile."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132

/datum/reagent/bath_salts
	name = "Bath Salts"
	id = "bath_salts"
	description = "Makes you nearly impervious to stuns and grants a stamina regeneration buff, but you'll be a nearly uncontrollable tramp-bearded raving lunatic."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 20
	addiction_threshold = 10

/datum/reagent/bath_salts/on_mob_life(var/mob/living/M as mob)
	if(!M) M = holder.my_atom
	var/high_message = pick("You feel amped up.", "You feel ready.", "You feel like you can push it to the limit.")
	if(prob(5))
		M << "<span class='notice'>[high_message]</span>"
	M.AdjustParalysis(-5)
	M.AdjustStunned(-5)
	M.AdjustWeakened(-5)
	M.AdjustWeakened(-10)
	M.adjustBrainLoss(1)
	M.adjustToxLoss(0.1)
	M.hallucination += 10
	if(M.canmove && !istype(M.loc, /turf/space))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
	..()
	return

/datum/chemical_reaction/bath_salts
	name = "bath_salts"
	id = "bath_salts"
	result = "bath_salts"
	required_reagents = list("????" = 1, "saltpetre" = 1, "nutriment" = 1, "cleaner" = 1, "enzyme" = 1, "tea" = 1)
	result_amount = 6
	required_temp = 374

/datum/reagent/bath_salts/overdose_process(var/mob/living/M as mob)
	M.hallucination += 10
	if(M.canmove && !istype(M.loc, /turf/space))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	if(prob(33))
		var/obj/item/I = M.get_active_hand()
		if(I)
			M.drop_item()
	..()
	return

/datum/reagent/bath_salts/addiction_act_stage1(var/mob/living/M as mob)
	M.hallucination += 10
	if(M.canmove && !istype(M.loc, /turf/space))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
	M.Jitter(5)
	M.adjustBrainLoss(10)
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	..()
	return

/datum/reagent/bath_salts/addiction_act_stage2(var/mob/living/M as mob)
	M.hallucination += 20
	if(M.canmove && !istype(M.loc, /turf/space))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
	M.Jitter(10)
	M.Dizzy(10)
	M.adjustBrainLoss(10)
	if(prob(30))
		M.emote(pick("twitch","drool","moan"))
	..()
	return

/datum/reagent/bath_salts/addiction_act_stage3(var/mob/living/M as mob)
	M.hallucination += 30
	if(M.canmove && !istype(M.loc, /turf/space))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
	M.Jitter(15)
	M.Dizzy(15)
	M.adjustBrainLoss(10)
	if(prob(40))
		M.emote(pick("twitch","drool","moan"))
	..()
	return

/datum/reagent/bath_salts/addiction_act_stage4(var/mob/living/carbon/human/M as mob)
	M.hallucination += 40
	if(M.canmove && !istype(M.loc, /turf/space))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
		step(M, pick(cardinal))
	M.Jitter(50)
	M.Dizzy(50)
	M.adjustToxLoss(5)
	M.adjustBrainLoss(10)
	if(prob(50))
		M.emote(pick("twitch","drool","moan"))
	..()
	return

/datum/chemical_reaction/aranesp
	name = "aranesp"
	id = "aranesp"
	result = "aranesp"
	required_reagents = list("epinephrine" = 1, "atropine" = 1, "morphine" = 1)
	result_amount = 3

/datum/reagent/aranesp
	name = "Aranesp"
	id = "aranesp"
	description = "Volatile."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132

/datum/reagent/aranesp/on_mob_life(var/mob/living/M as mob)
	if(!M) M = holder.my_atom
	var/high_message = pick("You feel amped up.", "You feel ready.", "You feel like you can push it to the limit.")
	if(prob(5))
		M << "<span class='notice'>[high_message]</span>"
	M.AdjustWeakened(-35)
	M.adjustToxLoss(1)
	if(prob(rand(1,100)))
		M.losebreath++
		M.adjustOxyLoss(20)
	..()
	return
