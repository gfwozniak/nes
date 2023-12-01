import sys

def generate_coe_files(file_path):
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

        # Read the Trainer data if it exists
        if (trainer_present):
            trainer_data = file.read(512)
        # Read the PRG ROM data
        prg_rom_data = file.read(prg_rom_size)
        # Read the CHR ROM data
        chr_rom_data = file.read(chr_rom_size)

        # Generate COE file content
        chr_content = "memory_initialization_radix=2;\n"
        chr_content += "memory_initialization_vector=\n"
        # Iterate over CHR ROM data and format as binary values
        for byte in chr_rom_data:
            chr_content += "{},\n".format(format(byte, '08b'))
        chr_content = chr_content[:-2] + ";"
        # Write the CHR ROM content to a file
        with open(file_path[:-4] + "_CHROM.coe", "w") as chr_file:
            chr_file.write(chr_content)

        # Generate COE file content
        prg_content = "memory_initialization_radix=2;\n"
        prg_content += "memory_initialization_vector=\n"
        # Iterate over PRG ROM data and format as binary values
        for byte in prg_rom_data:
            prg_content += "{},\n".format(format(byte, '08b'))
        prg_content = prg_content[:-2] + ";"
        # Write the PRG ROM content to a file
        with open(file_path[:-4] + "_PGROM.coe", "w") as prg_file:
            prg_file.write(prg_content)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python generate_coe.py <file_path>")
    else:
        file_path = sys.argv[1]
        generate_coe_files(file_path)
        print(f"COE files generated")

