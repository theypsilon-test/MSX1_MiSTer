// WD279x FDC
//
// Copyright (c) 2024-2025 Molekula
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

module wd279x_command_I #(parameter TEST=0)
(
	input  logic        clk,         // sys clock
	input  logic        msclk,       // clock 1ms enable
	input  logic        interrupt,
	input  logic        MRn,	     // master reset
	input  logic        command_start,
	input  logic  [7:0] command,
	input  logic  [7:0] reg_data,
	output logic  [7:0] status,
	output logic        INTRQ,
	output logic 		STEPn,
	output logic 		SDIRn,
	input  logic 		INDEXn,
	input  logic 		TRK00n,
	output logic        HLD,
	
	input  logic  [7:0] reg_track_in,
	output logic  [7:0] reg_track_out,
	output logic  		reg_track_write,
	
	input  logic  [7:0] sec_id[6],
	input  logic  		data_valid
);

	localparam ID_TRACK  = 0;
    localparam ID_SIDE   = 1;
    localparam ID_SECTOR = 2;
    localparam ID_LENGHT = 3;
    localparam ID_CRC1   = 4;
    localparam ID_CRC2   = 5;

	typedef enum {
		STATE_IDLE,
		STATE_STEP_A,
		STATE_STEP_B,
		STATE_STEP_C,
		STATE_STEP_WAIT,
		STATE_VERIFY,
		STATE_VERIFY_II,
		STATE_VERIFY_III
	} step_state_t;

	step_state_t state;

	logic busy;
	
	logic reg_CRC_ERROR;
	logic reg_SEEK_ERROR;
	logic [7:0] track_rq;
	logic [4:0] wait_count;
	logic [2:0] index_count;
	logic       last_index;

	assign busy = state != STATE_IDLE;
	assign status = {1'b0, 1'b0, 1'b0, reg_SEEK_ERROR, reg_CRC_ERROR, ~TRK00n, ~INDEXn, busy}; //TODO signály z mechaniky

	always_ff @(posedge clk) begin
		reg_track_write <= 0;
		INTRQ <= 0;
		if (~MRn || interrupt) begin
			STEPn <= 1;
			SDIRn <= 1;
			HLD <= 1;
			reg_CRC_ERROR <= 0;
			reg_SEEK_ERROR <= 0;
			state <= STATE_IDLE;
		end else begin
			last_index <= INDEXn;
			case(state)
				STATE_IDLE: begin
					if (command_start && !command[7]) begin
						reg_CRC_ERROR <= 0;
						reg_SEEK_ERROR <= 0;
						HLD <= ~command[3];
						state <= command[4] ? STATE_STEP_B : STATE_STEP_C;
						if (command[7:5] == 3'b000) begin		// SEEK, RESTORE 
							if (!command[4]) begin				// RESTORE
								reg_track_out <= 8'hFF;
								reg_track_write <= 1;
								track_rq      <= 0;
							end else begin						// SEEK
								track_rq      <= reg_data;
							end
							state <= STATE_STEP_A;
						end
						if (command[7:5] == 3'b010) SDIRn <= 1;
						if (command[7:5] == 3'b011) SDIRn <= 0;
					end
				end
				STATE_STEP_A: begin
					state <= STATE_STEP_B;
					if (reg_track_in == track_rq) 
						state <= STATE_VERIFY;
					else 
						SDIRn <= (track_rq > reg_track_in);
				end
				STATE_STEP_B: begin
					state <= STATE_STEP_C;
					if (SDIRn)
						reg_track_out <= reg_track_out + 1;
					else
						reg_track_out <= reg_track_out - 1;
					reg_track_write <= 1;
				end
				STATE_STEP_C: begin
					if (!SDIRn && !TRK00n) begin
						reg_track_out <= 0;
						reg_track_write <= 1;
						state <= STATE_VERIFY;
					end else begin
						state <= STATE_STEP_WAIT;
						STEPn <= 0;
						if (TEST)
							wait_count <= 2;
						else
							case(command[1:0])
								2'b00: wait_count <= 6;
								2'b01: wait_count <= 12;
								2'b10: wait_count <= 20;
								2'b11: wait_count <= 30;
							endcase
					end
				end
				STATE_STEP_WAIT: begin
					if (msclk) begin
						if (wait_count == 0) begin
							STEPn <= 1;
							if (command[7:5] == 3'b000) // SEEK, RESTORE
								state <= STATE_STEP_A;
							else 
								state <= STATE_VERIFY;
						end else begin
							wait_count <= wait_count - 1;
						end
					end
				end
				STATE_VERIFY: begin
					if (!command[2]) begin
						state <= STATE_IDLE;
						INTRQ <= 1;
					end else begin
						HLD <= 1;
						wait_count <= TEST ? 2 : 15;
						state <= STATE_VERIFY_II;
					end
				end
				STATE_VERIFY_II: begin
					if (wait_count != 0) begin
						if (msclk) begin
							wait_count <= wait_count - 1;
							index_count <= 0;
						end
					end else begin			// Lze kontrolovat
						
						if (last_index && !INDEXn) index_count <= index_count + 1;
						if (index_count > 4) begin
							state <= STATE_IDLE;
							INTRQ <= 1;
							reg_SEEK_ERROR <= 1;
						end
						if (data_valid && sec_id[ID_TRACK] == reg_track_in) begin
							state <= STATE_IDLE;
							INTRQ <= 1;
							state <= STATE_IDLE;
						end
					end
				end


				default: ;
			endcase
		end
	end
endmodule

