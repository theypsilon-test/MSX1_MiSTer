module track #(DELAYms = 3, MAX_TRACKS = 80)
(
    input  logic        clk,
    input  logic        msclk,  //clk at 1ms
    input  logic        reset,
    input  logic  [1:0] USEL,
    input  logic        READYn,
    input  logic        STEPn,
    input  logic        SDIRn,
    input  logic        SIDEn,
    input  logic        MOTORn,
    output logic        TRACK0n,
    output logic  [6:0] track,
    
    input  logic        disk_mounted,
    input  logic        disk_readonly,
    input  logic        disk_sides,

    output logic        track_ready,            // Track je nacten z SD
    input  logic [12:0] buffer_addr,
    output logic  [7:0] buffer_q,

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
    logic [2:0] track_delay;       // MAX 8 ms
    logic [6:0] reg_track[3:0];
    logic last_STEPn;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_track <= '{7'd0, 7'd0, 7'd0, 7'd0};
            track_delay <= '0;
        end else begin
            last_STEPn <= STEPn;
            
            if (msclk && track_delay > 0) begin
                track_delay <= track_delay - 1;
            end

            if (!STEPn && last_STEPn && track_delay == 0) begin
                if (SDIRn) begin
                    if (reg_track[USEL] < MAX_TRACKS) begin
                        reg_track[USEL] <= reg_track[USEL] + 1;
                        track_delay <= DELAYms;
                    end
                end else begin
                    if (reg_track[USEL] > 0) begin
                        reg_track[USEL] <= reg_track[USEL] - 1;
                        track_delay <= DELAYms;
                    end
                end
            end           
        end
    end

    assign track   = reg_track[USEL];
    assign TRACK0n = reg_track[USEL] != 0; //|| MOTORn; TODO

    track_buffer track_buffer (
        .clk(clk),
        .reset(reset),

        .track(track),
        .side(~SIDEn),
        .USEL(USEL),
        

        .ready(track_ready),

        .buffer_addr(buffer_addr),
        .buffer_q(buffer_q),

        .disk_mounted(disk_mounted),
        .disk_readonly(disk_readonly),
        .disk_sides(disk_sides),
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

endmodule
