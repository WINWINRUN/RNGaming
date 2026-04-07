return {
    Version = "world-prompt-assets-v1",
    Prompts = {
        WorldPrompt = "rolling alpine valley with a crater lake, ancient stone ruins, and smooth cliffs you can walk across"
    },
    Generation = {
        Seed = 1297779809
    },
    Pipeline = {
        Style = "smooth",
        PlanningArtStyle = "blocky",
        TerrainModel = "terrain-heightmap",
        UsesWorkspaceTerrain = true
    },
    Display = {
        Title = "Cozy Town Valley Pass",
        GoalText = "Explore the summit mushroom ruins, descend through the twin valleys, and reach the lower lake basin across the mountain ranges.",
        IntroText = "Smooth terrain runtime for a Cozy Town world with mountains landforms and 36 modular planning slots."
    },
    World = {
        WorldSpec = {
            theme = "cozy-town",
            art_style = "blocky",
            terrain = "mountains",
            flora_style = "",
            layout = "districts",
            density = "sparse",
            detail = "medium",
            scale = "medium",
            mood = "cozy",
            gameplay_focus = "exploration",
            district_count = 3,
            module_count = 36,
            main_route_count = 1,
            side_route_count = 1,
            landmark_count = 3,
            grid_size = 24,
            height_step = 12,
            color_story = {
                "cream",
                "brick",
                "forest green"
            },
            boundary_style = "triple mountain walls, cliff shelves, and relic terraces",
            spawn_anchor = "summit arrival",
            objective_anchor = "ancient machine crown",
            module_families = {
                "street",
                "plaza",
                "shopfront",
                "home",
                "garden",
                "fence",
                "mountain_range",
                "summit_plateau",
                "valley_floor",
                "ridge_bridge",
                "lake_basin"
            },
            navigation_pattern = "discover side paths and return to landmarks",
            prop_budget = "medium prop pass",
            open_space_ratio = 0.32,
            world_structure = "triple-range-verticality",
            mountain_range_count = 3,
            valley_count = 2,
            water_feature = "lake",
            section_mode = "contiguous-sections",
            validation_rules = {
                "Every path connector must terminate in a compatible connector.",
                "Every landmark must be reachable from spawn in under three route changes.",
                "No module should float or overlap after snap placement.",
                "Primary route must keep landmark sightlines at regular intervals.",
                "Gameplay-critical anchors must stay readable even in low-detail mode.",
                "Major elevation changes need readable approaches, terraces, or overlooks."
            },
            source_prompt = "rolling alpine valley with a crater lake, ancient stone ruins, and smooth cliffs you can walk across",
            landmarks = {
                "valley_pass",
                "lake_basin"
            }
        },
        ModularPlan = {
            anchor_order = {
                "summit arrival",
                "valley pass",
                "lake basin",
                "ancient machine crown"
            },
            module_families = {
                "street",
                "plaza",
                "shopfront",
                "home",
                "garden",
                "fence",
                "mountain_range",
                "summit_plateau",
                "valley_floor",
                "ridge_bridge",
                "lake_basin"
            },
            placement_rules = {
                "Buildings should face the primary route or a plaza edge.",
                "Dead ends require a visual payoff module such as a tower, prop cluster, or gate.",
                "Back-of-house modules should not block landmark sightlines.",
                "Boundary modules should close silhouettes before prop dressing begins."
            }
        },
        PipelineSteps = {
            "Parse the plain sentence into world tags, counts, and landmarks.",
            "Choose the cozy-town module kit in blocky style on a 24-stud grid.",
            "Generate a districts layout with 1 main route(s) and 1 supporting branch(es).",
            "Shape 3 mountain range(s), 2 valley corridor(s), and the lake before landmark dressing.",
            "Reserve 3 landmark slots and place spawn at summit arrival.",
            "Organize the world into contiguous-sections for summit, valleys, and lower basin traversal.",
            "Snap districts and module families into place with sparse density and 32% open space.",
            "Run a medium prop pass using the palette cream, brick, forest green.",
            "Validate routing, landmark readability, connector compatibility, and boundary closure."
        },
        FilledGaps = {
            theme = "cozy-town",
            art_style = "blocky",
            flora_style = "",
            layout = "districts",
            density = "sparse",
            detail = "medium",
            scale = "medium",
            mood = "cozy",
            gameplay_focus = "exploration",
            district_count = 3,
            module_count = 36,
            main_route_count = 1,
            side_route_count = 1,
            landmark_count = 3,
            grid_size = 24,
            height_step = 12,
            color_story = {
                "cream",
                "brick",
                "forest green"
            },
            boundary_style = "triple mountain walls, cliff shelves, and relic terraces",
            spawn_anchor = "summit arrival",
            objective_anchor = "ancient machine crown",
            module_families = {
                "street",
                "plaza",
                "shopfront",
                "home",
                "garden",
                "fence",
                "mountain_range",
                "summit_plateau",
                "valley_floor",
                "ridge_bridge",
                "lake_basin"
            },
            navigation_pattern = "discover side paths and return to landmarks",
            prop_budget = "medium prop pass",
            open_space_ratio = 0.32,
            world_structure = "triple-range-verticality",
            mountain_range_count = 3,
            valley_count = 2,
            section_mode = "contiguous-sections"
        }
    },
    AssetStyles = {
        PaletteRGB = {
            {
                234,
                225,
                202
            },
            {
                148,
                76,
                67
            },
            {
                74,
                116,
                68
            }
        },
        BaseplateColorRGB = {
            234,
            225,
            202
        },
        PrimaryAccentColorRGB = {
            148,
            76,
            67
        },
        SecondaryAccentColorRGB = {
            74,
            116,
            68
        },
        BoundaryStyle = "triple mountain walls, cliff shelves, and relic terraces"
    }
}
