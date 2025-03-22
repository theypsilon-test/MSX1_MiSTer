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

module wd279x_command_II  #(parameter WD279_57=1, TEST=0) 
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
 	input  logic 		INDEXn,
	input  logic        READYn,
	input  logic		WPROTn,
	output logic        SSO,
	output logic        HLD,
	
	input  logic  [7:0] reg_track_in,
	input  logic  [7:0] reg_sector_in,
	output logic  [7:0] reg_sector_out,
	output logic        reg_sector_write,
	
	
	input  logic  [7:0] sec_id[6],
	input  logic  		data_valid,
	input  logic        drq_out
);

	localparam ID_TRACK  = 0;
    localparam ID_SIDE   = 1;
    localparam ID_SECTOR = 2;
    localparam ID_LENGHT = 3;
    localparam ID_CRC1   = 4;
    localparam ID_CRC2   = 5;

	typedef enum {
		STATE_IDLE,
		STATE_PREPARE,
		STATE_CHECK,
		STATE_CHECK_II,
		STATE_READ,
		STATE_WRITE
		
	} sector_state_t;


	sector_state_t state;

	logic busy;
	logic reg_CRC_ERROR;
	logic reg_LOST_DATA;
	logic reg_RECORD_NOT_FOUND;
	logic reg_WRITE_PROTECTED;
	logic reg_RECORD_TYPE;
	logic reg_DRQ;

	logic [4:0] wait_count;
	logic [2:0] index_count;
	logic       last_index;

	assign status = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, reg_DRQ, busy}; //TODO signály z mechaniky
	assign busy  = state != STATE_IDLE;

	always_ff @(posedge clk) begin
		reg_sector_write <= 0;
		INTRQ <= 0;
		if (~MRn || interrupt) begin
			state <= STATE_IDLE;
			reg_CRC_ERROR <= 0;
			reg_LOST_DATA <= 0;
			reg_RECORD_NOT_FOUND <= 0;
			reg_WRITE_PROTECTED <= 0;
			reg_RECORD_TYPE <= 0;
			reg_DRQ <= 0;
			HLD <= 0;
			if (WD279_57) SSO <= 0;
		end else begin
			last_index <= INDEXn;
			case(state)
				STATE_IDLE: begin
					if (command_start && command[7:6] == 2'b10) begin
						$display("Time %t", $time);
						$display("Command II m(%d) Track Side sector: %X %X %X", command[4], reg_track_in, command[3], reg_sector_in);
						reg_CRC_ERROR <= 0;
						reg_LOST_DATA <= 0;
						reg_RECORD_NOT_FOUND <= 0;
						reg_WRITE_PROTECTED <= 0;
						reg_RECORD_TYPE <= 0;
						reg_DRQ <= 0;
						state <= STATE_PREPARE;
					end
				end
				STATE_PREPARE: begin
					if (READYn) begin
						state <= STATE_IDLE;
						INTRQ <= 1;
					end else begin
						if (WD279_57) begin
							SSO <= command[1];
						end
						HLD <= 1;
						state <= STATE_CHECK;
						wait_count <= command[2] ? 15 : 0 ;		//WAIT 15ms or 0ms
					end				
				end
				STATE_CHECK:
					if (wait_count > 0) begin
						if (msclk) wait_count <= wait_count - 1;
					end else begin
						if (command[5]) begin				 // Write ?
							if (!WPROTn) begin
								INTRQ <= 1;
								state <= STATE_IDLE;
								reg_WRITE_PROTECTED <= 1;
							end
						end else begin
							if (~data_valid) begin
								state <= STATE_CHECK_II;
								index_count <= 0;
							end
						end
					end
				STATE_CHECK_II: begin
					if (last_index && !INDEXn) index_count <= index_count + 1;
					if (index_count > 4) begin
						state <= STATE_IDLE;
						INTRQ <= 1;
						reg_RECORD_NOT_FOUND <= 1;
						$display("RECORD_NOT_FOUND");
					end else
						if (data_valid)
							if (sec_id[ID_TRACK] == reg_track_in && sec_id[ID_SECTOR] == reg_sector_in)
									if (WD279_57 == 1 ||  command[1] == 0 || sec_id[ID_SIDE][0] == command[3]) begin
										state <= command[5] ? STATE_WRITE : STATE_READ;
										$display("RECORD FOUND");
									end

				end
				STATE_READ: begin
					//TODO nastavit status bit 5. Stávající DSK formát nezná smazané data
					if (data_valid) begin
						reg_DRQ <= 1;
						//TODO přečíst všechny data
					end else begin
						reg_DRQ <= 0;
						if (command[4]) begin			//Multiple
							reg_sector_out <= reg_sector_in + 1;
							reg_sector_write <= 1;
							$display("Command II m(%d) Track Side sector: %X %X %X NEXT", command[4], reg_track_in, command[3], reg_sector_in + 1);
							state <= STATE_CHECK;
						end else begin
//							if (!drq_out) begin
								INTRQ <= 1;
								state <= STATE_IDLE;
//							end
						end
					end
				end

				default: ;
			endcase
		end
	end
endmodule

