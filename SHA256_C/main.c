// Standard (system) header files
#include <stdio.h>
#include "SHA256.h"

// Main program
int main (void)
{
	setvbuf(stdout, NULL, _IONBF, 0);

	//!Function to initialize the state registers
	initStateRegister ();

	//!Function to read the input string
	int stringLength = readString ();

	//!Function to perform padding operation
	padding (stringLength);

	//!Function to perform compression of input data
	sha256Compression();

	//!Function to print the compressed hash data
	print ();

	return 0;
}
