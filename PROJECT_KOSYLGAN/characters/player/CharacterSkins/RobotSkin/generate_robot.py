"""
Robot character generator for Godot top-down game.
Generates a low-poly humanoid robot as robot.glb with robot_colors.png texture.
Run: python3 generate_robot.py
"""

import struct
import json
import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ─── Colors (RGBA float) ───────────────────────────────────────────────────
SILVER   = [0.75, 0.75, 0.78, 1.0]
GUNMETAL = [0.15, 0.17, 0.20, 1.0]
CYAN     = [0.00, 0.85, 0.95, 1.0]
ORANGE   = [1.00, 0.40, 0.00, 1.0]
BLACK    = [0.05, 0.05, 0.07, 1.0]
WHITE    = [0.95, 0.95, 1.00, 1.0]

def uv(col, row):
    return [(col + 0.5) / 8.0, (row + 0.5) / 8.0]

UV_SILVER   = uv(0, 0)
UV_GUNMETAL = uv(1, 0)
UV_CYAN     = uv(2, 0)
UV_ORANGE   = uv(3, 0)
UV_BLACK    = uv(4, 0)
UV_WHITE    = uv(5, 0)


def box(cx, cy, cz, sx, sy, sz, uv_coord):
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    face_data = [
        ([0,  0, -1], [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1)]),
        ([0,  0,  1], [(-1,-1, 1),(1,-1, 1),(1,1, 1),(-1,1, 1)]),
        ([-1, 0,  0], [(-1,-1,-1),(-1,-1,1),(-1,1,1),(-1,1,-1)]),
        ([1,  0,  0], [(1,-1,-1),(1,-1,1),(1,1,1),(1,1,-1)]),
        ([0, -1,  0], [(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1)]),
        ([0,  1,  0], [(-1,1,-1),(1,1,-1),(1,1,1),(-1,1,1)]),
    ]
    positions, normals, uvs, indices = [], [], [], []
    for n, corners in face_data:
        base = len(positions)
        for dx, dy, dz in corners:
            positions.append([cx + dx*hx, cy + dy*hy, cz + dz*hz])
            normals.append(list(n))
            uvs.append(list(uv_coord))
        indices += [base, base+1, base+2, base, base+2, base+3]
    return positions, normals, uvs, indices


def merge(*parts):
    all_pos, all_nor, all_uvs, all_idx = [], [], [], []
    offset = 0
    for pos, nor, uvs, idx in parts:
        all_pos.extend(pos)
        all_nor.extend(nor)
        all_uvs.extend(uvs)
        all_idx.extend([i + offset for i in idx])
        offset += len(pos)
    return all_pos, all_nor, all_uvs, all_idx


