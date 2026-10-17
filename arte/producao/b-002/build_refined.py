"""Original posed miniature refinement; Blender 5.2, no rig, no external models.
Sources of B-001 stay preserved. Export four new GLBs and editable Blender scenes.
"""
from pathlib import Path
import importlib.util
import json
import math
import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
spec=importlib.util.spec_from_file_location('mini_tools',HERE.parent/'b-001/build_miniatures.py')
t=importlib.util.module_from_spec(spec)
spec.loader.exec_module(t)
OUT=ROOT/'src/assets/b/refined'
(HERE/'blender').mkdir(parents=True,exist_ok=True)
OUT.mkdir(parents=True,exist_ok=True)

def loft(name, rings, mat, sides=20):
    """Connected elliptical cross-sections instead of overlapping body primitives."""
    verts=[]
    for x,y,z,rx,ry in rings:
        verts += [(x+rx*math.cos(a*2*math.pi/sides),y+ry*math.sin(a*2*math.pi/sides),z) for a in range(sides)]
    faces=[tuple(range(sides-1,-1,-1))]
    for r in range(len(rings)-1):
        for a in range(sides):
            b=(a+1)%sides
            faces.append((r*sides+a,r*sides+b,(r+1)*sides+b,(r+1)*sides+a))
    faces.append(tuple((len(rings)-1)*sides+a for a in range(sides)))
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(verts,[],faces)
    mesh.update()
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    return t.finish(obj,name,mat)

def tube(name, points, radii, mat, sides=16):
    verts=[]
    for i,p in enumerate(points):
        p=Vector(p)
        before=Vector(points[max(i-1,0)])
        after=Vector(points[min(i+1,len(points)-1)])
        axis=(after-before).normalized()
        ref=Vector((0,1,0)) if abs(axis.y)<.95 else Vector((1,0,0))
        u=axis.cross(ref).normalized()
        v=axis.cross(u).normalized()
        rx,ry=radii[i] if isinstance(radii[i],tuple) else (radii[i],radii[i])
        for a in range(sides):
            theta=a*2*math.pi/sides
            verts.append(tuple(p+u*math.cos(theta)*rx+v*math.sin(theta)*ry))
    faces=[tuple(range(sides-1,-1,-1))]
    for i in range(len(points)-1):
        for a in range(sides):
            b=(a+1)%sides
            faces.append((i*sides+a,i*sides+b,(i+1)*sides+b,(i+1)*sides+a))
    faces.append(tuple((len(points)-1)*sides+a for a in range(sides)))
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(verts,[],faces)
    mesh.update()
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    return t.finish(obj,name,mat)

def patch(name, vertices, mat):
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(vertices,[],[tuple(range(len(vertices)))])
    mesh.update()
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    obj=t.finish(obj,name,mat,False)
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('cloth thickness','SOLIDIFY')
    mod.thickness=.012
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj

