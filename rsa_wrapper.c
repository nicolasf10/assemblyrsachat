#include <stdio.h>
#include <openssl/rsa.h>
#include <openssl/bn.h>

#define BUFFER_SIZE 256

void generate_rsa_keys_wrapper(unsigned char *p_prime, unsigned char *q_prime, unsigned char *n_prime, unsigned char *d_prime, int *e) {
    RSA *rsa = RSA_new();
    BIGNUM *e_bn = BN_new();

    const char *decimal_str = "65537";
    BN_dec2bn(&e_bn, decimal_str);

    //BN_set_word(e_bn, *e);

    // Generate RSA keys
    RSA_generate_key_ex(rsa, 2048, e_bn, NULL);

    // Extract the key components
    const BIGNUM *p, *q, *n, *d;
    RSA_get0_factors(rsa, &p, &q);
    RSA_get0_key(rsa, &n, NULL, &d);

    // Store the values at the specified memory addresses
    BN_bn2binpad(p, p_prime, 256);
    BN_bn2binpad(q, q_prime, 256);
    BN_bn2binpad(n, n_prime, 256);
    BN_bn2binpad(d, d_prime, 256); 

    RSA_free(rsa);
    BN_free(e_bn);
}

void public_encrypt_wrapper(unsigned char *buffer, unsigned char *public_n, unsigned char *public_e) {
	// Creating new rsa, n, and e objects
	RSA *rsa = RSA_new();
	BIGNUM *n = BN_new();
	BIGNUM *e = BN_new();

	printf("stored jinga: %s\n", buffer);

	unsigned char buffer_set[BUFFER_SIZE] = "okey dokey\n";

	printf("buffer - buffer_set\n");
	for (int j = 0; j < 256; j++) {
		printf("%d - %d \n", buffer[j], buffer_set[j]);
	}

	//buffer = buffer_set;

	// Set e
	const char *decimal_str = "65537";
    	BN_dec2bn(&e, decimal_str);


	// Converting the binary data into BIGNUM objects
	BN_bin2bn(public_n, 256, n);
	//BN_bin2bn(public_e, 32, e);
	RSA_set0_key(rsa, n, e, NULL);

	// Printing original message
	printf("original message: %s\n", buffer);

	int encrypt = RSA_public_encrypt(256, buffer, buffer, rsa, RSA_NO_PADDING);


	// Loading n
	char *bn_str = BN_bn2dec(n);

    	// Print the n
    	printf("n: %s\n", bn_str);

	// Loading e
	char *bn_str_e = BN_bn2dec(e);

    	// Printing e
    	printf("e: %s\n", bn_str_e);

	// Printing encrypted message
	printf("encrypted message: \n%s\n", buffer);

	printf("this is the crazy deets from the sender: \n");

	for (int n = 0; n < 256; n++) {
		printf("%d: %c - %d\n", n, buffer[n], buffer[n]);
	}

	
	//printf("after %s\n", buffer);

	//RSA_free(rsa);
	//BN_free(n);
	//BN_free(e);

}

void public_decrypt_wrapper(unsigned char *buffer, unsigned char *n_bin, unsigned char *d_bin, unsigned *e_bin) {
	// Creating new rsa object
	RSA *rsa = RSA_new();
	BIGNUM *n = BN_new();
	BIGNUM *d = BN_new();
	BIGNUM *e = BN_new();

	const char *decimal_str = "65537";
    	BN_dec2bn(&e, decimal_str);


	// Binary data to BIGNUM objects
	BN_bin2bn(n_bin, 256, n);
	BN_bin2bn(d_bin, 256, d);
	//BN_bin2bn(e_bin, 32, e);
	RSA_set0_key(rsa, n, e, d);

	// Printing encrypted message
	printf("encrypted message: %s\n", buffer);

	printf("this is crazy encrypted deets:\n");

	for (int i = 0; i < 256; i++) {
		printf("%d: %d - %c\n", i, buffer[i], buffer[i]);
	}

	// Decryption
	int decrypt = RSA_private_decrypt(256, buffer, buffer, rsa, RSA_NO_PADDING);

	// Loading n
	char *bn_str = BN_bn2dec(n);

    	// Printing n
    	printf("n: %s\n", bn_str);

	// Loading d
	char *bn_str_d = BN_bn2dec(d);

    	// Printing d
    	printf("d: %s\n", bn_str_d);

	// Loading e
	char *bn_str_e = BN_bn2dec(e);

    	// Printing e
    	printf("e: %s\n", bn_str_e);

	// Printing decrypted message
	printf("decrypted message: %s\n", buffer);


	for (int j = 0; j < 256; j++) {
		//printf("%d\n", buffer[j]);
	}	
	
	// Freeing memory
	/*
	RSA_free(rsa);
	BN_free(n);
	BN_free(d);
	BN_free(e);
	*/

}


