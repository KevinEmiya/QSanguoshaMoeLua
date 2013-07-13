module("extensions.moefan", package.seeall)
extension = sgs.Package("moefan")

kakarot = sgs.General(extension, "kakarot", "moe", 3, false)

Shenkeng = sgs.CreateTriggerSkill{
	name = "Shenkeng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local cnum = player:getHp()
		local e = player:getEquips():length()+player:getHandcards():length()
		
		if e>=cnum then 
			if (event==sgs.EventPhaseStart) and (player:getPhase () == sgs.Player_RoundStart) then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:askForDiscard(player, self:objectName(), cnum, cnum, false, true)
					player:turnOver()
				end
			end
		end
	end
}


Choufeng = sgs.CreateTriggerSkill{
	name = "Choufeng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TurnedOver},
	view_as_skill = ChoufengVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event==sgs.TurnedOver) then
			if room:askForSkillInvoke(player, self:objectName()) then
				local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "choufeng-invoke", true, true)
				local taghp = target:getHp()
				local selfhp = player:getHp()
				if taghp > selfhp then
					room:damage(sgs.DamageStruct(self:objectName(), player, target, 1))
					local to_throw = room:askForCardChosen(player, target, "choufeng_drop", self:objectName())
					local card = sgs.Sanguosha:getCard(to_throw)
					room:throwCard(card, target, player);
				else
					room:recover(target, sgs.RecoverStruct())
					target:drawCards(1)
				end
			end
		end
	end
}


kakarot:addSkill(Shenkeng)
kakarot:addSkill(Choufeng)

sgs.LoadTranslationTable{
	["moe"] = "萌",
	["moefan"] = "萌包",
	["kakarot"] = "卡卡洛",
	["#kakarot"] = "清廉正直",
	["Choufeng"] = "抽风",
	[":Choufeng"] = "每当你翻面时，你可立即选择一项：1.对任意一名体力值大于你的角色造成1点伤害，然后你弃置其1张牌；2.令任意一名体力值不大于你的角色回复1点体力，然后该角色摸1张牌。",
	["Shenkeng"] = "深坑",
	[":Shenkeng"] = "准备阶段，你可以弃置X张牌将自己的武将牌翻面。X为你当前的体力值。每阶段限一次。",
	["designer:kakarot"] = "洩矢の呼啦圈",
	["illustrator:kakarot"] = "小角色",
	["choufeng-invoke"] = "指定一名体力大于你的角色，对其造成1点伤害，然后你弃置其1张牌；或一名体力不大于你的角色，令其回复1点体力，然后摸一张牌。",
	["choufeng-drop"] = "请弃置目标角色一张牌。"
}
		