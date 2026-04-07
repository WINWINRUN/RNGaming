return {
    Version = "prompt-modular-assets-v1",
    Prompts = {
        GameplayPrompt = "50-player waiting in line game where each player is locked to one spot, earns more tickets near the front, pays more to move ahead, and meets the host at the end",
        WorldPrompt = "blocky sci-fi queue terminal with one long main route, bright checkpoints, and a reward room at the front"
    },
    Display = {
        Title = "Sci Fi Queue Terminal",
        GoalText = "Claim a spot, earn Tickets, pay to move ahead, and meet the host at the front.",
        QueueIntroText = "Blocky Sci Fi layout with 50 player capacity and Tickets progression.",
        FinalePromptText = "Meet the host",
        FinaleRole = "host"
    },
    Layout = {
        slot_count = 50,
        slots_per_row = 10,
        tile_spacing = 12,
        row_spacing = 14,
        queue_start_z = 72,
        queue_front_z = 16,
        queue_side_margin = 24,
        module_grid_size = 24,
        baseplate_width = 174,
        baseplate_depth = 154,
        route_style = "snake_rows"
    },
    Economy = {
        currency_name = "Tickets",
        reward_base = 4,
        reward_step = 4,
        advance_base_cost = 32,
        advance_cost_step = 44,
        finale_bonus = 5000
    },
    World = {
        Theme = "sci-fi",
        ArtStyle = "blocky",
        Terrain = "flat",
        LayoutStyle = "hub",
        IntegratedWorldSpec = {
            theme = "sci-fi",
            art_style = "blocky",
            terrain = "flat",
            layout = "hub",
            density = "medium",
            detail = "medium",
            scale = "medium",
            mood = "bright",
            gameplay_focus = "queue",
            district_count = 3,
            module_count = 58,
            main_route_count = 1,
            side_route_count = 1,
            landmark_count = 3,
            grid_size = 24,
            height_step = 12,
            color_story = {
                "steel",
                "off-white",
                "safety orange"
            },
            boundary_style = "service walls and canyon berms",
            spawn_anchor = "airlock checkpoint",
            objective_anchor = "main landing pad",
            module_families = {
                "checkpoint",
                "checkpoint_gate",
                "exit_lane",
                "hangar",
                "income_marker",
                "pad",
                "plaza",
                "queue_slot",
                "reward_pad",
                "road",
                "service_alley",
                "tower",
                "utility_room"
            },
            navigation_pattern = "one-directional advance with clear checkpoints",
            prop_budget = "medium prop pass",
            open_space_ratio = 0.32,
            validation_rules = {
                "Every path connector must terminate in a compatible connector.",
                "Every landmark must be reachable from spawn in under three route changes.",
                "No module should float or overlap after snap placement.",
                "Primary route must keep landmark sightlines at regular intervals.",
                "Gameplay-critical anchors must stay readable even in low-detail mode."
            },
            source_prompt = "blocky sci-fi queue terminal with one long main route, bright checkpoints, and a reward room at the front",
            landmarks = {
                "station",
                "gate"
            },
            required_zone_roles = {
                "spawn_entry",
                "queue_slots",
                "income_nodes",
                "finale_pad",
                "exit_reset"
            },
            gameplay_binding = {
                currency_name = "Tickets",
                loop_beats = {
                    "join",
                    "claim slot",
                    "earn currency",
                    "pay to advance",
                    "reach finale",
                    "reset or replay"
                },
                zone_allocations = {
                    {
                        zone_role = "spawn_entry",
                        anchor = "airlock checkpoint",
                        module_budget = 5,
                        preferred_world_modules = {
                            "checkpoint",
                            "checkpoint_gate",
                            "exit_lane"
                        }
                    },
                    {
                        zone_role = "queue_slots",
                        anchor = "station",
                        module_budget = 32,
                        preferred_world_modules = {
                            "checkpoint",
                            "checkpoint_gate",
                            "exit_lane",
                            "hangar"
                        }
                    },
                    {
                        zone_role = "income_nodes",
                        anchor = "gate",
                        module_budget = 7,
                        preferred_world_modules = {
                            "checkpoint_gate",
                            "exit_lane",
                            "hangar",
                            "income_marker"
                        }
                    },
                    {
                        zone_role = "finale_pad",
                        anchor = "main landing pad",
                        module_budget = 9,
                        preferred_world_modules = {
                            "exit_lane",
                            "hangar",
                            "income_marker",
                            "pad"
                        }
                    },
                    {
                        zone_role = "exit_reset",
                        anchor = "main landing pad",
                        module_budget = 6,
                        preferred_world_modules = {
                            "hangar",
                            "income_marker",
                            "pad",
                            "plaza"
                        }
                    }
                }
            }
        },
        ZoneAllocations = {
            {
                zone_role = "spawn_entry",
                anchor = "airlock checkpoint",
                module_budget = 5,
                preferred_world_modules = {
                    "checkpoint",
                    "checkpoint_gate",
                    "exit_lane"
                }
            },
            {
                zone_role = "queue_slots",
                anchor = "station",
                module_budget = 32,
                preferred_world_modules = {
                    "checkpoint",
                    "checkpoint_gate",
                    "exit_lane",
                    "hangar"
                }
            },
            {
                zone_role = "income_nodes",
                anchor = "gate",
                module_budget = 7,
                preferred_world_modules = {
                    "checkpoint_gate",
                    "exit_lane",
                    "hangar",
                    "income_marker"
                }
            },
            {
                zone_role = "finale_pad",
                anchor = "main landing pad",
                module_budget = 9,
                preferred_world_modules = {
                    "exit_lane",
                    "hangar",
                    "income_marker",
                    "pad"
                }
            },
            {
                zone_role = "exit_reset",
                anchor = "main landing pad",
                module_budget = 6,
                preferred_world_modules = {
                    "hangar",
                    "income_marker",
                    "pad",
                    "plaza"
                }
            }
        },
        RequiredModuleFamilies = {
            "checkpoint",
            "checkpoint_gate",
            "exit_lane",
            "hangar",
            "income_marker",
            "pad",
            "plaza",
            "queue_slot",
            "reward_pad",
            "road",
            "service_alley",
            "tower",
            "utility_room"
        },
        ThroughputRules = {
            "Support up to 50 concurrent players in the authored loop.",
            "Route gameplay through 50 checkpoint or position node(s).",
            "Keep spawn, first action, and first reward within a single readable route chain.",
            "Do not place economy, fail, or finale interactions behind ambiguous navigation choices.",
            "Every progression slot must advertise exclusive occupancy and a clear upgrade target.",
            "Lock player movement only after the slot or checkpoint is visibly claimed."
        },
        BindingNotes = {
            "Bind the primary loop to the world anchor chain: airlock checkpoint -> station -> gate -> main landing pad.",
            "Use hub routing to stage the queue-ladder loop without breaking landmark readability.",
            "Extend the world from 36 to 58 modules if the gameplay capacity demands it."
        }
    },
    AssetStyles = {
        ZoneColors = {
            spawn_entry = {
                255,
                210,
                96
            },
            queue_slots = {
                88,
                112,
                162
            },
            income_nodes = {
                116,
                220,
                176
            },
            finale_pad = {
                126,
                208,
                255
            },
            exit_reset = {
                162,
                241,
                180
            }
        },
        BaseplateColorRGB = {
            45,
            50,
            62
        },
        QueueLaneColorRGB = {
            42,
            47,
            60
        },
        QueueRowPlateColorRGB = {
            53,
            58,
            72
        },
        SideRailColorRGB = {
            70,
            76,
            92
        },
        BackdropColorRGB = {
            60,
            66,
            84
        },
        StructureMetalColorRGB = {
            56,
            62,
            76
        },
        AccentMetalColorRGB = {
            77,
            85,
            104
        },
        IncomeMarkerBaseColorRGB = {
            36,
            40,
            50
        },
        CheckpointGateColorRGB = {
            239,
            183,
            64
        },
        QueueSlotGradientStartRGB = {
            68,
            92,
            124
        },
        QueueSlotGradientEndRGB = {
            208,
            168,
            70
        }
    }
}
