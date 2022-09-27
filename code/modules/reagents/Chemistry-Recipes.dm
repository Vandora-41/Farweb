///////////////////////////////////////////////////////////////////////////////////
datum
	chemical_reaction
		var/name = null
		var/id = null
		var/result = null
		var/list/required_reagents = new/list()
		var/list/required_catalysts = new/list()

		// Both of these variables are mostly going to be used with slime cores - but if you want to, you can use them for other things
		var/atom/required_container = null // the container required for the reaction to happen
		var/required_other = 0 // an integer required for the reaction to happen

		var/result_amount = 0
		var/secondary = 0 // set to nonzero if secondary reaction
		var/mob_react = 0 //Determines if a chemical reaction can occur inside a mob

		var/list/secondary_results = list()		//additional reagents produced by the reaction
		var/requires_heating = 0


		var/required_temp = 0
		var/mix_message = "The solution begins to bubble."

		proc
			on_reaction(var/datum/reagents/holder, var/created_volume)
				return

		//I recommend you set the result amount to the total volume of all components.

		explosion_potassium
			name = "Explosion"
			id = "explosion_potassium"
			result = null
			required_reagents = list("water" = 1, "potassium" = 1)
			result_amount = 2
			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/datum/effect/effect/system/reagents_explosion/e = new()
				e.set_up(round (created_volume/10, 1), holder.my_atom, 0, 0)
				e.holder_damage(holder.my_atom)
				if(isliving(holder.my_atom))
					e.amount *= 0.5
					var/mob/living/L = holder.my_atom
					if(L.stat!=DEAD)
						e.amount *= 0.5
				e.start()
				holder.clear_reagents()
				return

		emp_pulse
			name = "EMP Pulse"
			id = "emp_pulse"
			result = null
			required_reagents = list("uranium" = 1, "iron" = 1) // Yes, laugh, it's the best recipe I could think of that makes a little bit of sense
			result_amount = 2

			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/location = get_turf(holder.my_atom)
				// 100 created volume = 4 heavy range & 7 light range. A few tiles smaller than traitor EMP grandes.
				// 200 created volume = 8 heavy range & 14 light range. 4 tiles larger than traitor EMP grenades.
				empulse(location, round(created_volume / 24), round(created_volume / 14), 1)
				holder.clear_reagents()
				return