def build(kind):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    hero=kind=='survivor_01'
    fat=kind=='fatty'
    run=kind=='runner'
    ink=t.material('b002_ink',(.075,.085,.08))
    skin=t.material('b002_skin_'+kind,(.68,.46,.32) if hero else (.48,.53,.36))
    skin_shadow=t.material('b002_skin_shadow_'+kind,(.48,.27,.17) if hero else (.30,.35,.24))
    cloth=t.material('b002_cloth_'+kind, (.13,.48,.51) if hero else ((.40,.20,.14) if run else (.28,.32,.25)))
    cloth_hi=t.material('b002_light_'+kind,(.24,.62,.61) if hero else ((.56,.31,.19) if run else (.43,.46,.31)))
    pants=t.material('b002_denim',(.16,.20,.22))
    boot=t.material('b002_boot',(.19,.15,.11))
    hair=t.material('b002_hair',(.16,.10,.065))
    straps=t.material('b002_straps',(.29,.24,.16))
    shirt=t.material('b002_shirt',(.67,.65,.49))
    metal=t.material('b002_metal',(.28,.31,.30))
    teeth=t.material('b002_teeth',(.76,.72,.53))
    blood=t.material('b002_wound',(.40,.13,.10))
    bulk=1.65 if fat else (.91 if hero else .87)
    # Contrapposto / shuffling / wide sprint, each baked as a static pose.
    for side in [-1,1]:
        hip=(side*.10*bulk,0,.79)
        knee=(side*.125*bulk,(-.19 if side==1 else .11) if run else (-.055 if side==1 else .045),.45)
        ankle=(side*.18*bulk,(-.34 if side==1 else .30) if run else (-.09 if side==1 else .09),.13)
        tube('connected trouser leg',[hip,(side*.11*bulk,knee[1]*.4,.65),knee,(ankle[0],ankle[1]*.85,.26),ankle],[(.095*bulk,.09),(.09*bulk,.085),(.073*bulk,.07),(.064*bulk,.06),(.055*bulk,.055)],pants)
        t.box('boot',(ankle[0],ankle[1]-.045,.095),(.135*bulk,.25,.17),boot,.022)
        t.box('rubber sole',(ankle[0],ankle[1]-.045,.023),(.145*bulk,.26,.035),ink,.007)
        for j in range(3): t.box('boot lace',(ankle[0],ankle[1]-.067+j*.035,.177),(.085*bulk,.012,.008),straps,.002)
        t.box('cargo pocket',(side*.16*bulk,knee[1]*.45-.012,.62),(.043,.135,.135),pants,.014)
        # Creases follow the fabric rather than black rings around joints.
        tube('knee fold',[(knee[0]-.055,knee[1]-.067,.46),(knee[0],knee[1]-.078,.44),(knee[0]+.05,knee[1]-.061,.43)],[.008,.009,.006],ink,8)
    loft('pelvis',[(0,0,.73,.17*bulk,.11),(0,0,.80,.19*bulk,.12),(0,0,.88,.17*bulk,.11)],pants)
    loft('tailored jacket',[(0,0,.84,.18*bulk,.12),(0,0,.91,.17*bulk,.12),(0,0,1.04,.17*bulk,.13),(0,.005,1.16,.22*bulk,.14),(0,.01,1.25,.22*bulk,.12),(0,.015,1.29,.12*bulk,.075)],cloth)
    if fat:
        loft('exposed belly',[(0,-.08,.80,.16,.10),(0,-.105,.91,.29,.22),(0,-.10,1.06,.29,.23),(0,-.055,1.19,.21,.18),(0,-.02,1.26,.13,.10)],skin)
        t.ellipsoid('navel',(0,-.328,.93),(.012,.008,.009),skin_shadow,12)
    else:
        patch('undershirt',[(-.072,-.133,.92),(.072,-.133,.92),(.095,-.145,1.22),(-.095,-.145,1.22)],shirt)
    for side in [-1,1]:
        patch('folded lapel',[(side*.02,-.15,1.12),(side*.11,-.15,1.27),(side*.19*bulk,-.11,1.20),(side*.13,-.16,1.08)],cloth_hi)
        t.box('jacket pocket',(side*.115*bulk,-.125,.97),(.09,.025,.095),cloth,.008)
        t.box('pocket flap',(side*.115*bulk,-.144,1.006),(.10,.016,.021),cloth_hi,.004)
        tube('jacket hem',[(side*.03,-.123,.87),(side*.14*bulk,-.105,.87),(side*.17*bulk,.005,.88)],[.010,.011,.008],cloth_hi,8)
    t.box('belt',(0,-.014,.82),(.35*bulk,.215,.037),straps,.008)
    t.box('belt buckle',(0,-.13,.82),(.045,.020,.040),metal,.004)
    if hero:
        t.box('backpack',(0,.15,1.08),(.25,.15,.29),straps,.042)
        t.box('pack flap',(0,.238,1.16),(.21,.022,.10),boot,.012)
        for side in [-1,1]:
            tube('shoulder strap',[(side*.14,.13,1.22),(side*.16,-.10,1.23),(side*.14,-.15,1.04),(side*.13,-.11,.91)],[.022,.022,.019,.015],straps,10)
            t.box('strap buckle',(side*.145,-.168,1.11),(.044,.014,.045),metal,.003)
    # Connected sleeves with modeled cuffs and asymmetrical arm poses.
    for side in [-1,1]:
        shoulder=(side*.21*bulk,.005,1.21)
        if hero:
            elbow=(side*.29,-.10,1.03)
            wrist=(.085 if side==1 else .045,-.37 if side==1 else -.31,1.09)
        elif run:
            elbow=(side*.29,-.23 if side==1 else .17,1.12 if side==1 else 1.04)
            wrist=(side*.14,-.42 if side==1 else .32,1.29 if side==1 else .96)
        else:
            elbow=(side*.29*bulk,-.08,1.01 if fat else 1.08)
            wrist=(side*.25*bulk,-.27,.90 if fat else 1.14)
        mid=tuple((a+b)/2 for a,b in zip(shoulder,elbow))
        tube('continuous sleeve',[shoulder,mid,elbow],[.087*bulk,.077*bulk,.061*bulk],cloth)
        mid=tuple((a+b)/2 for a,b in zip(elbow,wrist))
        tube('forearm',[elbow,mid,wrist],[.057*bulk,.051*bulk,.034*bulk],skin if not hero else cloth)
        t.ellipsoid('hand',wrist,(.044,.043,.06),skin)
        if hero:
            tube('cuff band',[mid,wrist],[.05,.04],cloth_hi,12)
        else:
            for finger in range(4):
                x=wrist[0]+(finger-1.5)*.016
                tube('bent finger',[(x,wrist[1]-.023,wrist[2]),(x,wrist[1]-.068,wrist[2]-.010),(x,wrist[1]-.078,wrist[2]-.034)],[.011,.010,.008],skin,8)
    # Sculpted head: jaw, cheeks, brow and forehead are one connected mesh.
    loft('neck',[(0,0,1.23,.060,.055),(0,0,1.33,.057,.057)],skin)
    loft('head',[(0,-.015,1.32,.045,.047),(0,-.027,1.35,.068,.063),(0,-.017,1.40,.095,.079),(0,-.003,1.47,.106,.086),(0,.003,1.53,.101,.082),(0,.008,1.58,.079,.066),(0,.01,1.61,.022,.024)],skin)
    for side in [-1,1]:
        t.ellipsoid('ear',(side*.105,.005,1.45),(.018,.023,.036),skin,16)
        t.ellipsoid('eye socket',(side*.043,-.073,1.477),(.030,.016,.017),skin_shadow,16)
        t.ellipsoid('eye',(side*.043,-.085,1.480),(.021,.006,.008),teeth,12)
        t.ellipsoid('pupil',(side*.039,-.091,1.479),(.008,.004,.008),ink,12)
        tube('brow',[(side*.017,-.086,1.50),(side*.043,-.087,1.506),(side*.070,-.075,1.501)],[.008,.011,.006],hair,8)
        tube('cheek crease',[(side*.065,-.073,1.445),(side*.078,-.066,1.422)],[.005,.003],skin_shadow,8)
    loft('nose',[(0,-.080,1.43,.020,.015),(0,-.102,1.445,.023,.020),(0,-.088,1.475,.014,.013),(0,-.075,1.50,.009,.008)],skin,12)
    tube('mouth',[(-.033,-.075,1.382),(0,-.083,1.378),(.033,-.075,1.382)],[.004,.006,.004],ink,8)
    if hero:
        # Hair cap wraps sides/back; locks and a distinct swept ponytail.
        loft('hair crown',[(0,.01,1.54,.102,.087),(0,.015,1.59,.085,.073),(0,.017,1.625,.035,.03)],hair)
        for side in [-1,1]:
            tube('temple lock',[(side*.087,-.015,1.58),(side*.105,-.025,1.51),(side*.095,-.045,1.44)],[.034,.029,.013],hair)
        tube('swept fringe',[(.07,-.027,1.61),(.025,-.070,1.596),(-.054,-.084,1.55),(-.085,-.075,1.47)],[.036,.033,.025,.008],hair)
        tube('ponytail',[(0,.08,1.56),(.035,.16,1.55),(.10,.23,1.48),(.13,.24,1.36),(.16,.21,1.30)],[.045,.053,.047,.026,.008],hair)
        t.box('hair tie',(.035,.145,1.54),(.08,.025,.058),cloth_hi,.008)
        for j in [-1,0,1]: tube('hair highlight',[(j*.016,.075,1.60),(.035+j*.016,.18,1.55),(.10+j*.012,.25,1.45)],[.004,.004,.002],straps,6)
    elif not fat:
        loft('uneven short hair',[(0,.012,1.54,.102,.084),(0,.025,1.60,.080,.067),(0,.02,1.63,.035,.03)],hair)
        for side in [-1,1]: patch('torn shirt edge',[(side*.04,-.145,.91),(side*.07,-.16,.85),(side*.10,-.14,.90),(side*.15,-.13,.85),(side*.17,-.12,.96)],cloth_hi)
        patch('scuffed sleeve',[(.20,-.035,1.22),(.24,-.095,1.18),(.25,-.06,1.12)],blood)
    else:
        t.ellipsoid('bald scalp highlight',(0,.015,1.58),(.075,.068,.035),skin)
        tube('jaw stubble',[(-.07,-.06,1.37),(0,-.07,1.33),(.07,-.06,1.37)],[.010,.015,.010],skin_shadow,10)
    # Baked lean changes silhouette at tabletop scale, not an animation.
    lean=.0 if hero else (.40 if run else (.09 if fat else .17))
    for obj in bpy.context.scene.objects:
        if obj.type!='MESH':continue
        for vert in obj.data.vertices:
            world=obj.matrix_world@vert.co
            world.y-=max(0,world.z-.72)*lean
            vert.co=obj.matrix_world.inverted()@world
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active=next(o for o in bpy.context.scene.objects if o.type=='MESH')
    bpy.ops.object.join()
    body=bpy.context.object
    body.name=kind
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    # Separate props are toggled from actual equipped inventory in the engine.
    if hero:
        props=[]
        for name in ['Pistol','Axe','Crowbar','Bat']:
            bpy.ops.object.select_all(action='DESELECT')
            if name=='Pistol':
                a=t.box('pistol grip',(.085,-.378,1.102),(.042,.055,.095),boot,.008)
                b=t.box('pistol slide',(.085,-.434,1.151),(.054,.19,.049),metal,.008)
                c=t.box('muzzle',(.085,-.532,1.151),(.031,.012,.025),ink,.003)
                parts=[a,b,c]
            elif name=='Axe':
                a=t.limb('axe shaft',(.085,-.37,.98),(.085,-.44,1.54),.018,straps)
                b=t.box('axe head',(.15,-.44,1.50),(.23,.045,.13),metal,.015)
                parts=[a,b]
            elif name=='Crowbar':
                a=t.limb('bar',(.085,-.37,.94),(.085,-.43,1.48),.016,metal)
                b=t.limb('hook',(.085,-.43,1.48),(.085,-.50,1.51),.018,metal)
                parts=[a,b]
            else:
                a=t.limb('bat handle',(.085,-.37,1.00),(.085,-.40,1.22),.018,straps)
                b=t.limb('bat barrel',(.085,-.40,1.22),(.085,-.44,1.54),.038,boot,.028)
                parts=[a,b]
            bpy.ops.object.select_all(action='DESELECT')
            for obj in parts:obj.select_set(True)
            bpy.context.view_layer.objects.active=parts[0]
            bpy.ops.object.join()
            obj=bpy.context.object
            obj.name='Weapon'+name
            props.append(obj)
    bpy.ops.object.select_all(action='SELECT')
    triangles=0
    for obj in list(bpy.context.scene.objects):
        if obj.type!='MESH':continue
        bpy.context.view_layer.objects.active=obj
        mod=obj.modifiers.new('triangulation','TRIANGULATE')
        bpy.ops.object.modifier_apply(modifier=mod.name)
        triangles+=len(obj.data.polygons)
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'blender'/f'{kind}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(OUT/f'{kind}.glb'),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
    return {'id':kind,'triangles_including_hidden_props':triangles,'rig':False,'body_height_blender':1.64,'engine_normalization':.66}

result=[build(k) for k in ['survivor_01','walker','runner','fatty']]
(HERE/'model-report.json').write_text(json.dumps({'blender':bpy.app.version_string,'models':result},indent=2)+'\n')
print('REFINED_COMPLETE',len(result))
