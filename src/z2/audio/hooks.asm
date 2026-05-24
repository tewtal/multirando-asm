optimize address ram

!B0 = ((!BASE_BANK)<<16)
!B5 = ((!BASE_BANK+$5)<<16)
!B6 = ((!BASE_BANK+$6)<<16)
!B7 = ((!BASE_BANK+$7)<<16)

;  Hooks for ends of the sound routines
org !B6+$8010 : jsr AudioRoutine1 : rts
org !B6+$9022 : jsr AudioRoutine2 : rts

;  Hooks for short-circuited status writes that skip AudioRoutineX hooks
org !B6+$9006 : jsr AudioShortCircuitedStatus_WriteA

;  APU control calls
org !B5+$A6B3 : jsr Apu_Control_WriteA
org !B5+$b3ed : jsr Apu_Control_WriteA
org !B6+$8007 : jsr Apu_Control_WriteA
org !B6+$9261 : jsr Apu_Control_WriteA
org !B6+$9292 : jsr Apu_Control_WriteA
org !B6+$9298 : jsr Apu_Control_WriteA
org !B6+$92b9 : jsr Apu_Control_WriteX
org !B6+$985a : jsr Apu_Control_WriteA

;  Frame counter calls
org !B6+$8002 : jsr Apu_FrameCounter_WriteA
org !B6+$900D : jsr Apu_FrameCounter_WriteA

;  Square wave 0 calls
org !B6+$810f : jsr Sq0_Duty_WriteX
org !B6+$820e : jsr Sq0_Duty_WriteA
org !B6+$8250 : jsr Sq0_Duty_WriteA
org !B6+$82a6 : jsr Sq0_Duty_WriteX
org !B6+$9031 : jsr Sq0_Duty_WriteX
org !B6+$92b1 : jsr Sq0_Duty_WriteX
org !B6+$935c : jsr Sq0_Duty_WriteA
org !B6+$9367 : jsr Sq0_Duty_WriteA
org !B6+$93aa : jsr Sq0_Duty_WriteA
org !B6+$9479 : jsr Sq0_Duty_WriteA
org !B6+$9495 : jsr Sq0_Duty_WriteA
org !B6+$97ac : jsr Sq0_Duty_WriteA
org !B6+$980e : jsr Sq0_Duty_WriteA
org !B6+$9870 : jsr Sq0_Duty_WriteA
org !B6+$98dc : jsr Sq0_Duty_WriteA
org !B6+$98f5 : jsr Sq0_Duty_WriteA
org !B6+$99c8 : jsr Sq0_Duty_WriteA
org !B6+$9acb : jsr Sq0_Duty_WriteA
org !B6+$9b45 : jsr Sq0_Duty_WriteA
org !B7+$CF83 : jsr Sq0_Duty_WriteY

org !B6+$8112 : jsr Sq0_Sweep_WriteY
org !B6+$8243 : jsr Sq0_Sweep_WriteA
org !B6+$9034 : jsr Sq0_Sweep_WriteY
org !B6+$9349 : jsr Sq0_Sweep_WriteA
org !B6+$97e9 : jsr Sq0_Sweep_WriteA
org !B6+$989b : jsr Sq0_Sweep_WriteA
org !B6+$98d1 : jsr Sq0_Sweep_WriteA
org !B6+$99f3 : jsr Sq0_Sweep_WriteA
org !B6+$9a29 : jsr Sq0_Sweep_WriteA
org !B6+$9a51 : jsr Sq0_Sweep_WriteA
org !B6+$9a79 : jsr Sq0_Sweep_WriteA

org !B6+$8128 : jsr Sq0_Timer_WriteXIndexed
org !B6+$8188 : jsr Sq0_Timer_WriteXIndexed
org !B6+$81e7 : jsr Sq0_Timer_WriteA
org !B6+$8256 : jsr Sq0_Timer_WriteA
org !B6+$904a : jsr Sq0_Timer_WriteXIndexed
org !B6+$90b1 : jsr Sq0_Timer_WriteXIndexed
org !B6+$9398 : jsr Sq0_Timer_WriteX
org !B6+$945f : jsr Sq0_Timer_WriteA
org !B6+$98ac : jsr Sq0_Timer_WriteA
org !B6+$9a04 : jsr Sq0_Timer_WriteA
org !B6+$9ac7 : jsr Sq0_Timer_WriteA

org !B6+$8140 : jsr Sq0_Length_WriteXIndexed
org !B6+$81f8 : jsr Sq0_Length_WriteA
org !B6+$8261 : jsr Sq0_Length_WriteA
org !B6+$9060 : jsr Sq0_Length_WriteXIndexed
org !B6+$939b : jsr Sq0_Length_WriteA
org !B6+$946a : jsr Sq0_Length_WriteA
org !B6+$98b2 : jsr Sq0_Length_WriteA
org !B6+$9a0a : jsr Sq0_Length_WriteA
org !B6+$9abf : jsr Sq0_Length_WriteA

