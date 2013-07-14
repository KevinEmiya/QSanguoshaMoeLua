module("extensions.moefan", package.seeall)
extension = sgs.Package("moefan")

kakarot = sgs.General(extension, "kakarot", "moe", 3, false)
moyfat = sgs.General(extension, "moyfat", "moe", 4, false)

--Skills of kakarot
--深坑
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

--抽风
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
					if (target:getEquips():length() > 0) or (target:getHandcards():length() > 0)  then
						local to_throw = room:askForCardChosen(player, target, "choufeng_drop", self:objectName())
						local card = sgs.Sanguosha:getCard(to_throw)
						room:throwCard(card, target, player);
					end
				else
					room:recover(target, sgs.RecoverStruct())
					target:drawCards(1)
				end
			end
		end
	end
}
---End of Skills of kakarot

---Skills of moyfat
--柔软
Rouruan = sgs.CreateTriggerSkill{
	name = "Rouruan", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		local source = effect.from
		local target = effect.to
		local card = effect.card
		if target and source then
			--if target:objectName() ~= source:objectName() then
				if card:isKindOf("IronChain") then
					if target:hasSkill(self:objectName()) then
						return true
					end
				end
			--end
		end
		if card:isKindOf("SupplyShortage") then
			if target:hasSkill(self:objectName()) then
				return true
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}

--悠闲
Youxian = sgs.CreateTriggerSkill{
	name = "Youxian",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		local n1 = source:getEquips():length()
		local n2 = player:getEquips():length()
		if n1>n2 then
			damage.damage = damage.damage + 1
			data:setValue(damage)
		elseif n1<n2 then
			damage.damage = damage.damage - 1
			data:setValue(damage)
		end
		return false
	end
}

--馍炮
MopaoCard = sgs.CreateSkillCard{
	name = "MopaoCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		source:loseMark("@mopao", 1)
		source:throwAllHandCardsAndEquips()
		local players = room:getOtherPlayers(source)
		for _,player in sgs.qlist(players) do
			local damage = sgs.DamageStruct()
			damage.card = self
			damage.from = source
			damage.to = player
			room:damage(damage)
			player:turnOver()
		end
		if source:isAlive() then
			source:gainAnExtraTurn()
		end
	end
}

MopaoVS = sgs.CreateViewAsSkill{
	name = "Mopao", 
	n = 0, 
	view_as = function(self, cards) 
		return MopaoCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("@mopao") >= 1
	end
}

Mopao = sgs.CreateTriggerSkill{
	name = "Mopao" ,
	frequency = sgs.Skill_Limited ,
	events = {sgs.GameStart},
	view_as_skill = MopaoVS,
	on_trigger = function(self,event,player,data)
		player:gainMark("@mopao")
	end
}

---End of Skills of moyfat

kakarot:addSkill(Shenkeng)
kakarot:addSkill(Choufeng)

moyfat:addSkill(Rouruan)
moyfat:addSkill(Youxian)
moyfat:addSkill(Mopao)

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
	["choufeng-drop"] = "请弃置目标角色一张牌。",
	["moyfat"] = "馍胖",
	["#moyfat"] = "红白油库里",
	["Rouruan"] = "柔软",
	[":Rouruan"] = "锁定技，铁索连环和兵粮寸断对你无效。",
	["Youxian"] = "悠闲",
	[":Youxian"] = "锁定技，装备区装备数少于你的角色对你造成的伤害-1;装备数多于你的角色对你造成的伤害+1。",
	["Mopao"] = "馍炮",
	[":Mopao"] = "限定技，出牌阶段，你可以弃置所有的牌，然后对所有角色依次造成1点伤害并令其翻面。结算完毕后你立即获得一个额外的回合。",
	["designer:moyfat"] = "洩矢の呼啦圈"
}
		