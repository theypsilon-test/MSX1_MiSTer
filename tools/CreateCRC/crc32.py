import os
import zlib
import struct
import json

MAPPER_FILE = "mappers.json"

def calculate_crc32(file_path):
    """Vypočítá CRC32 kontrolní součet souboru."""
    buf_size = 65536  # Čtení po částech o velikosti 64KB
    crc32 = 0

    with open(file_path, 'rb') as f:
        while chunk := f.read(buf_size):
            crc32 = zlib.crc32(chunk, crc32)

    # Zajistí, že kontrolní součet je ve formátu bez znaménka
    return crc32 & 0xFFFFFFFF

def extract_mapper_name(file_name):
    """Extrahuje název mapperu uzavřený ve hranatých závorkách z názvu souboru."""
    start = file_name.find('[')
    end = file_name.find(']', start)
    if start != -1 and end != -1:
        return file_name[start+1:end]
    return None

def load_existing_mappers(file_path):
    """Načte existující mappery ze souboru, pokud existuje."""
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}

def save_mappers_to_file(mappers, file_path):
    """Uloží mappery do souboru s každým mapperem a jeho polem na jednom řádku."""
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write('{\n')
        for i, (mapper_name, values) in enumerate(mappers.items()):
            line = json.dumps({mapper_name: values}, ensure_ascii=False)
            # Odstraníme vnější složené závorky z každého mapperu
            line_content = line[1:-1]
            f.write(f"  {line_content}")
            # Pokud není poslední, přidej čárku
            if i < len(mappers) - 1:
                f.write(',')
            f.write('\n')
        f.write('}\n')

def update_mappers(existing_mappers, new_mapper_names):
    """Aktualizuje existující mappery o nové názvy, pokud jsou nalezeny."""
    # Najde nejvyšší číselnou hodnotu mapperu
    max_index = max([info[0] for info in existing_mappers.values()], default=-1)
    updated = False

    for mapper_name in new_mapper_names:
        if mapper_name not in existing_mappers:
            max_index += 1
            # Přidá nový mapper s první hodnotou jako inkrement a další hodnoty jako 0
            existing_mappers[mapper_name] = [max_index, 0, 0, 0]
            updated = True

    return existing_mappers, updated

def find_files(root_dir, extensions):
    """Rekurzivně vyhledává soubory s danými příponami v kořenovém adresáři."""
    for dirpath, _, filenames in os.walk(root_dir):
        for file in filenames:
            if any(file.endswith(ext) for ext in extensions):
                yield os.path.join(dirpath, file)

def process_files(root_dir, existing_mappers):
    """Zpracovává soubory, vypočítává CRC32 a připravuje binární výstup."""
    file_extensions = ['.ROM', '.rom', '.BIN', '.bin']
    new_mapper_names = set()
    file_data = []

    # Najde a zpracuje soubory
    for file_path in find_files(root_dir, file_extensions):
        file_name = os.path.basename(file_path)
        mapper_name = extract_mapper_name(file_name)

        if mapper_name:
            new_mapper_names.add(mapper_name)
            crc32_checksum = calculate_crc32(file_path)
            file_data.append((file_path, file_name, crc32_checksum, mapper_name))

    # Aktualizuje seznam mapperů
    updated_mappers, updated = update_mappers(existing_mappers, new_mapper_names)

    # Připraví binární data
    binary_data = bytearray()
    for file_path, file_name, crc32_checksum, mapper_name in file_data:
        mapper_values = updated_mappers[mapper_name]
        # Zabalí CRC32 a hodnoty mapperu (4 byty) do binárního formátu
        binary_data.extend(struct.pack('<I', crc32_checksum))
        binary_data.extend(struct.pack('BBBB', *mapper_values))

    return binary_data, updated_mappers, updated, file_data

def write_binary_file(output_path, binary_data):
    """Zapíše binární data do souboru."""
    with open(output_path, 'wb') as f:
        f.write(binary_data)

# Hlavní část programu
if __name__ == '__main__':
    root_directory = input("Zadejte kořenový adresář pro vyhledávání: ").strip()
    output_file_path = "output_data.bin"

    # Načte existující seznam mapperů
    existing_mappers = load_existing_mappers(MAPPER_FILE)

    binary_data, updated_mappers, updated, file_data = process_files(root_directory, existing_mappers)
    write_binary_file(output_file_path, binary_data)

    # Uloží aktualizovaný seznam mapperů, pokud došlo ke změně
    if updated:
        save_mappers_to_file(updated_mappers, MAPPER_FILE)

    print(f"Zpracování dokončeno. Binární data zapsána do {output_file_path}.")