/*
		silicate
			name = "Silicate"
			id = "silicate"
			result = "silicate"
			required_reagents = list("aluminum" = 1, "silicon" = 1, "oxygen" = 1)
			result_amount = 3
*/
		stoxin
			name = "Sleep Toxin"
			id = "stoxin"
			result = "stoxin"
			required_reagents = list("chloralhydrate" = 1, "sugar" = 4)
			result_amount = 5

		sterilizine
			name = "Sterilizine"
			id = "sterilizine"
			result = "sterilizine"
			required_reagents = list("ethanol" = 1, "charcoal" = 1, "chlorine" = 1)
			result_amount = 3

		mutagen
			name = "Unstable mutagen"
			id = "mutagen"
			result = "mutagen"
			required_reagents = list("radium" = 1, "phosphorus" = 1, "chlorine" = 1)
			result_amount = 3

		tramadol
			name = "Tramadol"
			id = "tramadol"
			result = "tramadol"
			required_reagents = list("epinephrine" = 1, "ethanol" = 1, "oxygen" = 1)
			result_amount = 3

		paracetamol
			name = "Paracetamol"
			id = "paracetamol"
			result = "paracetamol"
			required_reagents = list("tramadol" = 1, "sugar" = 1, "water" = 1)
			result_amount = 3

		oxycodone
			name = "Oxycodone"
			id = "oxycodone"
			result = "oxycodone"
			required_reagents = list("ethanol" = 1, "tramadol" = 1)
			required_catalysts = list("plasma" = 1)
			result_amount = 1

		//cyanide
		//	name = "Cyanide"
		//	id = "cyanide"
		//	result = "cyanide"
		//	required_reagents = list("hydrogen" = 1, "carbon" = 1, "nitrogen" = 1)
		//	result_amount = 1

		thermite
			name = "Thermite"
			id = "thermite"
			result = "thermite"
			required_reagents = list("aluminum" = 1, "iron" = 1, "oxygen" = 1)
			result_amount = 3

		lexorin
			name = "Lexorin"
			id = "lexorin"
			result = "lexorin"
			required_reagents = list("plasma" = 1, "hydrogen" = 1, "nitrogen" = 1)
			result_amount = 3

		space_drugs
			name = "Space Drugs"
			id = "space_drugs"
			result = "space_drugs"
			required_reagents = list("mercury" = 1, "sugar" = 1, "lithium" = 1)
			result_amount = 3

		lube
			name = "Space Lube"
			id = "lube"
			result = "lube"
			required_reagents = list("water" = 1, "silicon" = 1, "oxygen" = 1)
			result_amount = 4

		pacid
			name = "Polytrinic acid"
			id = "pacid"
			result = "pacid"
			required_reagents = list("sacid" = 1, "chlorine" = 1, "potassium" = 1)
			result_amount = 3

		synaptizine
			name = "Synaptizine"
			id = "synaptizine"
			result = "synaptizine"
			required_reagents = list("sugar" = 1, "lithium" = 1, "water" = 1)
			result_amount = 3

		impedrezene
			name = "Impedrezene"
			id = "impedrezene"
			result = "impedrezene"
			required_reagents = list("mercury" = 1, "oxygen" = 1, "sugar" = 1)
			result_amount = 2

		peridaxon
			name = "Peridaxon"
			id = "peridaxon"
			result = "peridaxon"
			required_reagents = list("salglu_solution" = 2, "clonexadone" = 2)
			required_catalysts = list("plasma" = 5)
			result_amount = 2

		virus_food
			name = "Virus Food"
			id = "virusfood"
			result = "virusfood"
			required_reagents = list("water" = 1, "milk" = 1)
			result_amount = 5

		leporazine
			name = "Leporazine"
			id = "leporazine"
			result = "leporazine"
			required_reagents = list("silicon" = 1, "copper" = 1)
			required_catalysts = list("plasma" = 5)
			result_amount = 2

		cryptobiolin
			name = "Cryptobiolin"
			id = "cryptobiolin"
			result = "cryptobiolin"
			required_reagents = list("potassium" = 1, "oxygen" = 1, "sugar" = 1)
			result_amount = 3

		spaceacillin
			name = "Spaceacillin"
			id = "spaceacillin"
			result = "spaceacillin"
			required_reagents = list("cryptobiolin" = 1, "epinephrine" = 1)
			result_amount = 2

		glycerol
			name = "Glycerol"
			id = "glycerol"
			result = "glycerol"
			required_reagents = list("cornoil" = 3, "sacid" = 1)
			result_amount = 1

		nitroglycerin
			name = "Nitroglycerin"
			id = "nitroglycerin"
			result = "nitroglycerin"
			required_reagents = list("glycerol" = 1, "pacid" = 1, "sacid" = 1)
			result_amount = 2
			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/datum/effect/effect/system/reagents_explosion/e = new()
				e.set_up(round (created_volume/2, 1), holder.my_atom, 0, 0)
				e.holder_damage(holder.my_atom)
				if(isliving(holder.my_atom))
					e.amount *= 0.5
					var/mob/living/L = holder.my_atom
					if(L.stat!=DEAD)
						e.amount *= 0.5
				e.start()

				holder.clear_reagents()
				return

		sodiumchloride
			name = "Sodium Chloride"
			id = "sodiumchloride"
			result = "sodiumchloride"
			required_reagents = list("sodium" = 1, "chlorine" = 1)
			result_amount = 2

		flash_powder
			name = "Flash powder"
			id = "flash_powder"
			result = null
			required_reagents = list("aluminum" = 1, "potassium" = 1, "sulfur" = 1 )
			result_amount = null
			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/location = get_turf(holder.my_atom)
				var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
				s.set_up(2, 1, location)
				s.start()
				for(var/mob/living/carbon/M in viewers(world.view, location))
					switch(get_dist(M, location))
						if(0 to 3)
							if(hasvar(M, "glasses"))
								if(istype(M:glasses, /obj/item/clothing/glasses/sunglasses))
									continue

							flick("e_flash", M.flash)
							M.Weaken(15)

						if(4 to 5)
							if(hasvar(M, "glasses"))
								if(istype(M:glasses, /obj/item/clothing/glasses/sunglasses))
									continue

							flick("e_flash", M.flash)
							M.Stun(5)

		napalm
			name = "Napalm"
			id = "napalm"
			result = null
			required_reagents = list("aluminum" = 1, "plasma" = 1, "sacid" = 1 )
			result_amount = 1
			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/turf/location = get_turf(holder.my_atom.loc)
				for(var/turf/simulated/floor/target_tile in range(0,location))
					target_tile.assume_gas("volatile_fuel", created_volume, 400+T0C)
					spawn (0) target_tile.hotspot_expose(700, 400)
				holder.del_reagent("napalm")
				return

		/*
		smoke
			name = "Smoke"
			id = "smoke"
			result = null
			required_reagents = list("potassium" = 1, "sugar" = 1, "phosphorus" = 1 )
			result_amount = null
			secondary = 1
			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/location = get_turf(holder.my_atom)
				var/datum/effect/system/bad_smoke_spread/S = new /datum/effect/system/bad_smoke_spread
				S.attach(location)
				S.set_up(10, 0, location)
				playsound(location, 'sound/effects/smoke.ogg', 50, 1, -3)
				spawn(0)
					S.start()
					sleep(10)
					S.start()
					sleep(10)
					S.start()
					sleep(10)
					S.start()
					sleep(10)
					S.start()
				holder.clear_reagents()
				return	*/

		chemsmoke
			name = "Chemsmoke"
			id = "chemsmoke"
			result = null
			required_reagents = list("potassium" = 1, "sugar" = 1, "phosphorus" = 1)
			result_amount = null
			secondary = 1
			mob_react = 1

			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/location = get_turf(holder.my_atom)
				var/datum/effect/effect/system/smoke_spread/chem/S = new /datum/effect/effect/system/smoke_spread/chem
				S.attach(location)
				S.set_up(holder, 10, 0, location)
				playsound(location, 'sound/effects/smoke.ogg', 50, 1, -3)
				spawn(0)
					S.start()
					sleep(10)
					S.start()
				holder.clear_reagents()
				return

		chloralhydrate
			name = "Chloral Hydrate"
			id = "chloralhydrate"
			result = "chloralhydrate"
			required_reagents = list("ethanol" = 1, "chlorine" = 3, "water" = 1)
			result_amount = 1

		potassium_chloride
			name = "Potassium Chloride"
			id = "potassium_chloride"
			result = "potassium_chloride"
			required_reagents = list("sodiumchloride" = 1, "potassium" = 1)
			result_amount = 2

		potassium_chlorophoride
			name = "Potassium Chlorophoride"
			id = "potassium_chlorophoride"
			result = "potassium_chlorophoride"
			required_reagents = list("potassium_chloride" = 1, "plasma" = 1, "chloralhydrate" = 1)
			result_amount = 4

		stoxin
			name = "Sleep Toxin"
			id = "stoxin"
			result = "stoxin"
			required_reagents = list("chloralhydrate" = 1, "sugar" = 4)
			result_amount = 5

		zombiepowder
			name = "Zombie Powder"
			id = "zombiepowder"
			result = "zombiepowder"
			required_reagents = list("carpotoxin" = 5, "stoxin" = 5, "copper" = 5)
			result_amount = 2

		rezadone
			name = "Rezadone"
			id = "rezadone"
			result = "rezadone"
			required_reagents = list("carpotoxin" = 1, "cryptobiolin" = 1, "copper" = 1)
			result_amount = 3

		mindbreaker
			name = "Mindbreaker Toxin"
			id = "mindbreaker"
			result = "mindbreaker"
			required_reagents = list("silicon" = 1, "hydrogen" = 1, "charcoal" = 1)
			result_amount = 3

		plasmasolidification
			name = "Solid Plasma"
			id = "solidplasma"
			result = null
			required_reagents = list("iron" = 5, "frostoil" = 5, "plasma" = 20)
			result_amount = 1
			mob_react = 1

			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/location = get_turf(holder.my_atom)
				new /obj/item/stack/sheet/mineral/plasma(location)
				return

		plastication
			name = "Plastic"
			id = "solidplastic"
			result = null
			required_reagents = list("pacid" = 10, "plasticide" = 20)
			result_amount = 1
			on_reaction(var/datum/reagents/holder)
				new /obj/item/stack/sheet/mineral/plastic(get_turf(holder.my_atom),10)
				return

		virus_food
			name = "Virus Food"
			id = "virusfood"
			result = "virusfood"
			required_reagents = list("water" = 5, "milk" = 5, "oxygen" = 5)
			result_amount = 15
