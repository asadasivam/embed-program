//******************************************************************************
//   MSP430FR59xx Demo - eUSCI_A0, SPI 3-Wire Slave multiple byte RX/TX
//
//   Description: SPI master communicates to SPI slave sending and receiving
//   3 different messages of different length. SPI slave will enter LPM0
//   while waiting for the messages to be sent/receiving using SPI interrupt.
//   ACLK = NA, MCLK = SMCLK = DCO 16MHz.
//
//
//                   MSP430FR5969
//                 -----------------
//            /|\ |             P1.3|<- Master's GPIO (Chip Select)
//             |  |                 |
//             ---|RST          RST |<- Master's GPIO (To reset slave)
//                |                 |
//                |             P2.0|<- Data In (UCA0SIMO)
//                |                 |
//                |             P2.1|-> Data Out (UCA0SOMI)
//                |                 |
//                |             P1.5|<- Serial Clock In (UCA0CLK)
//
//   Nima Eskandari
//   Texas Instruments Inc.
//   April 2017
//   Built with CCS V7.0
//******************************************************************************

#include <msp430.h> 
#include <stdint.h>
#include <stdbool.h>

//******************************************************************************
// Example Commands ************************************************************
//******************************************************************************

#define DUMMY   0xFF

#define SLAVE_CS_IN     P1IN
#define SLAVE_CS_DIR    P1DIR
#define SLAVE_CS_PIN    BIT3

/* CMD_TYPE_X_SLAVE are example commands the master sends to the slave.
 * The slave will send example SlaveTypeX buffers in response.
 *
 * CMD_TYPE_X_MASTER are example commands the master sends to the slave.
 * The slave will initialize itself to receive MasterTypeX example buffers.
 * */

#define CMD_TYPE_0_SLAVE              0
#define CMD_TYPE_1_SLAVE              1
#define CMD_TYPE_2_SLAVE              2

#define CMD_TYPE_0_MASTER              3
#define CMD_TYPE_1_MASTER              4
#define CMD_TYPE_2_MASTER              5

#define TYPE_0_LENGTH              1
#define TYPE_1_LENGTH              2
#define TYPE_2_LENGTH              6

#define MAX_BUFFER_SIZE     20

/* MasterTypeX are example buffers initialized in the master, they will be
 * sent by the master to the slave.
 * SlaveTypeX are example buffers initialized in the slave, they will be
 * sent by the slave to the master.
 * */

uint8_t MasterType2 [TYPE_2_LENGTH] = {0};
uint8_t MasterType1 [TYPE_1_LENGTH] = { 0, 0};
uint8_t MasterType0 [TYPE_0_LENGTH] = { 0};

uint8_t SlaveType2 [TYPE_2_LENGTH] = {'A', 'B', 'C', 'D', '1', '2'};
uint8_t SlaveType1 [TYPE_1_LENGTH] = {0x15, 0x16};
uint8_t SlaveType0 [TYPE_0_LENGTH] = {12};

//******************************************************************************
// General SPI State Machine ***************************************************
//******************************************************************************

typedef enum SPI_ModeEnum{
    IDLE_MODE,
    TX_REG_ADDRESS_MODE,
    RX_REG_ADDRESS_MODE,
    TX_DATA_MODE,
    RX_DATA_MODE,
    TIMEOUT_MODE
} SPI_Mode;

/* Used to track the state of the software state machine*/
SPI_Mode SlaveMode = RX_REG_ADDRESS_MODE;

/* The Register Address/Command to use*/
uint8_t ReceiveRegAddr = 0;

/* ReceiveBuffer: Buffer used to receive data in the ISR
 * RXByteCtr: Number of bytes left to receive
 * ReceiveIndex: The index of the next byte to be received in ReceiveBuffer
 * TransmitBuffer: Buffer used to transmit data in the ISR
 * TXByteCtr: Number of bytes left to transfer
 * TransmitIndex: The index of the next byte to be transmitted in TransmitBuffer
 * */
uint8_t ReceiveBuffer[MAX_BUFFER_SIZE] = {0};
uint8_t RXByteCtr = 0;
uint8_t ReceiveIndex = 0;
uint8_t TransmitBuffer[MAX_BUFFER_SIZE] = {0};
uint8_t TXByteCtr = 0;
uint8_t TransmitIndex = 0;

/* Initialized the software state machine according to the received cmd
 *
 * cmd: The command/register address received
 * */
