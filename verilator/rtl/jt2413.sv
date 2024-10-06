module jt2413(
    input                rst,        // rst should be at least 6 clk&cen cycles long
    input                clk,        // CPU clock
    input                cen,        // optional clock enable, it not needed leave as 1'b1
    input         [ 7:0] din,
    input                addr,
    input                cs_n,
    input                wr_n,
    // combined output
    output signed [15:0] snd,
    output               sample
);

endmodule;