import os
import xml.etree.ElementTree as ET
import struct
import logging
from tools import load_constants, find_files_with_sha1, find_xml_files, convert_to_int_or_string, get_int_or_string_value

# Nastavení logování
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

ROM_DIR = 'ROM_test'
XML_DIR = 'Extension_test'
DIR_SAVE = 'MSX_test'

def create_block_entry(constants: dict, block_type: str, address: int, sha1: str = None, param1: int = 0, param2: int = 0, param3: int = 0) -> dict:
    block_entry = {
        "typ": constants['conf']['BLOCK'],
        "address": address,
        "block_typ": constants['block'][block_type],
        "param1": param1,
        "param2": param2,
        "param3": param3
    }
    if sha1:
        block_entry['SHA1'] = sha1
    return block_entry

def parse_fw_block(root: ET.Element, subslot: int, files_with_sha1: dict, constants: dict) -> list:
    block = {}
    result = []
    start = int(root.attrib.get("start", 0))
    count = int(root.attrib.get("count", 4))

    for element in root:
        if element.tag in ['SHA1', 'filename', 'device', 'mapper', 'sram', 'pattern', 'ram', 'device_param']:
            block[element.tag] = get_int_or_string_value(element)
        else:
            logger.info(f"Tag name: {element.tag} SKIP. Not expected here")

    if count > 4 - start:
        count = 4 - start

    address = ((subslot & 3) << 4) | ((start & 3) << 2) | ((count - 1) & 3)

    if 'SHA1' in block:
        if block['SHA1'] in files_with_sha1:
            result.append(create_block_entry(constants, 'ROM', address, sha1=block['SHA1']))
        else:
            logger.warning(f"Missing ROM. SHA1: {block['SHA1']}")

    if 'mapper' in block:
        if block['mapper'] in constants['mapper']:
            result.append(create_block_entry(constants, 'MAPPER', address, param1=constants['mapper'][block['mapper']]))
        else:
            logger.warning(f"Unknown mapper type: {block['mapper']}")

    if 'device' in block:
        if block['device'] in constants['device']:
            param_dev = block.get('device_param', 0)
            device_id = constants['device'][block['device']]
            result.append(create_block_entry(constants, 'DEVICE', address, param1=device_id, param2 = param_dev))
        else:
            logger.warning(f"Unknown device type: {block['device']}")

    # Potential extensions for 'sram' and 'ram' blocks could be added here

    return result

def parse_fw_secondary(root: ET.Element, subslot: int, files_with_sha1: dict, constants: dict) -> list:
    blocks = []
    for element in root:
        if element.tag == 'block':
            blocks.extend(parse_fw_block(element, subslot, files_with_sha1, constants))
    return blocks

def parse_fw(name: str, root: ET.Element, files_with_sha1: dict, constants: dict) -> list:
    results = []
    for element in root:
        if element.tag == 'secondary':
            slot = int(element.attrib["slot"])
            results.extend(parse_fw_secondary(element, slot, files_with_sha1, constants))
        elif element.tag == 'block':
            results.extend(parse_fw_block(element, 0, files_with_sha1, constants))
        elif element.tag == 'io_device':
            pass  # Placeholder for future extensions
        else:
            logger.info(f"Tag name: {element.tag} SKIP. Not expected here")

    return results

def parse_fw_config(root: ET.Element, files_with_sha1: dict, constants: dict) -> dict:
    results = {}
    for element in root:
        if element.tag == 'fw':
            name = element.attrib["name"]
            if name not in constants['cart_dev']:
                logger.info(f"FW name: {name} SKIP. Not in cart_device.json")
                continue
            results[name] = parse_fw(name, element, files_with_sha1, constants)
        else:
            logger.info(f"Unknown tag: {element.tag} SKIP.")
            continue
    return results

