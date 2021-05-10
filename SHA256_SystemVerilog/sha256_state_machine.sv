package sha256_functions;

function [31:0]sigma0;
	input logic [31:0]num;
	
	sigma0 = {num[6:0],num[31:7]} ^ {num[17:0],num[31:18]} ^ (num >> 3);
endfunction

function [31:0]sigma1;
	input logic [31:0]num;
	
	sigma1 = {num[16:0], num[31:17]} ^ {num[18:0],num[31:19]} ^ (num >> 10);
endfunction

function [31:0]enigma0;
	input logic [31:0]num;

	enigma0 = {num[1:0], num[31:2]} ^ {num[12:0], num[31:13]} ^ {num[21:0], num[31:22]};
endfunction

function [31:0]enigma1;
	input logic [31:0]num;
	
	enigma1 = {num[5:0], num[31:6]} ^ {num[10:0], num[31:11]} ^ {num[24:0], num[31:25]};
endfunction

function [31:0]choice;
	input logic [31:0]num1, num2, num3;

	choice = ((num1 & num2) ^ ((~num1) & num3));
endfunction

function [31:0]majority;
	input logic [31:0]num1, num2, num3;

	majority = ((num1 & num2) ^ (num1 & num3) ^ (num2 & num3));
endfunction

endpackage