; sta $40[$00 -> $15] : 8d [00] 40  ; vary [] param up to $15
; sta $40[$00 -> $15],x : 9d [00] 40
; stx $40[$00 -> $15] : 8e [00] 40
; sty $40[$00 -> $15] : 8c [00] 40

;  Square wave 1 calls
org !B6+$8116 : jsr Sq1_Duty_WriteX
org !B6+$8211 : jsr Sq1_Duty_WriteA
org !B6+$8253 : jsr Sq1_Duty_WriteA
org !B6+$82a9 : jsr Sq1_Duty_WriteX
org !B6+$9038 : jsr Sq1_Duty_WriteX
org !B6+$947c : jsr Sq1_Duty_WriteA
org !B6+$94da : jsr Sq1_Duty_WriteA
org !B6+$94e9 : jsr Sq1_Duty_WriteA
org !B6+$9548 : jsr Sq1_Duty_WriteA
org !B6+$9b48 : jsr Sq1_Duty_WriteA

org !B6+$8119 : jsr Sq1_Sweep_WriteY
org !B6+$8246 : jsr Sq1_Sweep_WriteA
org !B6+$903b : jsr Sq1_Sweep_WriteY

org !B6+$81f0 : jsr Sq1_Timer_WriteA
org !B6+$825c : jsr Sq1_Timer_WriteA
org !B6+$9462 : jsr Sq1_Timer_WriteA
org !B6+$94c6 : jsr Sq1_Timer_WriteA

org !B6+$81fb : jsr Sq1_Length_WriteA
org !B6+$8264 : jsr Sq1_Length_WriteA
org !B6+$946D : jsr Sq1_Length_WriteA
org !B6+$94CE : jsr Sq1_Length_WriteA

;  Sq1 but handled by sq0 routines:
; 190B1  9D 02 40       STA Sq0Timer_4002,X
; 19060  9D 03 40       STA Sq0Length_4003,X

;  Triangle calls
org !B6+$829E : jsr Tri_Linear_WriteX
org !B6+$8481 : jsr Tri_Linear_WriteA
org !B6+$8488 : jsr Tri_Linear_WriteA
org !B6+$8498 : jsr Tri_Linear_WriteA
org !B6+$93E1 : jsr Tri_Linear_WriteA
org !B6+$9576 : jsr Tri_Linear_WriteX
org !B6+$9B40 : jsr Tri_Linear_WriteA
org !B6+$9d63 : jsr Tri_Linear_WriteY

;  Triangle but handled by sq0 routines:
; 1904A  9D 02 40       STA Sq0Timer_4002,X (x==08)
; 19060  9D 03 40       STA Sq0Length_4003,X (x==08)

;  Noise calls
org !B6+$82A3 : jsr Noise_Volume_WriteX
org !B6+$84C5 : jsr Noise_Volume_WriteA
org !B6+$92B4 : jsr Noise_Volume_WriteX
org !B6+$93DC : jsr Noise_Volume_WriteA
org !B6+$9593 : jsr Noise_Volume_WriteA
org !B6+$95A3 : jsr Noise_Volume_WriteA
org !B6+$962F : jsr Noise_Volume_WriteA
org !B6+$97D2 : jsr Noise_Volume_WriteA
org !B6+$982E : jsr Noise_Volume_WriteA
org !B6+$98FC : jsr Noise_Volume_WriteA
org !B6+$9B0A : jsr Noise_Volume_WriteA
org !B6+$9B4B : jsr Noise_Volume_WriteA

org !B6+$84CB : jsr Noise_Period_WriteA
org !B6+$95A0 : jsr Noise_Period_WriteX
org !B6+$9625 : jsr Noise_Period_WriteA
org !B6+$9820 : jsr Noise_Period_WriteA
org !B6+$9B00 : jsr Noise_Period_WriteA

org !B6+$84D1 : jsr Noise_Length_WriteA
org !B6+$959d : jsr Noise_Length_WriteY
org !B6+$9634 : jsr Noise_Length_WriteA
org !B6+$9825 : jsr Noise_Length_WriteA
org !B6+$9B0F : jsr Noise_Length_WriteA

;  DMC calls
org !B6+$925C : jsr Dmc_Frequency_WriteA
org !B5+$A6AE : jsr Dmc_Counter_WriteA
org !B6+$9251 : jsr Dmc_Address_WriteA
org !B6+$9257 : jsr Dmc_Length_WriteA
