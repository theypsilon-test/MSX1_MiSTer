module CRC_32(clk,rst,we,crc_in,crc_out);
    input clk;
    input rst;
    input we;
    input [7:0] crc_in;
    output logic [31:0] crc_out;

    parameter POLY = 32'hEDB88320;

    logic [31:0] crc_reg;
    logic last_rst;
    integer i;

    initial begin
        crc_reg = 32'hFFFFFFFF;
    end

    always @(posedge clk) begin
        crc_out <= crc_out;
        if (~rst && last_rst) begin
            crc_reg <= 32'hFFFFFFFF;
            crc_out <= crc_reg ^ 32'hFFFFFFFF;
        end else begin
            if (we) begin
                crc_reg <= crc_next(crc_in, crc_reg);
            end
        end
        last_rst <= rst;
    end

    function [31:0] crc_next;
        input [7:0] data;
        input [31:0] crc;
        reg [31:0] crc_temp;
        begin
            crc_temp = crc ^ {24'd0, data};
            for (i = 0; i < 8; i = i + 1) begin
                if (crc_temp[0] == 1'b1) begin
                    crc_temp = (crc_temp >> 1) ^ POLY;
                end else begin
                    crc_temp = crc_temp >> 1;
                end
            end
            crc_next = crc_temp;
        end
    endfunction

endmodule
