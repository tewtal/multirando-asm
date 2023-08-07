;(address, type, shiftRight, bits, digits, xPos, lineNumber)

%AddStat(SwordTime, 1, 0, 32, 4, !FIRST_SWORD_X, !FIRST_SWORD_Y)
%AddStat(BootsTime, 1, 0, 32, 4, !PEGASUS_BOOTS_X, !PEGASUS_BOOTS_Y)
%AddStat(FluteTime, 1, 0, 32, 4, !FLUTE_X, !FLUTE_Y)
%AddStat(MirrorTime, 1, 0, 32, 4, !MIRROR_X, !MIRROR_Y)
%AddStat(SwordlessBossKills, 0, 0, 08, 2, !SWORDLESS_X, !SWORDLESS_Y)
%AddStat(SwordBossKills, 0, 4, 04, 2, !FIGHTERS_SWORD_X, !FIGHTERS_SWORD_Y)
%AddStat(SwordBossKills, 0, 0, 04, 2, !MASTER_SWORD_X, !MASTER_SWORD_Y)
%AddStat(SwordBossKills+1, 0, 4, 04, 2, !TEMPERED_SWORD_X, !TEMPERED_SWORD_Y)
%AddStat(SwordBossKills+1, 0, 0, 04, 2, !GOLD_SWORD_X, !GOLD_SWORD_Y)
%AddStat(DamageCounter, 0, 0, 16, 5, !DAMAGETAKEN_X, !DAMAGETAKEN_Y)
%AddStat(MagicCounter, 0, 0, 16, 5, !MAGICUSED_X, !MAGICUSED_Y)
%AddStat(BonkCounter, 0, 0, 08, 3, !BONKS_X, !BONKS_Y)
%AddStat(SaveQuitCounter, 0, 0, 08, 2, !SAVE_AND_QUITS_X, !SAVE_AND_QUITS_Y)
%AddStat(DeathCounter, 0, 0, 08, 2, !DEATHS_X, !DEATHS_Y)
%AddStat(FaerieRevivalCounter, 0, 0, 08, 3, !FAERIE_REVIVALS_X, !FAERIE_REVIVALS_Y)
%AddStat(MenuFrames, 1, 8, 32, 4, !TOTAL_MENU_TIME_X, !TOTAL_MENU_TIME_Y)
%AddStat($7F5038, 1, 0, 32, 4, !TOTAL_LAG_TIME_X, !TOTAL_LAG_TIME_Y)
%AddStat(TotalItemCounter, 0, 0, 16, 3, !COLLECTION_RATE_X, !COLLECTION_RATE_Y)
%AddStat(NMIFrames, 1, 0, 32, 4, !TOTAL_TIME_X, !TOTAL_TIME_Y)