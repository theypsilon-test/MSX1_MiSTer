module track_buffer 
(
    input  logic        clk,
    input  logic        reset,
    
    input  logic  [6:0] track,
    input  logic  [1:0] USEL,
    input  logic        side,
    
    input  logic [12:0] buffer_addr,
    output logic  [7:0] buffer_q,
    output logic        ready,
     
    //Image info
    input  logic        disk_mounted,
    input  logic        disk_readonly,

    //SD block level access
    output logic [31:0] sd_lba[0:3],
    output logic  [5:0] sd_blk_cnt[0:3],
    output logic  [3:0] sd_rd,
    output logic  [3:0] sd_wr,
    input  logic  [3:0] sd_ack,
   
    // SD byte level access. Signals for 2-PORT altsyncram.
    input  logic [13:0] sd_buff_addr,
    input  logic  [7:0] sd_buff_dout,
    output logic  [7:0] sd_buff_din[0:3],
    input  logic        sd_buff_wr
);

    logic [6:0] reg_track;
    logic [1:0] reg_USEL;
    logic       reg_side;

    logic       load;

    wire changed = {reg_track, reg_USEL, reg_side} != {track,  USEL, side};
    
    assign ready = !changed && !load && !load_busy;

    always_ff @(posedge clk) begin
        if (reset) begin
            load <= 1;
        end else begin
            
            if (!load_busy && changed) load <= 1;
            if (load_busy) load <= 0;
        end       
    end

    logic load_busy;
    logic [4:0] sectors;

    always_ff @(posedge clk) begin
        if (reset) begin
            load_busy <= 0;
        end else begin
            if (!load_busy && load && disk_mounted) begin
                {reg_track, reg_USEL, reg_side} <= {track,  USEL, side};
                load_busy <= 1;
                sd_lba[USEL] <=  (track * 9) + (side == 1'b1 ? 0 : 9);
                sd_blk_cnt[USEL] <= 9 ;
                sd_rd[USEL] <= 1;
            end
            if (sd_rd[reg_USEL] && sd_ack[reg_USEL] && load_busy) begin
                sd_rd[reg_USEL] <= 0;
            end
            if (!load && !sd_ack[reg_USEL] ) begin
                load_busy <= 0;
            end
        end
    end

    track_dpram track_dpram (
        .clock(clk),
        .address_a(sd_buff_addr[12:0]),
        .data_a(sd_buff_dout),
        .wren_a(sd_buff_wr),
        .q_a(sd_buff_din[reg_USEL]),

        .address_b(buffer_addr),
        .wren_b(0),
        .data_b(0),
        .q_b(buffer_q)
    );

endmodule


module track_dpram #(parameter DATAWIDTH=8, ADDRWIDTH=13)
(
	input	                     clock,

	input	     [ADDRWIDTH-1:0] address_a,
	input	     [DATAWIDTH-1:0] data_a,
	input	                     wren_a,
	output reg [DATAWIDTH-1:0] q_a,

	input	     [ADDRWIDTH-1:0] address_b,
	input	     [DATAWIDTH-1:0] data_b,
	input	                     wren_b,
	output reg [DATAWIDTH-1:0] q_b
);

logic [DATAWIDTH-1:0] ram[0:(1<<ADDRWIDTH)-1];

always_ff@(posedge clock) begin
	if(wren_a) begin
		ram[address_a] <= data_a;
		q_a <= data_a;
	end else begin
		q_a <= ram[address_a];
	end
end

always_ff@(posedge clock) begin
	if(wren_b) begin
		ram[address_b] <= data_b;
		q_b <= data_b;
	end else begin
		q_b <= ram[address_b];
	end
end

endmodule