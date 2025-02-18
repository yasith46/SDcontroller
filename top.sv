module top(
	input CLK, RST,

	// SD card I/O
	output SD_CLK,
	inout reg [3:0] SD_DAT,
	inout SD_CMD,
	input SD_WP_N,
	
	// Seven segment
	output [6:0] SEG7, SEG6, SEG5, SEG4, SEG3, SEG2, SEG1, SEG0
	);
	
endmodule 