/*
		mix_virus
			name = "Mix Virus"
			id = "mixvirus"
			result = "blood"
			required_reagents = list("virusfood" = 5)
			required_catalysts = list("blood")
			var/level = 2

			on_reaction(var/datum/reagents/holder, var/created_volume)

				var/datum/reagent/blood/B = locate(/datum/reagent/blood) in holder.reagent_list
				if(B && B.data)
					var/datum/disease/advance/D = locate(/datum/disease/advance) in B.data["viruses"]
					if(D)
						D.Evolve(level - rand(0, 1))


			mix_virus_2

				name = "Mix Virus 2"
				id = "mixvirus2"
				required_reagents = list("mutagen" = 5)
				level = 4

			rem_virus

				name = "Devolve Virus"
				id = "remvirus"
				required_reagents = list("synaptizine" = 5)

				on_reaction(var/datum/reagents/holder, var/created_volume)

					var/datum/reagent/blood/B = locate(/datum/reagent/blood) in holder.reagent_list
					if(B && B.data)
						var/datum/disease/advance/D = locate(/datum/disease/advance) in B.data["viruses"]
						if(D)
							D.Devolve()
*/
		condensedcapsaicin
			name = "Condensed Capsaicin"
			id = "condensedcapsaicin"
			result = "condensedcapsaicin"
			required_reagents = list("capsaicin" = 2)
			required_catalysts = list("plasma" = 5)
			result_amount = 1
