module("extensions.moefan", package.seeall)
extension = sgs.Package("moefan")

kakarot = sgs.General(extension, "kakarot", "moe", 3, false)
moyfat = sgs.General(extension, "moyfat", "moe", 4, false)
xiaojuese = sgs.General(extension, "xiaojuese", "moe", 3, false)
aide = sgs.General(extension, "aide", "moe", 4, true)
dailing = sgs.General(extension, "dailing", "moe", 4, false)

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
					room:broadcastSkillInvoke(self:objectName())
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
				room:broadcastSkillInvoke(self:objectName())
				local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "choufeng-invoke", true, true)
				local taghp = target:getHp()
				local selfhp = player:getHp()
				if taghp > selfhp then
					if (target:getEquips():length() > 0) or (target:getHandcards():length() > 0)  then
						local to_throw = room:askForCardChosen(player, target, "choufeng_drop", self:objectName())
						local card = sgs.Sanguosha:getCard(to_throw)
						room:throwCard(card, target, player);
					end
					room:damage(sgs.DamageStruct(self:objectName(), player, target, 1))
				else
					target:drawCards(1)
					room:recover(target, sgs.RecoverStruct())
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
		room = player:getRoom()
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
			room:broadcastSkillInvoke(self:objectName())
			damage.damage = damage.damage + 1
			data:setValue(damage)
		elseif n1<n2 then
			room:broadcastSkillInvoke(self:objectName())
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
		room:broadcastSkillInvoke(self:objectName())
		source:loseMark("@mopao", 1)
		source:throwAllHandCardsAndEquips()
		room:broadcastInvoke("animate", "lightbox:$mopaofadong:2000")
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

---Skills of xiaojuese
--冰箭
Bingjian = sgs.CreateTriggerSkill{
	name = "Bingjian",
	frequency = sgs.Skill_NotFrequency,
	events = {sgs.SlashProceed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|red"
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge:isGood() then
				local effect = data:toSlashEffect()
				local dest = effect.to
				if not dest:isNude() and dest:isAlive() then
					local to_throw = room:askForCardChosen(player, dest, "he", self:objectName())
					local card = sgs.Sanguosha:getCard(to_throw)
					room:throwCard(card, dest, player);
					--return true
				end
				--return false
			end
		end
		--return false
	end
}

--弓术
GongshuCard = sgs.CreateSkillCard{
	name = "GongshuCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(source, "InfinityAttackRange")
	end,
}

Gongshu = sgs.CreateViewAsSkill{
	name = "Gongshu",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = GongshuCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#GongshuCard")
	end,
}

--绘想
Huixiang = sgs.CreateTriggerSkill{
	name = "Huixiang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:drawCards(player, 1, self:objectName())
			local players = room:getAlivePlayers()
			local all_players_fu = true
			for _,tplayer in sgs.qlist(players) do
				if not tplayer:faceUp() then
					all_players_fu = false
				end
			end
			if not all_players_fu then
				local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
				if not target:faceUp() then
					target:turnOver()
				end
			end
		end
	end
}

---End of Skills of xiaojuese

---Skills of aide
KuangjuanCard = sgs.CreateSkillCard{
	name = "KuangjuanCard", 
	target_fixed = false, 
	will_throw = false, 
	filter = function(self, targets, to_select) 
		return (#targets == 0) and (not to_select:isKongcheng())
	end,
	on_use = function(self, room, source, targets) 
		local success = source:pindian(targets[1], self:objectName(), nil)
		if success then
			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
			targets[1]:drawCards(1)
		else
			room:loseHp(source, 1)
			--if source:isAlive() then
			--	source:drawCards(1)
			--end
		end
	end
}
Kuangjuan = sgs.CreateViewAsSkill{
	name = "Kuangjuan",
	n = 0,
	view_as = function()
		return KuangjuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end
}
---End of Skills of aide

---Skills of dailing
--不幸
Buxing = sgs.CreateTriggerSkill{
	name = "Buxing",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local card = judge.card
			if card:isRed() then
				local count = player:getCardCount(true)
					if count > 0 then
						room:askForDiscard(player, self:objectName(), 1, 1, false, true)
					end
			end
	end,
}

--抚慰
Fuwei = sgs.CreateTriggerSkill{
	name = "Fuwei",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardsMoveOneTime}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		local source = move.from
		local place = move.from_places:at(0)
		local cnum = move.card_ids:length()
		if source and source:objectName() == player:objectName() then
			if player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_NotActive or player:getPhase() == sgs.Player_Judge then
					if place == sgs.Player_PlaceEquip or place == sgs.Player_PlaceHand or place == sgs.Player_PlaceDelayedTrick then
						if player:askForSkillInvoke(self:objectName(), data) then
							local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "fuwei-invoke", true, true)
							target:drawCards(cnum)
						end
					end
				end
			end
		end
	end,
}

