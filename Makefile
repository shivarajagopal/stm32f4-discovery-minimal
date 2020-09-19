# Build out of tree
BUILD_DIR=build

# Name the target binaries
TARGET_NAME=toggle
TARGET_ELF=$(BUILD_DIR)/$(TARGET_NAME).elf
TARGET_BIN=$(BUILD_DIR)/$(TARGET_NAME).bin

# Point to the correct device and peripheral library location
STM_PERIPH_LIB=../STM32F4xx_DSP_StdPeriph_Lib_V1.8.0
STM_DEVICE=STM32F401xx
STM_DEVICE_LOWER = $(shell echo $(STM_DEVICE) | tr '[:upper:]' '[:lower:]')
STM_LD_FILE=STM32F401VC_FLASH.ld

# Tools
MKDIR=mkdir
CC=arm-none-eabi-gcc
OBJCOPY=arm-none-eabi-objcopy
ST_FLASH=st-flash

# Debugging
GDB_SERVER=openocd
GDB_SERVER_CFG =  -f interface/stlink-v2.cfg
GDB_SERVER_CFG += -f target/stm32f4x.cfg

GDB=arm-none-eabi-gdb
GDB_STARTUP_CMD =  -ex "target remote localhost:3333"
GDB_STARTUP_CMD += -ex "mon halt"
GDB_STARTUP_CMD += -ex "mon reset"
GDB_STARTUP_CMD += -ex "load"

# Flags for GCC
# Debug and all warnings
CFLAGS = -g -Og -Wall -Wextra
# Linker script
CFLAGS += -T$(STM_PERIPH_LIB)/Project/STM32F4xx_StdPeriph_Templates/TrueSTUDIO/$(STM_DEVICE)/$(STM_LD_FILE)
# ARM configurations
CFLAGS += -mlittle-endian -mthumb -mcpu=cortex-m4 -mthumb-interwork
CFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16
CFLAGS += --specs=nosys.specs
# ST-specific configurations and include directories
CFLAGS += -DUSE_STDPERIPH_DRIVER
CFLAGS += -D$(STM_DEVICE)
CFLAGS += -I.
CFLAGS += -I$(STM_PERIPH_LIB)/Libraries/CMSIS/Include
CFLAGS += -I$(STM_PERIPH_LIB)/Libraries/CMSIS/Device/ST/STM32F4xx/Include
CFLAGS += -I$(STM_PERIPH_LIB)/Libraries/STM32F4xx_StdPeriph_Driver/inc
CFLAGS += -I$(STM_PERIPH_LIB)/Project/STM32F4xx_StdPeriph_Templates

# Sources to build
SRCS=*.c
SRCS += $(STM_PERIPH_LIB)/Libraries/STM32F4xx_StdPeriph_Driver/src/stm32f4xx_gpio.c
SRCS += $(STM_PERIPH_LIB)/Libraries/STM32F4xx_StdPeriph_Driver/src/stm32f4xx_rcc.c
SRCS += $(STM_PERIPH_LIB)/Project/STM32F4xx_StdPeriph_Templates/system_stm32f4xx.c
SRCS += $(STM_PERIPH_LIB)/Libraries/CMSIS/Device/ST/STM32F4xx/Source/Templates/TrueSTUDIO/startup_$(STM_DEVICE_LOWER).s

.PHONY: $(TARGET_ELF)

# Make builds the ELF and the binary by default
all: $(TARGET_ELF)

# Create the build directory
$(BUILD_DIR):
	$(MKDIR) -p $@

# Compile the ELF
$(TARGET_ELF): $(BUILD_DIR)
	$(CC) $(CFLAGS) $(SRCS) -o $@

# Make the ELF into a binary for flashing
$(TARGET_BIN): $(TARGET_ELF)
	$(OBJCOPY) -O binary $(TARGET_ELF) $(TARGET_BIN)

# Quickly flash using st-flash once binary is created
quickflash: $(TARGET_BIN)
	$(ST_FLASH) --reset write $^ 0x8000000

# Start the GDB server
gdb_server:
	$(GDB_SERVER) $(GDB_SERVER_CFG)

# Start GDB
debug: $(TARGET_ELF)
	$(GDB) $(TARGET_ELF) $(GDB_STARTUP_CMD)

# Clean the build targets
clean:
	rm -rf $(BUILD_DIR)
