#define SAVEFILE_VERSION_MIN	8
#define SAVEFILE_VERSION_MAX	11

//handles converting savefiles to new formats
//MAKE SURE YOU KEEP THIS UP TO DATE!
//If the sanity checks are capable of handling any issues. Only increase SAVEFILE_VERSION_MAX,
//this will mean that savefile_version will still be over SAVEFILE_VERSION_MIN, meaning
//this savefile update doesn't run everytime we load from the savefile.
//This is mainly for format changes, such as the bitflags in toggles changing order or something.
//if a file can't be updated, return 0 to delete it and start again
//if a file was updated, return 1
/datum/preferences/proc/savefile_update()
	if(savefile_version < 8)	//lazily delete everything + additional files so they can be saved in the new format
		for(var/ckey in preferences_datums)
			var/datum/preferences/D = preferences_datums[ckey]
			if(D == src)
				var/delpath = "data/player_saves/[copytext(ckey,1,2)]/[ckey]/"
				if(delpath && fexists(delpath))
					fdel(delpath)
				break
		return 0

	if(savefile_version == SAVEFILE_VERSION_MAX)	//update successful.
		save_preferences()
		save_character()
		return 1
	return 0

/datum/preferences/proc/load_path(ckey,filename="preferences.sav")
	if(!ckey)	return
	path = "data/player_saves/[copytext(ckey,1,2)]/[ckey]/[filename]"
	savefile_version = SAVEFILE_VERSION_MAX

/datum/preferences/proc/load_preferences()
	if(!path)				return 0
	if(!fexists(path))		return 0
	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	S.cd = "/"

	S["version"] >> savefile_version
	//Conversion
	if(!savefile_version || !isnum(savefile_version) || savefile_version < SAVEFILE_VERSION_MIN || savefile_version > SAVEFILE_VERSION_MAX)
		if(!savefile_update())  //handles updates
			savefile_version = SAVEFILE_VERSION_MAX
			save_preferences()
			save_character()
			return 0

	//general preferences
	S["ooccolor"]			>> ooccolor
	S["nameglow"]			>> nameglow
	S["lastchangelog"]		>> lastchangelog
	S["UI_style"]			>> UI_style
	S["UI_type"]			>> UI_type
	S["be_special"]			>> be_special
	S["default_slot"]		>> default_slot
	S["toggles"]			>> toggles
	S["UI_style_color"]		>> UI_style_color
	S["UI_style_alpha"]		>> UI_style_alpha
	S["chromossomes"]		>> chromossomes
	S["family"]		        >> family
	S["roundsplayed"]		>> roundsplayed
	S["togglefuta"]			>> togglefuta
	S["togglesize"]			>> togglesize
	S["graphicsSetting"]	>> graphicsSetting
	S["fullscreenSetting"]	>> fullscreenSetting
	S["blurSetting"]		>> blurSetting
	S["toggle_nat"]			>> toggle_nat
	S["ambi_volume"]		>> ambi_volume
	S["music_volume"]		>> music_volume
	S["rsc_fix"]			>> rsc_fix
	S["zoom_level"]			>> zoom_level
	S["toggle_squire"]		>> toggle_squire
	S["font_size"]			>> font_size

	//Sanitize
	ooccolor		= sanitize_hexcolor(ooccolor, initial(ooccolor))
	lastchangelog	= sanitize_text(lastchangelog, initial(lastchangelog))
	UI_style		= sanitize_inlist(UI_style, list("Luna","Retro"), initial(UI_style))
	UI_type			= sanitize_inlist(UI_type, list("Luna","Retro"), initial(UI_type))
	be_special		= sanitize_integer(be_special, 0, 65535, initial(be_special))
	default_slot	= sanitize_integer(default_slot, 1, MAX_SAVE_SLOTS, initial(default_slot))
	toggles			= sanitize_integer(toggles, 0, 65535, initial(toggles))
	UI_style_color	= sanitize_hexcolor(UI_style_color, initial(UI_style_color))
	UI_style_alpha	= sanitize_integer(UI_style_alpha, 0, 255, initial(UI_style_alpha))
	if(isnull(roundsplayed)) roundsplayed = 0
	if(isnull(togglefuta)) togglefuta = 0
	if(isnull(togglesize)) togglesize = 0
	if(isnull(ambi_volume)) ambi_volume = 60
	if(isnull(music_volume)) music_volume = 70
	if(isnull(font_size)) font_size = 100
	//if(isnull(toggle_nat)) toggle_nat = 0
	//chromossomes	= sanitize_integer(chromossomes, initial(chromossomes))

	return 1

