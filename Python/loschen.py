import trimesh
from pythreejs import *
import numpy as np

# Lade dein OBJ + MTL
scene = trimesh.load(r"C:\Users\z004v3vh\Desktop\OBJ_PCB_Julian Kerzen Kopf.obj")

# Prüfen was es ist
print(scene)

# Falls es Scene ist → alle Geometrien zusammenfügen
if isinstance(scene, trimesh.Scene):
    meshes = [g for g in scene.geometry.values()]
    mesh = trimesh.util.concatenate(meshes)
else:
    mesh = scene

vertices = mesh.vertices.astype(np.float32)
faces = mesh.faces.astype(np.uint32)

geometry = BufferGeometry(
    attributes={
        'position': BufferAttribute(vertices, normalized=False),
        'index': BufferAttribute(faces.reshape(-1), normalized=False)
    }
)

material = MeshStandardMaterial(color='lightblue', metalness=0.2, roughness=0.7)

mesh3d = Mesh(geometry, material)

camera = PerspectiveCamera(position=[0, 0, 200], up=[0, 0, 1], fov=70)
scene3js = Scene(children=[mesh3d, AmbientLight(intensity=0.5), camera])

renderer = Renderer(camera=camera, scene=scene3js, 
                    controls=[OrbitControls(controlling=camera)], 
                    width=800, height=600)

renderer
