module jt8255(
    input               rst,
    input               clk,

    // CPU interface
    input       [1:0]   addr,
    input       [7:0]   din,
    output reg  [7:0]   dout,
    input               rdn,
    input               wrn,
    input               csn,

    // External pins to peripherals
    input       [7:0]   porta_din,
    input       [7:0]   portb_din,
    input       [7:0]   portc_din,

    output reg  [7:0]   porta_dout,
    output reg  [7:0]   portb_dout,
    output      [7:0]   portc_dout
);

endmodule