/datum/preferences/proc/save_preferences()
	if(!path)				return 0
	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	S.cd = "/"

	S["version"] << savefile_version

	//general preferences
	S["ooccolor"]			<< ooccolor
	S["nameglow"]			<< nameglow
	S["lastchangelog"]		<< lastchangelog
	S["UI_style"]			<< UI_style
	S["UI_type"]			<< UI_type
	S["be_special"]			<< be_special
	S["default_slot"]		<< default_slot
	S["toggles"]			<< toggles
	S["UI_style_color"]		<< UI_style_color
	S["UI_style_alpha"]		<< UI_style_alpha
	S["chromossomes"]		<< chromossomes
	S["family"]				<< family
	S["roundsplayed"]		<< roundsplayed
	S["toggle_nat"]			<< toggle_nat
	S["togglefuta"]			<< togglefuta
	S["togglesize"]			<< togglesize
	S["graphicsSetting"]	<< graphicsSetting
	S["fullscreenSetting"]	<< fullscreenSetting
	S["blurSetting"]		<< blurSetting
	S["ambi_volume"]		<< ambi_volume
	S["music_volume"]		<< music_volume
	S["rsc_preload"]		<< rsc_fix
	S["zoom_level"]			<< zoom_level
	S["toggle_squire"]		<< toggle_squire
	S["font_size"]			<< max(0,font_size)

	return 1

