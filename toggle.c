#include "stm32f4xx.h"
#include "stm32f4xx_rcc.h"
#include "stm32f4xx_gpio.h"

#define NUM_LEDS 4

static int leds[NUM_LEDS] = {
  GPIO_Pin_12,
  GPIO_Pin_13,
  GPIO_Pin_14,
  GPIO_Pin_15
};

static int led_idx = 0;

void sysinit(void) {
  GPIO_InitTypeDef GPIO_InitDef;

  // Init LED pins as outputs
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOD, ENABLE);
  for (int i = 0; i < NUM_LEDS; ++i) {
    GPIO_InitDef.GPIO_Pin = leds[i];
    GPIO_InitDef.GPIO_Mode = GPIO_Mode_OUT;
    GPIO_InitDef.GPIO_OType = GPIO_OType_PP;
    GPIO_InitDef.GPIO_PuPd = GPIO_PuPd_NOPULL;
    GPIO_InitDef.GPIO_Speed = GPIO_Speed_100MHz;
    GPIO_Init(GPIOD, &GPIO_InitDef);
  }

  // Init the user button as input
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOA, ENABLE);
  GPIO_InitDef.GPIO_Pin = GPIO_Pin_0;
  GPIO_InitDef.GPIO_Mode = GPIO_Mode_IN;
  GPIO_InitDef.GPIO_OType = GPIO_OType_PP;
  GPIO_InitDef.GPIO_PuPd = GPIO_PuPd_DOWN;
  GPIO_InitDef.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_Init(GPIOA, &GPIO_InitDef);
}


int main(void) {
  sysinit();
  volatile uint8_t button_pressed = 0;

  while (1) {
    if (GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_0)) {
      if (!button_pressed) {
        button_pressed = 1;
        GPIO_ToggleBits(GPIOD, leds[led_idx++]);
        // saturate at 4 LEDs
        led_idx = led_idx % 4;
      }
    } else {
      button_pressed = 0;
    }
  }
}
