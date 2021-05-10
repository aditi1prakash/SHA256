/* Register set
 * 1. CTRL REGISTER  			: Control bits to start the sha256 processing
 * 	32'd1 = start
 * 2. STATUS_REGISTER		 	: Register to indicate completion of sha 256
 * 	32'd1 = done
 * 3. DATA_IN					  	: 16x32 bit registers (512 bits) for input data
 * 4. DATA_OUT					  	: 8x32 bit registers (256 bits) for output data
 */

module sha256_wrapper_v4(
		input logic clk,									
		input logic reset_n,								
		input logic wren,									// Signal to enable CPU to write onto the registers
		input logic rden,									// Signal to enable CPU to read from the registers
		input logic [1:0]address,						// Address offset to select the register		
		input logic [31:0]reg_data,					// Register to get the value for control and status registers from CPU
		input logic [0:15][31:0]data_in,				// Register that provides input data from the CPU (testbench)
		output logic [0:7][31:0]data_out,			// Register that contains hashed output from SHA256 co-processor
		output logic [1:0]q_state						// Variable that indicates the state of the SHA256 co-processor
		);
		
		integer i = 0;
		
		// Control and Status register definition
		logic [31:0] ctrl_register; logic [31:0] status_register;
		
		// Register to store the input data
		logic [0:15][31:0] input_register; 
		
		// Local variables for start, done and q_start (net for sha-256)
		logic start = 0; logic done = 0; logic q_start;

		// Register to store the output data from SHA-256 after the processing is done
		logic [255:0] output_register = 256'd0; logic [255:0]hashOutput = 256'd0;

		
		//-----#### WRITE BLOCK ####-----//
		always_ff@(posedge clk)
		if(reset_n == 1'b0)
			begin
				ctrl_register <= 32'd0;
	
				// Initialise the input register to 0
				for (i = 0; i < 16; i++) begin
					input_register[i] <= 32'd0;
				end
			end
		else 
		   // If write is asserted, then check for the address and assign respective data
			if(wren)
			begin
				case (address) 
				// The 0th bit of control register indicates the start input from the CPU to begin SHA-256 processing
				0: ctrl_register <= reg_data;
				// The input data provided by the CPU is stored in the registers
				2: begin
					input_register[0] <= data_in[0];
					input_register[1] <= data_in[1];
					input_register[2] <= data_in[2];
					input_register[3] <= data_in[3];
					input_register[4] <= data_in[4];
					input_register[5] <= data_in[5];
					input_register[6] <= data_in[6];
					input_register[7] <= data_in[7];
					input_register[8] <= data_in[8];
					input_register[9] <= data_in[9];
					input_register[10] <= data_in[10];
					input_register[11] <= data_in[11];
					input_register[12] <= data_in[12];
					input_register[13] <= data_in[13];
					input_register[14] <= data_in[14];
					input_register[15] <= data_in[15];
				end
				endcase
			end
			//	In case of invalid signal - update registers with error values. This part should not be
			// executed under normal operation of the code
			else
				begin
					ctrl_register <= 32'hDEADBEEF;
				
					for (i = 0; i < 16; i++) begin
						input_register[i] <= 32'hDEADBEEF;
					end
				end
		
	
	always_ff@(posedge clk)
	begin
		if(reset_n == 1'b0)
			status_register <= 32'd0;
		// Start the SHA256 processor if there is start input from CPU
		if(ctrl_register == 32'd1)
			start <= 1;
		// Update the status register upon completion of SHA256 compression
		if(done)
			status_register <= 32'd1;
		// Control should not execute this part under normal conditions
		else
			status_register <= 32'hDEADBEEF;
	end

	integer j;
	// Latch is used since all the output is not being updated in the combinational block
	always_latch
		begin
			// Upon done assertion from SHA processor, load the output into local register
			if(status_register == 32'd1)
			begin
				output_register = hashOutput;
			end
			
			// If CPU asserts read signal, update the register with hash output
			if(rden)
				begin
					data_out[0] = output_register[255:224];
					data_out[1] = output_register[223:192];
					data_out[2] = output_register[191:160];
					data_out[3] = output_register[159:128];
					data_out[4] = output_register[127:96];
					data_out[5] = output_register[95:64];
					data_out[6] = output_register[63:32];
					data_out[7] = output_register[31:0];
				end
			// Without read assertion, store 0 as the default value in the output register
			else
				begin
					for (j = 0; j < 8; j++) begin
						data_out[j] = 32'd0;
					end
				end
		end	

			
    // Instantiation of the state machine
    sha256_state_machine inst_0(
		  						.clk(clk),
								.reset_n(reset_n),
								.start(start),
								.q_start(q_start),
								.q_done(done),
								.paddedMsg(input_register),
								.q_state(q_state),
								.hashOutput(hashOutput));
		
endmodule