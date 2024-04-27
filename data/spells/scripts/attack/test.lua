--[[
It was challenging to find good documentation about how to do spells. The examples got me some basics, but didn't go too far once I started doing more complex things. I ended up implementing a non-standard multi stage spell to try and recreate the same looks, which was made harder by the fact the ice tornado visuals have logic of their own on how they are displayed. In the end, I got close enough without spending too much time debugging the missing details. I made it one unit too big. All the squares around the character have empty space instead of large tornadoes.
]]
AREA_DIAMOND = {
	{
		{0, 0, 0, 1, 0, 0, 0},
		{0, 0, 1, 1, 1, 0, 0},
		{0, 1, 1, 1, 1, 1, 0},
		{1, 1, 1, 1, 3, 1, 1},
		{0, 1, 1, 1, 1, 1, 0},
		{0, 0, 1, 1, 1, 0, 0},
		{0, 0, 0, 1, 0, 0, 0}
	},
	{
		{0, 0, 0, 1, 0, 0, 0},
		{0, 0, 1, 1, 1, 0, 0},
		{0, 1, 1, 1, 1, 1, 0},
		{1, 1, 1, 1, 1, 1, 1},
		{0, 1, 1, 3, 1, 1, 0},
		{0, 0, 1, 1, 1, 0, 0},
		{0, 0, 0, 1, 0, 0, 0}
	},
	{
		{0, 0, 0, 1, 0, 0, 0},
		{0, 0, 1, 1, 1, 0, 0},
		{0, 1, 1, 1, 1, 1, 0},
		{1, 1, 3, 1, 1, 1, 1},
		{0, 1, 1, 1, 1, 1, 0},
		{0, 0, 1, 1, 1, 0, 0},
		{0, 0, 0, 1, 0, 0, 0}
	},
	{
		{0, 0, 0, 1, 0, 0, 0},
		{0, 0, 1, 1, 1, 0, 0},
		{0, 1, 1, 3, 1, 1, 0},
		{1, 1, 1, 1, 1, 1, 1},
		{0, 1, 1, 1, 1, 1, 0},
		{0, 0, 1, 1, 1, 0, 0},
		{0, 0, 0, 1, 0, 0, 0}
	}
}
local combatSteps = {}
local eventDelay = 200

-- Since I am creating a mult-stage spell, I need to be able to create each stage without copy pasting too much code.
function createCombatStep(step)
	function onGetFormulaValues(player, level, magicLevel)
		local min = (level / 5) + (magicLevel * 5.5) + 25
		local max = (level / 5) + (magicLevel * 11) + 50
		return -min, -max
	end
	local combat = Combat()
	combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_ICEDAMAGE)
	combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_ICETORNADO)
	combat:setParameter(COMBAT_PARAM_BLOCKARMOR, true)
	combat:setArea(createCombatArea(AREA_DIAMOND[step]))
	combat:setCallback(CALLBACK_PARAM_SKILLVALUE, "onGetFormulaValues")
	return combat
end

-- Since the area can be different sizes and lengths, do a loop through the area to assemble the multi-stage combat. 
for i,v in ipairs(AREA_DIAMOND) do
	table.insert(combatSteps, createCombatStep(i))
end

-- I found out while hooking up the multi-stage combat that not all the objects passed to lua are safe to pass around or copy, so I separated out the code executing the combat from the code setting up the event timing. Now it can pass safe data to re-get the objects it needs once it's time to execute the combat.
function executeSpell(combat, creatureId, variant)
	local creature = Creature(creatureId)
	combat:execute(creature, variant)
end

-- Since this spell is multi-stage combat, I loop through all the combat steps I created above and add events to execute them after delays to create a sense of animation.
function onCastSpell(creature, variant)
	for i,v in ipairs(combatSteps) do
		addEvent(executeSpell, (eventDelay*i)-eventDelay, v, creature:getId(), variant)
	end
	return true
end
