import os
import socket
import struct
import time
import mmap

# Nastavení pro paměť a server
MEMORY_ADDRESS = 0x1000  # Náhradní adresa v /dev/mem
MEMORY_SIZE = 1024       # Velikost bloku dat
HOST = '0.0.0.0'         # IP adresa serveru
PORT = 5000              # Port serveru

def read_memory(mem, sektor):
    addr = sektor<<20
    #print(f"Addr:{addr:x}")
    #mem.seek(addr)
    #data = mem.read(0x100000)
    data = mem[addr:addr+0x100000]
    return data

def read_counter(mem):
    val = int.from_bytes(mem[0:1], byteorder='little')
    return val

def main():
    f = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
    mem = mmap.mmap(f, 0x500000, mmap.MAP_SHARED, mmap.PROT_READ, offset=0x32000000)

    old_counter = 0

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_socket.bind((HOST, PORT))
        server_socket.listen()

        conn, addr = server_socket.accept()
        print("Server naslouchá...")

        with conn:
            print(f"Připojen klient: {addr}")
            print("Cekam na reset")

            while (read_counter(mem) != 0): None
            print("Reset probehl")
            old_counter = 0
            counter = 0

            while True:
                #print("Cekam na blok")
                while (counter == old_counter):
                    counter = read_counter(mem)

                old_counter = counter

                if counter == 0:
                     conn.sendall(b'E')
                     print("odesilam END")
                     break

                #print("Odeslat")
                conn.sendall(b'S')
                #addr = counter<<20
                #mem.seek(0)
                #data = mem[0:0x100000]
                #print(len(data))
                data = read_memory(mem, counter)
                #print(len(data))
                conn.sendall(data)
                #ack = conn.recv(3).decode('utf-8')
                #print(ack)
                #conn.sendall(b'E')
                #break

if __name__ == "__main__":
    main()
