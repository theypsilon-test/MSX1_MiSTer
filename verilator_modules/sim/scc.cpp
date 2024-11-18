#include "sim_cpu.h"
#include "sim_main.h"

void scc_test(SimCPU &CPU)
{
	CPU.tick(5000);
	CPU.setSlot(0, 1);
	CPU.setSlot(1, 1);
	CPU.setSlot(2, 1);
	CPU.setSlot(3, 1);
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

	CPU.tick(5000);
}

void scc_configure()
{
	setBlock(1, 0, MAPPER_KONAMI_SCC_PLUS, DEV_SCC, 0, 0, 0, 0, 0);
	setRam(0, 0, 131072, false);
}