def build_robot():
    parts = []
    # HEAD
    parts.append(box(0,    1.60,  0,    0.32, 0.32, 0.30, UV_SILVER))
    parts.append(box(0,    1.62,  0.16, 0.22, 0.10, 0.02, UV_CYAN))
    parts.append(box(0,    1.50,  0.14, 0.18, 0.04, 0.02, UV_ORANGE))
    parts.append(box(0,    1.76,  0,    0.16, 0.04, 0.16, UV_GUNMETAL))
    # NECK
    parts.append(box(0,    1.40,  0,    0.12, 0.08, 0.12, UV_GUNMETAL))
    # TORSO
    parts.append(box(0,    1.10,  0,    0.44, 0.46, 0.26, UV_SILVER))
    parts.append(box(0,    1.18,  0.14, 0.18, 0.16, 0.02, UV_GUNMETAL))
    parts.append(box(0,    1.10,  0.14, 0.06, 0.06, 0.02, UV_CYAN))
    parts.append(box(-0.16, 1.00, 0.14, 0.06, 0.06, 0.02, UV_ORANGE))
    parts.append(box( 0.16, 1.00, 0.14, 0.06, 0.06, 0.02, UV_ORANGE))
    parts.append(box(0,    0.84,  0,    0.36, 0.12, 0.22, UV_GUNMETAL))
    # LEFT ARM
    parts.append(box(-0.30, 1.20,  0,    0.10, 0.10, 0.10, UV_ORANGE))
    parts.append(box(-0.30, 1.02,  0,    0.12, 0.28, 0.12, UV_SILVER))
    parts.append(box(-0.30, 0.76,  0,    0.10, 0.08, 0.10, UV_GUNMETAL))
    parts.append(box(-0.30, 0.58,  0,    0.10, 0.24, 0.10, UV_SILVER))
    parts.append(box(-0.30, 0.38,  0,    0.12, 0.10, 0.10, UV_GUNMETAL))
    # RIGHT ARM
    parts.append(box( 0.30, 1.20,  0,    0.10, 0.10, 0.10, UV_ORANGE))
    parts.append(box( 0.30, 1.02,  0,    0.12, 0.28, 0.12, UV_SILVER))
    parts.append(box( 0.30, 0.76,  0,    0.10, 0.08, 0.10, UV_GUNMETAL))
    parts.append(box( 0.30, 0.58,  0,    0.10, 0.24, 0.10, UV_SILVER))
    parts.append(box( 0.30, 0.38,  0.10, 0.08, 0.08, 0.30, UV_GUNMETAL))
    parts.append(box( 0.30, 0.38,  0.27, 0.04, 0.04, 0.06, UV_BLACK))
    # HIPS
    parts.append(box( 0.12, 0.72, 0,    0.18, 0.10, 0.20, UV_GUNMETAL))
    parts.append(box(-0.12, 0.72, 0,    0.18, 0.10, 0.20, UV_GUNMETAL))
    # RIGHT LEG
    parts.append(box( 0.14, 0.52, 0,    0.14, 0.28, 0.14, UV_SILVER))
    parts.append(box( 0.14, 0.34, 0,    0.12, 0.08, 0.12, UV_ORANGE))
    parts.append(box( 0.14, 0.16, 0,    0.12, 0.28, 0.12, UV_SILVER))
    parts.append(box( 0.14, 0.00, 0.04, 0.14, 0.06, 0.20, UV_GUNMETAL))
    # LEFT LEG
    parts.append(box(-0.14, 0.52, 0,    0.14, 0.28, 0.14, UV_SILVER))
    parts.append(box(-0.14, 0.34, 0,    0.12, 0.08, 0.12, UV_ORANGE))
    parts.append(box(-0.14, 0.16, 0,    0.12, 0.28, 0.12, UV_SILVER))
    parts.append(box(-0.14, 0.00, 0.04, 0.14, 0.06, 0.20, UV_GUNMETAL))
    return merge(*parts)


def float_to_u8(f):
    return max(0, min(255, int(round(f * 255))))

def color_to_rgb(c):
    return (float_to_u8(c[0]), float_to_u8(c[1]), float_to_u8(c[2]))

def make_palette_png():
    import zlib
    W, H = 8, 8
    colors_rgb = [
        color_to_rgb(SILVER),
        color_to_rgb(GUNMETAL),
        color_to_rgb(CYAN),
        color_to_rgb(ORANGE),
        color_to_rgb(BLACK),
        color_to_rgb(WHITE),
        (100, 100, 100),
        (100, 100, 100),
    ]

    def png_chunk(tag, data):
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', crc)

    raw = b''
    for row in range(H):
        raw += b'\x00'
        for col in range(W):
            r, g, b = colors_rgb[col]
            raw += bytes([r, g, b])

    png = b'\x89PNG\r\n\x1a\n'
    png += png_chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0))
    png += png_chunk(b'IDAT', zlib.compress(raw, 9))
    png += png_chunk(b'IEND', b'')
    return png


def vec3_min_max(vecs):
    xs = [v[0] for v in vecs]
    ys = [v[1] for v in vecs]
    zs = [v[2] for v in vecs]
    return [min(xs), min(ys), min(zs)], [max(xs), max(ys), max(zs)]


