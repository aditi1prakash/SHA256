/*
 * SHA256.c
 *
 *  Created on: 23-Nov-2020
 *      Author: Aditi Prakash
 */

#include "SHA256.h"
#include "stdio.h"
#include <string.h>
#include <stdlib.h>

/*!==================== SHA-256 PRE-DEFINED FUNCTION MACROS ======================*/
#define ROTLEFT(num, rotation)		((num << rotation) | (num >> (32 - rotation)))
#define ROTRIGHT(num, rotation)		((num >> rotation) | (num << (32 - rotation)))

#define SIGMA0(num)					((ROTRIGHT (num, 7)) ^ (ROTRIGHT (num , 18)) ^ (num >> 3))
#define SIGMA1(num)					((ROTRIGHT (num, 17)) ^ (ROTRIGHT (num, 19)) ^ (num >> 10))
#define ENIGMA0(num)				((ROTRIGHT (num, 2)) ^ (ROTRIGHT (num, 13)) ^ ROTRIGHT (num, 22))
#define ENIGMA1(num)				((ROTRIGHT (num, 6)) ^ (ROTRIGHT (num, 11)) ^ ROTRIGHT (num, 25))
#define CHOICE(num1, num2, num3)	(((num1) & (num2)) ^ (~(num1) & (num3)))
#define MAJORITY(num1, num2, num3)	(((num1) & (num2)) ^ ((num1) & (num3)) ^ ((num2) & (num3)))

/*!==================================== GLOBAL DEFINES ============================================*/
unsigned char data[100] = {0};
const int paddingByte = 0x00;
unsigned int stateRegister [8] = {0};
unsigned int a, b, c, d, e, f, g, h, T1, T2;
unsigned char hash [32] = {0};
unsigned long long bitLength = 0;

/*!======================= SHA-256 constant: Cube roots of prime numbers ===========================*/
static const unsigned int k[LENGTH64BYTE] =
{
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f ,0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

/*!
 * \brief: Function to read the input string to be hashed
 * \param [IN]: NONE
 * \param [OUT]: NONE
 * \return: Returns the size of the input string
 */
size_t readString ()
{
	//Read the string
	printf ("Enter the string\n");

	gets(data);

	char strLength = strlen(data);

	return strLength;
}

/*!
 * \brief: Function to initialize the state registers
 * \details: The constants are initialized with square root of prime numbers
 * \param [IN]: NONE
 * \param [OUT]: NONE
 * \return: NONE
 */
void initStateRegister ()
{
	stateRegister [0] = 0x6a09e667;
	stateRegister [1] = 0xbb67ae85;
	stateRegister [2] = 0x3c6ef372;
	stateRegister [3] = 0xa54ff53a;
	stateRegister [4] = 0x510e527f;
	stateRegister [5] = 0x9b05688c;
	stateRegister [6] = 0x1f83d9ab;
	stateRegister [7] = 0x5be0cd19;

	a = stateRegister [0];
	b = stateRegister [1];
	c = stateRegister [2];
	d = stateRegister [3];
	e = stateRegister [4];
	f = stateRegister [5];
	g = stateRegister [6];
	h = stateRegister [7];

}

/*!
 * \brief: Function to perform initial padding to 512 bits or n*512
 * \param [IN]: strLength - Length of the input string
 * \param [OUT]: NONE
 * \return: NONE
 */
void padding (int strLength)
{
	unsigned int i = 0;

	//!Adding Separation bit to the input string
	data[strLength] = 0x80;

	if (strLength < LENGTH64BYTE)
	{
		for (i = strLength + 1; i < 56; i++)
		{
			data[i] = paddingByte;
		}
	}
	else
	{
		//TODO: When data is greater than 512 bits (64 bytes)
	}

	//!To calculate the number of bits
	bitLength = (strLength * 8);

	//! Append to the padding the total message's length in bits and transform.
	data[63] = bitLength;
	data[62] = bitLength >> 8;
	data[61] = bitLength >> 16;
	data[60] = bitLength >> 24;
	data[59] = bitLength >> 32;
	data[58] = bitLength >> 40;
	data[57] = bitLength >> 48;
	data[56] = bitLength >> 56;
}

/*!
 * \brief: Function to perform hashing and compression of the data
 * \param [IN]: NONE
 * \param [OUT]: NONE
 * \return: NONE
 */
void sha256Compression()
{
	unsigned int message[LENGTH64BYTE] = {0}, i = 0;

	//!Split the padded data into 32 bit words.
	for (int i = 0; i < 16; ++i)
	{
		message[i] = (data[i * 4] << 24) |
					 (data[(i * 4) + 1] << 16) |
					 (data[(i * 4) + 2] << 8) |
					 (data[(i * 4) + 3]);
//		printf("message[%d] = %x\n", i, message[i]);
	}

	//!Create message schedule for the remaining words until 64 words long
	for (i = 16 ; i < LENGTH64BYTE; ++i)
	{
		message[i] = SIGMA1(message[i - 2]) + message[i - 7] + SIGMA0(message[i - 15]) + message[i - 16];
//		printf("message[%d] = %x\n", i, message[i]);
	}

	//!Compression operation to obtain final compressed hash
	for (i = 0; i < 64; ++i)
	{
		T1 = h + ENIGMA1(e) + CHOICE(e,f,g) + k[i] + message[i];
		T2 = ENIGMA0(a) + MAJORITY(a,b,c);
		h = g;
		g = f;
		f = e;
		e = d + T1;
		d = c;
		c = b;
		b = a;
		a = T1 + T2;
	}
//	printf ("%x\n",a);

	//!Add final compressed hash to the initial hash
	stateRegister[0] += a;
	stateRegister[1] += b;
	stateRegister[2] += c;
	stateRegister[3] += d;
	stateRegister[4] += e;
	stateRegister[5] += f;
	stateRegister[6] += g;
	stateRegister[7] += h;

	//!The system works on Little Endian, SHA-256 uses Big Endian.
	//!Below operation converts data from Little Endian to Big Endian.
	for (unsigned int i = 0; i < 4; ++i)
	{
		hash[i]      = (stateRegister[0] >> (24 - (i * 8))) & 0x000000ff;
		hash[i + 4]  = (stateRegister[1] >> (24 - (i * 8))) & 0x000000ff;
		hash[i + 8]  = (stateRegister[2] >> (24 - (i * 8))) & 0x000000ff;
		hash[i + 12] = (stateRegister[3] >> (24 - (i * 8))) & 0x000000ff;
		hash[i + 16] = (stateRegister[4] >> (24 - (i * 8))) & 0x000000ff;
		hash[i + 20] = (stateRegister[5] >> (24 - (i * 8))) & 0x000000ff;
		hash[i + 24] = (stateRegister[6] >> (24 - (i * 8))) & 0x000000ff;
		hash[i + 28] = (stateRegister[7] >> (24 - (i * 8))) & 0x000000ff;
	}
}

/*!
 * \brief: Function to print the hash data
 * \param [IN]: NONE
 * \param [OUT]: NONE
 * \return: NONE
 */
void print()
{
	for (unsigned int i = 0; i < 32; i++)
	{
		printf ("%x ", hash[i]);
	}
}
