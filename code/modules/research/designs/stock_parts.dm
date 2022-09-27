////////////////////////////////////////
/////////////Stock Parts////////////////
////////////////////////////////////////
/*
/datum/design/RPED
	name = "Rapid Part Exchange Device"
	desc = "Special mechanical module made to store, sort, and apply standard machine parts."
	id = "rped"
	req_tech = list("engineering" = 3,
					"materials" = 3)
	build_type = PROTOLATHE
	materials = list("$metal" = 15000, "$glass" = 5000) //hardcore
	build_path = /obj/item/weapon/storage/part_replacer
*/

/datum/design/basic_capacitor
	name = "Basic Capacitor"
	desc = "A stock part used in the construction of various devices."
	id = "basic_capacitor"
	req_tech = list("powerstorage" = 1)
	build_type = PROTOLATHE | AUTOLATHE
	materials = list("$metal" = 50, "$glass" = 50)
	build_path = /obj/item/weapon/stock_parts/capacitor

/datum/design/basic_sensor
	name = "Basic Sensor Module"
	desc = "A stock part used in the construction of various devices."
	id = "basic_sensor"
	req_tech = list("magnets" = 1)
	build_type = PROTOLATHE | AUTOLATHE
	materials = list("$metal" = 50, "$glass" = 20)
	build_path = /obj/item/weapon/stock_parts/scanning_module

/datum/design/micro_mani
	name = "Micro Manipulator"
	desc = "A stock part used in the construction of various devices."
	id = "micro_mani"
	req_tech = list("materials" = 1, "programming" = 1)
	build_type = PROTOLATHE | AUTOLATHE
	materials = list("$metal" = 30)
	build_path = /obj/item/weapon/stock_parts/manipulator

/datum/design/basic_micro_laser
	name = "Basic Micro-Laser"
	desc = "A stock part used in the construction of various devices."
	id = "basic_micro_laser"
	req_tech = list("magnets" = 1)
	build_type = PROTOLATHE | AUTOLATHE
	materials = list("$metal" = 10, "$glass" = 20)
	build_path = /obj/item/weapon/stock_parts/micro_laser

/datum/design/basic_matter_bin
	name = "Basic Matter Bin"
	desc = "A stock part used in the construction of various devices."
	id = "basic_matter_bin"
	req_tech = list("materials" = 1)
	build_type = PROTOLATHE | AUTOLATHE
	materials = list("$metal" = 80)
	build_path = /obj/item/weapon/stock_parts/matter_bin

/datum/design/adv_capacitor
	name = "Advanced Capacitor"
	desc = "A stock part used in the construction of various devices."
	id = "adv_capacitor"
	req_tech = list("powerstorage" = 3)
	build_type = PROTOLATHE
	materials = list("$metal" = 50, "$glass" = 50)
	build_path = /obj/item/weapon/stock_parts/capacitor/adv

/datum/design/adv_sensor
	name = "Advanced Sensor Module"
	desc = "A stock part used in the construction of various devices."
	id = "adv_sensor"
	req_tech = list("magnets" = 3)
	build_type = PROTOLATHE
	materials = list("$metal" = 50, "$glass" = 20)
	build_path = /obj/item/weapon/stock_parts/scanning_module/adv

/datum/design/nano_mani
	name = "Nano Manipulator"
	desc = "A stock part used in the construction of various devices."
	id = "nano_mani"
	req_tech = list("materials" = 3, "programming" = 2)
	build_type = PROTOLATHE
	materials = list("$metal" = 30)
	build_path = /obj/item/weapon/stock_parts/manipulator/nano

/datum/design/high_micro_laser
	name = "High-Power Micro-Laser"
	desc = "A stock part used in the construction of various devices."
	id = "high_micro_laser"
	req_tech = list("magnets" = 3)
	build_type = PROTOLATHE
	materials = list("$metal" = 10, "$glass" = 20)
	build_path = /obj/item/weapon/stock_parts/micro_laser/high

/datum/design/adv_matter_bin
	name = "Advanced Matter Bin"
	desc = "A stock part used in the construction of various devices."
	id = "adv_matter_bin"
	req_tech = list("materials" = 3)
	build_type = PROTOLATHE
	materials = list("$metal" = 80)
	build_path = /obj/item/weapon/stock_parts/matter_bin/adv

/datum/design/super_capacitor
	name = "Super Capacitor"
	desc = "A stock part used in the construction of various devices."
	id = "super_capacitor"
	req_tech = list("powerstorage" = 5, "materials" = 4)
	build_type = PROTOLATHE
	reliability_base = 71
	materials = list("$metal" = 50, "$glass" = 50, "$gold" = 20)
	build_path = /obj/item/weapon/stock_parts/capacitor/super

