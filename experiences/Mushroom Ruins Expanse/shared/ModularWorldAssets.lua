return {
    Version = "world-prompt-assets-v1",
    Prompts = {
        WorldPrompt = "giant mushroom forest at the pinnacle of a mountain within three mountain ranges with two valleys and a lake near the bottom, surrounded by sci-fi robot giant ruins from ancient civilization"
    },
    Generation = {
        Seed = 765730868
    },
    Display = {
        Title = "Mushroom Crown Range",
        GoalText = "Explore the summit mushroom ruins, descend through the twin valleys, and reach the lower lake basin across the mountain ranges.",
        IntroText = "Blocky Ancient Tech layout with 108 modular slots."
    },
    World = {
        WorldSpec = {
            theme = "ancient-tech",
            art_style = "blocky",
            terrain = "mountains",
            flora_style = "mushroom-forest",
            layout = "branching",
            density = "sparse",
            detail = "medium",
            scale = "large",
            mood = "eerie",
            gameplay_focus = "exploration",
            district_count = 6,
            module_count = 108,
            main_route_count = 1,
            side_route_count = 2,
            landmark_count = 6,
            grid_size = 24,
            height_step = 12,
            color_story = {
                "stone",
                "steel",
                "deep blue"
            },
            boundary_style = "triple mountain walls, cliff shelves, and relic terraces",
            spawn_anchor = "summit arrival",
            objective_anchor = "ancient machine crown",
            module_families = {
                "path",
                "ruin_wall",
                "fallen_colossus",
                "relic_gate",
                "plaza",
                "bridge",
                "mushroom_grove",
                "fungal_clearing",
                "robot_ruin",
                "ancient_gate",
                "mountain_range",
                "summit_plateau",
                "valley_floor",
                "ridge_bridge",
                "lake_basin"
            },
            navigation_pattern = "discover side paths and return to landmarks",
            prop_budget = "medium prop pass",
            open_space_ratio = 0.42,
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
            source_prompt = "giant mushroom forest at the pinnacle of a mountain within three mountain ranges with two valleys and a lake near the bottom, surrounded by sci-fi robot giant ruins from ancient civilization",
            landmarks = {
                "mushroom_grove",
                "robot_ruin",
                "fallen_colossus",
                "ancient_gate",
                "summit_crown",
                "valley_pass",
                "lake_basin"
            }
        },
        ModularPlan = {
            anchor_order = {
                "summit arrival",
                "mushroom grove",
                "robot ruin",
                "fallen colossus",
                "ancient gate",
                "summit crown",
                "valley pass",
                "lake basin",
                "ancient machine crown"
            },
            module_families = {
                "path",
                "ruin_wall",
                "fallen_colossus",
                "relic_gate",
                "plaza",
                "bridge",
                "mushroom_grove",
                "fungal_clearing",
                "robot_ruin",
                "ancient_gate",
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
            "Choose the ancient-tech module kit in blocky style on a 24-stud grid.",
            "Generate a branching layout with 1 main route(s) and 2 supporting branch(es).",
            "Shape 3 mountain range(s), 2 valley corridor(s), and the lake before landmark dressing.",
            "Reserve 6 landmark slots and place spawn at summit arrival.",
            "Organize the world into contiguous-sections for summit, valleys, and lower basin traversal.",
            "Snap districts and module families into place with sparse density and 42% open space.",
            "Run a medium prop pass using the palette stone, steel, deep blue.",
            "Validate routing, landmark readability, connector compatibility, and boundary closure."
        },
        FilledGaps = {
            art_style = "blocky",
            density = "sparse",
            detail = "medium",
            mood = "eerie",
            gameplay_focus = "exploration",
            district_count = 6,
            module_count = 108,
            main_route_count = 1,
            side_route_count = 2,
            landmark_count = 6,
            grid_size = 24,
            height_step = 12,
            color_story = {
                "stone",
                "steel",
                "deep blue"
            },
            boundary_style = "triple mountain walls, cliff shelves, and relic terraces",
            spawn_anchor = "summit arrival",
            objective_anchor = "ancient machine crown",
            module_families = {
                "path",
                "ruin_wall",
                "fallen_colossus",
                "relic_gate",
                "plaza",
                "bridge",
                "mushroom_grove",
                "fungal_clearing",
                "robot_ruin",
                "ancient_gate",
                "mountain_range",
                "summit_plateau",
                "valley_floor",
                "ridge_bridge",
                "lake_basin"
            },
            navigation_pattern = "discover side paths and return to landmarks",
            prop_budget = "medium prop pass",
            open_space_ratio = 0.42,
            world_structure = "triple-range-verticality",
            section_mode = "contiguous-sections"
        }
    },
    AssetStyles = {
        PaletteRGB = {
            {
                120,
                121,
                128
            },
            {
                92,
                104,
                124
            },
            {
                58,
                82,
                142
            }
        },
        BaseplateColorRGB = {
            120,
            121,
            128
        },
        PrimaryAccentColorRGB = {
            92,
            104,
            124
        },
        SecondaryAccentColorRGB = {
            58,
            82,
            142
        },
        BoundaryStyle = "triple mountain walls, cliff shelves, and relic terraces"
    }
}