void SPI_Slave_ProcessCMD(uint8_t cmd);

/* The transaction between the slave and master is completed. Uses cmd
 * to do post transaction operations. (Place data from ReceiveBuffer
 * to the corresponding buffer based in the last received cmd)
 *
 * cmd: The command/register address corresponding to the completed
 * transaction
 */
void SPI_Slave_TransactionDone(uint8_t cmd);
void CopyArray(uint8_t *source, uint8_t *dest, uint8_t count);
void SendUCA0Data(uint8_t val);

void SendUCA0Data(uint8_t val)
{
    while (!(UCA0IFG & UCTXIFG));              // USCI_A0 TX buffer ready?
    UCA0TXBUF = val;
}

void SPI_Slave_ProcessCMD(uint8_t cmd)
{
    ReceiveIndex = 0;
    TransmitIndex = 0;
    RXByteCtr = 0;
    TXByteCtr = 0;

    switch (cmd)
    {
        case (CMD_TYPE_0_SLAVE):                        //Send slave device id (This device's id)
            SlaveMode = TX_DATA_MODE;
            TXByteCtr = TYPE_0_LENGTH;
            //Fill out the TransmitBuffer
            CopyArray(SlaveType0, TransmitBuffer, TYPE_0_LENGTH);
            //Send First Byte
            SendUCA0Data(TransmitBuffer[TransmitIndex++]);
            TXByteCtr--;
            break;
        case (CMD_TYPE_1_SLAVE):                      //Send slave device time (This device's time)
            SlaveMode = TX_DATA_MODE;
            TXByteCtr = TYPE_1_LENGTH;
            //Fill out the TransmitBuffer
            CopyArray(SlaveType1, TransmitBuffer, TYPE_1_LENGTH);
            //Send First Byte
            SendUCA0Data(TransmitBuffer[TransmitIndex++]);
            TXByteCtr--;
            break;
        case (CMD_TYPE_2_SLAVE):                  //Send slave device location (This device's location)
            SlaveMode = TX_DATA_MODE;
            TXByteCtr = TYPE_2_LENGTH;
            //Fill out the TransmitBuffer
            CopyArray(SlaveType2, TransmitBuffer, TYPE_2_LENGTH);
            //Send First Byte
            SendUCA0Data(TransmitBuffer[TransmitIndex++]);
            TXByteCtr--;
            break;
        case (CMD_TYPE_0_MASTER):
            SlaveMode = RX_DATA_MODE;
            RXByteCtr = TYPE_0_LENGTH;
            break;
        case (CMD_TYPE_1_MASTER):
            SlaveMode = RX_DATA_MODE;
            RXByteCtr = TYPE_1_LENGTH;
            break;
        case (CMD_TYPE_2_MASTER):
            SlaveMode = RX_DATA_MODE;
            RXByteCtr = TYPE_2_LENGTH;
            break;
        default:
            //while(1);
            __no_operation();
            break;
    }
}


void SPI_Slave_TransactionDone(uint8_t cmd)
{
    switch (cmd)
    {
        case (CMD_TYPE_0_SLAVE):                        //Slave device id was sent(This device's id)
            break;
        case (CMD_TYPE_1_SLAVE):                      //Slave device time was sent(This device's time)
            break;
        case (CMD_TYPE_2_SLAVE):                  //Send slave device location (This device's location)
            break;
        case (CMD_TYPE_0_MASTER):
            CopyArray(ReceiveBuffer, MasterType0, TYPE_0_LENGTH);
            break;
        case (CMD_TYPE_1_MASTER):
            CopyArray(ReceiveBuffer, MasterType1, TYPE_1_LENGTH);
            break;
        case (CMD_TYPE_2_MASTER):
            CopyArray(ReceiveBuffer, MasterType2, TYPE_2_LENGTH);
            break;
        default:
            __no_operation();
            break;
    }
}

void CopyArray(uint8_t *source, uint8_t *dest, uint8_t count)
{
    uint8_t copyIndex = 0;
    for (copyIndex = 0; copyIndex < count; copyIndex++)
    {
        dest[copyIndex] = source[copyIndex];
    }
}

//******************************************************************************
// Device Initialization *******************************************************
//******************************************************************************

