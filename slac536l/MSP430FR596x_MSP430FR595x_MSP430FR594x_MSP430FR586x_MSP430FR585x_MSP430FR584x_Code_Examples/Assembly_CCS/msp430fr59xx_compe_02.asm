; --COPYRIGHT--,BSD_EX
;  Copyright (c) 2012, Texas Instruments Incorporated
;  All rights reserved.
;
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions
;  are met:
;
;  *  Redistributions of source code must retain the above copyright
;     notice, this list of conditions and the following disclaimer.
;
;  *  Redistributions in binary form must reproduce the above copyright
;     notice, this list of conditions and the following disclaimer in the
;     documentation and/or other materials provided with the distribution.
;
;  *  Neither the name of Texas Instruments Incorporated nor the names of
;     its contributors may be used to endorse or promote products derived
;     from this software without specific prior written permission.
;
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
;  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
;  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
;  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
;  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
;  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
;  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
; ******************************************************************************
;
;                        MSP430 CODE EXAMPLE DISCLAIMER
;
;  MSP430 code examples are self-contained low-level programs that typically
;  demonstrate a single peripheral function or device feature in a highly
;  concise manner. For this the code may rely on the device's power-on default
;  register values and settings such as the clock configuration and care must
;  be taken when combining code from several examples to avoid potential side
;  effects. Also see www.ti.com/grace for a GUI- and www.ti.com/msp430ware
;  for an API functional library-approach to peripheral configuration.
;
; --/COPYRIGHT--
;******************************************************************************
; MSP430FR59xx Demo - COMPE output Toggle in LPM4; input channel CE12;
;                     Vcompare is compared against internal 2.0V reference
;
; Description: Use CompE and internal reference to determine if input'Vcompare'
; is high or low.  When Vcompare exceeds 2.0V CEOUT goes high and when Vcompare
; is less than 2.0V then CEOUT goes low.
;
;                MSP430FR5969
;             ------------------
;         /|\|                  |
;          | |                  |
;          --|RST      P3.0/CE12|<--Vcompare
;            |                  |
;            |        P3.5/CEOUT|----> 'high'(Vcompare>2.0V); 'low'(Vcompare<2.0V)
;            |                  |
;
;   E. Chen
;   Texas Instruments Inc.
;   October 2013
;   Built with Code Composer Studio V5.5
;******************************************************************************
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .global _main
            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

_main
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
SetupGPIO   bis.b   #BIT5,&P3DIR            ; P3.5 output direction
            bis.b   #BIT5,&P3SEL1           ; Select CEOUT function on P3.5/CEOUT

UnlockGPIO  bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default
                                            ; high-impedance mode to activate
                                            ; previously configured port settings

SetupCOMPE  mov.w   #CEIPEN+CEIPSEL_12,&CECTL0 ; Enable V+, input channel CE12
            mov.w   #CEPWRMD_1,&CECTL1      ; Set DCO to 1MHz
            mov.w   #CEREFL_2+CERS_3+CERSEL,&CECTL2 ; VREF is applied to -terminal
                                            ; R-ladder off; bandgap ref voltage
                                            ; supplied to ref amplifier to get Vcref=2.0V

            mov.w   #BITC,&CECTL3           ; Input Buffer Disable @P3.0CE12
            bis.w   #CEON,&CECTL1           ; Turn On Comparator_E

Wait        mov.w   #0x015,R15              ; Delay to R15 ~75 CPU cycles
L1          dec.w   R15                     ; Decrement R15
            jne     L1                      ; Delay over?
            bis.w   #LPM4,SR                ; Enter LPM4
            nop

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            .end
