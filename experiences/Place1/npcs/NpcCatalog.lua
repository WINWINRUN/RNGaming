return {
    AmongUsVendor = {
        DisplayName = "Red Crewmate",
        StallName = "Emergency Meeting Shop",
        Greeting = "Suspiciously good gear for a very temporary Place1 sandbox.",
        Items = {
            EmergencyButton = {
                DisplayName = "Emergency Button",
                Price = 25,
                ToolTip = "A portable panic button for dramatic tycoon decisions.",
                HandleSize = Vector3.new(1.5, 0.6, 1.5),
                HandleShape = "Cylinder",
                Color = Color3.fromRGB(214, 50, 51),
                Material = Enum.Material.SmoothPlastic,
            },
            TaskTablet = {
                DisplayName = "Task Tablet",
                Price = 15,
                ToolTip = "A tiny console loaded with definitely-complete tasks.",
                HandleSize = Vector3.new(1.6, 0.35, 1.1),
                HandleShape = "Block",
                Color = Color3.fromRGB(126, 208, 255),
                Material = Enum.Material.Glass,
                PreviewStyle = "TaskTablet",
                ScreenStyle = "TaskTablet",
            },
            CrewmateSnack = {
                DisplayName = "Crewmate Snack",
                Price = 10,
                ToolTip = "Emergency calories for long shifts and longer alibis.",
                HandleSize = Vector3.new(1.1, 1.1, 1.1),
                HandleShape = "Ball",
                Color = Color3.fromRGB(255, 201, 89),
                Material = Enum.Material.Neon,
            },
        },
        DisplayOrder = {
            "EmergencyButton",
            "TaskTablet",
            "CrewmateSnack",
        },
    },
}
