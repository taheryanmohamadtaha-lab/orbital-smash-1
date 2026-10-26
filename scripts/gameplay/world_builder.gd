class_name WorldBuilder
extends RefCounted
## Procedural 3D environments for the five worlds (no external model files needed).

const THEMES := {
	1: {"top": "#3d9bff", "hor": "#c9ecff", "amb": "#e6f2ff", "sun": "#fff1cf", "energy": 1.15, "plat_top": "#6fd35c", "plat_side": "#8d5a2b", "mover": "#ff9f1c"},
	2: {"top": "#120a3a", "hor": "#5a1d8f", "amb": "#7a6af0", "sun": "#b9a6ff", "energy": 0.95, "plat_top": "#1c1b3a", "plat_side": "#0e0d24", "mover": "#ff2fd0"},
	3: {"top": "#e8923c", "hor": "#ffe0a3", "amb": "#ffe6c4", "sun": "#fff0cc", "energy": 1.2, "plat_top": "#c9b27a", "plat_side": "#8a7550", "mover": "#ffd23f"},
	4: {"top": "#8fd0ff", "hor": "#f2fbff", "amb": "#dff3ff", "sun": "#ffffff", "energy": 1.1, "plat_top": "#cfefff", "plat_side": "#7fc3e8", "mover": "#2fd5ff"},
	5: {"top": "#04030f", "hor": "#1b1450", "amb": "#6a64c0", "sun": "#c7c2ff", "energy": 0.95, "plat_top": "#2a2d55", "plat_side": "#171a38", "mover": "#4dffd2"},
}

static func mover_color(world: int) -> Color:
	return Color(str((THEMES[world] as Dictionary)["mover"]))

