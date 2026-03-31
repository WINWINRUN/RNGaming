local ExperienceGuard = {}

function ExperienceGuard.canRunHere(config)
    if not config.ExperienceLockEnabled then
        return true
    end

    for _, placeId in ipairs(config.AllowedPlaceIds) do
        if game.PlaceId == placeId then
            return true
        end
    end

    return false
end

return ExperienceGuard
