#include "sim_cpu.h"
#include "sim_main.h"
#include "mfrsd_flash.h"

void set_SCC_commands(SimCPU& CPU)
{
	CPU.setSlot(0, 1);
	CPU.setSlot(1, 1);
	CPU.setSlot(2, 1);
	CPU.setSlot(3, 1);
	CPU.memoryWrite(0xFFFF, 0x055);	// subslot all 1

	CPU.memoryWrite(0xB000, 0x80);		//Enable SCC+
	CPU.memoryWrite(0xBFFE, 0x20);		//Mode SCC+

	CPU.memoryWrite(0xB800, 0x00);
	CPU.memoryWrite(0xB801, 0x20);
	CPU.memoryWrite(0xB802, 0x30);
	CPU.memoryWrite(0xB803, 0x40);
	CPU.memoryWrite(0xB804, 0x50);
	CPU.memoryWrite(0xB805, 0x58);
	CPU.memoryWrite(0xB806, 0x60);
	CPU.memoryWrite(0xB807, 0x68);
	CPU.memoryWrite(0xB808, 0x70);
	CPU.memoryWrite(0xB809, 0x68);
	CPU.memoryWrite(0xB80A, 0x60);
	CPU.memoryWrite(0xB80B, 0x58);
	CPU.memoryWrite(0xB80C, 0x50);
	CPU.memoryWrite(0xB80D, 0x40);
	CPU.memoryWrite(0xB80E, 0x30);
	CPU.memoryWrite(0xB80F, 0x20);

	CPU.memoryWrite(0xB810, 0x00);
	CPU.memoryWrite(0xB811, 0xE0);
	CPU.memoryWrite(0xB812, 0xD0);
	CPU.memoryWrite(0xB813, 0xC0);
	CPU.memoryWrite(0xB814, 0xB0);
	CPU.memoryWrite(0xB815, 0xA0);
	CPU.memoryWrite(0xB816, 0x98);
	CPU.memoryWrite(0xB817, 0x90);
	CPU.memoryWrite(0xB818, 0x88);
	CPU.memoryWrite(0xB819, 0x90);
	CPU.memoryWrite(0xB81A, 0x98);
	CPU.memoryWrite(0xB81B, 0xA0);
	CPU.memoryWrite(0xB81C, 0xB0);
	CPU.memoryWrite(0xB81D, 0xC0);
	CPU.memoryWrite(0xB81E, 0xD0);
	CPU.memoryWrite(0xB81F, 0xE0);

	CPU.memoryWrite(0xB8A0, 0x08);
	CPU.memoryWrite(0xB8AA, 0x0F);
	CPU.memoryWrite(0xB8AF, 0x01);

	CPU.tick(50000);
}


