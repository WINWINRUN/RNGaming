local bit32 = bit32

local Noise = {}

function Noise.clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

function Noise.lerp(a, b, t)
    return a + (b - a) * t
end

function Noise.smoothstep(edge0, edge1, value)
    if edge0 == edge1 then
        return value >= edge1 and 1 or 0
    end

    local alpha = Noise.clamp((value - edge0) / (edge1 - edge0), 0, 1)
    return alpha * alpha * (3 - 2 * alpha)
end

function Noise.hash2D(xi, zi, seed)
    local value = bit32.band(xi * 374761393 + zi * 668265263 + seed * 1442695041, 0xFFFFFFFF)
    value = bit32.bxor(value, bit32.rshift(value, 13))
    value = bit32.band(value * 1274126177, 0xFFFFFFFF)
    value = bit32.bxor(value, bit32.rshift(value, 16))
    return (value % 100000) / 50000 - 1
end

function Noise.hash01(xi, zi, seed)
    return (Noise.hash2D(xi, zi, seed) + 1) * 0.5
end

function Noise.value2D(x, z, scale, seed)
    local fx = x / scale
    local fz = z / scale

    local x0 = math.floor(fx)
    local z0 = math.floor(fz)
    local tx = fx - x0
    local tz = fz - z0
    local x1 = x0 + 1
    local z1 = z0 + 1
    local sx = tx * tx * (3 - 2 * tx)
    local sz = tz * tz * (3 - 2 * tz)

    local v00 = Noise.hash2D(x0, z0, seed)
    local v10 = Noise.hash2D(x1, z0, seed)
    local v01 = Noise.hash2D(x0, z1, seed)
    local v11 = Noise.hash2D(x1, z1, seed)

    local row0 = Noise.lerp(v00, v10, sx)
    local row1 = Noise.lerp(v01, v11, sx)

    return Noise.lerp(row0, row1, sz)
end

function Noise.fractal2D(x, z, scale, octaves, lacunarity, persistence, seed)
    local total = 0
    local amplitude = 1
    local amplitudeSum = 0
    local currentScale = scale

    for octave = 0, octaves - 1 do
        total = total + Noise.value2D(x, z, currentScale, seed + octave * 131) * amplitude
        amplitudeSum = amplitudeSum + amplitude
        amplitude = amplitude * persistence
        currentScale = currentScale / lacunarity
    end

    if amplitudeSum == 0 then
        return 0
    end

    return total / amplitudeSum
end

function Noise.ridge2D(x, z, scale, octaves, lacunarity, persistence, seed)
    local value = math.abs(Noise.fractal2D(x, z, scale, octaves, lacunarity, persistence, seed))
    return 1 - value
end

return Noise
