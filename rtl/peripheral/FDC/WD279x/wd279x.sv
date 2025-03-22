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
	input  logic        clk,         // sys clock
	input  logic        msclk,       // clock 1ms
	input  logic        MRn,	      // master reset
	input  logic        CSn,		  // i/o enable
	input  logic        REn,         // i/o read
	input  logic        WEn,         // i/o write
	input  logic  [1:0] A,           // i/o port addr
	input  logic  [7:0] DIN,         // i/o data in
	output logic  [7:0] DOUT,  // i/o data out
	output logic        DRQ,  // DMA request
	output logic        INTRQ,

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
	output logic		dbg_write,
	output logic		dbg_read,
	output logic        dbg_busy

	//input  logic        TEST,	//Zkrácené časy
	// output logic  [7:0] temp_status
);

	assign dbg_read = read_rq;
	assign dbg_write = write_rq;
	assign dbg_busy = busy;

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

	assign busy = command_start | status[0];
	assign DRQ = DRQ_II;
	assign INTRQ = INTRQ_I | INTRQ_II;

	always_comb begin
		DOUT = '1;
		if (!(REn || CSn))
			case (A)
				A_DATA:   DOUT = data_II;
				A_STATUS: DOUT = status;
				A_SECTOR: DOUT = reg_sector;
				A_TRACK:  DOUT = reg_track;
			endcase
	end

	always_comb begin
		casez (reg_cmd[7:4])
			4'b1101: begin command_type = COMMAND_TYPE_IV; status = 0; end
			4'b1100: begin command_type = COMMAND_TYPE_III; status = 0; end
			4'b10??: begin command_type = COMMAND_TYPE_II; status = {status_command_type_II[7:2], reg_DRQ, status_command_type_II[0]}; end
			default: begin command_type = COMMAND_TYPE_I; status = status_command_type_I; end
		endcase
	end

	logic last_REn, last_WEn, write_rq, read_rq;
	always_ff @(posedge clk) begin
		last_REn <= REn;
		last_WEn <= WEn;
	end

	assign write_rq = ~CSn && last_WEn && ~WEn;
	assign read_rq  = ~CSn && last_REn && ~REn;
	
	
	//Command register
	logic INTRQ_cmd_res;
		always_ff @(posedge clk) begin
		INTRQ_cmd_res <= 0;
		command_start <= 0;
		if (~MRn)	begin
			reg_cmd <= 8'h03;
			command_start <= 1;
		end else begin
			if (write_rq && A == A_COMMAND) begin
				if (!busy || (DIN[7:4] == 4'hD)) begin
					$display("SET CMD %X", DIN);
					reg_cmd <= DIN;
					command_start <= 1;
					INTRQ_cmd_res <= 1;
				end
			end
		end
	end

	//Track register
	always_ff @(posedge clk) begin
		if (~MRn)	begin
			reg_track <= 0;
		end	else begin
			if (write_rq && A == A_TRACK && !busy ) begin
				reg_track <= DIN;
				$display("SET TRACK %X", DIN);
			end
			if (reg_track_write) 
				reg_track <= reg_track_out;
		end
	end

	//Sector register
	always_ff @(posedge clk) begin
		if (~MRn)	begin
			reg_sector <= 1;
		end	else begin
			if (write_rq && A == A_SECTOR && !busy ) begin
				reg_sector <= DIN;
				$display("SET SECTOR %X", DIN);
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
			if (write_rq && A == A_DATA) begin
				$display("SET DATA  %X", DIN);
				reg_data <= DIN;
				reg_DRQ <= 0;
			end
			
			if (read_rq && A == A_DATA) begin
				reg_DRQ <= 0;
			end

			//if (~data_valid) adr <= 0;
			if (reg_cmd[7:5] == 3'b100 && status_command_type_II[1]) begin
				if (bclk && data_valid) begin
					if (reg_DRQ) 
						reg_LOST_DATA <= 1;
					reg_DRQ <= 1;
					reg_data <= data;

					//if (adr < 5) 
					//	$display("DATA %X", data);
					//adr <= adr + 1;
				end
			end
		end
	end
/*	
	wire [15:0] DISKcrc;
	crc #(.CRC_WIDTH(16)) crc1
	(
		.clk(clk),
		.valid(data_valid),
		.we(bclk),
		.data_in(data),
		.crc(DISKcrc)
	);
	/*
	crc #(.CRC_WIDTH(32), .POLYNOM(32'hEDB88320))crc2
	(
		.clk(clk),
		.valid(data_valid),
		.we(bclk),
		.data_in(data),
		.crc()
	);*/
/*
	CRC_32 crc3 (
		.clk(clk),
		.en(data_valid),
		.we(bclk),
		.crc_in(data),
		.crc_out()
	);
*/
	//INTRQ register
	/*
	always_ff @(posedge clk) begin
		if (~MRn)	begin
			INTRQ <= 0; 
		end	else begin
			if (INTRQ_cmd_res) begin
				INTRQ <= 0;
			end else 
				if (INTRQ_I || (INTRQ_II && ~reg_DRQ)|| INTRQ_IV) begin
					INTRQ <= 1;
					//if (INTRQ_II) $display("CRC %X", DISKcrc);
				end
		end
	end
*/
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
	.READYn(READYn),
	.WPROTn(WPROTn),
	.TRK00n(TRK00n),
	.HLD(),
	.INTRQ(INTRQ_I),
	.data_valid(data_valid),
	.sec_id(sec_id)
);

logic [7:0] reg_sector_out;
logic       reg_sector_write;
logic [7:0] status_command_type_II;
logic       DRQ_II, INTRQ_II;
logic [7:0] data_II;
wd279x_command_II #(.WD279_57(WD279_57)) command_II (
	.clk(clk),
	.msclk(msclk),
	.bclk(bclk),
	.interrupt(interrupt),
	.MRn(MRn),
	.command(reg_cmd),
	.command_start(command_start),
	.read_data(read_rq && A == A_DATA),
	.status(status_command_type_II),
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
	.DRQ(DRQ_II),
	.data(data_II),
	.data_valid(data_valid),
	.fdd_data(data),
	.sec_id(sec_id)
);

logic       INTRQ_IV;
logic       interrupt;
wd279x_command_IV  command_IV (
	.clk(clk),
	.msclk(msclk),
	.interrupt(interrupt),
	.MRn(MRn),
	.command(reg_cmd),
	.command_start(command_start),
	.INTRQ(INTRQ_IV)
);
endmodule

