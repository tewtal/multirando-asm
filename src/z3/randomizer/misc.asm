OWSmithAccept:
{
    lda.l FollowerIndicator : cmp.b #$07 : beq +
    cmp.b #$08 : beq +
        clc : rtl
    + sec : rtl
}

ComboOnFileLoadHook:
{
    ; Make sure the progressive item flags are set correctly
    ; This could be wrong for example if an item was gotten in another game
    LDA.l SwordEquipment : STA.l HighestSword
    LDA.l ArmorEquipment : STA.l HighestMail
    LDA.l ShieldEquipment : STA.l HighestShield
    RTL
}