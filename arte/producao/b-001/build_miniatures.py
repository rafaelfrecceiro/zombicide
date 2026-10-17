"""Editable original static miniature study. Run with Blender 5.2 --background --python.

This is a modeling script, not recovered content or a finished official survivor sculpt.
Z-up in Blender; GLB exporter converts to Godot Y-up. No rig or animations.
"""
from pathlib import Path
import math
import json
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
SOURCES = Path(__file__).resolve().parent / 'blender'
OUTPUT = ROOT / 'src/assets/b/models'
SOURCES.mkdir(parents=True, exist_ok=True)
OUTPUT.mkdir(parents=True, exist_ok=True)
MATS = {}

def material(name, color):
    if name not in MATS:
        m = bpy.data.materials.new(name)
        linear = tuple(c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4 for c in color)
        m.diffuse_color = (*linear, 1)
        m.use_nodes = True
        bsdf = next((n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'),None)
        if bsdf is None:
            bsdf = m.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
            output = m.node_tree.nodes.new('ShaderNodeOutputMaterial')
            m.node_tree.links.new(bsdf.outputs['BSDF'],output.inputs['Surface'])
        bsdf.inputs['Base Color'].default_value = (*linear, 1)
        bsdf.inputs['Roughness'].default_value = .9
        MATS[name] = m
    return MATS[name]

def finish(obj, name, mat, smooth=True):
    obj.name = name
    obj.data.materials.append(mat)
    if smooth:
        for p in obj.data.polygons: p.use_smooth = True
    return obj

def ellipsoid(name, center, scale, mat, segments=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=10, location=center)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(obj,name,mat)

def box(name, center, size, mat, bevel=.012, rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=center)
    obj=bpy.context.object
    obj.scale=size
    if rotation: obj.rotation_euler=rotation
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=obj.modifiers.new('rounded painted edges','BEVEL')
        mod.width=bevel
        mod.segments=2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(obj,name,mat,False)

def limb(name, a, b, radius, mat, end_radius=None):
    a,b=Vector(a),Vector(b)
    bpy.ops.mesh.primitive_cone_add(vertices=12,radius1=radius,radius2=end_radius or radius,depth=(b-a).length,location=(a+b)/2)
    obj=bpy.context.object
    obj.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return finish(obj,name,mat)

def make_model(name, jacket_color, skin_color, variant=0, zombie=None):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    ink=material('ink',(.025,.033,.035))
    skin=material('skin_'+name,skin_color)
    jacket=material('jacket_'+name,jacket_color)
    seam=material('seam_'+name,tuple(c*.57 for c in jacket_color))
    jeans=material('denim',(.10,.15,.18))
    boot=material('boots',(.065,.055,.044))
    shirt=material('undershirt',(.68,.64,.51))
    hair=material('hair_'+name,(.13,.085,.053) if variant!=4 else (.43,.43,.38))
    metal=material('gunmetal',(.19,.22,.23))
    leather=material('leather',(.22,.17,.11))
    eye=material('eye',(.88,.83,.67))
    bulk=1.65 if zombie=='fatty' else (.84 if zombie=='runner' else 1)
    # All figures are ~1.1 units high before engine scaling, with readable boots and legs.
    for side in [-1,1]:
        hip=(side*.085*bulk,0,.49)
        knee=(side*.095*bulk,-.035 if side==1 else .035,.29)
        foot=(side*.13*bulk,-.07 if side==1 else .06,.07)
        if zombie=='runner':
            knee=(side*.12,-.18 if side==1 else .14,.31)
            foot=(side*.16,-.31 if side==1 else .25,.08)
        limb('trouser thigh',hip,knee,.068*bulk,jeans,.052*bulk)
        ellipsoid('knee',knee,(.054*bulk,.057,.052),jeans)
        limb('trouser shin',knee,foot,.050*bulk,jeans,.040*bulk)
        box('boot',(foot[0],foot[1]-.033,.07),(.108*bulk,.19,.115),boot)
        box('boot sole',(foot[0],foot[1]-.033,.025),(.115*bulk,.20,.035),ink,.005)
        box('cargo pocket',(hip[0]+side*.035,hip[1]-.025,.40),(.048,.10,.085),seam)
    ellipsoid('hips',(0,0,.49),(.14*bulk,.09,.09),jeans)
    ellipsoid('jacket body',(0,.005,.69),(.17*bulk,.105*bulk,.205),jacket)
    if zombie=='fatty': ellipsoid('belly',(0,-.075,.62),(.25,.17,.23),skin)
    # Center shirt, jacket zipper, lapels, belt and pockets.
    box('shirt panel',(0,-.099*bulk,.71),(.115,.022,.25),shirt,.009)
    for side in [-1,1]:
        box('lapel',(side*.075,-.119*bulk,.79),(.055,.025,.14),jacket,.008, (0,side*.23,side*.12))
        box('jacket pocket',(side*.09*bulk,-.10*bulk,.63),(.065,.022,.065),seam,.006)
    box('belt',(0,-.005,.50),(.285*bulk,.19,.035),leather,.008)
    box('buckle',(0,-.108,.50),(.045,.018,.035),metal,.004)
    if not zombie:
        box('backpack',(0,.125,.70),(.21,.115,.23),leather,.03)
        for side in [-1,1]: limb('pack strap',(side*.115,-.097,.83),(side*.11,-.11,.56),.014,leather)
    # Distinct static silhouettes, not body animations.
    if zombie:
        shoulder_y=-.025 if zombie=='runner' else 0
        for side in [-1,1]:
            shoulder=(side*.16*bulk,shoulder_y,.81)
            elbow=(side*.23*bulk,-.11,.66 if zombie=='fatty' else .76)
            hand=(side*.20*bulk,-.27,.62 if zombie=='fatty' else .77)
            limb('torn upper sleeve',shoulder,elbow,.062*bulk,jacket,.043*bulk)
            limb('outstretched forearm',elbow,hand,.037*bulk,skin,.029*bulk)
            ellipsoid('hand',hand,(.040*bulk,.035,.041),skin)
            for finger in range(3):
                x=hand[0]+(finger-1)*.018
                limb('finger',(x,hand[1]-.01,hand[2]),(x,hand[1]-.07,hand[2]-.012),.008,skin)
    else:
        for side in [-1,1]:
            shoulder=(side*.16,0,.81)
            elbow=(side*.23,-.06,.66)
            hand=(side*.09,-.25,.71)
            if variant in [2,4]: hand=(side*.1,-.20,.59)
            limb('upper jacket sleeve',shoulder,elbow,.064,jacket,.045)
            limb('forearm sleeve',elbow,hand,.042,jacket,.030)
            ellipsoid('hand',hand,(.038,.04,.034),skin)
        # Neutral miniature weapon detail. Rules use actual inventory, not sculpt loadout.
        box('sidearm grip',(.075,-.245,.72),(.035,.045,.085),leather,.006,(.2,0,0))
        box('sidearm slide',(.075,-.285,.765),(.047,.14,.042),metal,.006)
        box('muzzle',(.075,-.361,.765),(.028,.013,.022),ink,.002)
    ellipsoid('neck',(0,0,.88),(.053,.048,.073),skin)
    head_y=-.035 if zombie=='runner' else -.005
    ellipsoid('head',(0,head_y,.986),(.092,.080,.115),skin)
    ellipsoid('chin',(0,head_y-.025,.928),(.060,.062,.045),skin)
    for side in [-1,1]:
        ellipsoid('ear',(side*.09,head_y,.982),(.017,.024,.029),skin,12)
        ellipsoid('eye socket',(side*.038,head_y-.069,1.003),(.026,.014,.016),ink,12)
        ellipsoid('eye white',(side*.038,head_y-.080,1.003),(.017,.005,.008),eye,12)
        box('brow',(side*.038,head_y-.080,1.025),(.047,.011,.011),hair,.003,(0,side*.10,0))
    ellipsoid('nose',(0,head_y-.085,.980),(.022,.030,.028),skin,12)
    box('mouth',(0,head_y-.078,.946),(.041,.008,.008),ink,.002)
    if zombie:
        ellipsoid('wound',(0.06,head_y-.06,.94),(.026,.009,.035),material('wound',(.29,.055,.045)),12)
    if variant==0:
        ellipsoid('hair crown',(0,.016,1.058),(.094,.079,.068),hair)
        for side in [-1,1]: ellipsoid('side hair',(side*.075,.012,1.012),(.023,.071,.066),hair)
        ellipsoid('ponytail',(.02,.113,1.018),(.046,.10,.075),hair)
        ellipsoid('ponytail tip',(.02,.17,.954),(.034,.048,.09),hair)
    elif variant==3:
        ellipsoid('bob hair',(0,.024,1.022),(.10,.079,.11),hair)
        for side in [-1,1]: ellipsoid('bob side',(side*.081,0,.974),(.027,.066,.084),hair)
    elif variant==4:
        ellipsoid('cap crown',(0,.01,1.067),(.10,.084,.056),jacket)
        box('cap visor',(0,-.085,1.059),(.19,.12,.022),jacket,.009)
        ellipsoid('beard',(0,-.035,.932),(.073,.06,.055),hair)
    elif variant==5:
        ellipsoid('hood',(0,.022,1.034),(.112,.102,.108),jacket)
        # Face remains in front of the hood.
        ellipsoid('face opening',(0,-.044,.987),(.08,.055,.092),skin)
    else:
        ellipsoid('short hair',(0,.014,1.064),(.094,.076,.052),hair)
        if variant==2: ellipsoid('beard',(0,-.03,.934),(.071,.061,.040),hair)
    # Join by material into a single mesh with editable material slots; no armature.
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active=next(o for o in bpy.context.scene.objects if o.type=='MESH')
    bpy.ops.object.join()
    obj=bpy.context.object
    obj.name=name
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    # Apply triangulation for stable exports and record real geometry counts.
    mod=obj.modifiers.new('runtime triangles','TRIANGULATE')
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCES/(name+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
    return {'name':name,'triangles':len(obj.data.polygons),'vertices':len(obj.data.vertices),'materials':len(obj.data.materials),'rig':False}

definitions=[
    ('survivor_01',(.10,.48,.51),(.64,.40,.24),0,None),
    ('survivor_02',(.72,.46,.10),(.27,.13,.07),1,None),
    ('survivor_03',(.58,.18,.12),(.65,.41,.27),2,None),
    ('survivor_04',(.40,.25,.54),(.54,.32,.21),3,None),
    ('survivor_05',(.35,.43,.22),(.61,.44,.30),4,None),
    ('survivor_06',(.19,.33,.56),(.49,.29,.18),5,None),
    ('walker',(.34,.40,.30),(.43,.50,.32),2,'walker'),
    ('runner',(.57,.29,.18),(.49,.54,.35),1,'runner'),
    ('fatty',(.27,.29,.25),(.48,.50,.34),2,'fatty'),
]
report=[make_model(*definition) for definition in definitions]
(SOURCES.parent/'model-report.json').write_text(json.dumps({'blender':bpy.app.version_string,'models':report},indent=2)+'\n')
print('MINIATURES_COMPLETE',len(report))
