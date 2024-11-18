module subslot (
    cpu_bus_if.device_mp    cpu_bus,        
    input             [1:0] active_slot,
    input             [3:0] expander_enable,
    output            [7:0] data,           
    output            [1:0] active_subslot, 
    output                  output_rq       
);

    logic [7:0] mapper_slot[3:0] /* verilator public */;
    
    wire [1:0] block = cpu_bus.addr[15:14];

    assign active_subslot = mapper_slot[active_slot][(3'd2 * block) +: 2];

endmodule