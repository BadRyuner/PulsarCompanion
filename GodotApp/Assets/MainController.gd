extends Control

onready var TABS := get_node("Tabs");
onready var CONNECTION := get_node("Connection");

onready var Address := get_node("Connection/Address");

var client := WebSocketClient.new();

var connected := false;

var reading_packet := false;

func _ready():
	_switch(false)
	client.connect("connection_closed", self, "_ws_closed")
	client.connect("connection_error", self, "_ws_closed")
	client.connect("connection_failed", self, "_ws_closed")
	client.connect("connection_established", self, "_ws_connected")
	client.connect("data_received", self, "_ws_data")
	#set_process(false)

func _process(delta):
	client.poll()

func _switch(c: bool) -> void:
	print("SWITCH: ", c)
	if c == false:
		connected = false
		TABS.hide()
		CONNECTION.show();
	else:
		connected = true
		TABS.show()
		CONNECTION.hide();

func _ws_connected(proto = ""):
	print("Connected")
	send_opcode(1)
	_switch(true)

func _ws_closed(was_clean = false):
	print("Connection closed")
	_switch(false)
	
func _ws_data():
	reading_packet = true;
	var packet := client.get_peer(1).get_packet()
	var buffer := StreamPeerBuffer.new()
	buffer.data_array = packet
	var id := buffer.get_8()
	match id:
		1: update_stats(buffer)
		2: update_eng_status(buffer)
		3: update_science_screen(buffer)
		4: update_logs(buffer)
		#10: fill_map_data(buffer)
		#11: update_map_data(buffer)
		_: print("unknown packed id: ", id)
	reading_packet = false;

#func name(packet: StreamPeerBuffer) -> void:

func _on_FullscreenButton_pressed():
	OS.window_fullscreen = !OS.window_fullscreen

