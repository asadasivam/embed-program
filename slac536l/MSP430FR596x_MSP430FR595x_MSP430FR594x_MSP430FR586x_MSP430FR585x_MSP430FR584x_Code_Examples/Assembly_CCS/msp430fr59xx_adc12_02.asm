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
;  MSP430FR59xx Demo - ADC12, Sample A1, 1.2V Shared Ref, Set P1.0 if A1 > 0.5V
;
;  Description: A single sample is made on A1 with reference to internal
;  1.2V Vref. Software sets ADC12SC to start sample and conversion - ADC10SC
;  automatically cleared at EOC. ADC12 internal oscillator times sample (16x)
;  and conversion. In Mainloop MSP430 waits in LPM0 to save power until ADC10
;  conversion complete, ADC12_ISR will force exit from LPM0 in Mainloop on
;  reti. If A1 > 0.5V, P1.0 set, else reset.
;
;                MSP430FR5969
;             -----------------
;         /|\|              XIN|-
;          | |                 |
;          --|RST          XOUT|-
;            |                 |
;        >---|P1.1/A1      P1.0|-->LED
;
;   William Goh
;   Texas Instruments Inc.
;   February 2014
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
SetupGPIO   bic.b   #BIT0,&P1OUT            ; Clear LED to start
            bis.b   #BIT0,&P1DIR            ; P1.0 output
            bis.b   #BIT1,&P1SEL0           ;
            bis.b   #BIT1,&P1SEL1           ;
UnlockGPIO  bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default
                                            ; high-impedance mode to activate
                                            ; previously configured port settings

SetVREF     bit.w   #REFGENBUSY,&REFCTL0    ; Is ref gen busy?
            jnz     SetVREF                 ; Yes, wait. No, set ref
            mov.w   #REFVSEL_0+REFON,&REFCTL0 ; Select internal ref = 1.5V
                                            ; Internal Reference ON
SetupADC12  mov.w   #ADC12SHT0_2+ADC12ON,&ADC12CTL0 ; 16x
            mov.w   #ADC12SHP,&ADC12CTL1    ; ADCCLK = MODOSC; sampling timer
            bis.w   #ADC12RES_2,&ADC12CTL2  ; 12-bit conversion results
            bis.w   #ADC12IE0,&ADC12IER0    ; Enable ADC conv complete interrupt
            bis.w   #ADC12INCH_1+ADC12VRSEL_1,&ADC12MCTL0 ; A1 ADC input select; Vref=1.2V
                                            ;
REFSettle   bit.w   #REFGENRDY,&REFCTL0     ; Wait for reference generator
            jz      REFSettle               ; to settle
                                            ;
Mainloop    mov.w   #2500,R15               ; Delay ~5000 cycles between conversions
L1          dec.w   R15                     ; Decrement R15
            jnz     L1                      ; Delay over?
            bis.w   #ADC12ENC+ADC12SC,&ADC12CTL0 ; Start sampling/conversion
            nop                             ; 
            bis.w   #LPM0+GIE,SR            ; Enter LPM0 w/ interrupt
            nop                             ; for debug
            jmp     Mainloop                ; Again
            nop

;-------------------------------------------------------------------------------
ADC12_ISR;  ADC12 interrupt service routine
;-------------------------------------------------------------------------------
            add.w   &ADC12IV,PC             ; add offset to PC
            reti                            ; Vector  0:  No interrupt
            reti                            ; Vector  2:  ADC12MEMx Overflow
            reti                            ; Vector  4:  Conversion time overflow
            reti                            ; Vector  6:  ADC12HI
            reti                            ; Vector  8:  ADC12LO
            reti                            ; Vector 10:  ADC12IN
            jmp     MEM0                    ; Vector 12:  ADC12MEM0 Interrupt
            reti                            ; Vector 14:  ADC12MEM1
            reti                            ; Vector 16:  ADC12MEM2
            reti                            ; Vector 18:  ADC12MEM3
            reti                            ; Vector 20:  ADC12MEM4
            reti                            ; Vector 22:  ADC12MEM5
            reti                            ; Vector 24:  ADC12MEM6
            reti                            ; Vector 26:  ADC12MEM7
            reti                            ; Vector 28:  ADC12MEM8
            reti                            ; Vector 30:  ADC12MEM9
            reti                            ; Vector 32:  ADC12MEM10
            reti                            ; Vector 34:  ADC12MEM11
            reti                            ; Vector 36:  ADC12MEM12
            reti                            ; Vector 38:  ADC12MEM13
            reti                            ; Vector 40:  ADC12MEM14
            reti                            ; Vector 42:  ADC12MEM15
            reti                            ; Vector 44:  ADC12MEM16
            reti                            ; Vector 46:  ADC12MEM17
            reti                            ; Vector 48:  ADC12MEM18
            reti                            ; Vector 50:  ADC12MEM19
            reti                            ; Vector 52:  ADC12MEM20
            reti                            ; Vector 54:  ADC12MEM21
            reti                            ; Vector 56:  ADC12MEM22
            reti                            ; Vector 58:  ADC12MEM23
            reti                            ; Vector 60:  ADC12MEM24
            reti                            ; Vector 62:  ADC12MEM25
            reti                            ; Vector 64:  ADC12MEM26
            reti                            ; Vector 66:  ADC12MEM27
            reti                            ; Vector 68:  ADC12MEM28
            reti                            ; Vector 70:  ADC12MEM29
            reti                            ; Vector 72:  ADC12MEM30
            reti                            ; Vector 74:  ADC12MEM31
            reti                            ; Vector 76:  ADC12RDY
MEM0        bic.b   #BIT0,&P1OUT            ; Clear LED as default
            cmp.w   #0x6B4,&ADC12MEM0       ; ADCMEM > 0.5V?
            jlo     ExitLPM0                ; No, exit ISR
            bis.b   #BIT0,&P1OUT            ; Yes, set LED
ExitLPM0    bic.w   #LPM0,0(SP)             ; Exit
            reti

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   ".reset"                    ; MSP430 RESET Vector
            .short  RESET                       ;
            .sect   ADC12_VECTOR                ; ADC12 Vector
            .short  ADC12_ISR                   ;
            .end
