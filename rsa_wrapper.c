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

	// Set e
	const char *decimal_str = "65537";
    	BN_dec2bn(&e, decimal_str);


	// Converting the binary data into BIGNUM objects
	BN_bin2bn(public_n, 256, n);
	//BN_bin2bn(public_e, 32, e);
	RSA_set0_key(rsa, n, e, NULL);

	int encrypt = RSA_public_encrypt(256, buffer, buffer, rsa, RSA_NO_PADDING);

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


	// Decryption
	int decrypt = RSA_private_decrypt(256, buffer, buffer, rsa, RSA_NO_PADDING);

	// Freeing memory
	/*
	RSA_free(rsa);
	BN_free(n);
	BN_free(d);
	BN_free(e);
	*/

}
