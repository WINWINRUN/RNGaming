import json
import math
from pathlib import Path


def load_project_manifest(project_path: Path) -> dict:
    manifest_path = project_path / "terrain_profiles.json"
    if not manifest_path.exists():
        raise FileNotFoundError(f"Could not find terrain_profiles.json at {manifest_path}")
    return json.loads(manifest_path.read_text(encoding="utf-8"))


def clamp(value: float, minimum: float, maximum: float) -> float:
    return max(minimum, min(maximum, value))


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def smoothstep(edge0: float, edge1: float, value: float) -> float:
    if edge0 == edge1:
        return 1.0 if value >= edge1 else 0.0
    alpha = clamp((value - edge0) / (edge1 - edge0), 0.0, 1.0)
    return alpha * alpha * (3.0 - 2.0 * alpha)


def hash2d(xi: int, zi: int, seed: int) -> float:
    value = (xi * 374761393 + zi * 668265263 + seed * 1442695041) & 0xFFFFFFFF
    value ^= value >> 13
    value = (value * 1274126177) & 0xFFFFFFFF
    value ^= value >> 16
    return (value % 100000) / 50000.0 - 1.0


def hash01(xi: int, zi: int, seed: int) -> float:
    return (hash2d(xi, zi, seed) + 1.0) * 0.5


def value2d(x: float, z: float, scale: float, seed: int) -> float:
    fx = x / scale
    fz = z / scale
    x0 = math.floor(fx)
    z0 = math.floor(fz)
    tx = fx - x0
    tz = fz - z0
    x1 = x0 + 1
    z1 = z0 + 1
    sx = tx * tx * (3.0 - 2.0 * tx)
    sz = tz * tz * (3.0 - 2.0 * tz)
    v00 = hash2d(x0, z0, seed)
    v10 = hash2d(x1, z0, seed)
    v01 = hash2d(x0, z1, seed)
    v11 = hash2d(x1, z1, seed)
    row0 = lerp(v00, v10, sx)
    row1 = lerp(v01, v11, sx)
    return lerp(row0, row1, sz)


def fractal2d(x: float, z: float, scale: float, octaves: int, lacunarity: float, persistence: float, seed: int) -> float:
    total = 0.0
    amplitude = 1.0
    amplitude_sum = 0.0
    current_scale = scale
    for octave in range(octaves):
        total += value2d(x, z, current_scale, seed + octave * 131) * amplitude
        amplitude_sum += amplitude
        amplitude *= persistence
        current_scale /= lacunarity
    return total / amplitude_sum if amplitude_sum else 0.0


def ridge2d(x: float, z: float, scale: float, octaves: int, lacunarity: float, persistence: float, seed: int) -> float:
    return 1.0 - abs(fractal2d(x, z, scale, octaves, lacunarity, persistence, seed))


def world_position(profile: dict, ix: int, iz: int, resolution: int) -> tuple[float, float]:
    center = profile["ManagedCenter"]
    half_size = profile["WorldSize"] * 0.5
    x = center["X"] - half_size + (ix + 0.5) / resolution * profile["WorldSize"]
    z = center["Z"] - half_size + (iz + 0.5) / resolution * profile["WorldSize"]
    return x, z


def sky_island_descriptors(profile: dict, seed: int) -> list[dict]:
    center = profile["ManagedCenter"]
    descriptors = [
        {
            "x": center["X"],
            "y": profile["Spawn"]["Height"],
            "z": center["Z"],
            "radius": profile["IslandRadius"] + 10,
        }
    ]
    total = profile["IslandCount"]
    for index in range(1, total):
        angle_noise = hash01(index, total, seed + 61)
        angle = ((index - 1) / max(total - 1, 1)) * math.pi * 2 + angle_noise * 0.45
        radial_offset = (hash01(index, total, seed + 73) - 0.5) * profile["RingJitter"]
        altitude_offset = (hash01(index, total, seed + 89) - 0.5) * profile["AltitudeJitter"]
        radius_offset = (hash01(index, total, seed + 101) - 0.5) * profile["IslandRadiusJitter"]
        radial_distance = profile["RingRadius"] + radial_offset
        altitude = profile["BaseHeight"] + altitude_offset
        radius = profile["IslandRadius"] + radius_offset
        descriptors.append(
            {
                "x": center["X"] + math.cos(angle) * radial_distance,
                "y": altitude,
                "z": center["Z"] + math.sin(angle) * radial_distance,
                "radius": radius,
            }
        )
    return descriptors


