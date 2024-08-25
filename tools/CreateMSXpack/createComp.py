import os
import xml.etree.ElementTree as ET
import struct
import base64
from tools import load_constants, find_files_with_sha1, find_xml_files, convert_to_int_or_string, get_int_or_string_value

ROM_DIR = 'ROM_test'
XML_DIR_COMP = 'Computer_test'
DIR_SAVE = 'MSX_test'

def parse_msx_block(root):
    """
    Parses a 'block' element from the XML and returns a dictionary with its properties.
    
    :param root: XML element <block>
    :return: Dictionary with block details.
    """
    result = {}
    start = convert_to_int_or_string(root.attrib.get("start", 0))
    count = convert_to_int_or_string(root.attrib.get("count", None))
    
    for element in root:
        result[element.tag] = get_int_or_string_value(element)

    # Adjust the count to not exceed the limit
    if 'count' in  result :
        if count is not None:
            print("Error, block contain multiple count")
        else :
            count = result['count']
    else :
        if count is None:
            count = 4

    if count > 4 - start:
        count = 4 - start

    result['start'] = start
    result['count'] = count
    return result

def parse_msx_secondary(root):
    """
    Parses a 'secondary' element from the XML and returns a dictionary with the parsed blocks.

    :param root: XML element <secondary>
    :return: Dictionary containing 'block' key with list of blocks.
    """
    blocks = [parse_msx_block(element) for element in root if element.tag == 'block']
    return {'block': blocks}

def parse_msx_primary(root):
    """
    Parses a 'primary' element from the XML and returns a dictionary with its sub-elements.

    :param root: XML element <primary>
    :return: Dictionary containing parsed blocks and secondary slots.
    """
    results = {}
    for element in root:
        if element.tag == 'secondary':
            slot = convert_to_int_or_string(element.attrib["slot"])
            results.setdefault('secondary', {})[slot] = parse_msx_secondary(element)
        elif element.tag == 'block':
            results.setdefault('block', []).append(parse_msx_block(element))
        else:
            print(f"Processing unknown element: {element.tag}")

    return results

def parse_msx_config(root):
    """
    Parses the entire <msxConfig> XML root element.

    :param root: Root XML element <msxConfig>.
    :return: Dictionary with parsed configuration.
    """
    results = {}
    for element in root:
        if element.tag == 'primary':
            slot = convert_to_int_or_string(element.attrib["slot"])
            results.setdefault('primary', {})[slot] = parse_msx_primary(element)
        else:
            value = get_int_or_string_value(element)
            if value:
                results[element.tag] = value

    return results

def create_msx_config_header(outfile):
    """
    Writes the MSX configuration header to the output file.
    
    :param outfile: Opened file object for writing.
    """
    data = struct.pack('BBBBBB', ord('M'), ord('S'), ord('x'), 0, 0, 0)
    outfile.write(data)