void initSPI()
{
    //Clock Polarity: The inactive state is high
    //MSB First, 8-bit, Master, 3-pin mode, Synchronous
    UCA0CTLW0 = UCSWRST;                       // **Put state machine in reset**
    UCA0CTLW0 |= UCCKPL + UCMSB + UCSYNC;      // 3-pin, 8-bit SPI Slave
    UCA0CTLW0 &= ~UCSWRST;                     // **Initialize USCI state machine**
    UCA0IE |= UCRXIE;                          // Enable USCI0 RX interrupt

}

void initGPIO()
{
    //LEDs
    P1OUT = 0x00;                             // P1 setup for LED & reset output
    P1DIR |= BIT0;

    // Configure GPIO
    P1SEL1 |= BIT5;                           // Configure SPI pins
    P2SEL1 |= BIT0 | BIT1;

    SLAVE_CS_DIR &= ~(SLAVE_CS_PIN);

    // Disable the GPIO power-on default high-impedance mode to activate
    // previously configured port settings
    PM5CTL0 &= ~LOCKLPM5;
}

void initClockTo16MHz()
{
    // Configure one FRAM waitstate as required by the device datasheet for MCLK
    // operation beyond 8MHz _before_ configuring the clock system.
    FRCTL0 = FRCTLPW | NWAITS_1;

    // Clock System Setup
    CSCTL0_H = CSKEY >> 8;                    // Unlock CS registers
    CSCTL1 = DCORSEL | DCOFSEL_4;             // Set DCO to 16MHz
    CSCTL2 = SELA__VLOCLK | SELS__DCOCLK | SELM__DCOCLK;
    CSCTL3 = DIVA__1 | DIVS__1 | DIVM__1;     // Set all dividers

    CSCTL0_H = 0;                             // Lock CS registerss
}


//******************************************************************************
// Main ************************************************************************
// Enters LPM0 and waits for SPI interrupts. The data sent from the master is  *
// then interpreted and the device will respond accordingly                    *
//******************************************************************************

int main(void) {
    WDTCTL = WDTPW | WDTHOLD;	// Stop watchdog timer

    initClockTo16MHz();
    initGPIO();
    initSPI();


    __bis_SR_register(LPM0_bits + GIE);                 // Enter LPM0, enable interrupts
    __no_operation();
    return 0;
}

//******************************************************************************
// SPI Interrupt ***************************************************************
//******************************************************************************

#if defined(__TI_COMPILER_VERSION__) || defined(__IAR_SYSTEMS_ICC__)
#pragma vector=USCI_A0_VECTOR
__interrupt void USCI_A0_ISR(void)
#elif defined(__GNUC__)
void __attribute__ ((interrupt(USCI_A0_VECTOR))) USCI_A0_ISR (void)
#else
#error Compiler not supported!
#endif
{
    uint8_t uca0_rx_val = 0;
    switch(__even_in_range(UCA0IV, USCI_SPI_UCTXIFG))
    {
        case USCI_NONE: break;
        case USCI_SPI_UCRXIFG:
            uca0_rx_val = UCA0RXBUF;
            UCA0IFG &= ~UCRXIFG;
            if (!(SLAVE_CS_IN & SLAVE_CS_PIN))
            {
                switch (SlaveMode)
                {
                    case (RX_REG_ADDRESS_MODE):
                        ReceiveRegAddr = uca0_rx_val;
                        SPI_Slave_ProcessCMD(ReceiveRegAddr);
                        break;
                    case (RX_DATA_MODE):
                        ReceiveBuffer[ReceiveIndex++] = uca0_rx_val;
                        RXByteCtr--;
                        if (RXByteCtr == 0)
                        {
                          //Done Receiving MSG
                          SlaveMode = RX_REG_ADDRESS_MODE;
                          SPI_Slave_TransactionDone(ReceiveRegAddr);
                        }
                        break;
                    case (TX_DATA_MODE):
                        if (TXByteCtr > 0)
                        {
                          SendUCA0Data(TransmitBuffer[TransmitIndex++]);
                          TXByteCtr--;
                        }
                        if (TXByteCtr == 0)
                        {
                          //Done Transmitting MSG
                          SlaveMode = RX_REG_ADDRESS_MODE;
                          SPI_Slave_TransactionDone(ReceiveRegAddr);
                        }
                        break;
                    default:
                      __no_operation();
                      break;
                }
            }
            break;
        case USCI_SPI_UCTXIFG:
            break;
        default: break;
    }
}