def build_glb(positions, normals, uvs, indices, png_bytes):
    def align4(b):
        return b + b'\x00' * ((4 - len(b) % 4) % 4)

    pos_bytes = struct.pack(f'<{len(positions)*3}f', *[x for v in positions for x in v])
    nor_bytes = struct.pack(f'<{len(normals)*3}f',   *[x for v in normals  for x in v])
    uv_bytes  = struct.pack(f'<{len(uvs)*2}f',       *[x for v in uvs      for x in v])

    if max(indices) < 65536:
        idx_bytes = struct.pack(f'<{len(indices)}H', *indices)
        idx_comp = 5123
    else:
        idx_bytes = struct.pack(f'<{len(indices)}I', *indices)
        idx_comp = 5125

    pos_bytes = align4(pos_bytes)
    nor_bytes = align4(nor_bytes)
    uv_bytes  = align4(uv_bytes)
    idx_bytes = align4(idx_bytes)
    tex_bytes = align4(png_bytes)

    buf = pos_bytes + nor_bytes + uv_bytes + idx_bytes + tex_bytes

    bv_pos = (0,                                           len(pos_bytes))
    bv_nor = (bv_pos[0]+bv_pos[1],                        len(nor_bytes))
    bv_uv  = (bv_nor[0]+bv_nor[1],                        len(uv_bytes))
    bv_idx = (bv_uv[0]+bv_uv[1],                          len(idx_bytes))
    bv_tex = (bv_idx[0]+bv_idx[1],                        len(tex_bytes))

    pmin, pmax = vec3_min_max(positions)
    n_verts = len(positions)
    n_idx   = len(indices)

    gltf = {
        "asset": {"version": "2.0", "generator": "RobotGen-PurePython"},
        "scene": 0,
        "scenes": [{"name": "Robot", "nodes": [0]}],
        "nodes": [{"name": "Robot", "mesh": 0}],
        "meshes": [{"name": "RobotMesh", "primitives": [{
            "attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2},
            "indices": 3, "material": 0
        }]}],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": n_verts, "type": "VEC3", "min": pmin, "max": pmax},
            {"bufferView": 1, "componentType": 5126, "count": n_verts, "type": "VEC3"},
            {"bufferView": 2, "componentType": 5126, "count": n_verts, "type": "VEC2"},
            {"bufferView": 3, "componentType": idx_comp, "count": n_idx, "type": "SCALAR"},
        ],
        "bufferViews": [
            {"buffer": 0, "byteOffset": bv_pos[0], "byteLength": bv_pos[1], "target": 34962},
            {"buffer": 0, "byteOffset": bv_nor[0], "byteLength": bv_nor[1], "target": 34962},
            {"buffer": 0, "byteOffset": bv_uv[0],  "byteLength": bv_uv[1],  "target": 34962},
            {"buffer": 0, "byteOffset": bv_idx[0], "byteLength": bv_idx[1], "target": 34963},
            {"buffer": 0, "byteOffset": bv_tex[0], "byteLength": bv_tex[1]},
        ],
        "buffers": [{"byteLength": len(buf)}],
        "materials": [{"name": "RobotMat", "pbrMetallicRoughness": {
            "baseColorTexture": {"index": 0}, "metallicFactor": 0.7, "roughnessFactor": 0.3
        }, "doubleSided": False}],
        "textures": [{"source": 0, "sampler": 0}],
        "images":   [{"bufferView": 4, "mimeType": "image/png"}],
        "samplers": [{"magFilter": 9728, "minFilter": 9728, "wrapS": 10497, "wrapT": 10497}]
    }

    json_bytes = align4(json.dumps(gltf, separators=(',', ':')).encode('utf-8'))
    chunk0 = struct.pack('<II', len(json_bytes), 0x4E4F534A) + json_bytes
    chunk1 = struct.pack('<II', len(buf),        0x004E4942) + buf
    total  = 12 + len(chunk0) + len(chunk1)
    header = struct.pack('<III', 0x46546C67, 2, total)
    return header + chunk0 + chunk1


def main():
    print("Building robot geometry ...")
    positions, normals, uvs, indices = build_robot()
    print(f"  {len(positions)} vertices, {len(indices)//3} triangles")

    print("Generating palette texture ...")
    png_bytes = make_palette_png()
    png_path = os.path.join(OUTPUT_DIR, "robot_colors.png")
    with open(png_path, 'wb') as f:
        f.write(png_bytes)
    print(f"  Saved: {png_path}")

    print("Assembling GLB ...")
    glb_bytes = build_glb(positions, normals, uvs, indices, png_bytes)
    glb_path = os.path.join(OUTPUT_DIR, "robot.glb")
    with open(glb_path, 'wb') as f:
        f.write(glb_bytes)
    print(f"  Saved: {glb_path}  ({len(glb_bytes)//1024} KB)")
    print()
    print("Done!  RobotSkin/")
    print("  robot.glb        - 3D model")
    print("  robot_colors.png - palette texture (embedded in GLB)")


if __name__ == '__main__':
    main()
