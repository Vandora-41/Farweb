
/obj/item/weapon/reagent_containers/glass/bottle/robot
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5,10,15,25,30,50,100)
	flags = FPRINT | TABLEPASS | OPENCONTAINER
	volume = 60
	var/reagent = ""


/obj/item/weapon/reagent_containers/glass/bottle/robot/epinephrine
	name = "internal epinephrine bottle"
	desc = "A small bottle. Contains epinephrine - used to stabilize patients."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle16"
	reagent = "epinephrine"

	New()
		..()
		reagents.add_reagent("epinephrine", 60)
		return


/obj/item/weapon/reagent_containers/glass/bottle/robot/antitoxin
	name = "internal anti-toxin bottle"
	desc = "A small bottle of Anti-toxins. Counters poisons, and repairs damage, a wonder drug."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle17"
	reagent = "charcoal"

	New()
		..()
		reagents.add_reagent("charcoal", 60)
		return