///////////////////////////////////////////////////////////////////////////////////

// foam and foam precursor

		surfactant
			name = "Foam surfactant"
			id = "foam surfactant"
			result = "fluorosurfactant"
			required_reagents = list("fluorine" = 2, "carbon" = 2, "sacid" = 1)
			result_amount = 5


		foam
			name = "Foam"
			id = "foam"
			result = null
			required_reagents = list("fluorosurfactant" = 1, "water" = 1)
			result_amount = 2
			mob_react = 1

			on_reaction(var/datum/reagents/holder, var/created_volume)


				var/location = get_turf(holder.my_atom)
				for(var/mob/M in viewers(5, location))
					M << "\red The solution violently bubbles!"

				location = get_turf(holder.my_atom)

				for(var/mob/M in viewers(5, location))
					M << "\red The solution spews out foam!"

				//world << "Holder volume is [holder.total_volume]"
				//for(var/datum/reagent/R in holder.reagent_list)
				//	world << "[R.name] = [R.volume]"

				var/datum/effect/effect/system/foam_spread/s = new()
				s.set_up(created_volume, location, holder, 0)
				s.start()
				holder.clear_reagents()
				return

		metalfoam
			name = "Metal Foam"
			id = "metalfoam"
			result = null
			required_reagents = list("aluminum" = 3, "foaming_agent" = 1, "pacid" = 1)
			result_amount = 5
			mob_react = 1

			on_reaction(var/datum/reagents/holder, var/created_volume)


				var/location = get_turf(holder.my_atom)

				for(var/mob/M in viewers(5, location))
					M << "\red The solution spews out a metalic foam!"

				var/datum/effect/effect/system/foam_spread/s = new()
				s.set_up(created_volume, location, holder, 1)
				s.start()
				return

		ironfoam
			name = "Iron Foam"
			id = "ironlfoam"
			result = null
			required_reagents = list("iron" = 3, "foaming_agent" = 1, "pacid" = 1)
			result_amount = 5
			mob_react = 1

			on_reaction(var/datum/reagents/holder, var/created_volume)


				var/location = get_turf(holder.my_atom)

				for(var/mob/M in viewers(5, location))
					M << "\red The solution spews out a metalic foam!"

				var/datum/effect/effect/system/foam_spread/s = new()
				s.set_up(created_volume, location, holder, 2)
				s.start()
				return



		foaming_agent
			name = "Foaming Agent"
			id = "foaming_agent"
			result = "foaming_agent"
			required_reagents = list("lithium" = 1, "hydrogen" = 1)
			result_amount = 1

		// Synthesizing these three chemicals is pretty complex in real life, but fuck it, it's just a game!
		ammonia
			name = "Ammonia"
			id = "ammonia"
			result = "ammonia"
			required_reagents = list("hydrogen" = 3, "nitrogen" = 1)
			result_amount = 3

		diethylamine
			name = "Diethylamine"
			id = "diethylamine"
			result = "diethylamine"
			required_reagents = list ("ammonia" = 1, "ethanol" = 1)
			result_amount = 2

		space_cleaner
			name = "Space cleaner"
			id = "cleaner"
			result = "cleaner"
			required_reagents = list("ammonia" = 1, "water" = 1)
			result_amount = 2

		plantbgone
			name = "Plant-B-Gone"
			id = "plantbgone"
			result = "plantbgone"
			required_reagents = list("toxin" = 1, "water" = 4)
			result_amount = 5

