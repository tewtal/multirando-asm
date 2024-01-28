    WavyIce_NewBehavior:
        LDA $6878    ; Check equipment
        AND #$40     ; Has wave?
        BEQ @NoWave
        JMP $D52C    ; Yes: UpdateWaveBullet
        ;(normally UpdateWaveBullet isn't called when you have ice, even if you do have wave)

        @NoWave:
        JMP $D4EB    ; No: UpdateBullet
        

    WavyIce_NewDamage:
        ; Y: Weapon type
        ;   1 = Normal
        ;   2 = Wave
        ;   3 = Ice or Wavy-ice
        ;   A = Bomb
        ;   B = Missile (I think)
        ; X: Enemy index
        ; 40B,X: enemy health

        LDY $040E,X        ; Get projectile that hit enemy
        LDA $6878          ; Get current equipment

        CPY #$03           ; If Ice...
        BNE @NotIce

        @Ice:
        AND #$C0           ;     Does the player have wave and ice beams?
        BNE Damage4        ;     If so, 4 damage
        BEQ Damage2        ;     Else, 2 damage

        @NotIce:
        ; Includes vanilla-beam, bomb, wave, and missile
        CPY #$0A           ; Bomb = 2 Damage (was 4 Damage in original wavy ice, but this is a bit much)
        BEQ Damage2
        CPY #$02           ; Wave = 2 Damage
        BEQ Damage2

        BIT $0A            ; Not-a-boss = 1 Damage
        BVC Damage1

    IsABoss:
        CPY #$0B           ; Vanilla-beam = 1 damage
        BNE Damage1        ; (missile will fall thru and do 4 damage)

    Damage4:
        DEC $040B,X
        BEQ exitRoutine
    Damage3:
        DEC $040B,X
        BEQ exitRoutine
    Damage2:
        DEC $040B,X
        BEQ exitRoutine
    Damage1:
        DEC $040B,X

    exitRoutine:
        ; Return to F60F (this is the code that checks if enemies has
        ; 0 HP and if so, kills him)
        JMP $F60F        
        
    endOfRAMCode:
        .if endOfRAMCode > $7F00
            .error Too much code in RAMp9\
        .endif
        