def create_msx_config_block(slot, subslot, blocks, outfile, files_with_sha1, constants):
    """
    Writes a block configuration to the output file, including any ROM data if applicable.

    :param slot: Slot number.
    :param subslot: Subslot number.
    :param blocks: List of block configurations.
    :param outfile: Opened file object for writing.
    :param files_with_sha1: Dictionary of files with their SHA1 hashes.
    :param constants: Dictionary with configuration constants.
    """
    for block in blocks:
        address = ((slot & 3) << 6) | ((subslot & 3) << 4) | ((block['start'] & 3) << 2) | ((block['count'] - 1) & 3)
        param1 = 0
        param2 = 0
        param3 = 0
        block_type = constants['block'][block['type']]
        filename = None

        if block['type'] == 'ROM':
            if 'SHA1' not in block:
                print(f"Missing SHA1 for ROM in slot {slot}/{subslot}")
            elif block['SHA1'] not in files_with_sha1:
                print(f"ROM SHA1 not found: {block['SHA1']} (ROM name: {block['filename']}) in slot {slot}/{subslot}")
            else:
                filename = files_with_sha1[block['SHA1']]
                file_size = os.path.getsize(filename)
                param1 = (file_size + 16383) // 16384

        elif block['type'] == 'RAM':
            param1 = block['count']
            param2 = block.get('pattern', 1)
        
        elif block['type'] == 'SLOT':
            param1 = block.get('num', 0)
        
        else:
            print(f"Error: unknown type '{block['type']}' in slot {slot}/{subslot}")

        data = struct.pack('BBBBBB', constants['conf']['BLOCK'], address, block_type, param1, param2, param3)
        print(f"BLOCK: {constants['conf']['BLOCK']} {address:02X} {block_type:02X} {param1:02X} {param2:02X} {param3:02X} {block['type']} block_count: {block['count']}")
        outfile.write(data)

        if filename:
            with open(filename, 'rb') as source_file:
                data = source_file.read()
                outfile.write(data)
                current_size = len(data)
                padding_needed = ((current_size + 16383) // 16384) * 16384 - current_size
                if padding_needed > 0:
                    outfile.write(b'\xff' * padding_needed)

def create_msx_config_subslot(slot, secondary, outfile, files_with_sha1, constants):
    """
    Writes the configuration for a subslot to the output file.

    :param slot: Slot number.
    :param secondary: Secondary slot configuration.
    :param outfile: Opened file object for writing.
    :param files_with_sha1: Dictionary of files with their SHA1 hashes.
    :param constants: Dictionary with configuration constants.
    """
    for subslot, subslot_data in secondary.items():
        if 'block' in subslot_data:
            create_msx_config_block(slot, subslot, subslot_data['block'], outfile, files_with_sha1, constants)

def create_msx_config_primary(primary, outfile, files_with_sha1, constants):
    """
    Writes the configuration for the primary slots to the output file.

    :param primary: Primary slot configuration.
    :param outfile: Opened file object for writing.
    :param files_with_sha1: Dictionary of files with their SHA1 hashes.
    :param constants: Dictionary with configuration constants.
    """
    for slot, slot_data in primary.items():
        if 'block' in slot_data:
            create_msx_config_block(slot, 0, slot_data['block'], outfile, files_with_sha1, constants)
        elif 'secondary' in slot_data:
            create_msx_config_subslot(slot, slot_data['secondary'], outfile, files_with_sha1, constants)

def create_msx_config_kbd_layout(layout, outfile, constants):
    """
    Writes the configuration for the kezboard layout to the output file.

    :param layout: Base64 encoded layout
    :param outfile: Opened file object for writing.
    :param constants: Dictionary with configuration constants.
    """
    if layout:
        data = struct.pack('BBBBBB', constants['conf']['KEYBOARD_LAYOUT'], 0, 0, 0, 0, 0)
        outfile.write(data)
        outfile.write(base64.b64decode(layout))

def create_msx_config(config, file_name, path, files_with_sha1, constants):
    """
    Creates the MSX configuration file based on the parsed configuration data.

    :param config: Parsed MSX configuration.
    :param file_name: Output file name.
    :param path: Output file path.
    :param files_with_sha1: Dictionary of files with their SHA1 hashes.
    :param constants: Dictionary with configuration constants.
    """
    file_path = os.path.join(DIR_SAVE, path)
    os.makedirs(file_path, exist_ok=True)
    file_path = os.path.join(file_path, file_name + '.msx')
    
    with open(file_path, "wb") as outfile:
        create_msx_config_header(outfile)
        create_msx_config_primary(config.get('primary', {}), outfile, files_with_sha1, constants)
        create_msx_config_kbd_layout(config.get('kbd_layout', None), outfile, constants) 
             
def create_msx_conf(file_name, path, files_with_sha1, constants):
    """
    Parses the XML configuration file and creates the corresponding MSX configuration file.

    :param file_name: Input XML file name (without extension).
    :param path: Relative path to the XML file.
    :param files_with_sha1: Dictionary of files with their SHA1 hashes.
    :param constants: Dictionary with configuration constants.
    """
    file_path = os.path.join(XML_DIR_COMP, path, file_name + '.xml')
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        if root.tag != "msxConfig":
            print(f"File {file_path} is not a valid msxConfig XML. Skipping.")
            return
        
        config = parse_msx_config(root)
        create_msx_config(config, file_name, path, files_with_sha1, constants)

    except (ET.ParseError, FileNotFoundError) as e:
        print(f"Error processing file {file_path}: {e}")

files_with_sha1 = find_files_with_sha1(ROM_DIR)
constants = load_constants()

xml_files = find_xml_files(XML_DIR_COMP)

for file_name, path in xml_files:
    create_msx_conf(file_name, path, files_with_sha1, constants)
