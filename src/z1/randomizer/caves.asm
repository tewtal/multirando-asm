LoadCaveShopItems_extended:
    phx
    tyx
    lda.l CaveShopItems_extended, x : sta.w CaveItemTemp
    lda.l CaveShopFlags_extended, x : sta.w CaveItemTempFlags
    lda.l CaveShopPrices_extended, x : sta.w CaveItemTempPrice
    plx
    
    lda.w CaveItemTemp : sta.w $0422, x
    lda.w CaveItemTempFlags : sta.b $00, x
    lda.w CaveItemTempPrice : sta.w $0430, x
    rtl
