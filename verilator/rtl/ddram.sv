module ddram (
    input         reset,
	input         DDRAM_CLK,

	input         DDRAM_BUSY,
	output logic [7:0] DDRAM_BURSTCNT,
	output logic [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output logic  DDRAM_RD,
	output logic [63:0] DDRAM_DIN,
	output logic [7:0] DDRAM_BE,
	output logic      DDRAM_WE,

	input  [27:0] addr  /* verilator public */,        // 256MB at the end of 1GB
	output  [7:0] dout  /* verilator public */,        // data output to cpu
	input   [7:0] din  /* verilator public */,         // data input from cpu
	input         we /* verilator public */,          // cpu requests write
	input         rd /* verilator public */,          // cpu requests read
	output        ready /* verilator public */,        // dout is valid. Ready to accept new read/write.
	output [63:0] dout64 /* verilator public */,
	input [255:0] debug_data /* verilator public */,
	input         debug_wr /* verilator public */	
);


typedef enum logic [2:0] {INIT, IDLE, READ, DEBUG, DEBUG_BLOCK} state_t; 

logic   old_rd, old_we, old_debug_wr;
logic   rd_rq, wr_rq, debug_rq, cache_en;
logic  [7:0] cached;
logic  [7:0] ram_q;
logic [27:0] ram_address;
logic [23:0] debug_address;
logic [63:0] ram_cache;

state_t state;

wire ready_int    = state == IDLE || DDRAM_BUSY;
//assign dout     = ram_q;
//assign dout64   = ram_cache;

assign rd_rq    = ~old_rd && rd;
assign wr_rq    = ~old_we && we;
assign debug_rq = ~old_debug_wr && debug_wr;

assign cache_en = (ram_address[27:3] == addr[27:3]) && ((cached & (8'd1 << addr[2:0])) != 8'd0);

always @(posedge DDRAM_CLK)
begin
	
	logic old_reset;
	
	old_reset <= reset;
	old_rd <= rd;
	old_we <= we;
	old_debug_wr <= debug_wr;

	if(old_reset && ~reset) begin
		state  <= INIT;
		cached <= 0;
	end

	if(rd_rq && cache_en) begin
		ram_q <= ram_cache[{addr[2:0], 3'b000} +:8];
	end

	if(!DDRAM_BUSY) begin
		DDRAM_RD <= 0;
		DDRAM_WE <= 0;

		case(state)
			INIT: begin
					DDRAM_BURSTCNT <= 1;
					DDRAM_BE       <= 8'hFF;
					DDRAM_ADDR     <= {5'b00110, 24'h400000}; // RAM at 0x32000000
					DDRAM_DIN      <= {32'd0, 32'hDEAD0000};
					DDRAM_WE 	   <= 1;
					debug_address  <= 24'h420000;
					state <= IDLE;
			end
			IDLE: begin
				if(wr_rq) begin
					DDRAM_BURSTCNT                     <= 1;
					DDRAM_WE 	                       <= 1;
					DDRAM_BE                           <= (8'd1<<addr[2:0]);			
					DDRAM_DIN[{addr[2:0], 3'b000} +:8] <= din;				
					DDRAM_ADDR                         <= {4'b0011, addr[27:3]}; // RAM at 0x30000000

					ram_cache[{addr[2:0], 3'b000} +:8] <= din;
					ram_address                        <= addr;			
					cached                             <= ((ram_address[27:3] == addr[27:3]) ? cached : 8'h00) | (8'd1<<addr[2:0]);
				end

				if(rd_rq && ~cache_en) begin
					DDRAM_BURSTCNT <= 1;
					DDRAM_RD       <= 1;
					DDRAM_BE       <= 8'hFF;
					DDRAM_ADDR     <= {4'b0011, addr[27:3]}; // RAM at 0x30000000
					state          <= READ;
					cached         <= 0;
					ram_address    <= addr;
				end else begin
					if (debug_rq && ~wr_rq) begin
						DDRAM_BURSTCNT <= 4;
						DDRAM_DIN      <= debug_data[63:0];
						DDRAM_ADDR     <= {5'b00110, debug_address}; // RAM at 0x30000000
						DDRAM_BE       <= 8'hFF;
						DDRAM_WE 	   <= 1;
						debug_address  <= debug_address + 24'h1;
						state          <= DEBUG;
					end
				end
			end
			READ: begin
				if(DDRAM_DOUT_READY) begin
					ram_q     <= DDRAM_DOUT[{ram_address[2:0], 3'b000} +:8];
					ram_cache <= DDRAM_DOUT;
					cached    <= 8'hFF;
					state     <= IDLE;
				end	
			end
			DEBUG: begin
					DDRAM_DIN      <= debug_data[{debug_address[1:0], 6'b000000} +:64];
					DDRAM_WE 	   <= 1;
					if (debug_address[1:0] == 3) begin
						if (debug_address[16:0] == 17'h1FFFF) begin
							state <= DEBUG_BLOCK;
						end else begin
							state     <= IDLE;
							debug_address  <= debug_address + 24'h1;
						end
					end else begin
						debug_address  <= debug_address + 24'h1;
					end
			end
			DEBUG_BLOCK: begin
				DDRAM_BURSTCNT <= 1;
				DDRAM_BE       <= 8'hFF;
				DDRAM_ADDR     <= {5'b00110, 24'h400000}; // RAM at 0x32000000
				DDRAM_DIN      <= {32'd0, 8'hDE, 8'hAD, 8'h01, 5'h0, debug_address[19:17]};
				DDRAM_WE 	   <= 1;
				if (debug_address[19:17] == 3'd4) begin
					debug_address  <= 24'h421000;
				end else begin
					debug_address  <= debug_address + 24'h1;
				end
				state <= IDLE;
			end
			default: ;
		endcase
	end
end

endmodule

/*
typedef enum logic [1:0] {INIT, IDLE, READ, DEBUG} state_t; 

logic   old_rd, old_we, old_debug_wr;
logic   rd_rq, wr_rq, debug_rq, cache_en;
logic  [7:0] cached;
logic  [7:0] ram_q;
logic [27:0] ram_address;
logic [24:0] debug_address;
logic [63:0] ram_cache;

state_t state;

assign ready    = state == IDLE || DDRAM_BUSY;
assign dout     = ram_q;

assign rd_rq    = ~old_rd && rd;
assign wr_rq    = ~old_we && we;
assign debug_rq = ~old_debug_wr && debug_wr;

assign cache_en = (ram_address[27:3] == addr[27:3]) && ((cached & (8'd1 << addr[2:0])) != 8'd0);

always @(posedge DDRAM_CLK)
begin
	
	logic old_reset;
	
	old_reset <= reset;
	if(old_reset && ~reset) begin
		state  <= IDLE;
		cached <= 0;
	end

	if(rd_rq && cache_en) begin
		ram_q <= ram_cache[{addr[2:0], 3'b000} +:8];
	end

	if(!DDRAM_BUSY) begin
		DDRAM_RD <= 0;
		DDRAM_WE <= 0;

		case(state)
			IDLE: begin
				old_rd <= rd;
				old_we <= we;
				old_debug_wr <= debug_wr;

				if(wr_rq) begin
					DDRAM_BURSTCNT                     <= 1;
					DDRAM_WE 	                       <= 1;
					DDRAM_BE                           <= (8'd1<<addr[2:0]);			
					DDRAM_DIN[{addr[2:0], 3'b000} +:8] <= din;				
					DDRAM_ADDR                         <= {4'b0011, addr[27:3]}; // RAM at 0x30000000

					ram_cache[{addr[2:0], 3'b000} +:8] <= din;
					ram_address                        <= addr;			
					cached                             <= ((ram_address[27:3] == addr[27:3]) ? cached : 8'h00) | (8'd1<<addr[2:0]);
				end

				if(rd_rq && ~cache_en) begin
					DDRAM_BURSTCNT <= 1;
					DDRAM_RD       <= 1;
					DDRAM_BE       <= 8'hFF;
					DDRAM_ADDR     <= {4'b0011, addr[27:3]}; // RAM at 0x30000000
					state          <= READ;
					cached         <= 0;
					ram_address    <= addr;
				end else begin
					if (debug_rq && ~wr_rq) begin
						DDRAM_BURSTCNT <= 4;
						DDRAM_DIN      <= debug_data[63:0];
						DDRAM_ADDR     <= {4'b0011, debug_address}; // RAM at 0x30000000
						DDRAM_BE       <= 8'hFF;
						DDRAM_WE 	   <= 1;
						state          <= DEBUG;
					end
				end
			end
			READ: begin
				if(DDRAM_DOUT_READY) begin
					ram_q     <= DDRAM_DOUT[{ram_address[2:0], 3'b000} +:8];
					ram_cache <= DDRAM_DOUT;
					cached    <= 8'hFF;
					state     <= IDLE;
				end	
			end
			default: ;
		endcase
	end
end

/*

/*
logic [63:0] debug_cache[4][4];
logic  [1:0] debug_pointer_wr, debug_pointer_send, debug_pointer_part;
logic        debug_old_wr, debug_send;
logic [27:0] debug_ram_address = 28'h2000000;
//assign DDRAM_BURSTCNT = 1;
assign DDRAM_BE       = 8'hFF; //(8'd1<<ram_address[2:0]) | {8{ram_read}};
assign DDRAM_ADDR     = {4'b0011, ram_address[27:3]}; // RAM at 0x30000000
assign DDRAM_RD       = ram_read;
assign DDRAM_DIN      = ram_cache;
assign DDRAM_WE       = ram_write;

// assign dout = ram_q;
// assign ready = ~busy;

reg  [7:0] ram_q;
reg [27:0] ram_address;
reg        ram_read;
reg [63:0] ram_cache;
reg        ram_write;
reg  [7:0] cached;
reg        busy;

wire [1:0] debug_pointer_send_next = debug_pointer_send + 2'd1;

always @(posedge DDRAM_CLK)
begin
	reg old_rd, old_we;
	reg old_reset;
	reg state;

	old_reset <= reset;
	if(old_reset && ~reset) begin
		busy   <= 0;
		state  <= 0;
		cached <= 0;
		debug_pointer_wr <= 0;
		debug_pointer_send <= 0;
		debug_pointer_part <= 0;
		debug_send <= 0;
		debug_ram_address <= 28'h2000000;
	end

	if(!DDRAM_BUSY)
	begin
		ram_write <= 0;
		ram_read  <= 0;
		if(state) begin
			if(DDRAM_DOUT_READY) begin		//state = 0 ceka ney prijdou data
				ram_q     <= DDRAM_DOUT[{ram_address[2:0], 3'b000} +:8];
				ram_cache <= DDRAM_DOUT;
				cached    <= 8'hFF;
				state     <= 0;
				busy      <= 0;
				DDRAM_BURSTCNT <= 8'd1;
			end
		end
		else begin // state = 1
			old_rd <= rd;
			old_we <= we;
			debug_old_wr <= debug_wr;
			busy   <= 0;

			if (debug_send) begin
				ram_cache <=  debug_cache[debug_pointer_send][debug_pointer_part];
				debug_pointer_part <= debug_pointer_part + 2'd1;
				ram_write 	<= 1;
				if (debug_pointer_part == 2'b11) begin
					debug_pointer_send <= debug_pointer_send_next;
					if (debug_pointer_send_next == debug_pointer_wr) begin
						debug_send <= 1'b0;
					end
				end
			end

			if(~debug_old_wr && debug_wr) begin
				{debug_cache[debug_pointer_wr][0],debug_cache[debug_pointer_wr][1],debug_cache[debug_pointer_wr][2],debug_cache[debug_pointer_wr][3]} = debug_data;
				debug_pointer_wr <= debug_pointer_wr + 2'd1;
				DDRAM_BURSTCNT <= 8'd4;
				debug_send <= 1'b1;
				ram_cache <=  debug_cache[debug_pointer_send][debug_pointer_part];
				debug_pointer_part <= debug_pointer_part + 2'd1;
				ram_write 	<= 1;
				ram_address <= debug_ram_address;
				if (debug_ram_address < 28'hff0000)
					debug_ram_address <= debug_ram_address + 28'd32;				
			end

			if(~old_we && we) begin
				ram_cache[{addr[2:0], 3'b000} +:8] <= din;
				DDRAM_BURSTCNT <= 8'd1;
				ram_address <= addr;
				busy        <= 1;
				ram_write 	<= 1;
				cached      <= ((ram_address[27:3] == addr[27:3]) ? cached : 8'h00) | (8'd1<<addr[2:0]);
			end

			if(~old_rd && rd) begin
				if((ram_address[27:3] == addr[27:3]) && (cached & (8'd1<<addr[2:0])) != 0) begin
					ram_q <= ram_cache[{addr[2:0], 3'b000} +:8];
				end
				else begin
					ram_address <= addr;
					ram_read    <= 1;
					state       <= 1;
					cached      <= 0;
					busy        <= 1;
					DDRAM_BURSTCNT <= 8'd1;
				end
			end
		end
	end
end
*/

