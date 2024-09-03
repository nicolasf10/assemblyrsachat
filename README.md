# RSA-Encrypted Chat made with AARCH64 Assembly

This project is an encrypted command line chat application developed in Assembly for the AArch64 architecture.
Developed in the following enviornment: `6.3.0-kali1-arm64`.

### Features:
- E2EE via RSA
- Message size of up to 256 bytes
- Connects server and client via socket

### How does it work?
A connection between the server and client is established using a socket (point-to-point communication). Once the server is listening for a connection (in this case the network is `localhost`) on a certain port, the client can connect to the server.

After connecting, the server and client exchange their public keys with one another. When the client sends a message to the server, the client will use the server's public key to encrypt its own message, and upon receiving the message, the server will decrypt it with its private key (and the opposite goes for when the server sends a message to the client).

### Screenshot
![Server screenshot](/server.png)


### RSA Encryption
The RSA-related functionality is done via the `rsa_wrapper.c` file, which define helper functions written in C (using the OpenSSL library):
- `generate_rsa_keys_wrapper` - generates RSA key
- `public_encrypt_wrapper` - encrypts message given a public key
- `public_decrypt_wrapper` - decrypts message given public and private key pair

To learn more about RSA encryption visit lesson [8.4 The RSA Cryptosystem | University of Toronto](https://www.teach.cs.toronto.edu/~csc110y/fall/notes/08-cryptography/04-rsa-cryptosystem.html).

### Resources
- [Sockets Tutorial | LinuxHowtos](https://www.linuxhowtos.org/C_C++/socket.htm)
- [Arm64 Syscalls](https://arm64.syscall.sh/)
- [8.4 The RSA Cryptosystem | University of Toronto](https://www.teach.cs.toronto.edu/~csc110y/fall/notes/08-cryptography/04-rsa-cryptosystem.html).