--色气
Seqi = sgs.CreateTriggerSkill{
	name = "Seqi",
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.HpRecover}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local recover = data:toRecover()
		local source = recover.who
		local count = recover.recover
		if source then
			if source:objectName() ~= player:objectName() then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|heart"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge:isGood() then
				room:recover(source, sgs.RecoverStruct())
			end
			end
		end
	end,
}

---End of Skills of dailing

kakarot:addSkill(Shenkeng)
kakarot:addSkill(Choufeng)

moyfat:addSkill(Rouruan)
moyfat:addSkill(Youxian)
moyfat:addSkill(Mopao)

xiaojuese:addSkill(Bingjian)
xiaojuese:addSkill(Gongshu)
xiaojuese:addSkill(Huixiang)

aide:addSkill(Kuangjuan)

dailing:addSkill(Buxing)
dailing:addSkill(Seqi)
dailing:addSkill(Fuwei)

sgs.LoadTranslationTable{
	["moe"] = "萌",
	["moefan"] = "萌包",
	["kakarot"] = "卡卡洛",
	["#kakarot"] = "清廉正直",
	["Choufeng"] = "抽风",
	[":Choufeng"] = "每当你翻面时，你可立即选择一项：1.弃置任意一名体力值大于你的角色1张牌，然后你对其造成1点伤害；2.令任意一名体力值不大于你的角色摸1张牌，然后该角色回复1点体力。",
	["Shenkeng"] = "深坑",
	[":Shenkeng"] = "准备阶段，你可以弃置X张牌将自己的武将牌翻面。X为你当前的体力值。每阶段限一次。",
	["designer:kakarot"] = "洩矢の呼啦圈",
	["illustrator:kakarot"] = "小角色",
	["choufeng-invoke"] = "指定一名体力大于你的角色，弃置其1张牌，然后你对其造成1点伤害；或一名体力不大于你的角色，令其摸一张牌，然后回复1点体力。",
	["choufeng-drop"] = "请弃置目标角色一张牌。",
	["moyfat"] = "馍胖",
	["#moyfat"] = "红白油库里",
	["Rouruan"] = "柔软",
	[":Rouruan"] = "锁定技，铁索连环和兵粮寸断对你无效。",
	["Youxian"] = "悠闲",
	[":Youxian"] = "锁定技，装备区装备数少于你的角色对你造成的伤害-1;装备数多于你的角色对你造成的伤害+1。",
	["Mopao"] = "馍炮",
	[":Mopao"] = "限定技，出牌阶段，你可以弃置所有的牌，然后对所有角色依次造成1点伤害并令其翻面。结算完毕后你立即获得一个额外的回合。",
	["$mopaofadong"] = "不能油库里的人类先孙通通去屎啊——！！！",
	["@mopao"] = "馍炮",
	["designer:moyfat"] = "洩矢の呼啦圈",
	["xiaojuese"] = "小角色",
	["#xiaojuese"] = "幻想漂流",
	["Bingjian"] = "冰箭",
	[":Bingjian"] = "你的【杀】指定一个目标后，你可以进行一次判定，若结果为黑，你可以弃置其一张牌。",
	["Gongshu"] = "弓术",
	["gongshu"] = "弓术",
	[":Gongshu"] = "出牌阶段，你可以弃置一张牌令你于此回合内攻击范围无限。",
	["Huixiang"] = "绘想",
	["huixiang"] = "绘想",
	[":Huixiang"] = "其他角色对你造成1次伤害后，你可以摸一张牌并指定一名角色翻至正面朝上。",
	["designer:xiaojuese"] = "洩矢の呼啦圈",
	["illustrator:xiaojuese"] = "小角色",
	["aide"] = "爱德",
	["#aide"] = "狂之绘士",
	["Kuangjuan"] = "狂卷",
	[":Kuangjuan"] = "出牌阶段，你可以和一名其他角色拼点。若你赢，你对其造成1点伤害，然后该角色摸一张牌；若你没赢，你流失1点体力。",
	["designer:aide"] = "洩矢の呼啦圈",
	["illustrator:aide"] = "爱德",
	["KuangjuanCard"] = "狂卷拼点牌",
	["dailing"] = "呆零",
	["#dailing"] = "夜勤病栋",
	["Buxing"] = "不幸",
	[":Buxing"] = "锁定技，在你的判定生效后，若判定牌为红色，你须立即弃置一张牌。",
	["Fuwei"] = "抚慰",
	[":Fuwei"] = "每当你于判定阶段或回合外失去或弃置牌时，你可以指定一名其他角色摸等量的牌。",
	["fuwei-invoke"] = "请指定一名其他角色摸等量的牌",
	["Seqi"] = "色气",
	[":Seqi"] = "锁定技，其他角色令你回复一次体力时，你须进行一次判定。若结果为红桃，在判定结算完毕后该角色回复一点体力。",
}
		