onready var MyShipName = get_node("Tabs/Main/ScreenBase/UP/LSN");
onready var EnemyShipName = get_node("Tabs/Main/ScreenBase/DOWN/LSN");
onready var MyEHP = get_node("Tabs/Main/ScreenBase/UP/EHPBar");
onready var MyWHP = get_node("Tabs/Main/ScreenBase/UP/WHPBar");
onready var MyLHP = get_node("Tabs/Main/ScreenBase/UP/LHPBar");
onready var MySHP = get_node("Tabs/Main/ScreenBase/UP/SHPBar");
onready var MyEHPFire = get_node("Tabs/Main/ScreenBase/UP/EHPBar/FIRE");
onready var MyWHPFire = get_node("Tabs/Main/ScreenBase/UP/WHPBar/FIRE");
onready var MyLHPFire = get_node("Tabs/Main/ScreenBase/UP/LHPBar/FIRE");
onready var MySHPFire = get_node("Tabs/Main/ScreenBase/UP/SHPBar/FIRE");
onready var MyEHPL = get_node("Tabs/Main/ScreenBase/UP/EHP");
onready var MyWHPL = get_node("Tabs/Main/ScreenBase/UP/WHP");
onready var MyLHPL = get_node("Tabs/Main/ScreenBase/UP/LHP");
onready var MySHPL = get_node("Tabs/Main/ScreenBase/UP/SHP");
onready var EnemyEHP = get_node("Tabs/Main/ScreenBase/DOWN/EHPBar");
onready var EnemyWHP = get_node("Tabs/Main/ScreenBase/DOWN/WHPBar");
onready var EnemyLHP = get_node("Tabs/Main/ScreenBase/DOWN/LHPBar");
onready var EnemySHP = get_node("Tabs/Main/ScreenBase/DOWN/SHPBar");
onready var EnemyEHPFire = get_node("Tabs/Main/ScreenBase/DOWN/EHPBar/FIRE");
onready var EnemyWHPFire = get_node("Tabs/Main/ScreenBase/DOWN/WHPBar/FIRE");
onready var EnemyLHPFire = get_node("Tabs/Main/ScreenBase/DOWN/LHPBar/FIRE");
onready var EnemySHPFire = get_node("Tabs/Main/ScreenBase/DOWN/SHPBar/FIRE");
onready var EnemyEHPL = get_node("Tabs/Main/ScreenBase/DOWN/EHP");
onready var EnemyWHPL = get_node("Tabs/Main/ScreenBase/DOWN/WHP");
onready var EnemyLHPL = get_node("Tabs/Main/ScreenBase/DOWN/LHP");
onready var EnemySHPL = get_node("Tabs/Main/ScreenBase/DOWN/SHP");
onready var MyHP = get_node("Tabs/Main/ScreenBase/UP/LHULLVAL");
onready var MySHIELD = get_node("Tabs/Main/ScreenBase/UP/LSHLDVAL");
onready var MyREACTOR = get_node("Tabs/Main/ScreenBase/UP/LREACVAL");
onready var MyQT = get_node("Tabs/Main/ScreenBase/UP/LQTSVAL");
onready var MyO2 = get_node("Tabs/Main/ScreenBase/UP/LO2VAL");
onready var EnemyHP = get_node("Tabs/Main/ScreenBase/DOWN/LHULLVAL");
onready var EnemySHIELD = get_node("Tabs/Main/ScreenBase/DOWN/LSHLDVAL");
onready var EnemyREACTOR = get_node("Tabs/Main/ScreenBase/DOWN/LREACVAL");
onready var EnemyQT = get_node("Tabs/Main/ScreenBase/DOWN/LQTSVAL");
onready var EnemyO2 = get_node("Tabs/Main/ScreenBase/DOWN/LO2VAL");
onready var ScreenDown = get_node("Tabs/Main/ScreenBase/DOWN");
func update_stats(packet: StreamPeerBuffer) -> void:
	var namelen := packet.get_16()
	MyShipName.text = packet.get_utf8_string(namelen)
	
	var syshealth := packet.get_8()
	if syshealth == 120:
		MyEHP.max_value = 20
		MyEHP.value = 0
		MyEHPL.text = "-"
		MyEHPFire.hide()
	else:
		var maxsyshealth := packet.get_8()
		MyEHP.max_value = maxsyshealth
		MyEHP.value = syshealth
		MyEHPL.text = str(syshealth)
		if packet.get_8() == 1:
			MyEHPFire.show()
		else:
			MyEHPFire.hide()
	
	syshealth = packet.get_8()
	if syshealth == 120:
		MyWHP.max_value = 20
		MyWHP.value = 0
		MyWHPL.text = "-"
		MyWHPFire.hide()
	else:
		var maxsyshealth := packet.get_8()
		MyWHP.max_value = maxsyshealth
		MyWHP.value = syshealth
		MyWHPL.text = str(syshealth)
		if packet.get_8() == 1:
			MyWHPFire.show()
		else:
			MyWHPFire.hide()
	
	syshealth = packet.get_8()
	if syshealth == 120:
		MyLHP.max_value = 20
		MyLHP.value = 0
		MyLHPL.text = "-"
		MyLHPFire.hide()
	else:
		var maxsyshealth := packet.get_8()
		MyLHP.max_value = maxsyshealth
		MyLHP.value = syshealth
		MyLHPL.text = str(syshealth)
		if packet.get_8() == 1:
			MyLHPFire.show()
		else:
			MyLHPFire.hide()
	
	syshealth = packet.get_8()
	if syshealth == 120:
		MySHP.max_value = 20
		MySHP.value = 0
		MySHPL.text = "-"
		MySHPFire.hide()
	else:
		var maxsyshealth := packet.get_8()
		MySHP.max_value = maxsyshealth
		MySHP.value = syshealth
		MySHPL.text = str(syshealth)
		if packet.get_8() == 1:
			MySHPFire.show()
		else:
			MySHPFire.hide()
	
	var length := packet.get_u16()
	MySHIELD.text = packet.get_utf8_string(length)
	length = packet.get_u16()
	MyHP.text = packet.get_utf8_string(length)
	length = packet.get_u16()
	MyREACTOR.text = packet.get_utf8_string(length)
	if MyREACTOR.text.length() == 2: # ok
		MyREACTOR.add_color_override("font_color", Color(0,1,0))
	else:
		MyREACTOR.add_color_override("font_color", Color(1,0,0))
	length = packet.get_u16()
	MyQT.text = packet.get_utf8_string(length)
	if MyQT.text.length() == 6: # online - green
		MyQT.add_color_override("font_color", Color(0,1,0))
	else: # offline - red
		MyQT.add_color_override("font_color", Color(1,0,0))
	length = packet.get_u16()
	MyO2.text = packet.get_utf8_string(length)
	if MyO2.text[0] == '-':
		MyO2.add_color_override("font_color", Color(1,0,0))
	else:
		MyO2.add_color_override("font_color", Color(0,1,0))
	
	var enemy = packet.get_8();
	
	if enemy == 1:
		ScreenDown.show()
		namelen = packet.get_16()
		EnemyShipName.text = packet.get_utf8_string(namelen)
		syshealth = packet.get_8()
		if syshealth == 120:
			EnemyEHP.max_value = 20
			EnemyEHP.value = 0
			EnemyEHPL.text = "-"
			EnemyEHPFire.hide()
		else:
			var maxsyshealth := packet.get_8()
			EnemyEHP.max_value = maxsyshealth
			EnemyEHP.value = syshealth
			EnemyEHPL.text = str(syshealth)
			if packet.get_8() == 1:
				EnemyEHPFire.show()
			else:
				EnemyEHPFire.hide()
		
		syshealth = packet.get_8()
		if syshealth == 120:
			EnemyWHP.max_value = 20
			EnemyWHP.value = 0
			EnemyWHPL.text = "-"
			EnemyWHPFire.hide()
		else:
			var maxsyshealth := packet.get_8()
			EnemyWHP.max_value = maxsyshealth
			EnemyWHP.value = syshealth
			EnemyWHPL.text = str(syshealth)
			if packet.get_8() == 1:
				EnemyWHPFire.show()
			else:
				EnemyWHPFire.hide()
		
		syshealth = packet.get_8()
		if syshealth == 120:
			EnemyLHP.max_value = 20
			EnemyLHP.value = 0
			EnemyLHPL.text = "-"
			EnemyLHPFire.hide()
		else:
			var maxsyshealth := packet.get_8()
			EnemyLHP.max_value = maxsyshealth
			EnemyLHP.value = syshealth
			EnemyLHPL.text = str(syshealth)
			if packet.get_8() == 1:
				EnemyLHPFire.show()
			else:
				EnemyLHPFire.hide()
		
		syshealth = packet.get_8()
		if syshealth == 120:
			EnemySHP.max_value = 20
			EnemySHP.value = 0
			EnemySHPL.text = "-"
			EnemySHPFire.hide()
		else:
			var maxsyshealth := packet.get_8()
			EnemySHP.max_value = maxsyshealth
			EnemySHP.value = syshealth
			EnemySHPL.text = str(syshealth)
			if packet.get_8() == 1:
				EnemySHPFire.show()
			else:
				EnemySHPFire.hide()
		
		length = packet.get_u16()
		EnemySHIELD.text = packet.get_utf8_string(length)
		length = packet.get_u16()
		EnemyHP.text = packet.get_utf8_string(length)
		length = packet.get_u16()
		EnemyREACTOR.text = packet.get_utf8_string(length)
		if EnemyREACTOR.text.length() == 2: # ok
			EnemyREACTOR.add_color_override("font_color", Color(0,1,0))
		else:
			EnemyREACTOR.add_color_override("font_color", Color(1,0,0))
		length = packet.get_u16()
		EnemyQT.text = packet.get_utf8_string(length)
		if EnemyQT.text.length() == 6: # online - green
			EnemyQT.add_color_override("font_color", Color(0,1,0))
		else: # offline - red
			EnemyQT.add_color_override("font_color", Color(1,0,0))
		length = packet.get_u16()
		EnemyO2.text = packet.get_utf8_string(length)
		if EnemyO2.text[0] == '-':
			EnemyO2.add_color_override("font_color", Color(1,0,0))
		else:
			EnemyO2.add_color_override("font_color", Color(0,1,0))
	else:
		ScreenDown.hide()
	
	pass

