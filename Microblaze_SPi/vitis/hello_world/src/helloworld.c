/******************************************************************************
 *
 * Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Use of the Software is limited solely to applications:
 * (a) running on a Xilinx device, or
 * (b) that interact with a Xilinx device through a bus or interconnect.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
 * OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Except as contained in this notice, the name of the Xilinx shall not be used
 * in advertising or otherwise to promote the sale, use or other dealings in
 * this Software without prior written authorization from Xilinx.
 *
 ******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <stdint.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h" // 딜레이 주는거


//typedef struct {
//   volatile uint32_t MODER;
//   volatile uint32_t ODR;
//   volatile uint32_t IDR;
//}GPIOA_TypeDef;

typedef struct {
   volatile uint32_t CR;
   volatile uint32_t SOD;
   volatile uint32_t SID;
   volatile uint32_t SR;
}SPI_TypeDef;

#define SPI_BASEADDR   0x44A00000U
#define SPI  ((SPI_TypeDef *)(SPI_BASEADDR))

//#define GPIOA_BASEADDR   0x44A10000U
//#define GPIOA  ((GPIOA_TypeDef *)(GPIO_BASEADDR))
//#define GPIO_DR         *(volatile uint32_t *)(GPIO_BASEADDR + 0x00)
//#define GPIO_CR         *(volatile uint32_t *)(GPIO_BASEADDR + 0x04)

//int LED(GPIO_TypeDef *GPIOx, int bit);


int main()
{
   SPI->CR = 4;
   SPI->SOD = 0xff;
   SPI->CR = 0;
   //GPIO_CR = 0xff00; // *(volatile unit32_t *)(GPIO_BASEADDR + 0x04) 의미
   // *(volatile unit32_t *)(0x40000004U) = 0xff00

   while(1)
   {
      if (SPI->SR & 1<<0)
      {
         printf("finish");
      }

   }
   return 0;
}

//void spi_mode(SPI_TypeDef *SPI, int mode)
//{
//   SPI-> = (1<<mode);
//}


//int LED(GPIO_TypeDef *GPIOx, int bit)
//{
//   int temp;
//   temp = GPIOx->DR & (1U << bit);
//   return (temp == 0) ? 0 : 1;
//}
