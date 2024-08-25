import os
import hashlib
import json

def calculate_sha1(file_path):
    """
    Calculates the SHA1 hash for a given file.

    :param file_path: Path to the file to calculate the hash for.
    :return: SHA1 hash as a hexadecimal string.
    """
    with open(file_path, 'rb') as f:
        return hashlib.sha1(f.read()).hexdigest()

def find_files_with_sha1(directory):
    """
    Recursively searches the given directory and its subdirectories, finds all files,
    and calculates the SHA1 hash for each file. Returns a dictionary with the hash as key and the file path as value.

    :param directory: Directory to search.
    :return: Dictionary with (SHA1 hash, file path).
    """
    files_with_sha1 = {}

    for root, _, files in os.walk(directory):
        for file in files:
            full_path = os.path.join(root, file)
            file_sha1 = calculate_sha1(full_path)
            files_with_sha1[file_sha1] = full_path

    return files_with_sha1

def load_constants():
    """
    Loads the constants from the specified JSON files.
    :return: Dictionary containing the loaded constants.
    """
    constants = {}
    with open('block.json', 'r') as file:
        constants['block'] = json.load(file)

    with open('conf.json', 'r') as file:
        constants['conf'] = json.load(file)

    with open('cart_device.json', 'r') as file:
        constants['cart_dev'] = json.load(file)
    
    with open('mapper.json', 'r') as file:
        constants['mapper'] = json.load(file)
    
    with open('device.json', 'r') as file:
        constants['device'] = json.load(file)

    return constants

def find_xml_files(directory):
    """
    Recursively searches the given directory and its subdirectories, finds all XML files,
    and returns a list containing the file name (without extension) and the relative file path.

    :param directory: Directory to search.
    :return: List of tuples (file name, relative path).
    """
    xml_files = []

    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".xml"):
                file_name = os.path.splitext(file)[0]
                path = os.path.relpath(root, directory)
                xml_files.append((file_name, path))

    return xml_files

def convert_to_int_or_string(text):
    if text is None:
        return None
    try:
        return int(text)
    except ValueError:
        return text

def get_int_or_string_value(element):
    if element.text and element.text.strip():
        return convert_to_int_or_string(element.text.strip())
    return None
