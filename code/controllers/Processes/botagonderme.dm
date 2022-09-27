/datum/controller/process/dcbot/setup()
	name = "obj"
	schedule_interval = 150 // every 2 seconds
	start_delay = 18

/datum/controller/process/dcbot/doWork()
	var/totalPlayers
	totalPlayers = LAZYLEN(GLOB.player_list)
	world.Export("http://localhost:22422/[totalPlayers]",1,null)
