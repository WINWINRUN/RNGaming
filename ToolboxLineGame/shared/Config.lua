local PromptPipelineSpec = require(script.Parent:WaitForChild("PromptPipelineSpec"))

local layout = PromptPipelineSpec.runtime_layout or {}
local economy = PromptPipelineSpec.runtime_economy or {}
local display = PromptPipelineSpec.runtime_display or {}

return {
    SlotCount = layout.slot_count or 50,
    SlotsPerRow = layout.slots_per_row or 10,
    TileSpacing = layout.tile_spacing or 12,
    RowSpacing = layout.row_spacing or 14,
    RewardBase = economy.reward_base or 4,
    RewardStep = economy.reward_step or 4,
    AdvanceBaseCost = economy.advance_base_cost or 30,
    AdvanceCostStep = economy.advance_cost_step or 45,
    MeetBonus = economy.finale_bonus or 5000,
    CurrencyName = economy.currency_name or "Tickets",
    GameTitle = display.title or "Prompt Pipeline Queue",
    GameGoalText = display.goal_text or "Move through the loop and reach the finale.",
    QueueIntroText = display.queue_intro_text or "Claim a slot and start progressing.",
    FinalePromptText = display.finale_prompt_text or "Meet the host",
}
