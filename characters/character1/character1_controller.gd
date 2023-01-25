extends KinematicBody

onready var character = $character1
onready var anim_tree = $character1/AnimationTree
onready var state_machine = anim_tree["parameters/playback"]

signal state

var normalAttack_counter = 0
var button_pressed = "non"
var g = -4
var velocity = Vector3.ZERO
var direction = Vector3.ZERO
var minTimeBetweenTicks = 1/60.0
var timer = 0
var currentTick = 0

func state():
	return state_machine.get_current_node()

func travel(state):
	state_machine.travel(state)
	
func animation_time():
	return state_machine.get_current_play_position()
	
func _process(delta):
	timer += delta
	
	while timer >= minTimeBetweenTicks:
		timer -= minTimeBetweenTicks
		HandleTick()
		currentTick += 1
	emit_signal("state", state())
	
func HandleTick():
	var clientInput = {}
	clientInput["D"] = direction
	clientInput["R"] = character.rotation.y
	clientInput["S"] = state()
	clientInput["B"] = button_pressed
	clientInput["AT"] = animation_time()
	clientInput["C"] = normalAttack_counter
	ProcessInput(clientInput)
	button_pressed = "non"
	
func calc_velocity(dir, speed):
	var vel = Vector3.ZERO
	var d = Vector2(dir.x, dir.z).normalized()
	var collision = move_and_collide(Vector3(d.x * speed, -1, d.y * speed) * minTimeBetweenTicks,
	true, true, true)
	if collision and collision.normal.y > 0.5:
		if collision.normal.y >= 1:
			vel = Vector3(d.x*speed, 0, d.y*speed)
		elif collision.normal.y > 0.9:
			vel = Vector3(d.x*speed, (1-collision.normal.y)*50, d.y*speed)
	else:
		vel = Vector3(d.x*speed, g, d.y*speed)
	return vel
	
func ProcessInput(input):
	velocity = Vector3.ZERO
	
	if input["S"] == "dodge":
		normalAttack_counter = 0
		if input["AT"] >0.1:
			velocity = calc_velocity(character.transform.basis.z, 7)
	if input["S"] == "s1":
		normalAttack_counter = 0
		pass
	if input["S"] == "s2":
		normalAttack_counter = 0
		if input["S"] == "s2":
			if input["AT"] <1.8 and input["AT"] > 0.1:
				velocity = calc_velocity(character.transform.basis.z, 4)
			else:
				pass
	elif input["B"] != "non":
		if input["B"] == "normal":
			if input["S"] == "normal2" or input["C"] > 2:
				travel("normal3")
				normalAttack_counter = 0
			elif input["S"] == "normal1" or input["C"] > 1:
				travel("normal2")
			else:
				travel("normal1")
		if input["B"] == "dodge":
			travel("dodge")
		if input["B"] == "s1":
			travel("s1")
		if input["B"] == "s2":
			travel("s2")
				
	elif input["S"] == "normal1":
		if input["AT"] > 0.1:
			velocity = calc_velocity(character.transform.basis.z, 8)			
	elif input["S"] == "normal2":
		velocity = calc_velocity(character.transform.basis.z, 10)		
	elif input["S"] == "normal3":
		velocity = calc_velocity(character.transform.basis.z, 2)		
	if(input["S"] == "idle"):
		normalAttack_counter = 0
		if(input["D"] == Vector3.ZERO):
			calc_velocity(input["D"], 0)
		else:
			travel("run")
	elif	input["S"]	== "run":
		normalAttack_counter = 0
		if(input["D"] == Vector3.ZERO):
			travel("idle")
		else:
			character.rotation.y = lerp_angle(input["R"], 
			atan2(input["D"].x, input["D"].z), minTimeBetweenTicks*10)
			velocity = calc_velocity(input["D"], 12)
	move_and_collide(velocity * minTimeBetweenTicks)
	
func _on_Controls_direction_vector(dir):
	direction = dir

func _on_Controls_dodge():
	button_pressed = "dodge"


func _on_Controls_normal_attack():
	button_pressed = "normal"
	normalAttack_counter += 1


func _on_Controls_s1():
	button_pressed = "s1"


func _on_Controls_s2():
	button_pressed = "s2"	
