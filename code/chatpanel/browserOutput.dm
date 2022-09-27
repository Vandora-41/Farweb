/*********************************
For the main html chat area
*********************************/


//Precaching a bunch of shit
GLOBAL_DATUM_INIT(iconCache, /savefile, new("data/iconCache.sav")) //Cache of icons for the browser output

//On client, created on login
/datum/chatOutput
	var/client/owner	 //client ref
	var/loaded       = FALSE // Has the client loaded the browser output area?
	var/list/messageQueue //If they haven't loaded chat, this is where messages will go until they do
	var/cookieSent   = FALSE // Has the client sent a cookie for analysis
	var/broken       = FALSE
	var/list/connectionHistory //Contains the connection history passed from chat cookie
	var/number_messages = 0

/datum/chatOutput/New(client/C)
	owner = C
	messageQueue = list()
	connectionHistory = list()

/datum/chatOutput/proc/start()
	//Check for existing chat
	if(!owner)
		return FALSE
	/*
	if(!winexists(owner, "browseroutput")) // Oh goddamnit.
		set waitfor = FALSE
		broken = TRUE
		message_admins("Couldn't start chat for [key_name_admin(owner)]!")
		. = FALSE
		//alert(owner.mob, "Updated chat window does not exist. If you are using a custom skin file please allow the game to update.")
		return
	*/
	load()

	return TRUE

/datum/chatOutput/proc/load()
	set waitfor = FALSE
	if(!owner)
		return
#ifndef FARWEB_LIVE
	var/datum/asset/stuff = get_asset_datum(/datum/asset/chatpanel)
	stuff.register()
	stuff.send(owner)
#endif
	/*
	spawn(0)
		owner << browse('code/chatpanel/browserassets/html/chatpanel.html', "window=browseroutput")
*/
/datum/chatOutput/Topic(href, list/href_list)
	if(usr.client != owner)
		return TRUE

	// Build arguments.
	// Arguments are in the form "param[paramname]=thing"
	var/list/params = list()
	for(var/key in href_list)
		if(length(key) > 7 && findtext(key, "param")) // 7 is the amount of characters in the basic param key template.
			var/param_name = copytext(key, 7, -1)
			var/item       = href_list[key]

			params[param_name] = item

//	var/data // Data to be sent back to the chat.
	if(href_list["cpload"] == "1")
		doneLoading()
	/*
	switch(href_list["proc"])
		if("doneLoading")
			data = doneLoading(arglist(params))

		if("debug")
			data = debug(arglist(params))

		if("ping")
			data = ping(arglist(params))

		if("analyzeClientData")
			data = analyzeClientData(arglist(params))
	*/
//	if(data)
//		ehjax_send(data = data)


//Called on chat output done-loading by JS.
/datum/chatOutput/proc/doneLoading()
	if(loaded)
		return
	testing("Chat loaded for [owner.ckey]")
	loaded = TRUE
	owner.chat_resize()
	winset(owner, "browseroutput", "on-size=.csize") //set at runtime to avoid causing errors from resizing the window before the chat is loaded.

	showChat()


	for(var/message in messageQueue)
		to_chat(owner, message)

	messageQueue = null
//	sendClientData()

	//do not convert to to_chat()
	//owner << "<span class=\"userdanger\">If you can see this, update byond.</span>"

//	pingLoop()

/client/verb/chat_resize()
	set name = ".csize"
	var/fsize = max(0,prefs.font_size)
	var/csize = winget(src, "browseroutput", "size")
	var/y = text2num(copytext(csize, 1, findtext(csize, "x"))) - 5
	var/x = text2num(copytext(csize, findtext(csize, "x")+1, 0)) - 40
	src << output(list2params(list(fsize)), "browseroutput:TextSize")
	src << output(list2params(list(x)), "browseroutput:SetSize")
	src << output(list2params(list(y)), "browseroutput:SetWidth")

/datum/chatOutput/proc/showChat()
	winset(owner, "output", "is-visible=false")
	winset(owner, "browseroutput", "is-disabled=false;is-visible=true")

