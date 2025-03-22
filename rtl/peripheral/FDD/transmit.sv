module transmit #(parameter sysCLK)
(
    input  logic        clk,
    output logic        bclk,   
    input  logic        reset,
    output logic [12:0] buffer_addr,
    input  logic  [7:0] buffer_q,
    input  logic        track_ready,
    input  logic  [6:0] track,
    input  logic        side,
    output logic        INDEXn,
    output logic  [7:0] data,
    output logic  [7:0] sec_id[6],
    output logic        data_valid
);

    localparam ID_TRACK  = 0;
    localparam ID_SIDE   = 1;
    localparam ID_SECTOR = 2;
    localparam ID_LENGHT = 3;
    localparam ID_CRC1   = 4;
    localparam ID_CRC2   = 5;

    assign data_valid    = track_state == SECTORS && track_position >= 60 && track_position < 572;
    assign buffer_addr   = (512 * sector) + (data_valid ? (track_position-60) : 0);
    
    assign sec_id[ID_TRACK]  = {8'(track)};
    assign sec_id[ID_SIDE]   = {8'(side)};
    assign sec_id[ID_SECTOR] = {8'(next_sector)};
    assign sec_id[ID_LENGHT] = 2;
    assign sec_id[ID_CRC1]   = 0;
    assign sec_id[ID_CRC2]   = 0;


    typedef enum logic [1:0] { 
        HEADER,
        SECTORS,
        GAPS
    } track_layout_t;

    logic [12:0] track_position;
    logic  [3:0] sector;
    logic  [3:0] next_sector;

    assign next_sector = sector + 1;
    
    track_layout_t track_state;

    always_ff @(posedge clk) begin
        if (reset) begin
            track_position <= 0;
            track_state <= HEADER;
        end else begin
            if (track_ready) begin
                if (bclk) begin
                    track_position <= track_position + 1;
                    case(track_state)
                        HEADER: begin
                            if (track_position == 145) begin
                                track_position <= 0;
                                track_state <= SECTORS;
                                sector <= 0;
                            end
                        end
                        SECTORS: begin
                            if (track_position == 657) begin
                                if (sector == 8) begin
                                    track_state <= GAPS;
                                    track_position <= 0;
                                end else begin
                                    sector <= sector + 1;
                                    track_position <= 0;
                                end
                            end
                        end
                        GAPS: begin
                            if (track_position == 181) begin
                                track_state <= HEADER;
                                track_position <= 0;
                            end
                        end
                        default: ;
                    endcase
                end 
            end else begin
                track_position <= 0;
                track_state <= HEADER;
            end
        end
    end

    always_comb begin
        INDEXn = 1;
        case (track_state)
            HEADER: begin
                if (track_position < 80) begin
                    data = 8'h4E;
                end else if (track_position < 92) begin
                    data = 8'h00;
                    INDEXn = 0;
                end else if (track_position < 95) begin
                    data = 8'hC2;
                    INDEXn = 0;
                end else if (track_position < 96) begin
                    data = 8'hFC;
                    INDEXn = 0;
                end else begin
                    data = 8'h4E;
                end
            end
            SECTORS: begin
                if (track_position < 12) begin
                    data = 8'h00;
                end else if (track_position < 15) begin
                    data = 8'hA1;
                end else if (track_position < 16) begin
                    data = 8'hFE;
                end else if (track_position < 17) begin
                    data = {1'd0,track};
                end else if (track_position < 18) begin
                    data = {7'd0,side};
                end else if (track_position < 19) begin
                    data = {4'd0, sector};
                end else if (track_position < 20) begin
                    data = sec_id[ID_LENGHT];
                end else if (track_position < 22) begin
                    data = 8'h00;   // TODO CRC
                end else if (track_position < 44) begin
                    data = 8'h4E;
                end else if (track_position < 56) begin
                    data = 8'h00;
                end else if (track_position < 59) begin
                    data = 8'hA1;
                end else if (track_position < 60) begin
                    data = 8'hFB;
                end else if (track_position < 572) begin
                    data = buffer_q;
                end else if (track_position < 574) begin
                    data = 8'h00;   // TODO CRC
                end else begin
                    data = 8'h4E;
                end
            end
            default: begin
                data = 8'h4E;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        
        int unsigned count;

        if (reset) begin
            count <= 0;
            bclk   <= 0;
        end else begin
            if (count > 1) begin
                count <= count - 1;
                bclk   <= 0;
            end else begin
                bclk   <= 1;
                count <= sysCLK / 31195; //TODO ověřit (145 + (657 * 9) + 181) * 5 pro RPM 300
            end
        end
    end

//https://map.grauw.nl/articles/low-level-disk/

endmodule
