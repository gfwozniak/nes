import sys

def read_ines_header(file_path):
    with open(file_path, 'rb') as file:
        # Read the first 16 bytes of the file (iNES header)
        header = file.read(16)

        # Check if the file starts with the iNES magic number
        if header[:4] != b'NES\x1A':
            print("Not a valid iNES file.")
            return

        # Extract information from the header
        prg_rom_size = header[4] * 16 * 1024  # Program ROM size in bytes
        chr_rom_size = header[5] * 8 * 1024   # Character ROM size in bytes
        mapper_type = (header[6] >> 4) | (header[7] & 0xF0)  # Mapper type
        nfiletype = ((header[6] & 0x0F) << 2) | ((header[7] & 0xC0) >> 6)  # File type

        # Extract individual flag information
        mirroring = header[6] & 0x01  # Bit 0
        battery_backed_ram = (header[6] & 0x02) >> 1  # Bit 1
        trainer_present = (header[6] & 0x04) >> 2  # Bit 2
        four_screen_vram = (header[6] & 0x08) >> 3  # Bit 3

        # Calculate number of banks
        prg_rom_banks = prg_rom_size // (16 * 1024)
        chr_rom_banks = chr_rom_size // (8 * 1024)

        # Print verbose flag information
        print("Mirroring:", "Vertical" if mirroring else "Horizontal")
        print("Battery-Backed RAM:", "Present" if battery_backed_ram else "Not present")
        print("Trainer Present:", "Yes" if trainer_present else "No")
        print("Four-Screen VRAM:", "Yes" if four_screen_vram else "No")

        # Print other header information
        print("PRG ROM size:", prg_rom_size, "bytes")
        print("CHR ROM size:", chr_rom_size, "bytes")
        print("Mapper type:", mapper_type)

        # Print number of banks
        print("Number of PRG ROM banks:", prg_rom_banks)
        print("Number of CHR ROM banks:", chr_rom_banks)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python read_ines_header.py <file_path>")
    else:
        file_path = sys.argv[1]
        read_ines_header(file_path)

