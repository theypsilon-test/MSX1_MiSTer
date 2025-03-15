module fdd #(SECTORS=9, SECTOR_SIZE=512, TRACKS=80)
(
    input  logic            clk,
    input  logic            msclk,
    input  logic            reset,

/*
    output logic            INDEXn,     // Pin 8  Index
    input  logic            MOTEAn,     // Pin 10 Motor Enable A
    input  logic            DRVSBn,     // Pin 12 Drive Sel B
    input  logic            DRVSAn,     // Pin 14 Drive Sel A
    input  logic            MOTEBn,     // Pin 16 Motor enable B
    input  logic            DIRn,       // Pin 18 Direction
    input  logic            STEPn,      // Pin 20 Step
    input  logic            WDATEn,     // Pin 22 Write data
    input  logic            WGATEn,     // Pin 24 Floppy Write Enable
    output logic            TRK00n,     // Pin 26 Track 0
    output logic            WPTn,       // Pin 28 Write protect
    output logic            RDATAn,     // Pin 30 Read data
    input  logic            SIDE1n,     // Pin 32 Head select
    output logic            DSKCHGn,    // Pin 34 Disk change/ready
*/
    input  logic      [1:0] USEL,
    input  logic            MOTORn,
    output logic            READYn,
    input  logic            STEPn,
    input  logic            SDIRn,
    input  logic            SIDEn,
    output logic            INDEXn,
    output logic            TRACK0n,
    output logic            WPROTn,

    output logic      [7:0] data,               // Octal data
    output logic      [7:0] sec_id[6],
    output logic            data_valid,
    output logic            bclk,

    //hps image
    input logic       [3:0] img_mounted,
    input logic             img_readonly,
    input logic      [63:0] img_size,

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
    input  logic        sd_buff_wr,
    input  logic        TEST           
);

//input        layout,      // 0 = Track-Side-Sector, 1 - Side-Track-Sector

    logic [3:0] motor_run;         // Stav motoru

    motor #(.TIMEOUT(30), .DELAY(3)) FDD_motor(
        .clk(clk),
        .msclk(msclk),
        .reset(reset),
        .USEL(USEL),
        .MOTORn(MOTORn),
        .motor_run(motor_run)
    );


    logic sides;
    ready FDD_ready(
        .clk(clk),
        .reset(reset),
        .USEL(USEL),
        .motor_run(motor_run),
        .READYn(READYn),
        .WPROTn(WPROTn),
        .sides(sides),
        .img_mounted(img_mounted),
        .img_readonly(img_readonly),
        .img_size(img_size)
    );

    logic  [6:0] track;
    logic [12:0] buffer_addr;
    logic  [7:0] buffer_q;
    logic        track_ready;

    track #(.DELAY(3), .MAX_TRACKS(80)) FDD_track(
        .clk(clk),
        .msclk(msclk),
        .reset(reset),
        .USEL(USEL),
        .READYn(READYn),
        .STEPn(STEPn),
        .SDIRn(SDIRn),
        .TRACK0n(TRACK0n),
        
        .track(track),
        .disk_mounted(~READYn),
        .disk_readonly(~WPROTn),
        .disk_sides(sides),

        .track_ready(track_ready),
        .buffer_addr(buffer_addr),
        .buffer_q(buffer_q),

        .sd_lba(sd_lba),
        .sd_blk_cnt(sd_blk_cnt),
        .sd_rd(sd_rd),
        .sd_wr(sd_wr),
        .sd_ack(sd_ack),
        .sd_buff_addr(sd_buff_addr),
        .sd_buff_dout(sd_buff_dout),
        .sd_buff_din(sd_buff_din),
        .sd_buff_wr(sd_buff_wr)
    );

    transmit FDD_transmit(
        .clk(clk),
        .bclk(bclk),
        .reset(reset),
        
        //Track buffer
        .buffer_addr(buffer_addr),
        .buffer_q(buffer_q),
        .track_ready(track_ready),

        .track(track),
        .side(~SIDEn),
        
        .INDEXn(INDEXn),
        .data(data),
        .sec_id(sec_id),
        .data_valid(data_valid)
    );

    sftgen bytRate (
        .len(568-1),
        .sft(bclk),
        .clk(clk),
        .rstn(~reset)
    );

endmodule

/*
module wd1793_dpram #(parameter DATAWIDTH=8, ADDRWIDTH=11)
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
*/