return {
    prompt = "snow world filled with giant trees and 4 giant flat top ice pillars",
    explicit_config = {
        theme = {
            value = "frozen-wilds",
            evidence = "snow world"
        },
        terrain = {
            value = "snow",
            evidence = "snow"
        },
        scale = {
            value = "large",
            evidence = "giant"
        },
        flora_style = {
            value = "giant-conifer-forest",
            evidence = "giant trees"
        },
        landmarks = {
            value = {
                "ice_pillar",
                "giant_tree_grove"
            },
            evidence = "ice pillar, giant trees"
        }
    },
    filled_gaps = {
        art_style = "blocky",
        layout = "districts",
        density = "sparse",
        detail = "medium",
        mood = "heroic",
        gameplay_focus = "exploration",
        district_count = 4,
        module_count = 96,
        main_route_count = 1,
        side_route_count = 1,
        landmark_count = 5,
        grid_size = 24,
        height_step = 12,
        color_story = {
            "snow white",
            "ice blue",
            "frost gray"
        },
        boundary_style = "glacier walls, frozen basins, and icy ridgelines",
        spawn_anchor = "snowfield arrival",
        objective_anchor = "ice crown",
        module_families = {
            "snowfield",
            "ice_pillar",
            "glacier_bridge",
            "ridge_path",
            "lookout",
            "frozen_grove",
            "plaza",
            "giant_tree_grove"
        },
        navigation_pattern = "discover side paths and return to landmarks",
        prop_budget = "medium prop pass",
        open_space_ratio = 0.4,
        world_structure = "ice-pillar-crown",
        mountain_range_count = 4,
        valley_count = 2,
        ice_pillar_count = 4,
        flat_top_pillars = true,
        creator_store_foliage = true,
        water_feature = "",
        section_mode = "contiguous-sections"
    },
    world_spec = {
        theme = "frozen-wilds",
        art_style = "blocky",
        terrain = "snow",
        flora_style = "giant-conifer-forest",
        layout = "districts",
        density = "sparse",
        detail = "medium",
        scale = "large",
        mood = "heroic",
        gameplay_focus = "exploration",
        district_count = 4,
        module_count = 96,
        main_route_count = 1,
        side_route_count = 1,
        landmark_count = 5,
        grid_size = 24,
        height_step = 12,
        color_story = {
            "snow white",
            "ice blue",
            "frost gray"
        },
        boundary_style = "glacier walls, frozen basins, and icy ridgelines",
        spawn_anchor = "snowfield arrival",
        objective_anchor = "ice crown",
        module_families = {
            "snowfield",
            "ice_pillar",
            "glacier_bridge",
            "ridge_path",
            "lookout",
            "frozen_grove",
            "plaza",
            "giant_tree_grove"
        },
        navigation_pattern = "discover side paths and return to landmarks",
        prop_budget = "medium prop pass",
        open_space_ratio = 0.4,
        world_structure = "ice-pillar-crown",
        mountain_range_count = 4,
        valley_count = 2,
        ice_pillar_count = 4,
        flat_top_pillars = true,
        creator_store_foliage = true,
        water_feature = "",
        section_mode = "contiguous-sections",
        validation_rules = {
            "Every path connector must terminate in a compatible connector.",
            "Every landmark must be reachable from spawn in under three route changes.",
            "No module should float or overlap after snap placement.",
            "Primary route must keep landmark sightlines at regular intervals.",
            "Gameplay-critical anchors must stay readable even in low-detail mode.",
            "Major elevation changes need readable approaches, terraces, or overlooks."
        },
        source_prompt = "snow world filled with giant trees and 4 giant flat top ice pillars",
        landmarks = {
            "ice_pillar",
            "giant_tree_grove"
        }
    },
    modular_plan = {
        anchor_order = {
            "snowfield arrival",
            "ice pillar",
            "giant tree grove",
            "ice crown"
        },
        module_families = {
            "snowfield",
            "ice_pillar",
            "glacier_bridge",
            "ridge_path",
            "lookout",
            "frozen_grove",
            "plaza",
            "giant_tree_grove"
        },
        placement_rules = {
            "Buildings should face the primary route or a plaza edge.",
            "Dead ends require a visual payoff module such as a tower, prop cluster, or gate.",
            "Back-of-house modules should not block landmark sightlines.",
            "Boundary modules should close silhouettes before prop dressing begins."
        }
    },
    pipeline_steps = {
        "Parse the plain sentence into world tags, counts, and landmarks.",
        "Choose the frozen-wilds module kit in blocky style on a 24-stud grid.",
        "Generate a districts layout with 1 main route(s) and 1 supporting branch(es).",
        "Build 4 giant ice pillar(s) with flat tops into the original snow terrain field.",
        "Reserve 5 landmark slots and place spawn at snowfield arrival.",
        "Snap districts and module families into place with sparse density and 40% open space.",
        "Populate tree and foliage zones with ready-made Creator Store assets after the original terrain pass.",
        "Run a medium prop pass using the palette snow white, ice blue, frost gray.",
        "Validate routing, landmark readability, connector compatibility, and boundary closure."
    }
}
