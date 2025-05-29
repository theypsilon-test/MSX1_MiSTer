import socket

# Nastavení klienta
HOST = '192.168.0.132'  # IP adresa serveru
PORT = 5000             # Port serveru
BUFFER_SIZE = 0x100000  # Velikost bufferu pro příjem dat

def save_to_disk(data):
    with open("output.bin", "wb") as file:
        file.write(data)
    print("Data byla uložena na disk.")

def receive_full_data(client_socket, expected_size):
    data = bytearray()  # Buffer pro kompletní data

    while len(data) < expected_size:
        packet = client_socket.recv(0x100000)
        if not packet:
            # Pokud `recv` vrátí prázdný řetězec, spojení bylo ukončeno
            break
        data.extend(packet)  # Přidá přijatý balík do bufferu

    return data

def main():
    # Vytvoření socketu a připojení k serveru
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client_socket:
        client_socket.connect((HOST, PORT))

        memory_buffer = bytearray()  # Paměťový buffer pro přijatá data

        while True:
            # Přijímání příkazů a dat
            command = client_socket.recv(1).decode('utf-8')

            if command == 'S':
                # Příjem datového bloku
                data = receive_full_data(client_socket, 0x100000);
                #print(len(data))
                #client_socket.sendall(b"ACK")
                memory_buffer.extend(data)  # Přidání do paměťového bufferu
            elif command == 'E':
                # Konec přenosu dat, ukládání do souboru
                save_to_disk(memory_buffer)
                print("Data save")
                break

if __name__ == "__main__":
    main()