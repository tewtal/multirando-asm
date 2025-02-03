OWSmithAccept:
{
    lda.l FollowerIndicator : cmp.b #$07 : beq +
    cmp.b #$08 : beq +
        clc : rtl
    + sec : rtl
}