/*
/datum/chatOutput/proc/ehjax_send(client/C = owner, window = "browseroutput", data)
	if(islist(data))
		data = json_encode(data)
	C << output("[data]", "[window]:ehjaxCallback")
*/
/*
//Sends client connection details to the chat to handle and save
/datum/chatOutput/proc/sendClientData()
	//Get dem deets
	var/list/deets = list("clientData" = list())
	deets["clientData"]["ckey"] = owner.ckey
	deets["clientData"]["ip"] = owner.address
	deets["clientData"]["compid"] = owner.computer_id
	var/data = json_encode(deets)
	ehjax_send(data = data)

//Called by client, sent data to investigate (cookie history so far)
/datum/chatOutput/proc/analyzeClientData(cookie = "")
	if(!cookie)
		return

	if(cookie != "none")
		var/list/connData = json_decode(cookie)
		if (connData && islist(connData) && connData.len > 0 && connData["connData"])
			connectionHistory = connData["connData"] //lol fuck
			var/list/found = new()
			for(var/i in connectionHistory.len to 1 step -1)
				var/list/row = src.connectionHistory[i]
				if (!row || row.len < 3 || (!row["ckey"] || !row["compid"] || !row["ip"])) //Passed malformed history object
					return
				if (world.IsBanned(row["ckey"], row["compid"], row["ip"]))
					found = row
					break

			//Uh oh this fucker has a history of playing on a banned account!!
			if (found.len > 0)
				//TODO: add a new evasion ban for the CURRENT client details, using the matched row details
				message_admins("[key_name(src.owner)] has a cookie from a banned account! (Matched: [found["ckey"]], [found["ip"]], [found["compid"]])")
				log_admin("[key_name(owner)] has a cookie from a banned account! (Matched: [found["ckey"]], [found["ip"]], [found["compid"]])")

	cookieSent = TRUE

//Called by js client every 60 seconds
/datum/chatOutput/proc/ping()
	return "pong"
*/
/proc/log_world(text)
	to_world_log(text) //this comes before the config check because it can't possibly runtime
	game_log("DD_OUTPUT", text)

//Called by js client on js error
/datum/chatOutput/proc/debug(error)
	log_world("\[[time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")]\] Client: [(src.owner.key ? src.owner.key : src.owner)] triggered JS error: [error]")

//Global chat procs

/proc/to_chat(target, message, extra = FALSE)
	if(!target)
		return

	//Ok so I did my best but I accept that some calls to this will be for shit like sound and images
	//It stands that we PROBABLY don't want to output those to the browser output so just handle them here
	if (istype(message, /image) || istype(message, /sound) || istype(target, /savefile))
		CRASH("Invalid message! [message]")

	if(!istext(message))
		return

	if(target == world)
		target = clients

	var/list/targets
	if(!islist(target))
		targets = list(target)
	else
		targets = target
		if(!targets.len)
			return
	var/original_message = message
	//Some macros remain in the string even after parsing and fuck up the eventual output
	message = replacetext(message, "\improper", "")
	message = replacetext(message, "\proper", "")
	message = replacetext(message, "\n", "<br>")
	message = replacetext(message, "\t", "[TAB][TAB]")
	message = replacetext(message, "\\", "&#92")

	for(var/I in targets)
		//Grab us a client if possible
		var/client/C = grab_client(I)

		if (!C)
			continue

		//Send it to the old style output window.
		C << original_message

		if(!C.chatOutput || C.chatOutput.broken) // A player who hasn't updated his skin file.
			continue

		if(!C.chatOutput.loaded)
			//Client still loading, put their messages in a queue
			C.chatOutput.messageQueue += message
			continue
		var/list/send = list(message,extra)
		C << output(list2params(send), "browseroutput:receiveMessage")

/proc/grab_client(target)
	if(istype(target, /client))
		return target
	else if(ismob(target))
		var/mob/M = target
		if(M.client)
			return M.client
	else if(istype(target, /datum/mind))
		var/datum/mind/M = target
		if(M.current && M.current.client)
			return M.current.client

/proc/generatehintbox(var/imgUrl = "", var/description = "")
	var/message = {"<span class='ovr'><img class ='IMG big' src='[imgUrl]'><div class='htxt'>[description]</div></span>"}
	return message