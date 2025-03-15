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

module wd279x #(parameter WD279_57=1) 
(
	input        clk,         // sys clock
	input        msclk,       // clock 1ms
	input        MRn,	      // master reset
	input        CSn,		  // i/o enable
	input        REn,         // i/o read
	input        WEn,         // i/o write
	input  [1:0] A,           // i/o port addr
	input  [7:0] DIN,         // i/o data in
	output [7:0] DOUT,        // i/o data out
	output       DRQ,         // DMA request
	output  logic       INTRQ,

	output logic 		STEPn,
	output logic 		SDIRn,
	input  logic 		INDEXn,
	input  logic 		TRK00n,
	input  logic        READYn,
	input  logic        WPROTn,
	output logic        SSO,
	input  logic  [7:0] data,
	input  logic        bclk,
	input  logic  [7:0] sec_id[6],
	input  logic  		data_valid,

	input  logic        TEST,	//Zkrácené časy
	output logic  [7:0] temp_status
);

	localparam A_COMMAND         = 0;
	localparam A_STATUS          = 0;
	localparam A_TRACK           = 1;
	localparam A_SECTOR          = 2;
	localparam A_DATA            = 3;

	typedef enum {
		COMMAND_TYPE_I,
		COMMAND_TYPE_II,
		COMMAND_TYPE_III,
		COMMAND_TYPE_IV
	} command_type_t;

	command_type_t command_type;

	logic [7:0] reg_cmd, reg_track, reg_sector, reg_data, status;
	logic       command_start;
	logic       busy;

	assign temp_status = status;
	assign busy = command_start | status_command_type_I[0] | status_command_type_II[0];
	assign DOUT = (~REn && A == A_DATA) ? reg_data : 
				  (~REn && A == A_STATUS) ? status : 8'hFF;

	always_comb begin
		casez (reg_cmd[7:4])
			4'b1101: begin command_type = COMMAND_TYPE_IV; status = 0; end
			4'b1100: begin command_type = COMMAND_TYPE_III; status = 0; end
			4'b10??: begin command_type = COMMAND_TYPE_II; status = {status_command_type_II[7:2], reg_DRQ, status_command_type_II[0]}; end
			default: begin command_type = COMMAND_TYPE_I; status = status_command_type_I; end
		endcase
	end

	logic last_REn, last_WEn;
	always_ff @(posedge clk) begin
		last_REn <= REn;
		last_WEn <= WEn;
	end
	
	//Command register
	logic INTRQ_cmd_res;
	logic interrupt;
	always_ff @(posedge clk) begin
		INTRQ_cmd_res <= 0;
		interrupt <= 0;
		if (~MRn)	begin
			reg_cmd <= 8'h03;
			command_start <= 1;
		end else begin
			if (last_WEn && ~WEn && A == A_COMMAND) begin
				if (DIN[7:4] == 4'h0D) begin					// FORCE interupt
					reg_cmd <= DIN;								// TODO operace po prijeti commandu
					command_start <= 0;
					INTRQ_cmd_res <= 1;
					interrupt <= 1;
				end else begin
					if (!busy) begin
						reg_cmd <= DIN;
						command_start <= 1;
						INTRQ_cmd_res <= 1;
					end
				end
			end

			if (status[0]) 
				command_start <= 0;
			
		end
	end

	//Track register
	always_ff @(posedge clk) begin
		if (~MRn)	begin
			reg_track <= 0;
		end	else begin
			if (last_WEn && ~WEn && A == A_TRACK && !busy )
				reg_track <= DIN;

			if (reg_track_write) 
				reg_track <= reg_track_out;
		end
	end

	//Sector register
	always_ff @(posedge clk) begin
		if (~MRn)	begin
			reg_sector <= 1;
		end	else begin
			if (last_WEn && ~WEn && A == A_SECTOR && !busy ) begin
				reg_sector <= DIN;
			end
			if (reg_sector_write) 
				reg_sector <= reg_sector_out;
		end
	end

	//Data register
	logic reg_DRQ;
	logic reg_LOST_DATA;
	always_ff @(posedge clk) begin
		if (~MRn)	begin
			reg_data <= 0;
			reg_LOST_DATA <= 0;
			reg_DRQ <= 0;
		end	else begin
			if (last_WEn && ~WEn && A == A_DATA) begin
				reg_data <= DIN;
			end
			
			if (last_REn && ~REn && A == A_DATA && reg_DRQ) begin
				reg_DRQ <= 0;
			end

			if (reg_cmd[7:5] == 3'b100 && status_command_type_II[1]) begin
				if (bclk && data_valid) begin
					if (reg_DRQ) 
						reg_LOST_DATA <= 1;
					reg_DRQ <= 1;
					reg_data <= data;
				end
			end
		end
	end

	//INTRQ register
	always_ff @(posedge clk) begin
		if (~MRn)	begin
			INTRQ <= 0; 
		end	else begin
			if (INTRQ_cmd_res) begin
				INTRQ <= 0;
			end else 
				if (INTRQ_I || INTRQ_II) begin
					INTRQ <= 1;
				end
		end
	end

logic [7:0] reg_track_out;
logic       reg_track_write;
logic [7:0] status_command_type_I;
logic       INTRQ_I;
wd279x_command_I command_I (
	.clk(clk),
	.msclk(msclk),
	.interrupt(interrupt),
	.MRn(MRn),
	.command(reg_cmd),
	.command_start(command_start),
	.status(status_command_type_I),
	.reg_data(reg_data),
	.reg_track_in(reg_track_write ? reg_track_out : reg_track),
	.reg_track_out(reg_track_out),
	.reg_track_write(reg_track_write),
	.STEPn(STEPn),
	.SDIRn(SDIRn),
	.INDEXn(INDEXn),
	.TRK00n(TRK00n),
	.HLD(),
	.INTRQ(INTRQ_I),
	.data_valid(data_valid),
	.sec_id(sec_id),
	.TEST(TEST)
);

logic [7:0] reg_sector_out;
logic       reg_sector_write;
logic [7:0] status_command_type_II;
logic       INTRQ_II;
wd279x_command_II command_II (
	.clk(clk),
	.msclk(msclk),
	.interrupt(interrupt),
	.MRn(MRn),
	.command(reg_cmd),
	.command_start(command_start),
	.status(status_command_type_II),
	.reg_data(reg_data),
	.reg_track_in(reg_track),
	.reg_sector_in(reg_sector_write ? reg_sector_out : reg_sector),
	.reg_sector_out(reg_sector_out),
	.reg_sector_write(reg_sector_write),
	.INDEXn(INDEXn),
	.READYn(READYn),
	.WPROTn(WPROTn),
	.SSO(SSO),
	.HLD(),
	.INTRQ(INTRQ_II),
	.data_valid(data_valid),
	.sec_id(sec_id),
	.TEST(TEST)
);

endmodule