/datum/design/phasic_sensor
	name = "Phasic Sensor Module"
	desc = "A stock part used in the construction of various devices."
	id = "phasic_sensor"
	req_tech = list("magnets" = 5, "materials" = 3)
	build_type = PROTOLATHE
	materials = list("$metal" = 50, "$glass" = 20, "$silver" = 10)
	reliability_base = 72
	build_path = /obj/item/weapon/stock_parts/scanning_module/phasic

/datum/design/pico_mani
	name = "Pico Manipulator"
	desc = "A stock part used in the construction of various devices."
	id = "pico_mani"
	req_tech = list("materials" = 5, "programming" = 2)
	build_type = PROTOLATHE
	materials = list("$metal" = 30)
	reliability_base = 73
	build_path = /obj/item/weapon/stock_parts/manipulator/pico

/datum/design/ultra_micro_laser
	name = "Ultra-High-Power Micro-Laser"
	desc = "A stock part used in the construction of various devices."
	id = "ultra_micro_laser"
	req_tech = list("magnets" = 5, "materials" = 5)
	build_type = PROTOLATHE
	materials = list("$metal" = 10, "$glass" = 20, "$uranium" = 10)
	reliability_base = 70
	build_path = /obj/item/weapon/stock_parts/micro_laser/ultra

/datum/design/super_matter_bin
	name = "Super Matter Bin"
	desc = "A stock part used in the construction of various devices."
	id = "super_matter_bin"
	req_tech = list("materials" = 5)
	build_type = PROTOLATHE
	materials = list("$metal" = 80)
	reliability_base = 75
	build_path = /obj/item/weapon/stock_parts/matter_bin/super


// Bluespace

/datum/design/subspace_ansible
	name = "Subspace Ansible"
	desc = "A compact module capable of sensing extradimensional activity."
	id = "s-ansible"
	req_tech = list("programming" = 3, "magnets" = 4, "materials" = 4, "bluespace" = 2)
	build_type = PROTOLATHE
	materials = list("$metal" = 80, "$silver" = 20)
	build_path = /obj/item/weapon/stock_parts/subspace/ansible

/datum/design/hyperwave_filter
	name = "Hyperwave filter"
	desc = "A tiny device capable of d_filtering and converting super-intense radiowaves."
	id = "s-filter"
	req_tech = list("programming" = 3, "magnets" = 3)
	build_type = PROTOLATHE
	materials = list("$metal" = 40, "$silver" = 10)
	build_path = /obj/item/weapon/stock_parts/subspace/filter

/datum/design/subspace_amplifier
	name = "Subspace Amplifier"
	desc = "A compact micro-machine capable of amplifying weak subspace transmissions."
	id = "s-amplifier"
	req_tech = list("programming" = 3, "magnets" = 4, "materials" = 4, "bluespace" = 2)
	build_type = PROTOLATHE
	materials = list("$metal" = 10, "$gold" = 30, "$uranium" = 15)
	build_path = /obj/item/weapon/stock_parts/subspace/amplifier

/datum/design/subspace_treatment
	name = "Subspace Treatment Disk"
	desc = "A compact micro-machine capable of stretching out hyper-compressed radio waves."
	id = "s-treatment"
	req_tech = list("programming" = 3, "magnets" = 2, "materials" = 4, "bluespace" = 2)
	build_type = PROTOLATHE
	materials = list("$metal" = 10, "$silver" = 20)
	build_path = /obj/item/weapon/stock_parts/subspace/treatment

/datum/design/subspace_analyzer
	name = "Subspace Analyzer"
	desc = "A sophisticated analyzer capable of analyzing cryptic subspace wavelengths."
	id = "s-analyzer"
	req_tech = list("programming" = 3, "magnets" = 4, "materials" = 4, "bluespace" = 2)
	build_type = PROTOLATHE
	materials = list("$metal" = 10, "$gold" = 15)
	build_path = /obj/item/weapon/stock_parts/subspace/analyzer

/datum/design/subspace_crystal
	name = "Ansible Crystal"
	desc = "A sophisticated analyzer capable of analyzing cryptic subspace wavelengths."
	id = "s-crystal"
	req_tech = list("magnets" = 4, "materials" = 4, "bluespace" = 2)
	build_type = PROTOLATHE
	materials = list("$glass" = 1000, "$silver" = 20, "$gold" = 20)
	build_path = /obj/item/weapon/stock_parts/subspace/crystal

/datum/design/subspace_transmitter
	name = "Subspace Transmitter"
	desc = "A large piece of equipment used to open a window into the subspace dimension."
	id = "s-transmitter"
	req_tech = list("magnets" = 5, "materials" = 5, "bluespace" = 3)
	build_type = PROTOLATHE
	materials = list("$glass" = 100, "$silver" = 10, "$uranium" = 15)
	build_path = /obj/item/weapon/stock_parts/subspace/transmitter