extends Node

signal changed
signal rejected(message: String)
const Rules = preload("res://core/rules.gd")
const Storage = preload("res://core/storage.gd")
var rules = Rules.new()
var view: Dictionary = {}
var role = "host"
var mode = "offline"
var invitation = ""
var reconnect_secret = ""
var guest_secret = ""
var peers = {}
var serial = 0
var address = "127.0.0.1"
var port = 27170
var room_key = ""
const SAVE = "user://m0-mission.save"
var save_path = SAVE

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_peer_left)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(func(): rejected.emit("Não foi possível conectar. Confira endereço, porta e anfitrião."))
	multiplayer.server_disconnected.connect(_server_left)
	rules.start()
	refresh()

func secret() -> String:
	return Crypto.new().generate_random_bytes(24).hex_encode()

func host(code: String, number: int = 27170) -> Error:
	if code.length() < 6: return ERR_INVALID_PARAMETER
	if mode != "offline": return ERR_ALREADY_IN_USE
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(number,2)
	if err != OK: return err
	multiplayer.multiplayer_peer = peer
	mode = "host"
	role = "host"
	port = number
	invitation = code
	guest_secret = ""
	peers.clear()
	rules.start(0,true)
	rules.pause("Aguardando o amigo convidado.")
	refresh()
	return OK

func join(ip: String,code: String,number: int = 27170) -> Error:
	if mode == "host": return ERR_ALREADY_IN_USE
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip,number)
	if err != OK: return err
	address = ip
	port = number
	invitation = code
	room_key = (ip+":"+str(number)+":"+code).sha256_text()
	var credentials = ConfigFile.new()
	if credentials.load("user://private-rooms.cfg") == OK:
		reconnect_secret = str(credentials.get_value("rooms",room_key,""))
	role = "guest"
	mode = "client"
	multiplayer.multiplayer_peer = peer
	return OK

func disconnect_client() -> void:
	if mode != "client": return
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_server_left()

func _connected() -> void:
	_hello.rpc_id(1,invitation,reconnect_secret)

@rpc("any_peer","call_remote","reliable")
func _hello(code: String,credential: String) -> void:
	if mode != "host": return
	var sender = multiplayer.get_remote_sender_id()
	if code != invitation or peers.size() >= 1 or (not guest_secret.is_empty() and credential != guest_secret):
		_reject.rpc_id(sender,"Convite inválido, sala ocupada ou credencial de retorno diferente.")
		return
	if guest_secret.is_empty(): guest_secret = secret()
	peers[sender] = "guest"
	_welcome.rpc_id(sender,guest_secret)
	rules.resume()
	refresh()

@rpc("authority","call_remote","reliable")
func _welcome(credential: String) -> void:
	if mode == "client":
		reconnect_secret = credential
		var credentials = ConfigFile.new()
		credentials.load("user://private-rooms.cfg")
		credentials.set_value("rooms",room_key,credential)
		credentials.save("user://private-rooms.cfg")

@rpc("authority","call_remote","reliable")
func _reject(message: String) -> void:
	rejected.emit(message)

@rpc("authority","call_remote","reliable")
func _snapshot(data: Dictionary) -> void:
	if mode != "client": return
	view = data
	changed.emit()

@rpc("any_peer","call_remote","reliable")
func _command(cmd: Dictionary) -> void:
	if mode != "host": return
	var sender = multiplayer.get_remote_sender_id()
	if not peers.has(sender): return
	if JSON.stringify(cmd).length() > 2048: return
	var result = rules.apply(cmd,peers[sender])
	if not result.ok: _reject.rpc_id(sender,result.error)
	else: refresh()

func submit(cmd: Dictionary) -> Dictionary:
	serial += 1
	cmd["request"] = (reconnect_secret if role == "guest" else "local")+":"+str(Time.get_ticks_usec())+":"+str(serial)
	cmd["revision"] = view.get("revision",0)
	if mode == "client":
		if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			rejected.emit("Conexão interrompida. Reconecte para continuar.")
			return {"ok":false}
		_command.rpc_id(1,cmd)
		return {"ok":true,"sent":true}
	var result = rules.apply(cmd,role)
	if result.ok: refresh()
	else: rejected.emit(result.error)
	return result

func refresh() -> void:
	view = rules.public_state()
	changed.emit()
	if mode == "host":
		for id in peers: _snapshot.rpc_id(int(id),view)

func _peer_left(id: int) -> void:
	if mode != "host" or not peers.has(id): return
	peers.erase(id)
	rules.pause("O amigo desconectou. Aguardando seu retorno; peças preservadas.")
	save_game()
	refresh()

func _server_left() -> void:
	if mode != "client": return
	if not view.is_empty():
		view.paused = true
		view.pause_reason = "Conexão com o anfitrião perdida. Reconecte para retomar."
	changed.emit()

func save_game(path: String = "") -> Error:
	if path.is_empty(): path = save_path
	if mode == "client": return ERR_UNAUTHORIZED
	var payload = rules.save_payload()
	payload["guest_secret"] = guest_secret
	var err = Storage.write(path,payload)
	if err == OK: rejected.emit("Missão salva. A gravação inclui turno, cartas e decisões pendentes.")
	else: rejected.emit("Não foi possível salvar (%d)." % err)
	return err

func load_game(path: String = "") -> bool:
	if path.is_empty(): path = save_path
	if mode == "client": return false
	var payload = Storage.read(path)
	if payload.is_empty(): payload = Storage.read(path+".bak")
	var trial = Rules.new()
	trial.start(1)
	if not trial.restore(payload):
		rejected.emit("Save incompatível ou inválido; estado atual preservado.")
		return false
	# Preserve participants; restoring an online mission never grants their pieces to host.
	if trial.s.players.size() > 1 and mode != "host":
		rejected.emit("Este save é online. Crie uma sala privada antes de carregá-lo.")
		return false
	if mode == "host" and trial.s.players.size() == 1:
		rejected.emit("Este save é solo. Abra-o antes de criar a sala online.")
		return false
	rules = trial
	guest_secret = str(payload.get("guest_secret",""))
	if mode == "host":
		# Restoring changes the rejoin context: disconnect existing peer and require re-entry.
		for id in peers.keys(): multiplayer.multiplayer_peer.disconnect_peer(int(id))
		peers.clear()
		rules.pause("Missão restaurada. Aguardando o mesmo convidado.")
	refresh()
	rejected.emit("Missão restaurada.")
	return true
