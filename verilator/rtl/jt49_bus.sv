/*verilator tracing_off*/
module jt49_bus ( // note that input ports are not multiplexed
    input            rst_n,
    input            clk,    // signal on positive edge
    input            clk_en /* synthesis direct_enable = 1 */,
    // bus control pins of original chip
    input            bdir,
    input            bc1,
    input  [7:0]     din,

    input            sel, // if sel is low, the clock is divided by 2
    output     [7:0] dout,
    output     [9:0] sound,  // combined channel output
    output     [7:0] A,      // linearised channel output
    output     [7:0] B,
    output     [7:0] C,
    output           sample,

    input      [7:0] IOA_in,
    output     [7:0] IOA_out,

    input      [7:0] IOB_in,
    output     [7:0] IOB_out
);

endmodule
