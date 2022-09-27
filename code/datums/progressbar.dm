/datum/progressbar
	var/goal = 1
	var/image/bar
	var/shown = 0
	var/mob/user
	var/client/client

/datum/progressbar/New(mob/user, goal_number, atom/target)
	. = ..()
	if(!target) target = user
	if (!istype(target))
		EXCEPTION("Invalid target given")
	if (goal_number)
		goal = goal_number
	bar = image('icons/effects/progressbar.dmi', target, "0")
	bar.appearance_flags = NO_CLIENT_COLOR|RESET_ALPHA
	bar.plane = HUD_PLANE
	bar.layer = HUD_ABOVE_ITEM_LAYER
	src.user = user
	if(user)
		client = user.client

/datum/progressbar/Destroy()
	if (client)
		client.images -= bar
	qdel(bar)
	. = ..()

/datum/progressbar/proc/update(i)
//	log_debug("Update [progress] - [goal] - [(progress / goal)] - [((progress / goal) * 100)] - [round(((progress / goal) * 100), 5)]")

	if (!user || !user.client)
		shown = 0
		return
	if (user.client != client)
		if (client)
			client.images -= bar
			shown = 0
		client = user.client

	bar.icon_state = "[i]"
	if (!shown)
		user.client.images += bar
		shown = 1