/datum/preferences/proc/load_character(slot)
	if(!path)				return 0
	if(!fexists(path))		return 0
	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	S.cd = "/"
	if(!slot)	slot = default_slot
	slot = sanitize_integer(slot, 1, MAX_SAVE_SLOTS, initial(default_slot))
	if(slot != default_slot)
		default_slot = slot
		S["default_slot"] << slot
	S.cd = "/character[slot]"

	//Character
	S["real_name"]			>> real_name
	S["dwarven"]			>> dwarven
	S["name_is_always_random"] >> be_random_name
	S["gender"]				>> gender
	S["fat"]				>> fat
	S["age"]				>> age
	//colors to be consolidated into hex strings (requires some work with dna code)
	S["hair_red"]			>> r_hair
	S["hair_green"]			>> g_hair
	S["hair_blue"]			>> b_hair
	S["facial_red"]			>> r_facial
	S["facial_green"]		>> g_facial
	S["facial_blue"]		>> b_facial
	S["detail_red"]			>> r_detail
	S["detail_green"]		>> g_detail
	S["detail_blue"]		>> b_detail
	S["skin_tone"]			>> s_tone
	S["hair_style_name"]	>> h_style
	S["detail_name"]	    >> d_style
	S["facial_style_name"]	>> f_style
	S["eyes_red"]			>> r_eyes
	S["eyes_green"]			>> g_eyes
	S["eyes_blue"]			>> b_eyes
	S["underwear"]			>> underwear
	S["backbag"]			>> backbag
	S["b_type"]				>> b_type

	//Jobs
	S["alternate_option"]	>> alternate_option
	S["job_civilian_high"]	>> job_civilian_high
	S["job_civilian_med"]	>> job_civilian_med
	S["job_civilian_low"]	>> job_civilian_low
	S["job_medsci_high"]	>> job_medsci_high
	S["job_medsci_med"]		>> job_medsci_med
	S["job_medsci_low"]		>> job_medsci_low
	S["job_engsec_high"]	>> job_engsec_high
	S["job_engsec_med"]		>> job_engsec_med
	S["job_engsec_low"]		>> job_engsec_low

	//Flavour Text
	S["flavor_texts_general"]	>> flavor_texts["general"]
	S["flavor_texts_head"]		>> flavor_texts["head"]
	S["flavor_texts_face"]		>> flavor_texts["face"]
	S["flavor_texts_eyes"]		>> flavor_texts["eyes"]
	S["flavor_texts_torso"]		>> flavor_texts["torso"]
	S["flavor_texts_arms"]		>> flavor_texts["arms"]
	S["flavor_texts_hands"]		>> flavor_texts["hands"]
	S["flavor_texts_legs"]		>> flavor_texts["legs"]
	S["flavor_texts_feet"]		>> flavor_texts["feet"]

	//Miscellaneous
	S["med_record"]			>> med_record
	S["sec_record"]			>> sec_record
	S["gen_record"]			>> gen_record
	S["be_special"]			>> be_special
	S["disabilities"]		>> disabilities
	S["organ_data"]			>> organ_data

	S["nanotrasen_relation"] >> nanotrasen_relation
	//S["skin_style"]			>> skin_style

	S["uplinklocation"] >> uplinklocation
	S["vice"] >> vice
	S["MigProvince"] >> MigProvince
	S["zodiac"] >> zodiac
	S["family"] >> family


	//Sanitize
	real_name		= reject_bad_name(real_name)
	if(isnull(species)) species = "Human"
	if(isnull(language)) language = "None"
	if(isnull(nanotrasen_relation)) nanotrasen_relation = initial(nanotrasen_relation)
	if(!real_name) real_name = random_name(gender)
	be_random_name	= sanitize_integer(be_random_name, 0, 1, initial(be_random_name))
	dwarven 		= sanitize_integer(dwarven, 0, 1, initial(dwarven))
	gender			= sanitize_gender(gender)
	fat				= sanitize_integer(fat, 0, 1, initial(fat))
	age				= sanitize_integer(age, AGE_MIN, AGE_MAX, initial(age))
	r_hair			= sanitize_integer(r_hair, 0, 255, initial(r_hair))
	g_hair			= sanitize_integer(g_hair, 0, 255, initial(g_hair))
	b_hair			= sanitize_integer(b_hair, 0, 255, initial(b_hair))
	r_facial		= sanitize_integer(r_facial, 0, 255, initial(r_facial))
	g_facial		= sanitize_integer(g_facial, 0, 255, initial(g_facial))
	b_facial		= sanitize_integer(b_facial, 0, 255, initial(b_facial))
	r_detail		= sanitize_integer(r_detail, 0, 255, initial(r_detail))
	g_detail		= sanitize_integer(g_detail, 0, 255, initial(g_detail))
	b_detail		= sanitize_integer(b_detail, 0, 255, initial(b_detail))
	s_tone			= sanitize_integer(s_tone, -185, 34, initial(s_tone))
	h_style			= sanitize_inlist(h_style, hair_styles_list, initial(h_style))
	d_style			= sanitize_inlist(d_style, facial_details_list, initial(d_style))
	f_style			= sanitize_inlist(f_style, facial_hair_styles_list, initial(f_style))
	r_eyes			= sanitize_integer(r_eyes, 0, 255, initial(r_eyes))
	g_eyes			= sanitize_integer(g_eyes, 0, 255, initial(g_eyes))
	b_eyes			= sanitize_integer(b_eyes, 0, 255, initial(b_eyes))
	underwear		= sanitize_integer(underwear, 1, underwear_m.len, initial(underwear))
	backbag			= sanitize_integer(backbag, 1, backbaglist.len, initial(backbag))
	b_type			= sanitize_text(b_type, initial(b_type))
	if(isnull(vice)) vice = initial(vice)
	if(isnull(zodiac)) zodiac = initial(zodiac)
	if(isnull(MigProvince)) MigProvince = initial(MigProvince)
	if(isnull(family)) family = initial(family)

	//vice			= sanitize_text(vice, , initial(vice))
	//zodiac			= sanitize_text(zodiac, , initial(zodiac))

	alternate_option = sanitize_integer(alternate_option, 0, 2, initial(alternate_option))
	job_civilian_high = sanitize_integer(job_civilian_high, 0, 65535, initial(job_civilian_high))
	job_civilian_med = sanitize_integer(job_civilian_med, 0, 65535, initial(job_civilian_med))
	job_civilian_low = sanitize_integer(job_civilian_low, 0, 65535, initial(job_civilian_low))
	job_medsci_high = sanitize_integer(job_medsci_high, 0, 65535, initial(job_medsci_high))
	job_medsci_med = sanitize_integer(job_medsci_med, 0, 65535, initial(job_medsci_med))
	job_medsci_low = sanitize_integer(job_medsci_low, 0, 65535, initial(job_medsci_low))
	job_engsec_high = sanitize_integer(job_engsec_high, 0, 65535, initial(job_engsec_high))
	job_engsec_med = sanitize_integer(job_engsec_med, 0, 65535, initial(job_engsec_med))
	job_engsec_low = sanitize_integer(job_engsec_low, 0, 65535, initial(job_engsec_low))

	if(isnull(disabilities)) disabilities = 0
	if(!organ_data) src.organ_data = list()
	//if(!skin_style) skin_style = "Default"

	return 1

