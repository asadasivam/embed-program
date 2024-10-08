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
;   MSP430FR59xx Demo - Configure MCLK for 16MHz operation
;
;   Description: Configure SMCLK = MCLK = 16MHz, ACLK = VLOCLK
;   IMPORTANT NOTE: While the FR59xx is capable of operation w/ MCLK = 16MHz
;   the throughput of the device is dependent on accesses to FRAM.
;   The maximum speed for accessing FRAM is limited to 8MHz and it is required
;   to manually configure a waitstate for MCLK frequencies beyond 8MHz. Refer
;   to the FRCTL chapter of the User's Guide for further information.
;
;           MSP430FR5969
;         ---------------
;     /|\|               |
;      | |               |
;      --|RST            |
;        |               |
;        |           P1.0|---> LED
;        |           P2.0|---> ACLK = ~9.4kHz
;        |           P3.4|---> SMCLK = MCLK = 16MHz
;
;   Tyler Witt/ P. Thanigai
;   Texas Instruments Inc.
;   August 2012
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
SetupGPIO   bic.b   #BIT0,&P1OUT            ; Clear P1.0 output latch for a defined power-on state
            bis.b   #BIT0,&P1DIR            ; Set P1.0 to output direction

            bis.b   #BIT0,&P2DIR
            bis.b   #BIT0,&P2SEL0           ; Output ACLK
            bis.b   #BIT0,&P2SEL1

            clr.b   &P3OUT                  ; Output SMCLK
            bis.b   #BIT4,&P3DIR
            bis.b   #BIT4,&P3SEL1
UnlockGPIO  bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default
                                            ; high-impedance mode to activate
                                            ; previously configured port settings
SetupFRCTL  mov.w   #FRCTLPW|NWAITS_1,&FRCTL0  ; Configure one FRAM waitstate
                                            ; as required by the device datasheet
                                            ; for MCLK operation beyond 8MHz
                                            ; _before_ configuring the clock system.
SetupCS     mov.b   #CSKEY_H,&CSCTL0_H      ; Unlock CS registers
            mov.w   #DCORSEL+DCOFSEL_4,&CSCTL1 ; Set max DCO setting
            mov.w   #SELA__VLOCLK+SELS__DCOCLK+SELM__DCOCLK,&CSCTL2  ; SMCLK = MCLK = DCO
                                            ; ACLK = VLOCLK
            mov.w   #DIVA__1+DIVS__1+DIVM__1,&CSCTL3  ; set all dividers
            clr.b   &CSCTL0_H               ; Lock CS registers

Mainloop    xor.b   #BIT0,P1OUT             ; Toggle LED
            pushm.a #2, R14
            mov.w   #0x48fc,R13
            mov.w   #0x003c,R14
Wait        dec.w   R13                     ; Wait ~16,000,000 CPU Cycles
            sbc.w   R14
            jne     Wait
            tst.w   R13
            jne     Wait
            popm.a  #2, R14
            jmp     Mainloop                ; endless loop
            nop                             ; for debug

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET                   ;
            .end
