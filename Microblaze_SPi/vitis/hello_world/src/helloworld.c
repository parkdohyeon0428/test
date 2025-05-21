#include <sleep.h>
#include <stdio.h>
#include "platform.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "sleep.h" // 딜레이 주는거

#define SPI_BASEADDR 0x44A10000U

typedef struct {
   volatile uint32_t CR;   // Control Register: [2]=START, [1]=CPHA, [0]=CPOL
   volatile uint32_t SOD;  // MOSI
   volatile uint32_t SID;  // MISO
   volatile uint32_t SR;   // [1]=ready, [0]=done
} SPI_typedef;

#define GPSPI ((SPI_typedef*) SPI_BASEADDR)

int main()
{
    init_platform();

    uint32_t tx_data = 0xaa;   // 보낼 데이터
    uint32_t rx_data = 0;

    xil_printf("SPI Matching Test Start\r\n");

    // Step 1: 송신할 데이터 설정
    GPSPI->SOD = tx_data;
    xil_printf("SOD <- 0x%02X \r\n", tx_data);
    usleep(100);

    // Step 2: START = 1
    GPSPI->CR = 0b100;
    xil_printf("CD <- START=1 (0b100)\r\n");


    // Step 3: START = 0
    GPSPI->CR = 0;
    xil_printf("CD <- START=0 (0b000)\r\n");

    //usleep(803);

    // Step 4: DONE=1 될 때까지 대기
    //xil_printf("Waiting for DONE...\r\n");
    //while ((GPSPI->SR & (1<<0)) == 0);  // SR[0] == done
    //printf("SID: %c\n", GPSPI->SID);
    while((GPSPI->SR) == 2);
	xil_printf("ready received!\r\n");

    // Step 5: 수신 데이터 확인
    while((rx_data = GPSPI->SID) == 0xaa);
    xil_printf("SID -> 0x%02X \r\n", rx_data);

    // Step 6: 일치 비교
    if (rx_data == tx_data) {
        xil_printf("Match! SPI 전송 성공\r\n");
    } else {
        xil_printf("Mismatch! SPI 수신 실패\r\n");
    }

    cleanup_platform();
    return 0;
}
