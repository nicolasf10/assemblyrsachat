.extern generate_rsa_keys_wrapper
.extern public_encrypt_wrapper
.extern public_decrypt_wrapper

.data
hello:
    	.ascii "Hello, World!\n"

server_addr:			// struct sockaddr_in
	.short 2		// AF_INET (sin_family)
portno_place:	.skip 2		// Placeholder for port number (sin_port)
sin_addr:	.word 0x0	// IP address INADDR_ANY (sin_addr)
	.zero 8			// Not used

cli_addr:			// struct sockaddr_in
	.space 2
	.space 2
	.space 4
	.zero 8
cli_len:
	.word 16
listen_msg:
	.asciz "Listening!!\n"
client_connected:
	.asciz "Client connected\n"
	.zero 7
client_disconnected:
	.asciz "Client disconnected\n"
	.zero 4

// struct pollfd
fds:
	.word 0x0		// fds[0].fd - 0
	.short 0x0		// fds[0].events - 4
	.short 0x0		// fds[0].revents - 6
	
	.word 0x0		// fds[1].fd - 8
	.short 0x0		// fds[1].events - 12
	.short 0x0		// fds[1].revents - 14

.bss
buffer: .zero 256
ans_buffer: .zero 256
portno: .skip 2
sockfd: .skip 2
newsockfd: .skip 2
p_prime: .skip 256
q_prime: .skip 256
n_prime: .skip 256
e_reference: .skip 28
e:	 .skip 4
d_prime: .skip 256

client_n: .skip 256
client_e: .skip 32

zero_test: .zero 32

.text

.equ BUFFER_SIZE, 256
.equ SIGIO, 29
.equ KEY_SIZE, 288


