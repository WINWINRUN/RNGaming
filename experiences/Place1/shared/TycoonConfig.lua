local TycoonConfig = {
    WorldFolderName = "AmongUsTycoonWorld",
    PlotCount = 8,
    PlotRadius = 220,
    PlotSize = Vector3.new(88, 2, 88),
    IncomeTickSeconds = 1,
    BaseIncomePerSecond = 1,
    ClaimPromptText = "Claim Plot",
    CollectPromptText = "Collect Cash",
    PlotNames = {
        "Red Reactor Plot",
        "Blue Tablet Plot",
        "Green Vent Plot",
        "Yellow Snack Plot",
        "Orange Cafeteria Plot",
        "Pink Medbay Plot",
        "Cyan Shields Plot",
        "White Security Plot",
    },
    PlotColors = {
        Color3.fromRGB(194, 41, 46),
        Color3.fromRGB(68, 119, 214),
        Color3.fromRGB(74, 154, 89),
        Color3.fromRGB(237, 193, 67),
        Color3.fromRGB(229, 127, 55),
        Color3.fromRGB(240, 121, 199),
        Color3.fromRGB(94, 222, 230),
        Color3.fromRGB(220, 224, 232),
    },
    Upgrades = {
        {
            Id = "EmergencyButtonPress",
            DisplayName = "Emergency Button Press",
            PromptText = "Build Emergency Button",
            Cost = 30,
            IncomePerSecond = 2,
            PreviewStyle = "EmergencyButton",
            RelativePosition = Vector3.new(-24, 1, -10),
        },
        {
            Id = "TaskTabletDesk",
            DisplayName = "Task Tablet Desk",
            PromptText = "Build Task Tablet Desk",
            Cost = 75,
            IncomePerSecond = 5,
            PreviewStyle = "TaskTablet",
            RelativePosition = Vector3.new(0, 1, -10),
        },
        {
            Id = "CrewmateSnackBar",
            DisplayName = "Crewmate Snack Bar",
            PromptText = "Build Snack Bar",
            Cost = 130,
            IncomePerSecond = 9,
            PreviewStyle = "SnackBar",
            RelativePosition = Vector3.new(24, 1, -10),
        },
        {
            Id = "VentNetwork",
            DisplayName = "Vent Network",
            PromptText = "Build Vent Network",
            Cost = 220,
            IncomePerSecond = 14,
            PreviewStyle = "Vent",
            RelativePosition = Vector3.new(-24, 1, 20),
        },
        {
            Id = "ReactorCore",
            DisplayName = "Reactor Core",
            PromptText = "Build Reactor Core",
            Cost = 340,
            IncomePerSecond = 20,
            PreviewStyle = "Reactor",
            RelativePosition = Vector3.new(0, 1, 20),
        },
        {
            Id = "CrewmateCloneBay",
            DisplayName = "Crewmate Clone Bay",
            PromptText = "Build Clone Bay",
            Cost = 500,
            IncomePerSecond = 28,
            PreviewStyle = "CloneBay",
            RelativePosition = Vector3.new(24, 1, 20),
        },
    },
}

function TycoonConfig.getPlotColor(index)
    return TycoonConfig.PlotColors[((index - 1) % #TycoonConfig.PlotColors) + 1]
end

function TycoonConfig.getPlotName(index)
    return TycoonConfig.PlotNames[((index - 1) % #TycoonConfig.PlotNames) + 1]
end

function TycoonConfig.getUpgradeById(upgradeId)
    for _, upgrade in ipairs(TycoonConfig.Upgrades) do
        if upgrade.Id == upgradeId then
            return upgrade
        end
    end

    return nil
end

return TycoonConfig