# ------------------------------------------------------------ helpers
static func _m(color: Color, emission: float = 0.0, alpha: float = 1.0, metallic: float = 0.0, rough: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.metallic = metallic
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func _unshaded(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

static func _box(sz: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = sz
	return b

static func _cyl(top_r: float, bot_r: float, h: float, seg: int = 14) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bot_r
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c

static func _sph(r: float, seg: int = 16) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = maxi(3, seg / 2)
	return s

static func _plane(sx: float, sz: float) -> PlaneMesh:
	var p := PlaneMesh.new()
	p.size = Vector2(sx, sz)
	return p

static func _torus(inner: float, outer: float, rings: int = 40, segs: int = 6) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = rings
	t.ring_segments = segs
	return t

static func _add(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

# ------------------------------------------------------------ build
static func build(world: int, quality: int) -> Node3D:
	var root := Node3D.new()
	root.name = "WorldDecor"
	var th: Dictionary = THEMES[world]
	var we := WorldEnvironment.new()
	var env := Environment.new()
	if world == 5:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(str(th["top"]))
	else:
		var sky := Sky.new()
		var sm := ProceduralSkyMaterial.new()
		sm.sky_top_color = Color(str(th["top"]))
		sm.sky_horizon_color = Color(str(th["hor"]))
		sm.ground_horizon_color = Color(str(th["hor"]))
		sm.ground_bottom_color = Color(str(th["hor"])).darkened(0.3)
		sky.sky_material = sm
		env.background_mode = Environment.BG_SKY
		env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(str(th["amb"]))
	env.ambient_light_energy = 0.8
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(str(th["sun"]))
	sun.light_energy = float(th["energy"])
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.shadow_enabled = quality >= 1
	sun.directional_shadow_max_distance = 45.0
	root.add_child(sun)
	match world:
		1:
			_w1(root, quality)
		2:
			_w2(root, quality)
		3:
			_w3(root, quality)
		4:
			_w4(root, quality)
		_:
			_w5(root, quality)
	return root

static func make_platform(world: int, size: Vector3, center: Vector3, quality: int) -> StaticBody3D:
	var th: Dictionary = THEMES[world]
	var body := StaticBody3D.new()
	body.position = center
	body.collision_layer = 2
	body.collision_mask = 0
	var pm := PhysicsMaterial.new()
	pm.friction = 0.9
	pm.bounce = 0.0
	body.physics_material_override = pm
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	var top_col := Color(str(th["plat_top"]))
	var side_col := Color(str(th["plat_side"]))
	var side_mat := _m(side_col, 0.0, 1.0, 0.3 if world >= 2 else 0.0, 0.6)
	if world == 4:
		side_mat = _m(side_col, 0.15, 0.85, 0.2, 0.2)
	_add(body, _box(Vector3(size.x, size.y * 0.88, size.z)), side_mat, Vector3(0, -size.y * 0.06, 0))
	var top_mat := _m(top_col, 0.0, 0.9 if world == 4 else 1.0, 0.0, 0.7)
	_add(body, _box(Vector3(size.x, 0.12, size.z)), top_mat, Vector3(0, size.y * 0.44, 0))
	# glowing / decorative edge strips
	var edge_col := Color.WHITE
	var edge_em := 0.0
	match world:
		2:
			edge_col = Color("#2fd5ff")
			edge_em = 2.0
		3:
			edge_col = Color("#ffd23f")
			edge_em = 0.6
		4:
			edge_col = Color("#bff0ff")
			edge_em = 1.0
		5:
			edge_col = Color("#4dffd2")
			edge_em = 2.0
	if edge_em > 0.0:
		var y := size.y * 0.5 + 0.02
		var em := _m(edge_col, edge_em)
		_add(body, _box(Vector3(size.x, 0.06, 0.18)), em, Vector3(0, y, size.z * 0.5 - 0.09))
		_add(body, _box(Vector3(size.x, 0.06, 0.18)), em, Vector3(0, y, -size.z * 0.5 + 0.09))
		_add(body, _box(Vector3(0.18, 0.06, size.z)), em, Vector3(size.x * 0.5 - 0.09, y, 0))
		_add(body, _box(Vector3(0.18, 0.06, size.z)), em, Vector3(-size.x * 0.5 + 0.09, y, 0))
	if world == 1 and quality >= 1:
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var cols := [Color("#ff6ec7"), Color("#ffe14a"), Color("#ffffff"), Color("#ff8a3d")]
		for i in 18:
			var c: Color = cols[i % cols.size()]
			var fx := rng.randf_range(-size.x * 0.5 + 0.3, size.x * 0.5 - 0.3)
			var fz := rng.randf_range(-size.z * 0.5 + 0.3, size.z * 0.5 - 0.3)
			_add(body, _sph(0.11, 6), _m(c, 0.3), Vector3(fx, size.y * 0.5 + 0.1, fz))
	return body

# ------------------------------------------------------------ world 1: Rainbow Island
static func _w1(root: Node3D, q: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	_add(root, _plane(500, 500), _m(Color("#2fb9d8"), 0.0, 0.85, 0.2, 0.2), Vector3(0, -10, -60))
	var isl := [Vector3(-16, -2, -34), Vector3(18, 1, -44), Vector3(-26, 4, -58), Vector3(28, -3, -30), Vector3(6, 6, -70), Vector3(-8, -6, -50)]
	for p in isl:
		var pos: Vector3 = p
		var r := rng.randf_range(4.0, 7.0)
		_add(root, _cyl(r, r, 1.0, 20), _m(Color("#72d85f")), pos)
		_add(root, _cyl(r, 0.1, r * 1.3, 16), _m(Color("#8d5a2b")), pos + Vector3(0, -0.5 - r * 0.65, 0))
		if q >= 1:
			for i in 2:
				var tp := pos + Vector3(rng.randf_range(-r * 0.6, r * 0.6), 0.5, rng.randf_range(-r * 0.6, r * 0.6))
				_add(root, _cyl(0.2, 0.25, 1.4, 6), _m(Color("#7a4a22")), tp + Vector3(0, 0.7, 0))
				_add(root, _cyl(0.0, 1.1, 2.2, 8), _m(Color("#2fa84f")), tp + Vector3(0, 2.2, 0))
	var n_clouds := 7 if q >= 1 else 3
	for i in n_clouds:
		var c := Vector3(rng.randf_range(-45, 45), rng.randf_range(8, 22), rng.randf_range(-80, -40))
		for k in 4:
			var s := rng.randf_range(2.0, 3.5)
			var mi := _add(root, _sph(s, 10), _m(Color.WHITE, 0.3, 0.95), c + Vector3(k * 2.4 - 3.6, rng.randf_range(-0.5, 0.5), 0))
			mi.scale = Vector3(1.0, 0.6, 1.0)
	var rc := [Color("#ff3b3b"), Color("#ff9f1c"), Color("#ffe14a"), Color("#4dff88"), Color("#4da6ff"), Color("#6a5cff"), Color("#b46bff")]
	for i in rc.size():
		var col: Color = rc[i]
		_add(root, _torus(34.0 + i * 1.0, 35.0 + i * 1.0, 48, 6), _m(col, 0.8), Vector3(0, -6, -90), Vector3(deg_to_rad(90.0), 0, 0))

# ------------------------------------------------------------ world 2: Neon City
static func _w2(root: Node3D, q: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 22
	_add(root, _plane(500, 500), _m(Color("#0b0824")), Vector3(0, -14, -60))
	var grid := _m(Color("#ff2fd0"), 1.5)
	for i in range(-10, 11):
		_add(root, _box(Vector3(0.1, 0.05, 200)), grid, Vector3(i * 6, -13.9, -60))
	for i in 20:
		_add(root, _box(Vector3(200, 0.05, 0.1)), grid, Vector3(0, -13.9, -i * 8.0))
	var n := 26 if q >= 1 else 14
	var neon_cols := [Color("#2fd5ff"), Color("#ff2fd0"), Color("#ffe14a")]
	for i in n:
		var side := -1.0 if i % 2 == 0 else 1.0
		var h := rng.randf_range(14.0, 46.0)
		var w := rng.randf_range(4.0, 8.0)
		var x := side * rng.randf_range(14.0, 42.0)
		var z := -rng.randf_range(16.0, 90.0)
		_add(root, _box(Vector3(w, h, w)), _m(Color("#1a1448"), 0.0, 1.0, 0.4, 0.4), Vector3(x, h * 0.5 - 14.0, z))
		var neon: Color = neon_cols[i % 3]
		for k in 3:
			_add(root, _box(Vector3(w * 0.9, 0.25, 0.1)), _m(neon, 2.0), Vector3(x, rng.randf_range(0.0, h) - 14.0, z + w * 0.5 + 0.06))
	for i in 4:
		var col: Color = neon_cols[i % 2]
		_add(root, _torus(5.0, 5.5, 32, 6), _m(col, 2.2), Vector3((i - 1.5) * 16.0, 10.0 + (i % 2) * 6.0, -45.0 - i * 8.0), Vector3(deg_to_rad(90.0), 0, 0))

# ------------------------------------------------------------ world 3: Ancient Temple
static func _w3(root: Node3D, q: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	_add(root, _plane(500, 500), _m(Color("#d9b46a")), Vector3(0, -10, -60))
	var mcols := [Color("#8a6a4a"), Color("#a07850"), Color("#7a6a60")]
	for i in 7:
		var h := rng.randf_range(30.0, 55.0)
		var r := rng.randf_range(18.0, 30.0)
		var mc: Color = mcols[i % 3]
		_add(root, _cyl(0.0, r, h, 8), _m(mc), Vector3(-90.0 + i * 30.0, h * 0.5 - 10.0, rng.randf_range(-130.0, -90.0)))
	var stone := _m(Color("#d8c9a0"))
	var ncol := 12 if q >= 1 else 6
	for i in ncol:
		var side := -1.0 if i % 2 == 0 else 1.0
		var h := rng.randf_range(8.0, 18.0)
		var x := side * rng.randf_range(16.0, 32.0)
		var z := -rng.randf_range(20.0, 70.0)
		_add(root, _cyl(0.8, 0.95, h, 12), stone, Vector3(x, h * 0.5 - 10.0, z))
		_add(root, _box(Vector3(2.4, 0.7, 2.4)), stone, Vector3(x, h - 10.0 + 0.35, z))
		_add(root, _box(Vector3(2.2, 0.6, 2.2)), stone, Vector3(x, -9.7, z))
	for sx in [-24.0, 24.0]:
		var x: float = sx
		var base := Vector3(x, -10.0, -48.0)
		_add(root, _box(Vector3(7, 2, 7)), stone, base + Vector3(0, 1, 0))
		_add(root, _box(Vector3(3.2, 8, 3.2)), _m(Color("#bfae82")), base + Vector3(0, 6, 0))
		_add(root, _sph(1.7, 12), _m(Color("#bfae82")), base + Vector3(0, 11.5, 0))
		_add(root, _box(Vector3(3.6, 0.5, 3.6)), _m(Color("#ffd23f"), 0.6), base + Vector3(0, 2.3, 0))

# ------------------------------------------------------------ world 4: Ice Land
static func _w4(root: Node3D, q: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	_add(root, _plane(500, 500), _m(Color("#e9f6ff"), 0.0, 1.0, 0.1, 0.3), Vector3(0, -10, -60))
	for i in 8:
		var h := rng.randf_range(26.0, 50.0)
		var r := rng.randf_range(16.0, 28.0)
		_add(root, _cyl(0.0, r, h, 8), _m(Color("#f4fbff")), Vector3(-100.0 + i * 28.0, h * 0.5 - 10.0, rng.randf_range(-130.0, -85.0)))
		_add(root, _cyl(0.0, r * 0.45, h * 0.35, 8), _m(Color("#9fd8ff")), Vector3(-100.0 + i * 28.0, h * 0.82 - 10.0, rng.randf_range(-84.0, -80.0)))
	var ncr := 14 if q >= 1 else 6
	for i in ncr:
		var side := -1.0 if i % 2 == 0 else 1.0
		var h := rng.randf_range(5.0, 14.0)
		var r := rng.randf_range(1.0, 2.2)
		var x := side * rng.randf_range(10.0, 35.0)
		var z := -rng.randf_range(18.0, 75.0)
		_add(root, _cyl(0.0, r, h, 6), _m(Color("#7fe0ff"), 0.35, 0.7, 0.1, 0.1),
			Vector3(x, h * 0.5 - 10.0, z), Vector3(0, 0, rng.randf_range(-0.3, 0.3)))
	if q >= 1:
		var sn := CPUParticles3D.new()
		sn.amount = 120 if q == 1 else 260
		sn.lifetime = 7.0
		sn.preprocess = 7.0
		sn.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		sn.emission_box_extents = Vector3(30, 0.5, 30)
		sn.direction = Vector3(0.2, -1, 0)
		sn.spread = 15.0
		sn.initial_velocity_min = 1.5
		sn.initial_velocity_max = 3.0
		sn.gravity = Vector3(0, -0.5, 0)
		sn.scale_amount_min = 0.12
		sn.scale_amount_max = 0.25
		var flake := _sph(0.5, 6)
		flake.material = _unshaded(Color.WHITE)
		sn.mesh = flake
		sn.position = Vector3(0, 22, -20)
		root.add_child(sn)
		sn.emitting = true

# ------------------------------------------------------------ world 5: Cosmic Space
static func _w5(root: Node3D, q: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _sph(0.25, 6)
	mm.instance_count = 160 if q >= 1 else 80
	for i in mm.instance_count:
		var dir := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.3, 1.0), rng.randf_range(-1.0, -0.1)).normalized()
		var s := rng.randf_range(0.5, 1.6)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), dir * rng.randf_range(100.0, 150.0)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _unshaded(Color.WHITE)
	root.add_child(mmi)
	var planets := [
		[Vector3(-34, 20, -95), 14.0, Color("#ff7a4d")],
		[Vector3(40, 34, -120), 20.0, Color("#4da6ff")],
		[Vector3(10, 55, -150), 10.0, Color("#b46bff")],
	]
	for p in planets:
		var pos: Vector3 = p[0]
		var r: float = p[1]
		var col: Color = p[2]
		_add(root, _sph(r, 24), _m(col, 0.25, 1.0, 0.0, 0.7), pos)
		if r > 12.0:
			_add(root, _torus(r * 1.4, r * 1.7, 40, 4), _m(col.lightened(0.3), 0.4, 0.7), pos, Vector3(deg_to_rad(80.0), 0, deg_to_rad(15.0)))
	var neb := [Color("#7a2bff"), Color("#2b6aff"), Color("#ff2bd0")]
	for i in 3:
		var nc: Color = neb[i]
		_add(root, _sph(30.0, 12), _m(nc, 0.6, 0.12), Vector3(-50.0 + i * 50.0, 10.0 + i * 8.0, -140.0))
	var n_rocks := 14 if q >= 1 else 6
	for i in n_rocks:
		var side := -1.0 if i % 2 == 0 else 1.0
		var sz := rng.randf_range(1.5, 4.0)
		var pos := Vector3(side * rng.randf_range(12.0, 40.0), rng.randf_range(-6.0, 20.0), -rng.randf_range(20.0, 80.0))
		_add(root, _box(Vector3(sz, sz * 0.7, sz)), _m(Color("#2a2d55"), 0.0, 1.0, 0.4, 0.5), pos,
			Vector3(rng.randf(), rng.randf(), rng.randf()) * 3.0)
		_add(root, _box(Vector3(sz * 1.02, 0.12, sz * 1.02)), _m(Color("#4dffd2"), 1.8), pos + Vector3(0, sz * 0.36, 0),
			Vector3(0, 0, 0))