def sample_height(profile: dict, seed: int, x: float, z: float) -> float:
    if profile["Kind"] == "SkyIslands":
        top = float(profile["ClearMinY"])
        spawn = profile["Spawn"]
        for descriptor in sky_island_descriptors(profile, seed):
            dx = x - descriptor["x"]
            dz = z - descriptor["z"]
            distance = math.sqrt(dx * dx + dz * dz)
            radius = descriptor["radius"]
            if distance <= radius:
                alpha = 1.0 - distance / radius
                height = descriptor["y"] + profile["TopThickness"] * 0.5
                bulge_distance = max(distance - spawn["InnerBlendRadius"], 0.0)
                bulge_range = max(radius - spawn["InnerBlendRadius"], 1.0)
                bulge_alpha = 1.0 - clamp(bulge_distance / bulge_range, 0.0, 1.0)
                height += bulge_alpha * profile["TopBulge"]
                top = max(top, height)
        return top

    dx = x - profile["ManagedCenter"]["X"]
    dz = z - profile["ManagedCenter"]["Z"]
    distance = math.sqrt(dx * dx + dz * dz)
    noise = profile["Noise"]
    continental = fractal2d(x, z, noise["ContinentalScale"], noise["ContinentalOctaves"], noise["Lacunarity"], noise["Persistence"], seed + 11)
    detail = fractal2d(x, z, noise["DetailScale"], noise["DetailOctaves"], noise["Lacunarity"], noise["Persistence"], seed + 173)
    ridge = ridge2d(x, z, noise["RidgeScale"], 3, noise["Lacunarity"], noise["Persistence"], seed + 307)
    height = profile["BaseHeight"] + continental * profile["HeightAmplitude"] + detail * profile["DetailAmplitude"] + ridge * profile["RidgeAmplitude"]
    river = profile["River"]
    if river["Enabled"]:
        river_noise = abs(fractal2d(x, z, river["Scale"], 2, 2.0, 0.5, seed + 557))
        if river_noise < river["Width"]:
            river_alpha = 1.0 - river_noise / river["Width"]
            height -= river_alpha * river["Depth"]
    edge = profile["Edge"]
    height -= smoothstep(edge["InnerRadius"], edge["OuterRadius"], distance) * edge["Drop"]
    spawn = profile["Spawn"]
    if distance < spawn["FlattenRadius"]:
        spawn_alpha = smoothstep(spawn["InnerBlendRadius"], spawn["FlattenRadius"], distance)
        height = lerp(spawn["Height"], height, spawn_alpha)
    return max(height, profile["BaseY"] + profile["CellSize"])


def sample_moisture(profile: dict, seed: int, x: float, z: float) -> float:
    if profile["Kind"] == "SkyIslands":
        return (fractal2d(x, z, 180.0, 3, 2.0, 0.5, seed + 419) + 1.0) * 0.5
    noise = profile["Noise"]
    return (fractal2d(x, z, noise["MoistureScale"], 3, noise["Lacunarity"], noise["Persistence"], seed + 419) + 1.0) * 0.5


def classify_surface(profile: dict, height: float, moisture: float, slope: float) -> str:
    name = profile["Name"]
    if profile["Kind"] == "SkyIslands":
        if slope >= 1.15:
            return "cliff"
        if height >= profile["Spawn"]["Height"] + 26:
            return "summit"
        if moisture >= 0.58:
            return "grove"
        return "meadow"
    if height <= profile["WaterLevel"]:
        return "water"
    if height <= profile["WaterLevel"] + 6:
        return "shore"
    if slope >= 1.1:
        return "cliff"
    if name == "DesertCanyon":
        if height >= profile["Spawn"]["Height"] + 34:
            return "mesa"
        return "dunes"
    if height >= profile["SnowLine"]:
        return "alpine"
    if moisture >= 0.58:
        return "forest"
    return "meadow"


def sample_profile(profile: dict, seed: int, resolution: int) -> dict:
    heights: list[list[float]] = []
    moistures: list[list[float]] = []
    slopes: list[list[float]] = []
    surfaces: list[list[str]] = []

    for iz in range(resolution):
        height_row = []
        moisture_row = []
        for ix in range(resolution):
            x, z = world_position(profile, ix, iz, resolution)
            height_row.append(sample_height(profile, seed, x, z))
            moisture_row.append(sample_moisture(profile, seed, x, z))
        heights.append(height_row)
        moistures.append(moisture_row)

    for iz in range(resolution):
        slope_row = []
        surface_row = []
        for ix in range(resolution):
            left = heights[iz][max(ix - 1, 0)]
            right = heights[iz][min(ix + 1, resolution - 1)]
            up = heights[max(iz - 1, 0)][ix]
            down = heights[min(iz + 1, resolution - 1)][ix]
            slope = max(abs(left - right), abs(up - down)) / max(profile["CellSize"], 1)
            slope_row.append(slope)
            surface_row.append(classify_surface(profile, heights[iz][ix], moistures[iz][ix], slope))
        slopes.append(slope_row)
        surfaces.append(surface_row)

    return {"heights": heights, "moistures": moistures, "slopes": slopes, "surfaces": surfaces}


def summarize_profile(profile: dict, seed: int, resolution: int = 128) -> dict:
    sampled = sample_profile(profile, seed, resolution)
    heights = sampled["heights"]
    slopes = sampled["slopes"]
    surfaces = sampled["surfaces"]
    flat_heights = [height for row in heights for height in row]
    flat_slopes = [slope for row in slopes for slope in row]
    water_cells = sum(1 for row in surfaces for surface in row if surface == "water")
    steep_cells = sum(1 for slope in flat_slopes if slope >= 1.1)
    min_height = min(flat_heights)
    max_height = max(flat_heights)
    spawn = profile["Spawn"]
    spawn_samples = []
    center_ix = resolution // 2
    center_iz = resolution // 2
    spawn_radius_cells = max(int((spawn["InnerBlendRadius"] / profile["WorldSize"]) * resolution), 1)
    for dz in range(-spawn_radius_cells, spawn_radius_cells + 1):
        for dx in range(-spawn_radius_cells, spawn_radius_cells + 1):
            ix = clamp(center_ix + dx, 0, resolution - 1)
            iz = clamp(center_iz + dz, 0, resolution - 1)
            spawn_samples.append(heights[int(iz)][int(ix)])
    spawn_average = sum(spawn_samples) / len(spawn_samples)
    spawn_variance = sum((sample - spawn_average) ** 2 for sample in spawn_samples) / len(spawn_samples)
    return {
        "resolution": resolution,
        "minimum_height": min_height,
        "maximum_height": max_height,
        "height_span": max_height - min_height,
        "water_coverage": water_cells / (resolution * resolution),
        "steep_coverage": steep_cells / (resolution * resolution),
        "spawn_average_height": spawn_average,
        "spawn_height_stddev": math.sqrt(spawn_variance),
        "sampled": sampled,
    }