// Function to convert null-terminated string to int (exits with error if not digit)
// Input:  x0 - address to start of string
//	   x1 - address of exit label
// Output: x1 - int 
str_to_int:
	stp x2, x3, [sp, #-16]!	// Storing previous x2, x3 values
	stp x4, x15, [sp, #-16]!// Storing previous x4, x15

	eor  x2, x2, x2		// Accumulator
	eor x3, x3, x3		// Store current digit
	
digits_loop:
	ldr x3, [x0] 		// Storing next digit
	and x3, x3, 0xFF	// Storing only first byte
	cbz x3, str_to_int_done

	sub x3, x3, '0'		// Converting ascii to int
after_dig:
	cmp x3,	0		// Checking digit validity
	blo error_str_to_int 	// Error if less than 0

	cmp x3, 9
	bgt error_str_to_int 	// Error if more than 

	mov x15, 10
	mul x2, x2, x15		// Multiply accumulator by 10
	add x2, x2, x3		// Add next digit

	add x0, x0, #1		// Incrementing address

	b digits_loop

str_to_int_done:
	mov x1, x2		// Storing result in x1
	ldp x4, x15, [sp], #16	// Restoring previous x4, x15 values
	ldp x2, x3, [sp], #16 	// Restoring previous x2, x3 values	
	ret

error_str_to_int:
	blr x1			// Branching to error address

	
.global _start

_start:
load:	
	mov x17, 1
	// Load argv
	ldr x1, [sp] 		// Number of arguments (argc)
	ldr x2, [sp, #8] 	// Load pointer to array of arguments (argv)
	cmp x1, #2		// Check if there are at least two arguments
	blt error_exit

	// Skip program name
iter_name:
	ldr x0, [x2]
	and x1, x0, 0xFF
	cbz x1, continue	// Check if it's null terminator
	add x2, x2, #1
	b iter_name
	
continue:
	add x2, x2, #1		// First digit of port number in address x2

	mov x0,  x2		// Store address of start of string in x0
	adr x1, error_exit
	
	// Convert string of port number to int
	bl str_to_int

after_portno:
	ldr x2, =portno
	strh w1, [x2]		// Storing port number in .bss section

generate_keys:
	// Set e to 0x10001
	ldr x1, =e		// Load into x1 address of e
	mov w0, 0x00010001
	str w0, [x1]		// Write into memory the value of e

	// Call C function wrapper (OpenSSL implementation)
	ldr x0, =p_prime
	ldr x1, =q_prime
	ldr x2, =n_prime
	ldr x3, =d_prime
	ldr x4, =e
	bl generate_rsa_keys_wrapper

socket:
	// socket(AF_INET, SOCK_STREAM, 0)
	mov x8, #198		// Load syscall number 198 (socket) into x8
	mov x0, #2		// AF_NINET - internet domain
	mov x1, #1		// SOCK_STREAM type
	mov x2, #0 		// Use default (TCP) protocal for SOCK_STREAM
	svc #0			// syscall - file descriptor will be stored in x0

	mov x4, x0
	cmp x4, #0 		// Check for error after calling socket()
	blt error_exit

	ldr x1, =sockfd
	strh w4, [x1]

bind:
	// bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr))
	ldr x1, =portno		// Loading portno
	ldrsh w2, [x1]

	rev16 w2, w2		// htons (converting to network byte order)

	ldr x1, =portno_place	// Store address of the portno placeholder
	strh w2, [x1]		// Store portno at portno_place

	mov x0, #0
	ldr x2, =sockfd
	ldrh w0, [x2]		// Load sockfd number
	
	ldr x1, =server_addr	// Loading address of server_addr (struct sockaddr*)
	mov x2, #16		// Size of sockaddr_in struct
	mov x8, #200		// Load syscall number 200 (bind) into x8
	svc #0			// Syscall	
	cmp x0, #0		
	bne error_exit		// Error if bind doesn't return 0

listen:
	// listen(sockfd,5);
	mov x0, #0
	ldr x2, =sockfd
	ldrh w0, [x2]		// Load sockfd to x0

	mov x1, #5		// Size of backlog queue

	mov x8, #201		// Set syscall number to 201 (listen)
	svc #0			// syscall
	
	// Print message "Listening!!"
	mov x0, 1
	ldr x1, =listen_msg
	mov x2, #12

	mov x8, #64
	svc #0

accept:
	// accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);
	mov x0, #0
	ldr x2, =sockfd
	ldrh w0, [x2]		// Load sockfd to x0

	ldr x1, =cli_addr	// Load address of cli_addr struct to x1
	ldr x2, =cli_len	// Load address of cli_len word to x2
	
	mov x8, #202		// Set syscall number to 202 (accept)
	svc #0			// syscall
	cmp x0, #0
	blt error_exit		// Error if accept returns negative number
	
	ldr x1, =newsockfd
	strh w0, [x1]

client_connected_print:
	// Print message "Client connected"
	ldr x1, =client_connected
	mov x0, #1		// stdout
	mov x2, #20
	mov x8, #64		// Syscall number for write
	svc #0			// Syscall

swap_keys:
	// Sending our RSA public key to client
	ldr x1, =newsockfd	// Load address of newsockfd into x1
	mov x0, #0
	ldrh w0, [x1]		// Load value of newsockfd into x0

	mov w4, w0		// Save newsockfd for later
	
	ldr x1, =n_prime	// Load n into x1
	mov x2, #KEY_SIZE
	mov x8, #64		// Syscall number for write
	svc #0			// Syscall

	// Receive n from client
	mov x0, #0
	mov w0, w4		// Retrieve newsockfd
	ldr x1, =client_n	// Load into x1 the memory for the client's n key
	mov x2, #KEY_SIZE	// Load into x2 the size of the key
	mov x8, #63		// Syscall number for read
	svc #0			// Syscall

setup_poll:
	// Setting up polling
	ldr x3, =newsockfd	// Load address of newsockfd (client file descriptor) into x3
	ldr x1, =fds		// Load address of fds into x1
	ldr w0, [x3]		// Load value of newsockfd into w0 (word sized)
	str w0, [x1]		// Store newsockfd into fds[0].fd

	add x1, x1, #4		// Increment x1 by 4 bytes, now points to fds[0].events
	mov x3, #1		// POLLIN = 1 / there is data to read
	strh w3, [x1]		// Store POLLIN (half-word) in fds[0].events
	
	add x1, x1, #4		// Increment x1 by 4 bytes, now points to fds[1].fd
	mov x0, #0		// STDIN_FILENO = 0 / standard input value
	str w0, [x1]		// Store stdin file descriptor into fds[1].fd
	
	add x1, x1, #4		// Increment x1 by 4 bytes, now points to fds[1].events
	mov x3, #1		// POLLIN = 1 / there is data to read
	strh w3, [x1]		// Store POLLIN (half-word) in fds[1].events

event_loop:
	// Call ppoll(fds, 2, NULL, NULL)
	ldr x0, =fds		// struct pollfd* fds
	mov x1, #2		// Number of file descriptors being watched
	mov x2, #0		// struct _kernel_timespec*
	mov x3, #0		// sigmask
	mov x4, #2
	mov x8, #73		// Syscall number for ppoll
call_ppoll:
	svc #0			// Syscall

	cmp x0, #0
	blt error_exit		// Exit if ppoll returned error

check_socket:
	// Check for incoming data from socket
	ldr x1, =fds		// Load address of fds array into x1
	add x1, x1, #6		// Increment x1 by 6 to point to fds[0].revent
	ldrh w0, [x1]		// Load half-word fds[0].revents into w0
	
	and w0, w0, #1		// fds[0].revent & POLLIN
	cmp w0, #0

	beq check_input		// If no new messages, branch to check input

	// Process socket message
	ldr x0, =ans_buffer
	mov x3, #BUFFER_SIZE	// Move buffer size into x3

zero_ans_buffer:
	stp xzr, xzr, [x0], #16	// Store two zero registeres in the answer buffer
	subs x3, x3, #16	// Subtract 16 bytes from buffer size
	b.gt zero_ans_buffer	// Branch back if there are more bytes remaining

read_msg:
	// read(newsockfd, ans_buffer, BUFFER_SIZE - 1)
	ldr x1, =newsockfd	// Load newsockfd address into x1
	mov x0, #0
	ldrh w0, [x1]		// Load newsockfd value into x0 (half-word)
	
	ldr x1, =ans_buffer	// Load answer buffer into x1
	mov x2, #BUFFER_SIZE // Move buffer size into x2
	mov x8, #63		// Syscall number for read
	svc #0			// Syscall

	cmp x0, #0
	b.gt decrypt_message	// If message length is greater than 0 print it
	
	// Print client disconnected
	ldr x1, =client_disconnected
	mov x0, #1		// stdout
	mov x2, #24
	mov x8, #64		// Syscall number for write
	svc #0			// Syscall

	b exit			// Exit program

decrypt_message:
	ldr x0, =ans_buffer	// Load into x0 the answer_buffer
	ldr x1, =n_prime	// Load into x1 the server's own n key
	ldr x2, =d_prime	// Load into x2 the d component of private key
	ldr x3, =e_reference	// Load into x3 the e component of private key

	bl public_decrypt_wrapper // Call external decrypt function wrapper
	
print_message:
	ldr x1, =ans_buffer	// Load answer buffer into x1
	mov x0, #1		// stdout
	mov x2, #BUFFER_SIZE
	mov x8, #64		// Syscall number for write
	svc #0			// Syscall

check_input:
	ldr x1, =fds		// Load address of fds into x1
	add x1, x1, #14		// Increment x1 by 14 to point to fds[1].revents
	mov x0, #0
	ldrh w0, [x1]		// Load half-word fds[1].revents into w0
prev_check:
	and w0, w0, #1		// fds[1].revents & POLLIN
	cmp w0, #0
	beq event_loop		// If there is no data available, branch back to event_loop

	ldr x0, =buffer		// Load into x0 buffer
	mov x3, #BUFFER_SIZE	// Load into x3 the buffer size
	
zero_buffer:
	stp xzr, xzr, [x0], #16	// Store two zero registeres in the answer buffer
	subs x3, x3, #16	// Subtract 16 bytes from buffer size
	b.gt zero_buffer	// Branch back if there are more bytes remaining

handle_input:
	mov x0, #0		// stdin
	ldr x1, =buffer		// Load buffer into x1
	mov x2, #BUFFER_SIZE
	sub x2, x2, #1		// Set buffer size
	mov x8, #63		// Syscall number for read
	svc #0			// Syscall
	
	cmp x0, #0
	blt error_exit		// Error if read length less than 0

encrypt_message:
	// Encrypt message with RSA public key of the client
	ldr x0, =buffer		// Load into x0 the address of the buffer
	ldr x1, =client_n	// Load into x1 the address of the client's public key
	ldr x2, =e_reference	// Load into x2 the address of the client's public exponent

	bl public_encrypt_wrapper // Calling external helper function to encrypt buffer with client's public key
	
write_socket:
	ldr x1, =newsockfd	// Load address of newsockfd into x1
	mov x0, #0
	ldrh w0, [x1]		// Load value of newsockfd into x0
	
	ldr x1, =buffer		// Load buffer into x1
	mov x2, #BUFFER_SIZE
	mov x8, #64		// Syscall number for write
	svc #0			// Syscall

	b event_loop

close_socket:
	ldr x1, =newsockfd	// Load newsockfd address
	mov x0, #0
	ldrh w0, [x1]		// Load half-word into w0 (sockfd value)

	mov x8, #39 		// Syscall number 39 for close
	svc #0			// Syscall
	
	// close sockfd
	ldr x1, =sockfd
	mov x0, #0
	ldrh w0, [x1]

	mov x8, #9		// Syscall number 39 for close
	svc #0			// Syscall

close:
	mov x8, #57		// Load into x8 syscall number of close
	svc #0			// Syscall

loop_accept:
	//brk #0
	add x17, x17, 1
	cmp x17, #2
	beq accept

exit:
    	// Exit program
    	mov  x0, #0        // Return code 0
    	mov  x8, #93       // System call number for exit
    	svc  #0            // Make system call

error_exit:
	// Exit program with error
	mov x0, #2
	mov x8, #93
	svc #0