//////////////////////////////////////////FOOD MIXTURES////////////////////////////////////

		tofu
			name = "Tofu"
			id = "tofu"
			result = null
			required_reagents = list("soymilk" = 10)
			required_catalysts = list("enzyme" = 5)
			result_amount = 1
			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/location = get_turf(holder.my_atom)
				for(var/i = 1, i <= created_volume, i++)
					new /obj/item/weapon/reagent_containers/food/snacks/tofu(location)
				return

		chocolate_bar
			name = "Chocolate Bar"
			id = "chocolate_bar"
			result = null
			required_reagents = list("soymilk" = 2, "coco" = 2, "sugar" = 2)
			result_amount = 1
			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/location = get_turf(holder.my_atom)
				for(var/i = 1, i <= created_volume, i++)
					new /obj/item/weapon/reagent_containers/food/snacks/chocolatebar(location)
				return

		chocolate_bar2
			name = "Chocolate Bar"
			id = "chocolate_bar"
			result = null
			required_reagents = list("milk" = 2, "coco" = 2, "sugar" = 2)
			result_amount = 1
			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/location = get_turf(holder.my_atom)
				for(var/i = 1, i <= created_volume, i++)
					new /obj/item/weapon/reagent_containers/food/snacks/chocolatebar(location)
				return

		hot_coco
			name = "Hot Coco"
			id = "hot_coco"
			result = "hot_coco"
			required_reagents = list("water" = 5, "coco" = 1)
			result_amount = 5

		soysauce
			name = "Soy Sauce"
			id = "soysauce"
			result = "soysauce"
			required_reagents = list("soymilk" = 4, "sacid" = 1)
			result_amount = 5

		cheesewheel
			name = "Cheesewheel"
			id = "cheesewheel"
			result = null
			required_reagents = list("milk" = 40)
			required_catalysts = list("enzyme" = 5)
			result_amount = 1
			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/location = get_turf(holder.my_atom)
				new /obj/item/weapon/reagent_containers/food/snacks/sliceable/cheesewheel(location)
				return

		syntiflesh
			name = "Syntiflesh"
			id = "syntiflesh"
			result = null
			required_reagents = list("blood" = 5, "clonexadone" = 1)
			result_amount = 1
			on_reaction(var/datum/reagents/holder, var/created_volume)
				var/location = get_turf(holder.my_atom)
				new /obj/item/weapon/reagent_containers/food/snacks/meat/syntiflesh(location)
				return

		hot_ramen
			name = "Hot Ramen"
			id = "hot_ramen"
			result = "hot_ramen"
			required_reagents = list("water" = 1, "dry_ramen" = 3)
			result_amount = 3

		hell_ramen
			name = "Hell Ramen"
			id = "hell_ramen"
			result = "hell_ramen"
			required_reagents = list("capsaicin" = 1, "hot_ramen" = 6)
			result_amount = 6


////////////////////////////////////////// COCKTAILS //////////////////////////////////////


		goldschlager
			name = "Goldschlager"
			id = "goldschlager"
			result = "goldschlager"
			required_reagents = list("vodka" = 10, "gold" = 1)
			result_amount = 10

		patron
			name = "Patron"
			id = "patron"
			result = "patron"
			required_reagents = list("tequilla" = 10, "silver" = 1)
			result_amount = 10

		bilk
			name = "Bilk"
			id = "bilk"
			result = "bilk"
			required_reagents = list("milk" = 1, "beer" = 1)
			result_amount = 2

		icetea
			name = "Iced Tea"
			id = "icetea"
			result = "icetea"
			required_reagents = list("ice" = 1, "tea" = 3)
			result_amount = 4

		icecoffee
			name = "Iced Coffee"
			id = "icecoffee"
			result = "icecoffee"
			required_reagents = list("ice" = 1, "coffee" = 3)
			result_amount = 4

		nuka_cola
			name = "Nuka Cola"
			id = "nuka_cola"
			result = "nuka_cola"
			required_reagents = list("uranium" = 1, "cola" = 6)
			result_amount = 6

		moonshine
			name = "Moonshine"
			id = "moonshine"
			result = "moonshine"
			required_reagents = list("nutriment" = 10)
			required_catalysts = list("enzyme" = 5)
			result_amount = 10

		grenadine
			name = "Grenadine Syrup"
			id = "grenadine"
			result = "grenadine"
			required_reagents = list("berryjuice" = 10)
			required_catalysts = list("enzyme" = 5)
			result_amount = 10

		wine
			name = "Wine"
			id = "wine"
			result = "wine"
			required_reagents = list("grapejuice" = 10)
			required_catalysts = list("enzyme" = 5)
			result_amount = 10

		pwine
			name = "Poison Wine"
			id = "pwine"
			result = "pwine"
			required_reagents = list("poisonberryjuice" = 10)
			required_catalysts = list("enzyme" = 5)
			result_amount = 10

		melonliquor
			name = "Melon Liquor"
			id = "melonliquor"
			result = "melonliquor"
			required_reagents = list("watermelonjuice" = 10)
			required_catalysts = list("enzyme" = 5)
			result_amount = 10

		bluecuracao
			name = "Blue Curacao"
			id = "bluecuracao"
			result = "bluecuracao"
			required_reagents = list("orangejuice" = 10)
			required_catalysts = list("enzyme" = 5)
			result_amount = 10

		spacebeer
			name = "Space Beer"
			id = "spacebeer"
			result = "beer"
			required_reagents = list("flour" = 10)
			required_catalysts = list("enzyme" = 5)
			result_amount = 10

		vodka
			name = "Vodka"
			id = "vodka"
			result = "vodka"
			required_reagents = list("potato" = 10)
			required_catalysts = list("enzyme" = 5)
			result_amount = 10
		sake
			name = "Sake"
			id = "sake"
			result = "sake"
			required_reagents = list("rice" = 10)
			required_catalysts = list("enzyme" = 5)
			result_amount = 10

		kahlua
			name = "Kahlua"
			id = "kahlua"
			result = "kahlua"
			required_reagents = list("coffee" = 5, "sugar" = 5)
			required_catalysts = list("enzyme" = 5)
			result_amount = 5

		gin_tonic
			name = "Gin and Tonic"
			id = "gintonic"
			result = "gintonic"
			required_reagents = list("gin" = 2, "tonic" = 1)
			result_amount = 3

		cuba_libre
			name = "Cuba Libre"
			id = "cubalibre"
			result = "cubalibre"
			required_reagents = list("rum" = 2, "cola" = 1)
			result_amount = 3

		martini
			name = "Classic Martini"
			id = "martini"
			result = "martini"
			required_reagents = list("gin" = 2, "vermouth" = 1)
			result_amount = 3

		vodkamartini
			name = "Vodka Martini"
			id = "vodkamartini"
			result = "vodkamartini"
			required_reagents = list("vodka" = 2, "vermouth" = 1)
			result_amount = 3

		white_russian
			name = "White Russian"
			id = "whiterussian"
			result = "whiterussian"
			required_reagents = list("blackrussian" = 3, "cream" = 2)
			result_amount = 5

		whiskey_cola
			name = "Whiskey Cola"
			id = "whiskeycola"
			result = "whiskeycola"
			required_reagents = list("whiskey" = 2, "cola" = 1)
			result_amount = 3

		screwdriver
			name = "Screwdriver"
			id = "screwdrivercocktail"
			result = "screwdrivercocktail"
			required_reagents = list("vodka" = 2, "orangejuice" = 1)
			result_amount = 3

		bloody_mary
			name = "Bloody Mary"
			id = "bloodymary"
			result = "bloodymary"
			required_reagents = list("vodka" = 1, "tomatojuice" = 2, "limejuice" = 1)
			result_amount = 4

		gargle_blaster
			name = "Pan-Galactic Gargle Blaster"
			id = "gargleblaster"
			result = "gargleblaster"
			required_reagents = list("vodka" = 1, "gin" = 1, "whiskey" = 1, "cognac" = 1, "limejuice" = 1)
			result_amount = 5

		brave_bull
			name = "Brave Bull"
			id = "bravebull"
			result = "bravebull"
			required_reagents = list("tequilla" = 2, "kahlua" = 1)
			result_amount = 3

		tequilla_sunrise
			name = "Tequilla Sunrise"
			id = "tequillasunrise"
			result = "tequillasunrise"
			required_reagents = list("tequilla" = 2, "orangejuice" = 1)
			result_amount = 3

		toxins_special
			name = "Toxins Special"
			id = "toxinsspecial"
			result = "toxinsspecial"
			required_reagents = list("rum" = 2, "vermouth" = 1, "plasma" = 2)
			result_amount = 5

		beepsky_smash
			name = "Beepksy Smash"
			id = "beepksysmash"
			result = "beepskysmash"
			required_reagents = list("limejuice" = 2, "whiskey" = 2, "iron" = 1)
			result_amount = 4

