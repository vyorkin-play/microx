default: run

build/multiboot_header.o: src/multiboot_header.asm
	nasm -f elf64 src/multiboot_header.asm -o build/multiboot_header.o

build/boot.o: src/boot.asm
	nasm -f elf64 src/boot.asm -o build/boot.o

build/kernel.bin: build/multiboot_header.o build/boot.o src/linker.ld
	x86_64-pc-elf-ld -n -o build/kernel.bin -T src/linker.ld build/multiboot_header.o build/boot.o

build/os.iso: build/kernel.bin src/grub.cfg
	mkdir -p build/isofiles/boot/grub
	cp src/grub.cfg build/isofiles/boot/grub
	cp build/kernel.bin build/isofiles/boot
	grub-mkrescue -o build/os.iso build/isofiles

run: build/os.iso
	bochs

clean:
	rm -rf build/*

.PHONY: clean
