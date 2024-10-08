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
;  MSP430FR59xx Demo - Timer0_A3 Capture of VLO Period using DCO SMCLK
;
;  Description; Capture a number of periods of the VLO clock and store them in an array.
;  When the set number of periods is captured the program is trapped and the LED on
;  P1.0 is toggled. At this point halt the program execution read out the values using
;  the debugger.
;  ACLK = VLOCLK = 9.4kHz (typ.), MCLK = SMCLK = default DCO / default divider = 1MHz
;
;            MSP430FR58xxFR59xx
;             -----------------
;         /|\|              XIN|-
;          | |                 |
;          --|RST          XOUT|-
;            |                 |
;            |             P1.0|-->LED
;
;  E. Chen
;  Texas Instruments, Inc
;  October 2013
;  Built with Code Composer Studio V5.5
;******************************************************************************
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
TACapPtr    .set    R5
timerAcaptureValues .usect ".bss",20
;-------------------------------------------------------------------------------
            .global _main
            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

_main
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop watchdog timer
SetupGPIO   bic.b   #BIT0,&P1OUT            ; Clear P1.0 output
            bis.b   #BIT0,&P1DIR            ; Set P1.0 output direction

UnlockGPIO  bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default
                                            ; high-impedance mode to activate
                                            ; previously configured port settings

SetupCS     mov.b   #CSKEY_H,&CSCTL0_H      ; Unlock CS registers
            bic.w   #SELA_7,&CSCTL2
            bis.w   #SELA__VLOCLK,CSCTL2    ; Select ACLK=VLOCLK
            clr.b   &CSCTL0_H               ; Lock CS registers

            mov.w   #0x014a,R15
Delay1      dec.w   R15                     ; Allow clock system to settle
            jnz     Delay1

SetupTA0    mov.w   #CM_1+CCIS_1+SCS+CAP+CCIE,&TA0CCTL2 ; Capture rising edge,
                                            ; Use CCI2B=ACLK,
                                            ; Synchronous capture,
                                            ; Enable capture mode,
                                            ; Enable capture interrupt
            mov.w   #TASSEL__SMCLK+MC__CONTINUOUS,&TA0CTL ; Use SMCLK as clock source,
                                            ; Start timer in continuous mode
            clr.w   TACapPtr
            mov.w   #timerAcaptureValues,R8
            nop                             ; 
            bis.w   #LPM0+GIE,SR            ; Enter LPM0 w/ interrupts
            nop                             ; for debugger

;-------------------------------------------------------------------------------
TIMER0_A1_ISR;    Timer0_A3 CC1-2 Interrupt Service Routine
;-------------------------------------------------------------------------------
            add.w   &TA0IV,PC               ; add offset to PC
            reti                            ; Vector  0:  No interrupt
            reti                            ; Vector  2:  CCR1 not used
            jmp     Capture                 ; Vector  4:  CCR2 not used
            reti                            ; Vector  6:  reserved
            reti                            ; Vector  8:  reserved
            reti                            ; Vector 10:  reserved
            reti                            ; Vector 12:  reserved
            reti                            ; Vector 14:  overflow
Capture     mov.w   &TA0CCR2, 0(R8)
            incd.w  R8

            inc.b   TACapPtr
            cmp.b   #20,TACapPtr
            jhs     ToggleLED
            reti
ToggleLED   xor.b   #BIT0,&P1OUT            ; Toggle LED P1.0
            mov.w   #0x8232,R15
Delay2      dec.w   R15                     ; Allow clock system to settle
            jnz     Delay2
            jmp     ToggleLED
            reti
;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET                   ;
            .sect   TIMER0_A1_VECTOR        ; Timer0_A3 CC1-2 Interrupt Vector
            .short  TIMER0_A1_ISR           ;
            .end
