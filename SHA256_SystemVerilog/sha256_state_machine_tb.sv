`timescale 1ns/1ns

`define HALF_CLOCK_PERIOD	10		// To generate clock of 50Mhz, each clock cycle is 20ns --> HALF_CLOCK_PERIOD = 10ns
`define RESET_PERIOD 		10		// Assert reset after 10ns
`define DELAY			200		

/*
 * Input message = hello world
 * Hash output   = b9 4d 27 b9 93 4d 3e 8 a5 2e 52 d7 da 7d ab fa c4 84 ef e3 7a 53 80 ee 90 88 f7 ac e2 ef cd e9
*/

module sha256_state_machine_tb();
	
    // Testbench parameter declarations 
    logic [87:0]tb_inputMsg;
    logic tb_q_start;
    logic [1:0]tb_q_state;
    logic [255:0]tb_hashOutput;
    logic tb_start = 0; 
    logic tb_local_reset_n = 0;
    integer i = 0;

    //###--------- CLOCK GENERATION ---------###
    logic tb_local_clock = 0;
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
	//Initialize hash output to zero
	tb_hashOutput = 256'd0;
	//Reset assertion
	#`RESET_PERIOD tb_local_reset_n	=  1'b1;
	// Start pulse generation
	tb_inputMsg = "hello world";
	for(i=0; i < 32; i = i+1) begin
	    #`DELAY if(i % 8 == 0) tb_start = ~tb_start;
	end
	$display ("Simulation done ...");
	$stop();
      end
     //###------ END OF SIMULATION -------###

    // Instantiation of the state machine
    sha256_state_machine #(.MSG_SIZE(88), .PADDED_MSG_SIZE(512)) inst_0(
								.clk(tb_local_clock),
								.reset_n(tb_local_reset_n),
								.start(tb_start),
								.inputMsg(tb_inputMsg),
								.q_start(tb_q_start),
								.q_state(tb_q_state),
								.hashOutput(tb_hashOutput));

     //String to indicate the state of the state machine
    logic [12*8:1] state_string;		

    //ASCII string
    always@(tb_q_state)
      case(tb_q_state)
	 2'b00: state_string = "RESET_STATE";
	 2'b01: state_string = "IDLE_STATE";
	 2'b10: state_string = "PROC_STATE";
	 2'b11: state_string = "DONE_STATE";
      endcase

endmodule

