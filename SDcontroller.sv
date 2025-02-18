module SDcontroller(
		// Controller to SD
		output reg CS1_n, SCLK, DO,
		input  DI,
		
		// Controller commands
		input  CLK, RST, CTRL_WRITE, CTRL_READ, 
		input  [31:0] WRITEBUFFER, ADDRESS,
		output BYTE_READY, CONTROLLER_READY,
		output [7:0] READBUFFER, 
	);
	
	typedef enum logic [3:0] {
		IDLE,
		INIT_POWERUP,
		INIT_CMD0,
		INIT_CMD55,
		INIT_CMD41,
		SEND,
		RECEIVE_WAIT,
		RECEIVE_BYTE,
		WAIT,
		READ,
		WRITE,
		ERROR
	} state_t;
	
	state_t STATE, RETURN;
	
	reg [24:0] COUNTER;
	reg BYTE_COUNTER;
	reg [55:0] DO_BUFFER;
	reg [7:0]  DI_BUFFER;
	
	always@(posedge CLK or negedge RST) begin
		// Initialize
		if (~RST) 			
			SCLK  <= 1'b0;
		else
			SCLK  <= ~SCLK;
	end
	
	always@(posedge SCLK or negedge RST) begin
		// Reset initialisation
		if (~RST) begin
			STATE <= INIT_POWERUP;
			CS1_n	<= 1'b0;
			DO		<= 1'b1;
			CONTROLLER_READY <= 1'b0;
			READ_READY       <= 1'b0;
			
			COUNTER <= 25'b0;
			
		end else begin
			
			case (STATE) 
				INIT_POWERUP:
					begin
						COUNTER <= COUNTER + 25'b1;
						
						if (COUNTER == 25'd25000000)
							CS1_n <= 1'b1;
						
						if (COUTNER == 25'b25000079) begin
							CS1_n <= 1'b0;
							STATE <= INIT_CMD0;
							COUNTER <= 1'b0;
						end
					end
					
				INIT_CMD0:
					begin
						COUNTER   <= 25'b0;
						DO_BUFFER <= 56'bFF_40_00_00_00_00_95;
						RETURN	 <= INIT_CMD55;		
						STATE 	 <= SEND;
					end
					
				INIT_CMD55:
					begin
						COUNTER   <= 25'b0;
						DO_BUFFER <= 56'bFF_77_00_00_00_00_01;
						RETURN	 <= INIT_CMD41;		
						STATE 	 <= SEND;
					end
				
				INIT_CMD41:
					begin
						COUNTER   <= 25'b0;
						DO_BUFFER <= 56'bFF_69_00_00_00_00_01;
						RETURN	 <= INIT_POLL;		
						STATE 	 <= SEND;
					end
					
				INIT_POLL:
					begin
						if (~DI_BUFFER[0])
							STATE <= IDLE;
						else
							STATE <= CMD55;
					end
					
				IDLE:
					begin
						if (CTRL_READ) 
							STATE <= READ_BLOCK;
						else if (CTRL_WRITE) 
							STATE <= WRITE_BLOCK;
						else
							STATE <= IDLE;
					end
					
				READ_BLOCK:
					begin	
						COUNTER   <= 25'b0;
						DO_BUFFER <= {16'hFF_51, address, 8'hFF};
						RETURN	 <= READ_BLOCK_WAIT;
						STATE		 <= SEND;
					end
					
				READ_BLOCK_WAIT:
					begin
						if (SCLK) begin
							if (~DI) begin
								BYTE_COUNTER <= 511;
								RETURN	<= READ_BLOCK_DATA;
								STATE		<= RECEIVE_BYTE;
							end
						end
					end
					
				READ_BLOCK_DATA:
					begin
						READBUFFER <= DI_BUFFER;
						BYTE_READY <= 1'b1;
						
						if (BYTE_COUNTER == 0) begin
							RETURN  <= READ_BLOCK_CRC;
							STATE	  <= RECEIVE_BYTE;
						end else begin
							BYTE_COUNTER <= BYTE_COUNTER - 1;
							RETURN		 <= READ_BLOCK_DATA;
							STATE			 <= RECEIVE_BYTE;
						end
					end
					
				RECEIVE_BYTE_CRC:
					begin
						RETURN	<= IDLE;
						STATE		<= RECEIVE_BYTE;
					end
					
				WRITE_BLOCK:
					begin
					end
					
				SEND:	
					begin
						DO_BUFFER <= {DO_BUFFER[54:0], 1'b0};
						
						if (COUNTER == 25'd56) begin
							COUNTER <= 25'b0;
							STATE   <= RECEIVE_BYTE_WAIT;
						end else begin
							COUTNER	<= COUNTER + 25'b1;
						end
					end
				
				RECEIVE_WAIT:
					begin
						if (SCLK) begin
							if (~DI) begin
								DI_BUFFER <= 8'b0;
								STATE		 <= RECIEVE_BYTE;
							end
						end
					end
					
				RECEIVE_BYTE:
					begin
						BYTE_READY <= 1'b0;
						if (SCLK) begin
							DI_BUFFER <= {DI_BUFFER[6:0], DI};
							if (COUNTER == 25'd6) begin
								COUNTER <= 25'd0;
								STATE   <= RETURN_STATE;
							end else begin
								COUNTER = COUNTER + 25'b1;
							end
						end
					end
					
				
				default:
					begin
					end
			endcase
		end
	end
	
	assign DO = DO_BUFFER[55];
	
endmodule 