/datum/preferences/proc/save_character()
	if(!path)				return 0
	var/savefile/S = new /savefile(path)
	if(!S)					return 0
	S.cd = "/character[default_slot]"

	//Character
	S["real_name"]			<< real_name
	S["name_is_always_random"] << be_random_name
	S["dwarven"]			<< dwarven
	S["gender"]				<< gender
	S["fat"]				<< fat
	S["age"]				<< age
	S["hair_red"]			<< r_hair
	S["hair_green"]			<< g_hair
	S["hair_blue"]			<< b_hair
	S["facial_red"]			<< r_facial
	S["facial_green"]		<< g_facial
	S["facial_blue"]		<< b_facial
	S["detail_red"]			<< r_detail
	S["detail_green"]		<< g_detail
	S["detail_blue"]		<< b_detail
	S["skin_tone"]			<< s_tone
	S["hair_style_name"]	<< h_style
	S["detail_name"]	    << d_style
	S["facial_style_name"]	<< f_style
	S["eyes_red"]			<< r_eyes
	S["eyes_green"]			<< g_eyes
	S["eyes_blue"]			<< b_eyes
	S["underwear"]			<< underwear
	S["backbag"]			<< backbag
	S["b_type"]				<< b_type

	//Flavour Text
	S["flavor_texts_general"]	<< flavor_texts["general"]
	S["flavor_texts_head"]		<< flavor_texts["head"]
	S["flavor_texts_face"]		<< flavor_texts["face"]
	S["flavor_texts_eyes"]		<< flavor_texts["eyes"]
	S["flavor_texts_torso"]		<< flavor_texts["torso"]
	S["flavor_texts_arms"]		<< flavor_texts["arms"]
	S["flavor_texts_hands"]		<< flavor_texts["hands"]
	S["flavor_texts_legs"]		<< flavor_texts["legs"]
	S["flavor_texts_feet"]		<< flavor_texts["feet"]

	//Jobs
	S["alternate_option"]	<< alternate_option
	S["job_civilian_high"]	<< job_civilian_high
	S["job_civilian_med"]	<< job_civilian_med
	S["job_civilian_low"]	<< job_civilian_low
	S["job_medsci_high"]	<< job_medsci_high
	S["job_medsci_med"]		<< job_medsci_med
	S["job_medsci_low"]		<< job_medsci_low
	S["job_engsec_high"]	<< job_engsec_high
	S["job_engsec_med"]		<< job_engsec_med
	S["job_engsec_low"]		<< job_engsec_low

	//Miscellaneous
	S["med_record"]			<< med_record
	S["sec_record"]			<< sec_record
	S["gen_record"]			<< gen_record
	S["be_special"]			<< be_special
	S["disabilities"]		<< disabilities
	S["organ_data"]			<< organ_data

	S["nanotrasen_relation"] << nanotrasen_relation
	//S["skin_style"]			<< skin_style

	S["uplinklocation"] << uplinklocation
	S["vice"] << vice
	S["MigProvince"] << MigProvince
	S["zodiac"] << zodiac
	S["family"] << family

	return 1


#undef SAVEFILE_VERSION_MAX
#undef SAVEFILE_VERSION_MIN
