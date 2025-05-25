// YM2148 MIDI UART device
//
// Copyright (c) 2025 Molekula
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Redistributions in synthesized form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in the
//   documentation and/or other materials provided with the distribution.
//
// * Neither the name of the author nor the names of other contributors may
//   be used to endorse or promote products derived from this software without
//   specific prior written agreement from the author.
//
// * License is granted for non-commercial use only.  A fee may not be charged
//   for redistributions as source code or in synthesized/hardware form without
//   specific prior written agreement from the author.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

module dev_YM2148 #(parameter COUNT=1) (
    cpu_bus_if.device_mp   cpu_bus,
    device_bus             device_bus,
    clock_bus_if.base_mp   clock_bus,
    input MSX::io_device_t io_device[3],
    input            [7:0] uart_rx_data,
    input                  uart_rx,
    output         [7:0]   data,
    output                 irq,
    output logic [7:0] key_matrix[8]
);

    localparam STAT_TXRDY = 0;
    localparam STAT_RXRDY = 1;
    localparam STAT_OE    = 4;
    localparam STAT_FE    = 5;

    localparam CMD_TXEN   = 0;
    localparam CMD_TXIE   = 1;
    localparam CMD_RXEN   = 2;
    localparam CMD_RXIE   = 3;
    localparam CMD_ER     = 4;
    localparam CMD_IR     = 7;

    logic [7:0] irq_vector[2];
    logic [7:0] status;
    logic [7:0] cmd_reg;
    logic [7:0] rx_buffer;
    logic       rxIRQ;
    logic       txIRQ;
    logic [7:0] key_row;

    wire irq_vector_to_bus = cpu_bus.m1 && cpu_bus.iorq && cpu_bus.int_rq && io_device[0].enable;

    assign data            = irq_vector_to_bus                   ? irq_vector[irq] :
                             dev_rd && cpu_bus.addr[2:0] == 3'd2 ? matrix_data :
                             dev_rd && cpu_bus.addr[2:0] == 3'd5 ? rx_buffer :
                             dev_rd && cpu_bus.addr[2:0] == 3'd6 ? status :
                                                                   8'hFF;
    assign irq             = rxIRQ | txIRQ;

    wire   dev_en = io_device[0].enable && io_device[0].device_ref == device_bus.device_ref && device_bus.we;
    wire   dev_wr = dev_en && cpu_bus.req && cpu_bus.wr;
    wire   dev_rd = dev_en && cpu_bus.rd;

    always_ff @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            rx_buffer  <= '0;
            status     <= '0;
            rxIRQ      <= '0;
            txIRQ      <= '0;
            status     <= '0;
            cmd_reg    <= '0;
            irq_vector <= '{'1,'1};
        end else begin
            if (dev_wr) begin
                case(cpu_bus.addr[2:0])
                    3'd2: key_row       <= cpu_bus.data;    // Keyboard row
                    3'd3: irq_vector[1] <= cpu_bus.data;    // MIDI IRQ Vector 
                    3'd4: irq_vector[0] <= cpu_bus.data;    // EXT  IRQ Vector 
                    3'd5: begin                             // Data
                        if (cmd_reg[CMD_TXEN]) begin
                        /*
                            if (syncTrans.pendingSyncPoint()) {
                                // We're still sending the previous character, only buffer
                                // this one. Don't accept any further characters.
                                txBuffer2 = value;
                                status &= byte(~STAT_TXRDY);
                                txIRQ.reset();
                            } else {
                                // Immediately start sending this character. We're still
                                // ready to accept a next character.
                                send(value, time);
                           }*/
                           ;
                        end
                    end
                    3'd6: begin                             // Command
                        if (cpu_bus.data[CMD_IR]) begin     // RESET
                            rx_buffer  <= '0;
                            status     <= '0;
                            rxIRQ      <= '0;
                            txIRQ      <= '0;
                            status     <= '0;
                        end else if (cpu_bus.data[CMD_ER]) begin
                            status[STAT_OE] <= 0;            
                            status[STAT_FE] <= 0;
                        end else begin
                            cmd_reg <= cpu_bus.data;
                            if (cpu_bus.data[CMD_RXEN]) begin
                                if (cpu_bus.data[CMD_RXIE]) begin
                                    rxIRQ          <= status[STAT_RXRDY];
                                end
                            end else begin
                                status[STAT_RXRDY] <= 0;
                                rxIRQ              <= 0;
                            end

                            if (cpu_bus.data[CMD_TXEN]) begin
                                if (~cmd_reg[CMD_TXEN]) begin
                                    status[STAT_TXRDY] <= 1;
                                    txIRQ              <= cpu_bus.data[CMD_TXIE];
                                end
                            end else begin
                                status[STAT_TXRDY] <= 0;
                                txIRQ              <= 0;
                            end
                        end
                    end
                    default:;
                endcase
            end
            //UART receive
            if (cmd_reg[CMD_RXEN] && uart_rx) begin
                if (status[STAT_RXRDY]) begin
                    status[STAT_OE] <= 1;
                end else begin
                    rx_buffer <= uart_rx_data;
                    status[STAT_RXRDY] <= 1;
                    if (cmd_reg[CMD_RXIE]) begin
                        rxIRQ <= 1;
                    end
                end
            end
            //Reset status after read data
            if (dev_rd && cpu_bus.addr[2:0] == 3'd5) begin
                rxIRQ <= 0;
                status[STAT_RXRDY] <= 0;
            end
        end
    end

    typedef enum logic [1:0] {
        IDLE, READ_NOTE, READ_VELOCITY
    } state_t;

    state_t     state;
    logic       status_note;
    logic [6:0] note;
    //logic [7:0] key_matrix[8];

    always_ff @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            state                 <= IDLE;
            status_note           <= '0;
            key_matrix            <= '{'1, '1, '1, '1, '1, '1, '1, '1};
        end else begin
            if (uart_rx) begin
                if (uart_rx_data[7]) begin
                    if (uart_rx_data[6:5] == 2'b00) begin
                        status_note <= uart_rx_data[4];
                        state       <= READ_NOTE;
                    end else begin
                        state       <= IDLE;
                    end
                end else begin
                    case(state)
                        IDLE: ;
                        READ_NOTE: begin
                            note        <= uart_rx_data[6:0];
                            state       <= READ_VELOCITY;
                        end
                        READ_VELOCITY: begin
                            state       <= READ_NOTE;
                            key_matrix[note[2:0]][note[5:3]] <= status_note && uart_rx_data != 0 ? 1'b0 : 1'b1;
                        end
                        default;
                    endcase    
                end
            end
        end
    end

    logic [7:0] matrix_data;
    always_comb begin
        matrix_data = '1;
        for (int i = 0; i < 8; i++) begin
            if (key_row[i]) matrix_data &= key_matrix[i];
        end
    end

endmodule
