extends RefCounted

static func write(path: String,payload: Dictionary) -> Error:
	var body = JSON.stringify(payload)
	var temp = path+".tmp"
	var backup = path+".bak"
	var f = FileAccess.open(temp,FileAccess.WRITE)
	if f == null: return FileAccess.get_open_error()
	f.store_string(JSON.stringify({"format":"zom-save-1","body":body,"sha256":body.sha256_text()}))
	f.flush()
	f.close()
	if read(temp).is_empty(): return ERR_FILE_CORRUPT
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup):
			var err = DirAccess.remove_absolute(backup)
			if err != OK: return err
		var err = DirAccess.rename_absolute(path,backup)
		if err != OK: return err
	var err = DirAccess.rename_absolute(temp,path)
	if err != OK and FileAccess.file_exists(backup): DirAccess.rename_absolute(backup,path)
	return err

static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var f = FileAccess.open(path,FileAccess.READ)
	if f == null or f.get_length() > 4000000: return {}
	var parser = JSON.new()
	if parser.parse(f.get_as_text()) != OK: return {}
	var parsed = parser.data
	if not parsed is Dictionary or parsed.get("format","") != "zom-save-1": return {}
	var body = parsed.get("body",null)
	if not body is String or body.sha256_text() != parsed.get("sha256",""): return {}
	if parser.parse(body) != OK: return {}
	var payload = parser.data
	return payload if payload is Dictionary else {}