onready var ReacName = get_node("Tabs/Engineering/ScreenBase/REACNAME");
onready var TempBar = $Tabs/Engineering/ScreenBase/TEMPBar
onready var TempBarCur = $Tabs/Engineering/ScreenBase/TEMPBar/Current
onready var TempBarMax = $Tabs/Engineering/ScreenBase/TEMPBar/Max
onready var Stability = $Tabs/Engineering/ScreenBase/STAB
onready var OC = $Tabs/Engineering/ScreenBase/OC
onready var EngBar = $Tabs/Engineering/ScreenBase/EngBar
onready var EngBarSlider = $Tabs/Engineering/ScreenBase/EngBar/Slider
onready var SciBar = $Tabs/Engineering/ScreenBase/SciBar
onready var SciBarSlider = $Tabs/Engineering/ScreenBase/SciBar/Slider
onready var ShiBar = $Tabs/Engineering/ScreenBase/ShiBar
onready var ShiBarSlider = $Tabs/Engineering/ScreenBase/ShiBar/Slider
onready var WeaBar = $Tabs/Engineering/ScreenBase/WeaBar
onready var WeaBarSlider = $Tabs/Engineering/ScreenBase/WeaBar/Slider
onready var TotBar = $Tabs/Engineering/ScreenBase/TotBar
onready var TotBarSlider = $Tabs/Engineering/ScreenBase/TotBar/Slider
func update_eng_status(packet: StreamPeerBuffer) -> void:
	var length := packet.get_16()
	ReacName.text = packet.get_utf8_string(length)
	TempBar.max_value = packet.get_float()
	TempBar.value = packet.get_float()
	TempBarCur.text = str(floor(TempBar.value))
	TempBarMax.text = str(floor(TempBar.max_value))
	Stability.text = str(packet.get_8())
	if packet.get_8() == 1:
		OC.pressed = true
	else:
		OC.pressed = false
	
	EngBar.value = packet.get_float()
	EngBarSlider.value = packet.get_float()
	SciBar.value = packet.get_float()
	SciBarSlider.value = packet.get_float()
	ShiBar.value = packet.get_float()
	ShiBarSlider.value = packet.get_float()
	WeaBar.value = packet.get_float()
	WeaBarSlider.value = packet.get_float()
	TotBar.value = packet.get_float()
	TotBarSlider.value = packet.get_float()

