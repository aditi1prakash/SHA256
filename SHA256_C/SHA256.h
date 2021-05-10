/*
 * SHA256.h
 *
 *  Created on: 23-Nov-2020
 *      Author: Aditi Prakash
 */

#ifndef SHA256_H_
#define SHA256_H_

#include <stdio.h>

/*!=============================== MACROS ========================================*/
#define 	LENGTH64BYTE		64

/*!
 * \brief: Function to initialize the state registers
 * \details: The constants are initialized with square root of prime numbers
 * \param [IN]: NONE
 * \param [OUT]: NONE
 * \return: NONE
 */
void initStateRegister ();

/*
 * @brief: Function to read the input string to be hashed
 * @param [IN]: NONE
 * @param [OUT]: NONE
 * @return: NONE
 */
size_t readString ();

/*
 * @brief: Function to perform initial padding to 512 bits or n*512
 * @param [IN]: NONE
 * @param [OUT]: NONE
 * @return: NONE
 */
void padding (int stringLength);

/*!
 * \brief: Function to perform hashing and compression of the data
 * \param [IN]: NONE
 * \param [OUT]: NONE
 * \return: NONE
 */
void sha256Compression();

/*!
 * \brief: Function to print the hash data
 * \param [IN]: NONE
 * \param [OUT]: NONE
 * \return: NONE
 */
void print ();

#endif /* SHA256_H_ */