/*		doctor_delight
			name = "The Doctor's Delight"
			id = "doctordelight"
			result = "omnizine"
			required_reagents = list("limejuice" = 1, "tomatojuice" = 1, "orangejuice" = 1, "cream" = 1, "omnizine" = 1)
			result_amount = 5
*/

		irish_cream
			name = "Irish Cream"
			id = "irishcream"
			result = "irishcream"
			required_reagents = list("whiskey" = 2, "cream" = 1)
			result_amount = 3

		manly_dorf
			name = "The Manly Dorf"
			id = "manlydorf"
			result = "manlydorf"
			required_reagents = list ("beer" = 1, "ale" = 2)
			result_amount = 3

		hooch
			name = "Hooch"
			id = "hooch"
			result = "hooch"
			required_reagents = list ("sugar" = 1, "ethanol" = 2, "fuel" = 1)
			result_amount = 3

		irish_coffee
			name = "Irish Coffee"
			id = "irishcoffee"
			result = "irishcoffee"
			required_reagents = list("irishcream" = 1, "coffee" = 1)
			result_amount = 2

		b52
			name = "B-52"
			id = "b52"
			result = "b52"
			required_reagents = list("irishcream" = 1, "kahlua" = 1, "cognac" = 1)
			result_amount = 3

		atomicbomb
			name = "Atomic Bomb"
			id = "atomicbomb"
			result = "atomicbomb"
			required_reagents = list("b52" = 10, "uranium" = 1)
			result_amount = 10

		margarita
			name = "Margarita"
			id = "margarita"
			result = "margarita"
			required_reagents = list("tequilla" = 2, "limejuice" = 1)
			result_amount = 3

		longislandicedtea
			name = "Long Island Iced Tea"
			id = "longislandicedtea"
			result = "longislandicedtea"
			required_reagents = list("vodka" = 1, "gin" = 1, "tequilla" = 1, "cubalibre" = 1)
			result_amount = 4

		icedtea
			name = "Long Island Iced Tea"
			id = "longislandicedtea"
			result = "longislandicedtea"
			required_reagents = list("vodka" = 1, "gin" = 1, "tequilla" = 1, "cubalibre" = 1)
			result_amount = 4

		threemileisland
			name = "Three Mile Island Iced Tea"
			id = "threemileisland"
			result = "threemileisland"
			required_reagents = list("longislandicedtea" = 10, "uranium" = 1)
			result_amount = 10

		whiskeysoda
			name = "Whiskey Soda"
			id = "whiskeysoda"
			result = "whiskeysoda"
			required_reagents = list("whiskey" = 2, "sodawater" = 1)
			result_amount = 3

		black_russian
			name = "Black Russian"
			id = "blackrussian"
			result = "blackrussian"
			required_reagents = list("vodka" = 3, "kahlua" = 2)
			result_amount = 5

		manhattan
			name = "Manhattan"
			id = "manhattan"
			result = "manhattan"
			required_reagents = list("whiskey" = 2, "vermouth" = 1)
			result_amount = 3

		manhattan_proj
			name = "Manhattan Project"
			id = "manhattan_proj"
			result = "manhattan_proj"
			required_reagents = list("manhattan" = 10, "uranium" = 1)
			result_amount = 10

		vodka_tonic
			name = "Vodka and Tonic"
			id = "vodkatonic"
			result = "vodkatonic"
			required_reagents = list("vodka" = 2, "tonic" = 1)
			result_amount = 3

		gin_fizz
			name = "Gin Fizz"
			id = "ginfizz"
			result = "ginfizz"
			required_reagents = list("gin" = 2, "sodawater" = 1, "limejuice" = 1)
			result_amount = 4

		bahama_mama
			name = "Bahama mama"
			id = "bahama_mama"
			result = "bahama_mama"
			required_reagents = list("rum" = 2, "orangejuice" = 2, "limejuice" = 1, "ice" = 1)
			result_amount = 6

		singulo
			name = "Singulo"
			id = "singulo"
			result = "singulo"
			required_reagents = list("vodka" = 5, "radium" = 1, "wine" = 5)
			result_amount = 10

		alliescocktail
			name = "Allies Cocktail"
			id = "alliescocktail"
			result = "alliescocktail"
			required_reagents = list("martini" = 1, "vodka" = 1)
			result_amount = 2

		demonsblood
			name = "Demons Blood"
			id = "demonsblood"
			result = "demonsblood"
			required_reagents = list("rum" = 1, "spacemountainwind" = 1, "blood" = 1, "dr_gibb" = 1)
			result_amount = 4

		booger
			name = "Booger"
			id = "booger"
			result = "booger"
			required_reagents = list("cream" = 1, "banana" = 1, "rum" = 1, "watermelonjuice" = 1)
			result_amount = 4

		antifreeze
			name = "Anti-freeze"
			id = "antifreeze"
			result = "antifreeze"
			required_reagents = list("vodka" = 2, "cream" = 1, "ice" = 1)
			result_amount = 4

		barefoot
			name = "Barefoot"
			id = "barefoot"
			result = "barefoot"
			required_reagents = list("berryjuice" = 1, "cream" = 1, "vermouth" = 1)
			result_amount = 3

		grapesoda
			name = "Grape Soda"
			id = "grapesoda"
			result = "grapesoda"
			required_reagents = list("grapejuice" = 2, "cola" = 1)
			result_amount = 3



