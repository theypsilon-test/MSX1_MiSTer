module fdd #(parameter sysCLK, SECTORS=9, SECTOR_SIZE=512, TRACKS=80, TEST=0)
(
    input  logic            clk,
    input  logic            msclk,
    input  logic            reset,
    FDD_if.FDD_mp           FDD_bus,
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
    /*
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
    */
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
    input  logic        sd_buff_wr     
);

    logic [3:0] motor_run;         // Stav motoru

    motor #(.TIMEOUTms(30000), .DELAYms(3)) FDD_motor(
        .clk(clk),
        .msclk(msclk),
        .reset(reset),
        .USEL(FDD_bus.USEL),
        .MOTORn(FDD_bus.MOTORn),
        .motor_run(motor_run)
    );

    logic sides;
    ready FDD_ready(
        .clk(clk),
        .reset(reset),
        .USEL(FDD_bus.USEL),
        .motor_run(motor_run),
        .READYn(FDD_bus.READYn),
        .WPROTn(FDD_bus.WPROTn),
        .sides(sides),
        .img_mounted(img_mounted),
        .img_readonly(img_readonly),
        .img_size(img_size)
    );

    logic  [6:0] track;
    logic [12:0] buffer_addr;
    logic  [7:0] buffer_q;
    logic        track_ready;

    track #(.DELAYms(3), .MAX_TRACKS(80)) FDD_track(
        .clk(clk),
        .msclk(msclk),
        .reset(reset),
        .USEL(FDD_bus.USEL),
        .READYn(FDD_bus.READYn),
        .STEPn(FDD_bus.STEPn),
        .SDIRn(FDD_bus.SDIRn),
        .TRACK0n(FDD_bus.TRACK0n),
        .SIDEn(FDD_bus.SIDEn),
        
        .track(track),
        .disk_mounted(~FDD_bus.READYn),
        .disk_readonly(~FDD_bus.WPROTn),
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

    transmit #(.sysCLK(sysCLK)) FDD_transmit(
        .clk(clk),
        .bclk(FDD_bus.bclk),
        .reset(reset),
        
        //Track buffer
        .buffer_addr(buffer_addr),
        .buffer_q(buffer_q),
        .track_ready(track_ready),

        .track(track),
        .side(~FDD_bus.SIDEn),
        
        .INDEXn(FDD_bus.INDEXn),
        .data(FDD_bus.data),
        .sec_id(FDD_bus.sec_id),
        .data_valid(FDD_bus.data_valid)
    );

endmodule