//###----- DIFFERENT STATES FOR STATE MACHINE -----###
package state_machine_definitions;
	enum logic [1:0] {__RESET = 2'b00,
			  __IDLE = 2'b01,
			  __PROC = 2'b10,
			  __DONE = 2'b11}state;
endpackage

//###------- STATE REGISTERS AND k-CONSTANTS ------###
package constants;
	logic [0:7][31:0]stateReg = {
				    32'h6a09e667,
				    32'hbb67ae85,
				    32'h3c6ef372,
				    32'ha54ff53a,
				    32'h510e527f,
				    32'h9b05688c,
				    32'h1f83d9ab,
				    32'h5be0cd19
				    };
					 
	logic [0:63][31:0]k = {
	32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
	32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
	32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc, 32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
	32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7, 32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
	32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13, 32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
	32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3, 32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
	32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5, 32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
	32'h748f82ee, 32'h78a5636f ,32'h84c87814, 32'h8cc70208, 32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
	};
	
endpackage	

//###------------------------------ SHA 256 STATE MACHINE --------------------------------###
module sha256_state_machine #(parameter MSG_SIZE = 24, parameter PADDED_MSG_SIZE = 512)
	(input logic [MSG_SIZE - 1 : 0]inputMsg,				// Input signal to be hashed
	input logic clk,							// System clock signal	
	input logic reset_n,							// System reset
	input logic start,							// Start signal that is used to generate the trigger signal used for processing
	output logic q_start,							// Trigger signal to begin the processing of SHA-256 in state machine
	output logic [1:0] q_state,						// Debug signal that indicates the state of the State machine
	output logic [255:0]hashOutput						// Final hash output of SHA-256
	);

	logic [31:0]h1, h2, h3, h4, h5, h6, h7, h8,				// Local and intermediate parameters used in the SHA-256 calculation
		    a, b, c, d, e, f, g, h, t1, t2;

	logic [63:0][31:0]W;							// 64 Word registers each of 32 bit

	localparam LOOP_ITERATIONS = 192;					// Iterations required for the state machine to process SHA-256
	logic [7:0]state_counter;						// Counter to loop through the state machine 
	logic [5:0]loopVariable = 6'd0;						// Parameter to loop between even and odd clock cycles
	
	//###------ PACKAGE IMPORTS ------###
	import state_machine_definitions::*;					// Package that holds the states of the state machine
	import constants::*;							// Package that holds the initial state registers and k-constants
	import sha256_functions::*;						// Package that holds the 6 standard SHA-256 functions

	
	//###---------- MESSAGE PADDING BLOCK ---------------###
	logic [PADDED_MSG_SIZE - 1:0] paddedMsg;
	
	localparam zeroPadding = PADDED_MSG_SIZE - MSG_SIZE - 1 - 64;
	localparam lengthPadding = 64 - $bits(MSG_SIZE);
	
	assign paddedMsg = {inputMsg, 1'b1, {zeroPadding{1'b0}}, {lengthPadding{1'b0}}, MSG_SIZE};
	//###----------- END OF PADDING BLOCK -------------###
	
	//###---------- SYNC_START GENERATION -----------###
	logic [3:0] sync_reg = 4'b0000;
	always_ff@(posedge clk)
	    begin : start_detection
		if(reset_n == 1'b0)
 		   sync_reg <= 4'b0000;
		else
		   // Shifting data from the right-hand side, shifting everything to the left
		   sync_reg <= {sync_reg[2:0],start};
	    end : start_detection

	logic sync_start;              
	//                                                            __
	// To generate a trigger signal for processing state  -->  __|  |__
	assign sync_start = (sync_reg == 4'b0011) ? 1'b1 : 1'b0;
	//###---------- END OF SYNC_START GENERATION ---------###

	
	//###------- STATE MACHINE ------###
	always_ff@(posedge clk)
	   begin : state_machine
		if(reset_n == 1'b0)
		    begin
			state		<= 	__RESET;
		    end
		else
		    case(state)
		     __RESET : begin	
			state_counter    <= 	8'd15;
			state		 <= 	__IDLE;
		     end

		     __IDLE : begin
			//Initialisation of state registers
			 a		<=	stateReg[0];
			 b		<=	stateReg[1];
			 c		<=	stateReg[2];
			 d		<=	stateReg[3];
			 e		<=	stateReg[4];
			 f		<=	stateReg[5];
			 g		<=	stateReg[6];
			 h		<=	stateReg[7];	
			//On activation of the sync_start signal switch to __PROC state
			if(sync_start)
			    state 	<= 	__PROC;
		        end
				
		    __PROC : begin
			// Update initial 16 word registers with padded message
			if(state_counter == 15)	begin
				W[15]	<= 	paddedMsg[31:0];
				W[14]	<=	paddedMsg[63:32];
				W[13]	<=	paddedMsg[95:64];
				W[12]	<=	paddedMsg[127:96];
				W[11]	<=	paddedMsg[159:128];
				W[10]	<=	paddedMsg[191:160];
				W[9]	<=	paddedMsg[223:192];
				W[8]	<=	paddedMsg[255:224];
				W[7]	<=	paddedMsg[287:256];
				W[6]	<=	paddedMsg[319:288];
				W[5]	<=	paddedMsg[351:320];
				W[4]	<=	paddedMsg[383:352];
				W[3]	<=	paddedMsg[415:384];
				W[2]	<=	paddedMsg[447:416];
				W[1]	<=	paddedMsg[479:448];
				W[0]	<=	paddedMsg[511:480];
			end

			else if (state_counter > 15 && state_counter < 64) 
			begin	// Update word registers from W[16] to W[64]
				W[state_counter] <= (sigma1(W[state_counter - 2]) + W[state_counter - 7] + sigma0(W[state_counter - 15]) + W[state_counter - 16]);
			end
			//###-------- COMPRESSION --------###
			else if (state_counter >= 64 && state_counter < 192) begin 
				// Values of t1 and t2 have to be available before the calculation of state registers, 
				// Therefore, they are calculated one cycle prior (even cycles)
				// Both the code path (if and else) are executed 64 times in alternate cycles
				if(state_counter % 2 == 0)begin
				t1		<= 	h + enigma1(e) + choice(e,f,g) + k[loopVariable] + W[loopVariable];
				t2 		<= 	enigma0(a) + majority(a,b,c);
				loopVariable 	<= 	loopVariable + 1;
				end
				// Assign and calculate the state registers in the odd cycles
				else begin
				h	<= 	g;
				g	<=	f;				
				f	<= 	e;
				e	<= 	d + t1;
				d	<= 	c;
				c	<= 	b;
				b	<= 	a;
				a	<= 	(t1 + t2); 
				end
			end
			
			else begin 
				// Update hash registers
				h1 	<= 	stateReg[0] + a;
				h2	<= 	stateReg[1] + b;
				h3	<= 	stateReg[2] + c;
				h4	<= 	stateReg[3] + d;
				h5	<= 	stateReg[4] + e;
				h6	<= 	stateReg[5] + f;
				h7	<= 	stateReg[6] + g;
				h8	<= 	stateReg[7] + h;
			end
			// Hashing is done if the state_counter counts through the total number of iterations, set the state to __DONE
			if(state_counter == LOOP_ITERATIONS)
			begin
			  state_counter	<= 8'd15;
			  state 	<=	__DONE;
			end
			// Hashing is still pending, increment the state_counter and return to __PROC state
			else
			begin
			  state_counter <= 	state_counter + 1;
			  state		<=	__PROC;
			end
			
			end
		        // After hashing, return to __IDLE state and wait for the next trigger signal to start processing
		    __DONE: begin
			state		<=	__IDLE;
			end
		
		default: begin
			state		<=	__RESET;
		end
		
			endcase	
	end : state_machine
	//###-------- END OF STATE MACHINE --------###

	// For better illustration purpose during simulation
	assign q_start	  =	sync_start;
	assign q_state	  =	state;
	
	// Concatenate the hash registers to obtain the final hash output of 256 bits
	assign hashOutput = 	{h1, h2, h3, h4, h5, h6, h7, h8};

endmodule
//###---------------------- END OF SHA-256 STATE MACHINE DESIGN FILE --------------------------------###