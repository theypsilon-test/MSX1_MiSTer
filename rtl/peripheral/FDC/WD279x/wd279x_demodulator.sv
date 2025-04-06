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

module wd279x_demodulator #(parameter sysCLK)
(
	input  logic        clk,
    input  logic        MRn,
    input  logic        INDEXn,
    input  logic        DDENn,
    input  logic        RAWRDn,
	output logic  [7:0] IDAM_data[6],
    output logic  [7:0] fdd_data,
    output logic        fdd_rx,
    output logic        IDAM_valid,
	output logic        DAM_valid,
	output logic        DAM_deleted,
    output logic        DAM_CRC_valid
);

    logic        IDAM;
	logic  [7:0] DAM_crc[2];
	logic  [9:0] DATA_counter;
	logic  [1:0] check_crc;

	assign DAM_CRC_valid = crc_out == {DAM_crc[0], DAM_crc[1]};

	always_ff @(posedge clk) begin
		logic [1:0] a1_cnt;
		logic [2:0] sec_id_cnt;
		crcwr <= 0;
		if (~MRn) begin
			a1_cnt <= 0;
			IDAM <= 0;
			crc_calc <= 0;
			IDAM_valid <= 0;
			DAM_valid <= 0;
		end else begin
			if (~INDEXn || mfm_c2) begin
				IDAM_valid <= 0;
				DAM_valid <= 0;
				a1_cnt <= 0;
			end
			if (mfm_a1) begin
				a1_cnt <= a1_cnt + 1;
				crc_calc <= 1;
				crcwr <= a1_cnt == 0;
				DAM_valid <= 0;
			end else if (fdd_rx || mfm_c2) begin
				a1_cnt <= 0;
			end
			if (a1_cnt == 3 && fdd_rx) begin
				if (mfm_data == 8'hFE) begin
					IDAM_valid <= 0;
					a1_cnt <= 0;
					sec_id_cnt <= 0;
					IDAM <= 1;
				end else if (IDAM_valid && (mfm_data == 8'hFB || mfm_data == 8'hF8)) begin
					DATA_counter <= 128 << IDAM_data[3][1:0];
					DAM_valid <= 1;
					DAM_deleted <= mfm_data == 8'hF8;
				end else begin
					crc_calc <= 0;
				end
			end
			if (IDAM && fdd_rx) begin
				IDAM_data[sec_id_cnt] <= fdd_data;
				sec_id_cnt <= sec_id_cnt + 1;
				if (sec_id_cnt == 3) begin
					crc_calc <= 0;
				end
				if (sec_id_cnt == 5) begin
					IDAM <= 0;
					sec_id_cnt <= 0;
					if (crc_out == {IDAM_data[4], fdd_data} ) begin
						IDAM_valid <= 1;
					end 
				end
			end
			if (DAM_valid && DATA_counter > 0 && fdd_rx) begin
				DATA_counter <= DATA_counter - 1;
				if (DATA_counter == 1) begin
					DAM_valid <= 0;
					crc_calc <= 0;
					check_crc <= 2;
				end
			end
			if (check_crc > 0 && fdd_rx) begin
				check_crc <= check_crc - 1;
				DAM_crc[2-check_crc] <= fdd_data; 
			end
		end
	end

    assign fdd_data = DDENn ? fm_data : mfm_data;
    assign fdd_rx   = DDENn ? fm_rx : mfm_rx;

    logic [7:0] fm_data;
    logic       fm_rx;
    wd279x_fmdem fmdem(
        .clk(clk),
        .rstn(MRn),
        .datin(RAWRDn),
        .bitlen(sysCLK / 500000),        //Todo podle bitrate
        .RXDAT(fm_data),
        .RXED(fm_rx)
    );

    logic [7:0] mfm_data;
    logic       mfm_rx;
    logic       mfm_a1, mfm_c2;
    wd279x_mfmdem mfmdem(
        .clk(clk),
        .rstn(MRn),
        .datin(RAWRDn),
        .bitlen(sysCLK / 500000),         //Todo podle bitrate
        .RXDAT(mfm_data),
        .RXED(mfm_rx),
        .DetMA1(mfm_a1),
        .DetMC2(mfm_c2)
    );

    logic [15:0] crc_out;
    logic crc_calc, crcwr;
    wd279x_crc #(.POLYNOM(16'h1021)) crc (
        .clk(clk),
        .valid(crc_calc),
        .we(fdd_rx | crcwr),
        .data_in(fdd_data),
        .crc(crc_out)
    );


endmodule