int main() {
    const char *d_str = "3093065934147234543077607211974614497980137922534942713360535267549580626925818675566156213696046422523017572297598234852213458059349952382276710210206770100743704484527444981176714007283114308954614509484423985748695296569387850670113015485658160745995505683433160149420559945251800075844339275945432839379334280559487155833150478215236377335504190416331123289310596297546122600828303880622494991902332508639445756686038666607475139563416044517837275258509638453418377500679294483344079745866258551360687349926976361787017952866393550688827383942883980405011853627253984921212062491385795162568637371616517529690433";
    const char *n_str = "22786647003150292892386200713825036963867709816330311089554717217261162439716856508928088011015821585459121294804506235460803941547293849232189049152300502791143579770705912553589016367179620806578497342023166895310340789337710009235575833499034659702848836399399025165632947987179448273121757431055731355021396526864400860667025344032923256441769279787552187265905837552390598687776084691255814940676467127860087478531721314030785131237649678204144251843398528748844734278757518728548513597831570977914814641284298489876933591157042649890506581432525817625823238128983283472552208042563141255456763869097726589288473";
    
    const char *wrong_n = "30370625165619650100113207532152064186520832837592687895301477774677976519192822571988924805643712981450431580889018517480300117246079054418912336689579539581945344706371701665668217004283528349177959073396288288095958855580108918734306477550908600466261279425935817399351724634579888417019885721744576994724473577265771426078399931267503895266772758005533201453112726241114633461077313855600834804381290465079849847747915993679982507284850587974208448030949431871577562449843966118553162398703832584774393294980971848641550078628031232253568601121309330922516437554031027946142227246156440484735062446693325458518821";
    const char *e_str = "65537";  // Common value for e
				  //

    wrong_n = n_str;

    // Create BIGNUM objects
    BIGNUM *d = BN_new();
    BIGNUM *n = BN_new();
    BIGNUM *e = BN_new();
    BIGNUM *n_w = BN_new();

    // Convert decimal strings to BIGNUMs
    BN_dec2bn(&d, d_str);
    BN_dec2bn(&n, n_str);
    BN_dec2bn(&e, e_str);
    BN_dec2bn(&n_w, wrong_n);

    // Create buffers to hold binary data
    unsigned char d_bin[BUFFER_SIZE] = {0};
    unsigned char n_bin[BUFFER_SIZE] = {0};
    unsigned char e_bin[BUFFER_SIZE] = {0};
    unsigned char n_w_bin[BUFFER_SIZE] = {0};

    // Convert BIGNUMs to binary format
    int d_len = BN_bn2binpad(d, d_bin, BUFFER_SIZE);
    int n_len = BN_bn2binpad(n, n_bin, BUFFER_SIZE);
    int e_len = BN_bn2binpad(e, e_bin, BUFFER_SIZE);
    int n_w_len = BN_bn2binpad(n_w, n_w_bin, BUFFER_SIZE);

    // Ensure the lengths match the expected sizes
    if (d_len != BUFFER_SIZE || n_len != BUFFER_SIZE || e_len != BUFFER_SIZE) {
        fprintf(stderr, "Error: BIGNUM to binary conversion did not produce the expected size.\n");
        BN_free(d);
        BN_free(n);
        BN_free(e);
        return 1;
    }

    // Prepare buffer for encryption/decryption
    unsigned char buffer[BUFFER_SIZE] = "okey dokey\n";  // Example plaintext message

    // Encrypt the message
    public_encrypt_wrapper(buffer, n_bin, e_bin);

    printf("this is rlly encrypted: %s\n", buffer);

    // Decrypt the message
    public_decrypt_wrapper(buffer, n_w_bin, d_bin, (unsigned *)e_bin);

    // Print the decrypted message
    printf("Decrypted message fo sho: %s\n", buffer);

    // Free BIGNUM objects
    BN_free(d);
    BN_free(n);
    BN_free(e);

    return 0;
}
