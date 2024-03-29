local mod    = DBM:NewMod("Zarithrian", "DBM-ChamberOfAspects", 2)
local L        = mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4380 $"):sub(12, -3))
mod:SetCreatureID(39746)

mod:RegisterCombat("combat")

mod:RegisterEvents(
    "SPELL_CAST_START",
    "SPELL_AURA_APPLIED",
    "SPELL_AURA_APPLIED_DOSE",
    "CHAT_MSG_MONSTER_YELL"
)

local warningAdds                = mod:NewAnnounce("WarnAdds", 3)
local warnCleaveArmor            = mod:NewAnnounce("warnCleaveArmor", 2, 74367, mod:IsTank() or mod:IsHealer())
local warningFear                = mod:NewSpellAnnounce(74384, 3)

local specWarnCleaveArmor        = mod:NewSpecialWarningStack(74367, nil, 2)--ability lasts 30 seconds, has a 15 second cd, so tanks should trade at 2 stacks.

local timerAddsCD                = mod:NewTimer(42.5, "TimerAdds")
local timerCleaveArmor            = mod:NewTargetTimer(30, 74367, nil, mod:IsTank() or mod:IsHealer())
local timerFearCD                = mod:NewCDTimer(42, 74384)--anywhere from 33-40 seconds in between fears.

function mod:OnCombatStart(delay)
    timerFearCD:Start(42-delay)--need more pulls to verify consistency
    timerAddsCD:Start(42-delay)--need more pulls to verify consistency
    timerCleaveArmor:Start(15)
end

function mod:SPELL_CAST_START(args)
    if args:IsSpellID(74384) then
        warningFear:Show()
        timerFearCD:Start()
    end
end

function mod:SPELL_AURA_APPLIED(args)
    if args:IsSpellID(74367) then
        warnCleaveArmor:Show(args.spellName, args.destName, args.amount or 1)
        timerCleaveArmor:Start(15)(args.destname)
        if args:IsPlayer() and args.amount >= 2 then
            specWarnCleaveArmor:Show(args.amount)
        end
    end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:CHAT_MSG_MONSTER_YELL(msg)
    if msg == L.SummonMinions or msg:match(L.SummonMinions) then
        warningFear:Show()
        timerAddsCD:Start()
        timerFearCD:Start()
    end
end