void mfrsd_test(SimCPU& CPU)
{
	CPU.setTrace(false);
	CPU.tick(5000);		//Reset stability
	//set_SCC_commands(CPU);

	CPU.setSlot(0, 1);
	CPU.setSlot(1, 1);
	CPU.setSlot(2, 1);
	CPU.setSlot(3, 1);
	/*
	CPU.memoryWrite(0x7FFF, 0x00);  // 0x00007FFF   MAPPER REG
	CPU.memoryWrite(0x7FFD, 0x00);  // 0x00007FFD   OFFSET REG
	CPU.memoryWrite(0x7FFE, 0x00);  // 0x00007FFE   OFFSET2 REG
	CPU.memoryWrite(0xB000, 0x00);  // 0x0000B000   BANK Konami SCC
	CPU.memoryWrite(0xFFFF, 0xA6);  // 0x0000FFFF   SET SUBSLOT
	CPU.memoryWrite(0x7FFF, 0x00);  // 0x00007FFF   MAPPER REG
	CPU.memoryWrite(0x7FFD, 0x02);  // 0x00007FFD   OFFSET REG
	CPU.memoryWrite(0x7FFE, 0x00);  // 0x00007FFE   OFFSET2 REG
	CPU.memoryWrite(0x5000, 0x00);  // 0x00005000   BANK Konami SCC
	CPU.memoryWrite(0x7FFF, 0x02);  // 0x00007FFF   MAPPER REG

	CPU.setTrace(true);
	CPU.memoryWrite(0x4000, 0xF0);  // 0x00014000   
	CPU.memoryWrite(0x4AAA, 0xAA);  // 0x00014AAA   
	CPU.memoryWrite(0x4555, 0x55);  // 0x00014555   
	CPU.memoryWrite(0x4AAA, 0x80);  // 0x00014AAA   
	CPU.memoryWrite(0x4AAA, 0xAA);  // 0x00014AAA   
	CPU.memoryWrite(0x4555, 0x55);  // 0x00014555   
	CPU.memoryWrite(0x4AAA, 0x30);  // 0x00014AAA
	CPU.setTrace(false);
	CPU.tick(22000);			//Wait reset done
	CPU.setTrace(true);


	CPU.memoryWrite(0x6AAA, 0x56);  // 0x00016AAA   
	CPU.memoryWrite(0x7F00, 0x11);  // 0x00017F00   
	CPU.memoryWrite(0x7F01, 0x01);  // 0x00017F01   
	CPU.memoryWrite(0x7F02, 0x00);  // 0x00017F02   
	CPU.memoryWrite(0x7F03, 0xED);  // 0x00017F03
	*/
	CPU.setTrace(false);
	flash_zanac(CPU);

	CPU.setTrace(true);
	CPU.setReset();
	CPU.setSlot(0, 1);
	CPU.setSlot(1, 1);
	CPU.setSlot(2, 1);
	CPU.setSlot(3, 1);
	
	CPU.memoryWrite(0xFFFF, 0x10);	
	CPU.memoryRead(0xbf00);  


	return;
	CPU.memoryWrite(0x4000, 0xF0);  //RESET 

	CPU.memoryWrite(0x4AAA, 0xAA);  //
	CPU.memoryWrite(0x4555, 0x55);  //
	CPU.memoryWrite(0x4AAA, 0x80);  //
	CPU.memoryWrite(0x4AAA, 0xAA);  //
	CPU.memoryWrite(0x4555, 0x55);  //
	CPU.memoryWrite(0x4AAA, 0x30);  //ERASE
	CPU.tick(10);					//Wait reset done
	//CPU.setTrace(false);
	CPU.tick(22000);			//Wait reset done
	CPU.setTrace(true);
	CPU.tick(10);		   	    //Wait reset done
	CPU.memoryWrite(0x4AAA, 0x56);  //Write
	CPU.memoryWrite(0x4000, 0x41);  //1
	CPU.memoryWrite(0x4001, 0x42);  //2
	CPU.memoryWrite(0x4002, 0x2E);  //3
	CPU.memoryWrite(0x4003, 0x40);  //4
	CPU.memoryWrite(0x4AAA, 0x56);  //Write
	CPU.memoryWrite(0x4004, 0x43);  //
	CPU.memoryWrite(0x4005, 0x4F);  //
	CPU.memoryWrite(0x4006, 0x4D);  //
	CPU.memoryWrite(0x4007, 0x20);  //
	return;
	
	
	
	
	/*
	[MAPPER REGISTER(#7FFF)]
	7	mapper mode 1: \ #00 = SCC, #40 = 64K
		6	mapper mode 0: / #80 = ASC8, #C0 = ASC16
		5	mapper mode : Select Konami mapper(0 = SCC or 1 = normal)
		4
		3	Disable #4000 - #5FFF mapper in Konami mode
		2	Disable this mapper register #7FFF
		1	Disable mapper and offset registers
		0	Enable 512K mapper limit in SCC mapper or 256K limit in Konami mapper


		[OFFSET REGISTER(#7FFD)]
	7 - 0 Offset value bits 7 - 0


		[OFFSET REGISTER(#7FFE)]
	1	Offset bit 9
		0	Offset bit 8


		[CONFIG REGISTER(#7FFC)]
	7	Disable config register (1 = Disabled)
		6
		5	Disable SRAM(i.e.the RAM in subslot 2)
		4	DSK mode(1 = On) : Bank 0 and 1 are remapped to DSK kernel(config banks 2 - 3)
		3	Cartridge PSG also mapped to ports #A0 - #A3
		2	Subslots disabled(1 = Disabled) Only MegaFlashROM SCC + is available.
		1	FlashROM Block protect(1 = Protect) VPP_WD pin
		0	FlashROM write enable(1 = Enabled)
*/

	
}

void mfrsd_configure()
{
	setBlock(0, 0, MAPPER_OFFSET, DEV_NONE, 0, 0, 0, 0, 0);

	setBlock(1, 0, MAPPER_MFRSD0, DEV_NONE, 0, 0, 1, 0, 0);
	setBlock(1, 1, MAPPER_MFRSD1, DEV_SCC, 0, 0, 2, 0, 0);
	setBlock(1, 2, MAPPER_MFRSD2, DEV_MSX2_RAM, 0, 0, 3, 0, 0);
	setBlock(1, 3, MAPPER_MFRSD3, DEV_NONE, 0, 0, 4, 2, 0);
	
	
	uint32_t next_addr; 
	next_addr = setRam(0, 0, 32768, true);			  //BIOS
	next_addr = setRam(1, next_addr, 16384, true);    //kernel
	next_addr = setRam(2, next_addr, 4177920, true);  //ROM
	next_addr = setRam(3, next_addr, 524288, false);  //RAM
	next_addr = setRam(4, next_addr, 1048576, true);  //DISK ROM
	
}