////DRINKS THAT REQUIRED IMPROVED SPRITES BELOW:: -Agouri/////

		sbiten
			name = "Sbiten"
			id = "sbiten"
			result = "sbiten"
			required_reagents = list("vodka" = 10, "capsaicin" = 1)
			result_amount = 10

		red_mead
			name = "Red Mead"
			id = "red_mead"
			result = "red_mead"
			required_reagents = list("blood" = 1, "mead" = 1)
			result_amount = 2

		mead
			name = "Mead"
			id = "mead"
			result = "mead"
			required_reagents = list("sugar" = 1, "water" = 1)
			required_catalysts = list("enzyme" = 5)
			result_amount = 2

		iced_beer
			name = "Iced Beer"
			id = "iced_beer"
			result = "iced_beer"
			required_reagents = list("beer" = 10, "frostoil" = 1)
			result_amount = 10

		iced_beer2
			name = "Iced Beer"
			id = "iced_beer"
			result = "iced_beer"
			required_reagents = list("beer" = 5, "ice" = 1)
			result_amount = 6

		grog
			name = "Grog"
			id = "grog"
			result = "grog"
			required_reagents = list("rum" = 1, "water" = 1)
			result_amount = 2

		soy_latte
			name = "Soy Latte"
			id = "soy_latte"
			result = "soy_latte"
			required_reagents = list("coffee" = 1, "soymilk" = 1)
			result_amount = 2

		cafe_latte
			name = "Cafe Latte"
			id = "cafe_latte"
			result = "cafe_latte"
			required_reagents = list("coffee" = 1, "milk" = 1)
			result_amount = 2

		acidspit
			name = "Acid Spit"
			id = "acidspit"
			result = "acidspit"
			required_reagents = list("sacid" = 1, "wine" = 5)
			result_amount = 6

		amasec
			name = "Amasec"
			id = "amasec"
			result = "amasec"
			required_reagents = list("iron" = 1, "wine" = 5, "vodka" = 5)
			result_amount = 10

		changelingsting
			name = "Changeling Sting"
			id = "changelingsting"
			result = "changelingsting"
			required_reagents = list("screwdrivercocktail" = 1, "limejuice" = 1, "lemonjuice" = 1)
			result_amount = 5

		aloe
			name = "Aloe"
			id = "aloe"
			result = "aloe"
			required_reagents = list("cream" = 1, "whiskey" = 1, "watermelonjuice" = 1)
			result_amount = 2

		andalusia
			name = "Andalusia"
			id = "andalusia"
			result = "andalusia"
			required_reagents = list("rum" = 1, "whiskey" = 1, "lemonjuice" = 1)
			result_amount = 3

		neurotoxin
			name = "Neurotoxin"
			id = "neurotoxin"
			result = "neurotoxin"
			required_reagents = list("gargleblaster" = 1, "stoxin" = 1)
			result_amount = 2

		snowwhite
			name = "Snow White"
			id = "snowwhite"
			result = "snowwhite"
			required_reagents = list("beer" = 1, "lemon_lime" = 1)
			result_amount = 2

		irishcarbomb
			name = "Irish Car Bomb"
			id = "irishcarbomb"
			result = "irishcarbomb"
			required_reagents = list("ale" = 1, "irishcream" = 1)
			result_amount = 2

		syndicatebomb
			name = "Syndicate Bomb"
			id = "syndicatebomb"
			result = "syndicatebomb"
			required_reagents = list("beer" = 1, "whiskeycola" = 1)
			result_amount = 2

		erikasurprise
			name = "Erika Surprise"
			id = "erikasurprise"
			result = "erikasurprise"
			required_reagents = list("ale" = 1, "limejuice" = 1, "whiskey" = 1, "banana" = 1, "ice" = 1)
			result_amount = 5

		devilskiss
			name = "Devils Kiss"
			id = "devilskiss"
			result = "devilskiss"
			required_reagents = list("blood" = 1, "kahlua" = 1, "rum" = 1)
			result_amount = 3

		hippiesdelight
			name = "Hippies Delight"
			id = "hippiesdelight"
			result = "hippiesdelight"
			required_reagents = list("psilocybin" = 1, "gargleblaster" = 1)
			result_amount = 2

		bananahonk
			name = "Banana Honk"
			id = "bananahonk"
			result = "bananahonk"
			required_reagents = list("banana" = 1, "cream" = 1, "sugar" = 1)
			result_amount = 3

		silencer
			name = "Silencer"
			id = "silencer"
			result = "silencer"
			required_reagents = list("nothing" = 1, "cream" = 1, "sugar" = 1)
			result_amount = 3

		driestmartini
			name = "Driest Martini"
			id = "driestmartini"
			result = "driestmartini"
			required_reagents = list("nothing" = 1, "gin" = 1)
			result_amount = 2

		lemonade
			name = "Lemonade"
			id = "lemonade"
			result = "lemonade"
			required_reagents = list("lemonjuice" = 1, "sugar" = 1, "water" = 1)
			result_amount = 3

		kiraspecial
			name = "Kira Special"
			id = "kiraspecial"
			result = "kiraspecial"
			required_reagents = list("orangejuice" = 1, "limejuice" = 1, "sodawater" = 1)
			result_amount = 2

		brownstar
			name = "Brown Star"
			id = "brownstar"
			result = "brownstar"
			required_reagents = list("orangejuice" = 2, "cola" = 1)
			result_amount = 2

		milkshake
			name = "Milkshake"
			id = "milkshake"
			result = "milkshake"
			required_reagents = list("cream" = 1, "ice" = 2, "milk" = 2)
			result_amount = 5

		rewriter
			name = "Rewriter"
			id = "rewriter"
			result = "rewriter"
			required_reagents = list("spacemountainwind" = 1, "coffee" = 1)
			result_amount = 2

		suidream
			name = "Sui Dream"
			id = "suidream"
			result = "suidream"
			required_reagents = list("space_up" = 2, "bluecuracao" = 1, "melonliquor" = 1)
			result_amount = 4
