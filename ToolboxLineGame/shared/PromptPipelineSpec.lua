return {
    gameplay_prompt = "50-player waiting in line game where each player is locked to one spot, earns more tickets near the front, pays more to move ahead, and meets the host at the end",
    world_prompt = "blocky sci-fi queue terminal with one long main route, bright checkpoints, and a reward room at the front",
    explicit_gameplay_config = {
        core_loop = {
            value = "queue-ladder",
            evidence = "waiting in line"
        },
        economy_model = {
            value = "tickets",
            evidence = "tickets"
        },
        reward_model = {
            value = "jackpot-finale",
            evidence = "at the end"
        },
        gating_style = {
            value = "cost-gate",
            evidence = "pays more"
        },
        player_motion = {
            value = "locked-slots",
            evidence = "one spot"
        },
        objective_style = {
            value = "reach-finale",
            evidence = "at the end"
        },
        player_capacity = {
            value = 50,
            evidence = "50-player"
        },
        finale_role = {
            value = "host",
            evidence = "host"
        }
    },
    filled_gameplay_gaps = {
        interaction_mode = "social-shared",
        session_shape = "mid-session",
        failure_state = "soft-reset",
        occupancy_model = "one-per-slot",
        advancement_rule = "purchase-advance",
        pacing = "steady",
        checkpoint_count = 50,
        stage_count = 25,
        upgrade_count = 5,
        round_count = 3,
        currency_name = "Tickets",
        zone_roles = {
            "spawn_entry",
            "queue_slots",
            "income_nodes",
            "finale_pad",
            "exit_reset"
        },
        required_modules = {
            "queue_slot",
            "checkpoint_gate",
            "income_marker",
            "reward_pad",
            "exit_lane"
        },
        loop_beats = {
            "join",
            "claim slot",
            "earn currency",
            "pay to advance",
            "reach finale",
            "reset or replay"
        }
    },
    gameplay_spec = {
        core_loop = "queue-ladder",
        interaction_mode = "social-shared",
        session_shape = "mid-session",
        economy_model = "tickets",
        reward_model = "jackpot-finale",
        failure_state = "soft-reset",
        gating_style = "cost-gate",
        player_motion = "locked-slots",
        occupancy_model = "one-per-slot",
        advancement_rule = "purchase-advance",
        pacing = "steady",
        objective_style = "reach-finale",
        player_capacity = 50,
        checkpoint_count = 50,
        stage_count = 25,
        upgrade_count = 5,
        round_count = 3,
        currency_name = "Tickets",
        zone_roles = {
            "spawn_entry",
            "queue_slots",
            "income_nodes",
            "finale_pad",
            "exit_reset"
        },
        required_modules = {
            "queue_slot",
            "checkpoint_gate",
            "income_marker",
            "reward_pad",
            "exit_lane"
        },
        loop_beats = {
            "join",
            "claim slot",
            "earn currency",
            "pay to advance",
            "reach finale",
            "reset or replay"
        },
        source_prompt = "50-player waiting in line game where each player is locked to one spot, earns more tickets near the front, pays more to move ahead, and meets the host at the end",
        finale_role = "host"
    },
    world_binding = {
        required_module_families = {
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
        integrated_world_spec = {
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
        },
        throughput_rules = {
            "Support up to 50 concurrent players in the authored loop.",
            "Route gameplay through 50 checkpoint or position node(s).",
            "Keep spawn, first action, and first reward within a single readable route chain.",
            "Do not place economy, fail, or finale interactions behind ambiguous navigation choices.",
            "Every progression slot must advertise exclusive occupancy and a clear upgrade target.",
            "Lock player movement only after the slot or checkpoint is visibly claimed."
        },
        binding_notes = {
            "Bind the primary loop to the world anchor chain: airlock checkpoint -> station -> gate -> main landing pad.",
            "Use hub routing to stage the queue-ladder loop without breaking landmark readability.",
            "Extend the world from 36 to 58 modules if the gameplay capacity demands it."
        }
    },
    world_result = {
        prompt = "blocky sci-fi queue terminal with one long main route, bright checkpoints, and a reward room at the front",
        explicit_config = {
            theme = {
                value = "sci-fi",
                evidence = "sci-fi"
            },
            art_style = {
                value = "blocky",
                evidence = "blocky"
            },
            gameplay_focus = {
                value = "queue",
                evidence = "queue"
            },
            mood = {
                value = "bright",
                evidence = "bright"
            },
            landmarks = {
                value = {
                    "station",
                    "gate"
                },
                evidence = "terminal, checkpoint"
            }
        },
        filled_gaps = {
            terrain = "flat",
            layout = "hub",
            density = "medium",
            detail = "medium",
            scale = "medium",
            district_count = 3,
            module_count = 36,
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
                "road",
                "service_alley",
                "hangar",
                "utility_room",
                "tower",
                "pad",
                "plaza",
                "checkpoint"
            },
            navigation_pattern = "one-directional advance with clear checkpoints",
            prop_budget = "medium prop pass",
            open_space_ratio = 0.32
        },
        world_spec = {
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
            module_count = 36,
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
                "road",
                "service_alley",
                "hangar",
                "utility_room",
                "tower",
                "pad",
                "plaza",
                "checkpoint"
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
            }
        },
        modular_plan = {
            anchor_order = {
                "airlock checkpoint",
                "station",
                "gate",
                "main landing pad"
            },
            module_families = {
                "road",
                "service_alley",
                "hangar",
                "utility_room",
                "tower",
                "pad",
                "plaza",
                "checkpoint"
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
            "Choose the sci-fi module kit in blocky style on a 24-stud grid.",
            "Generate a hub layout with 1 main route(s) and 1 supporting branch(es).",
            "Reserve 3 landmark slots and place spawn at airlock checkpoint.",
            "Snap districts and module families into place with medium density and 32% open space.",
            "Run a medium prop pass using the palette steel, off-white, safety orange.",
            "Validate routing, landmark readability, connector compatibility, and boundary closure."
        }
    },
    gameplay_pipeline_steps = {
        "Parse the sentence into gameplay loop, progression, economy, and occupancy signals.",
        "Pull the modular world spec and inherit its anchors, layout, and module families.",
        "Choose the queue-ladder loop with social-shared interaction and mid-session session shape.",
        "Allocate 5 gameplay zones across 58 modular world slots.",
        "Bind rewards to Tickets using the jackpot-finale reward curve and cost-gate gating.",
        "Route players with locked-slots motion and one-per-slot occupancy rules.",
        "Validate throughput, first-time readability, recovery after failure, and finale clarity."
    },
    runtime_layout = {
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
    runtime_economy = {
        currency_name = "Tickets",
        reward_base = 4,
        reward_step = 4,
        advance_base_cost = 32,
        advance_cost_step = 44,
        finale_bonus = 5000
    },
    runtime_display = {
        title = "Sci Fi Queue Terminal",
        goal_text = "Claim a spot, earn Tickets, pay to move ahead, and meet the host at the front.",
        queue_intro_text = "Blocky Sci Fi layout with 50 player capacity and Tickets progression.",
        finale_prompt_text = "Meet the host"
    }
}