func update_science_screen(packet: StreamPeerBuffer) -> void:
	pass

onready var LogsLeft = $Tabs/Logs/ScrollContainer/HBoxContainer/Left
onready var LogsRight = $Tabs/Logs/ScrollContainer/HBoxContainer/Right
func update_logs(packet: StreamPeerBuffer) -> void:
	var length := packet.get_32()
	LogsLeft.bbcode_text = packet.get_utf8_string(length)
	length = packet.get_32()
	LogsRight.bbcode_text = packet.get_utf8_string(length)


#onready var SectorPrefab := preload("res://Assets/Prefabs/Sector.tscn");
#onready var SectorsParent := get_node("Tabs/Map/Base");
#var SectorsArray := Array()

#func fill_map_data(packet: StreamPeerBuffer) -> void:
#	# packet structure
#	# i32 count | sectors*
#	#
#	# where sector is 
#	# { f32 x, f32 y, i32 id, i8 type, i8 faction, name { i16 len, u8* } }
#	SectorsArray.clear()
#	for c in SectorsParent.get_children():
#		SectorsParent.remove_child(c)
#		c.queue_free()
#	
#	#SectorsParent.size
#	
#	var count := packet.get_32() - 1
#	while count > 0:
#		var sector := SectorPrefab.instance() as SectorType
#		SectorsParent.add_child(sector)
#		
#		var x := packet.get_float()
#		var y := packet.get_float()
#		sector.update_pos(x, y)
#		sector.update_id(packet.get_32())
#		sector.update_type(packet.get_8())
#		sector.update_faction(packet.get_8())
#		
#		var namelength := packet.get_16()
#		if namelength > 0:
#			sector.update_name(packet.get_utf8_string(namelength))
#		else:
#			sector.update_name(str(sector.id))
#		SectorsArray.append(sector)
#		count = count - 1;

#func update_map_data(packet: StreamPeerBuffer) -> void:
#	# packet: i16 id, i8 type, i8 faction
#	var id = packet.get_16()
#	for i in SectorsArray:
#		if i.id == id:
#			i.update_type(packet.get_8())
#			i.update_faction(packet.get_8())
#			return;

func send_opcode(data: int) -> void:
	client.get_peer(1).put_packet([data])

func send_opcode_float(op: int, data: float) -> void:
	var buf := StreamPeerBuffer.new()
	buf.data_array = PoolByteArray()
	buf.put_8(op)
	buf.put_float(data)
	client.get_peer(1).put_packet(buf.data_array)

func _on_ConnectButton_button_down(): # connect to websocket
	var status = client.get_connection_status()
	print_debug("Current status: ", status)
	var err = client.connect_to_url(Address.text)
	if err != OK:
		print_debug(err)

func _on_tab_changed(tab: int) -> void:
	if tab == 0:
		print_debug("Main! Send 1")
		send_opcode(1)
	#elif tab == 1:
	#	if SectorsArray.empty():
	#		print_debug("Map! Send 11")
	#		send_opcode(10)
	#	else:
	#		print_debug("Map! Send 10")
	#		send_opcode(11)
	elif tab == 1:
		print_debug("Engineering! send 2")
		send_opcode(2)
	elif tab == 2:
		print_debug("Logs! send 4")
		send_opcode(4)


func _on_OC_toggled(button_pressed):
	if !reading_packet:
		send_opcode(101)

func _on_EngSlider_value_changed(value):
	if !reading_packet:
		send_opcode_float(102, value)

func _on_SciSlider_value_changed(value):
	if !reading_packet:
		send_opcode_float(103, value)

func _on_ShiSlider_value_changed(value):
	if !reading_packet:
		send_opcode_float(104, value)

func _on_WeaSlider_value_changed(value):
	if !reading_packet:
		send_opcode_float(105, value)

func _on_TotSlider_value_changed(value):
	if !reading_packet:
		send_opcode_float(106, value)