def prepare_roms(config: dict, files_with_sha1: dict) -> dict:
    roms = {}
    start = 0
    id = 0
    try:
        with open('ROM.bin', 'wb') as rom_file:
            for key in config:
                for block in config[key]:
                    if 'SHA1' in block:
                        if block['SHA1'] not in roms:
                            filename = files_with_sha1[block['SHA1']]
                            file_size = os.path.getsize(filename)
                            file_blocks = (file_size + 16383) // 16384
                            with open(filename, 'rb') as source_file:
                                data = source_file.read()
                                rom_file.write(data)
                                current_size = len(data)
                                padding_needed = ((current_size + 16383) // 16384) * 16384 - current_size
                                if padding_needed > 0:
                                    rom_file.write(b'\xff' * padding_needed)

                            roms[block['SHA1']] = {"start": start, "blocks": file_blocks, "id": id}
                            id += 1
                            start += file_blocks * 16384
        return roms
    except IOError as e:
        logger.error(f"Error writing to ROM.bin: {e}")
        return {}

def set_address(address_array: bytearray, index: int, address: int):
    if index < 0 or index >= 256:
        raise ValueError("Index must be in the range 0 to 255.")
    
    start = index * 4
    address_array[start:start+4] = struct.pack('I', address)

def init_address(address_array: bytearray, addr: int):
    for i in range(256):
        set_address(address_array, i, addr)

def create_fw_config(config: dict, constants: dict, roms: dict) -> tuple:
    data = bytearray()
    address_array = bytearray(256 * 4)
    addr = 0x10 + len(address_array)
    init_address(address_array, addr)
    
    data += struct.pack('BBBBBB', constants['conf']['END'], 0, 0, 0, 0, 0)
    logger.info(f"CONF addr:{addr:04X} < {constants['conf']['END']:02X} 00 00 00 00 00") 
    addr += 6

    for key in config:
        logger.info(f"NAME: {key} index: {constants['cart_dev'][key]:02X}")
        set_address(address_array, constants['cart_dev'][key], addr)
        
        for conf in config[key]:
            conf['param1'] = conf.get('param1', 0)
            conf['param2'] = conf.get('param2', 0)
            conf['param3'] = conf.get('param3', 0)

            if conf['typ'] == constants['conf']['BLOCK'] and conf['block_typ'] == constants['block']['ROM']:
                if 'SHA1' in conf and conf['SHA1'] in roms:
                    sha1_value = conf['SHA1']
                    conf['param1'] = roms[sha1_value]['id']
                    conf['param2'] = (roms[sha1_value]['blocks'] >> 8) & 0xff
                    conf['param3'] = roms[sha1_value]['blocks'] & 0xff
                else:
                    logger.warning(f"Missing SHA1 in ROM configuration or SHA1 not found in ROMs: {conf}")
                    continue

            # Formátování číselných parametrů pro logování
            param1_str = f"{conf['param1']:02X}" if isinstance(conf['param1'], int) else str(conf['param1'])
            param2_str = f"{conf['param2']:02X}" if isinstance(conf['param2'], int) else str(conf['param2'])
            param3_str = f"{conf['param3']:02X}" if isinstance(conf['param3'], int) else str(conf['param3'])

            logger.info(f"CONF addr:{addr:04X} < {conf['typ']:02X} {conf['address']:02X} {conf['block_typ']:02X} {param1_str} {param2_str} {param3_str}") 
            data += struct.pack('BBBBBB', conf['typ'], conf['address'], conf['block_typ'], conf['param1'], conf['param2'], conf['param3'])
            addr += 6
        data += struct.pack('BBBBBB', constants['conf']['END'], 0, 0, 0, 0, 0)
        addr += 6
    
    return address_array, data, addr

def save_fw_config(config: dict, file_name: str, path: str, files_with_sha1: dict, constants: dict, roms: dict, table: bytearray, data: bytearray, rom_start_addr: int):
    file_path = os.path.join(DIR_SAVE, path)
    os.makedirs(file_path, exist_ok=True)
    file_path = os.path.join(file_path, file_name + '.msx')
    
    try:
        with open(file_path, "wb") as outfile:
            head = struct.pack('BBBBI', ord('M'), ord('s'), ord('X'), 0, rom_start_addr)
            outfile.write(head)
            outfile.write(b'\x00' * 8)
            outfile.write(table)
            outfile.write(data)
    
            addr_rom_start = rom_start_addr + 4 * len(roms)
            rom_table = bytearray()

            for rom in roms:
                rom_table += struct.pack('I', addr_rom_start + roms[rom]['start'])

            outfile.write(rom_table)
    
            with open('ROM.bin', 'rb') as rom_file:
                rom_content = rom_file.read()

            outfile.write(rom_content)
            os.remove('ROM.bin')
    except IOError as e:
        logger.error(f"Error saving MSX config to {file_path}: {e}")

def create_fw_conf(file_name: str, path: str, files_with_sha1: dict, constants: dict):
    file_path = os.path.join(XML_DIR, path, file_name + '.xml')
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        if root.tag != "fwConfig":
            logger.warning(f"File {file_path} is not a valid msxConfig XML. Skipping.")
            return
        
        config = parse_fw_config(root, files_with_sha1, constants)
        roms = prepare_roms(config, files_with_sha1)
        table, data, rom_start_addr = create_fw_config(config, constants, roms)
        logger.info(roms)
        save_fw_config(config, file_name, path, files_with_sha1, constants, roms, table, data, rom_start_addr)

    except (ET.ParseError, FileNotFoundError) as e:
        logger.error(f"Error processing file {file_path}: {e}")

files_with_sha1 = find_files_with_sha1(ROM_DIR)
constants = load_constants()

xml_files = find_xml_files(XML_DIR)

for file_name, path in xml_files:
    create_fw_conf(file_name, path, files_with_sha1, constants)
