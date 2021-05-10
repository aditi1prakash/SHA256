`timescale 1ns/1ns

`define HALF_CLOCK_PERIOD	10		// To generate clock of 50Mhz, each clock cycle is 20ns --> HALF_CLOCK_PERIOD = 10ns
`define RESET_PERIOD 		10		// Assert reset after 10ns
`define DELAY					200	// Delay period for 200ns
`define DATA_PERIOD			50		// Small delay for read, write and address assertion

/*
 * Input message = hello world
 * Hash output   = b9 4d 27 b9 93 4d 3e 8 a5 2e 52 d7 da 7d ab fa c4 84 ef e3 7a 53 80 ee 90 88 f7 ac e2 ef cd e9
*/

module sha256_wrapper_v4_tb();

    // Testbench parameter declarations 
    logic tb_local_clock = 0;
    logic tb_local_reset_n = 0;
    logic tb_rden = 0;
    logic tb_wren = 0;
    logic [1:0]tb_address;
    logic [0:15][31:0]tb_inputMsg; 
    logic [0:7][31:0]tb_readHashOutput;
    logic [1:0]tb_q_state;
    logic [31:0]tb_reg_data_in = 32'd0;

    integer i = 0;

    //###--------- CLOCK GENERATION ---------###
    
      initial
	begin: clock_generation_process
	  tb_local_clock = 0;
	    forever begin
		#`HALF_CLOCK_PERIOD tb_local_clock = ~tb_local_clock;
	    end
	end
    //###------ END OF CLOCK GENERATION ------###

		 
    //###-------- SIMULATION ---------###
    initial 
      begin: reset_generation_process
	$display ("Simulation starts...");
	
	//Reset assertion
	#`RESET_PERIOD tb_local_reset_n	=  1'b1;
	
	// Initialise input message to 0
	for(i = 0; i < 16; i = i+1) begin
	    tb_inputMsg[i] = 32'd0;
	end
	
	// Assert start signal to start sha256 processor
	#`DATA_PERIOD tb_wren = ~tb_wren; tb_address = 2'd0; tb_reg_data_in = 32'd1;
	
	// Load input message for sha256 to process
	#`DATA_PERIOD tb_address = 2'd2; 
	tb_inputMsg = {32'h68656c6c,32'h6f20776f,32'h726c6480,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h0,32'h58};
	
	// Time delay to allow sha256 processor to process the output
	#(`DELAY*10)
	tb_wren = 1'b0;

	// Read processed hash output of sha-256
	#(`DATA_PERIOD) tb_address = 2'd3;
	#(`DATA_PERIOD) tb_rden = ~tb_rden;
	#(`DELAY*10)

	$display ("Simulation done ...");
	$stop();
   end
   //###------ END OF SIMULATION -------###
	
    // Instantiate the co-processor module
    sha256_wrapper_v4 inst_0(
			 .clk(tb_local_clock),
			 .reset_n(tb_local_reset_n),
			 .wren(tb_wren),
			 .rden(tb_rden),
			 .address(tb_address),
			 .reg_data(tb_reg_data_in),
			 .data_in(tb_inputMsg),
			 .data_out(tb_readHashOutput),
			 .q_state(tb_q_state));
								
	 // String to indicate the state of the state machine
    logic [12*8:1] state_string;		
  
    // ASCII string
    always@(tb_q_state)
      case(tb_q_state)
	 2'b00: state_string = "RESET_STATE";
	 2'b01: state_string = "IDLE_STATE";
	 2'b10: state_string = "PROC_STATE";
	 2'b11: state_string = "DONE_STATE";
      endcase
		
endmodule