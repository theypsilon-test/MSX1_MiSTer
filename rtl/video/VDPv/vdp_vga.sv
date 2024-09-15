//
//  vdp_vga.vhd
//   VGA up-scan converter.
//
//  Copyright (C) 2006 Kunihiko Ohnaka
//  All rights reserved.
//                                     http://www.ohnaka.jp/ese-vdp/
//
//  本ソフトウェアおよび本ソフトウェアに基づいて作成された派生物は、以下の条件を
//  満たす場合に限り、再頒布および使用が許可されます。
//
//  1.ソースコード形式で再頒布する場合、上記の著作権表示、本条件一覧、および下記
//    免責条項をそのままの形で保持すること。
//  2.バイナリ形式で再頒布する場合、頒布物に付属のドキュメント等の資料に、上記の
//    著作権表示、本条件一覧、および下記免責条項を含めること。
//  3.書面による事前の許可なしに、本ソフトウェアを販売、および商業的な製品や活動
//    に使用しないこと。
//
//  本ソフトウェアは、著作権者によって「現状のまま」提供されています。著作権者は、
//  特定目的への適合性の保証、商品性の保証、またそれに限定されない、いかなる明示
//  的もしくは暗黙な保証責任も負いません。著作権者は、事由のいかんを問わず、損害
//  発生の原因いかんを問わず、かつ責任の根拠が契約であるか厳格責任であるか（過失
//  その他の）不法行為であるかを問わず、仮にそのような損害が発生する可能性を知ら
//  されていたとしても、本ソフトウェアの使用によって発生した（代替品または代用サ
//  ービスの調達、使用の喪失、データの喪失、利益の喪失、業務の中断も含め、またそ
//  れに限定されない）直接損害、間接損害、偶発的な損害、特別損害、懲罰的損害、ま
//  たは結果損害について、一切責任を負わないものとします。
//
//  Note that above Japanese version license is the formal document.
//  The following translation is only for reference.
//
//  Redistribution and use of this software or any derivative works,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above
//     copyright notice, this list of conditions and the following
//     disclaimer in the documentation and/or other materials
//     provided with the distribution.
//  3. Redistributions may not be sold, nor may they be used in a
//     commercial product or activity without specific prior written
//     permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
//  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
//-----------------------------------------------------------------------------
// Memo
//   Japanese comment lines are starts with "JP:".
//   JP: 日本語のコメント行は JP:を頭に付ける事にする
//
//-----------------------------------------------------------------------------
// Revision History
//
// 3rd,June,2018 modified by KdL
//  - Added a trick to help set a pixel ratio 1:1
//    on an LED display at 60Hz (not guaranteed on all displays)
//
// 29th,October,2006 modified by Kunihiko Ohnaka
//  - Inserted the license text
//  - Added the document part below
//
// ??th,August,2006 modified by Kunihiko Ohnaka
//  - Moved the equalization pulse generator from vdp.vhd
//
// 20th,August,2006 modified by Kunihiko Ohnaka
//  - Changed field mapping algorithm when interlace mode is enabled
//        even field  -> even line (odd  line is black)
//        odd  field  -> odd line  (even line is black)
//
// 13th,October,2003 created by Kunihiko Ohnaka
// JP: VDPのコアの実装と表示デバイスへの出力を別ソースにした．
//
//-----------------------------------------------------------------------------
// Document
//
// JP: ESE-VDPコア(vdp.vhd)が生成したビデオ信号を、VGAタイミングに
// JP: 変換するアップスキャンコンバータです。
// JP: NTSCは水平同期周波数が15.7kHz、垂直同期周波数が60Hzですが、
// JP: VGAの水平同期周波数は31.5kHz、垂直同期周波数は60Hzであり、
// JP: ライン数だけがほぼ倍になったようなタイミングになります。
// JP: そこで、vdpを ntscモードで動かし、各ラインを倍の速度で
// JP: 二度描画することでスキャンコンバートを実現しています。
//

module VDP_VGA_v (
    input  logic         CLK21M,
    input  logic         RESET,
    input  logic [5:0]   VIDEORIN,
    input  logic [5:0]   VIDEOGIN,
    input  logic [5:0]   VIDEOBIN,
    input  logic         VIDEOVSIN_N,
    input  logic [10:0]  HCOUNTERIN,
    input  logic [10:0]  VCOUNTERIN,
    input  logic         PALMODE,        // Added by caro
    input  logic         INTERLACEMODE,
    input  logic         LEGACY_VGA,
    output logic [5:0]   VIDEOROUT,
    output logic [5:0]   VIDEOGOUT,
    output logic [5:0]   VIDEOBOUT,
    output logic         VIDEODEOUT,
    output logic         VIDEOHSOUT_N,
    output logic         VIDEOVSOUT_N,
    output logic         BLANK_O,
    input  logic [2:0]   RATIOMODE
);

    logic FF_HSYNC_N, FF_VSYNC_N;
    logic VIDEOOUTX;
    logic [9:0] XPOSITIONW, XPOSITIONR;
    logic EVENODD;
    logic [5:0] DATAROUT, DATAGOUT, DATABOUT;

    // Constants
    localparam integer DISP_WIDTH   = 576;
    localparam integer DISP_START_Y =  3;
    localparam integer PRB_HEIGHT   = 25;
    localparam integer RIGHT_X      = 684 - DISP_WIDTH - 2;              // 106
    localparam integer PAL_RIGHT_X  = 87;                                // 87
    localparam integer CENTER_X     = RIGHT_X - 32 - 2;                  // 72
    localparam integer BASE_LEFT_X  = CENTER_X - 32 - 2 - 3;             // 35
    localparam integer CENTER_Y     = 12;

    integer DISP_START_X = 684 - DISP_WIDTH - 2;

    assign VIDEOROUT = (VIDEOOUTX == 1'b1) ? DATAROUT : 6'b000000;
    assign VIDEOGOUT = (VIDEOOUTX == 1'b1) ? DATAGOUT : 6'b000000;
    assign VIDEOBOUT = (VIDEOOUTX == 1'b1) ? DATABOUT : 6'b000000;

    VDP_DOUBLEBUF_v DBUF (
        .CLK(CLK21M),
        .XPOSITIONW(XPOSITIONW),
        .XPOSITIONR(XPOSITIONR),
        .EVENODD(EVENODD),
        .WE(1'b1),
        .DATARIN(VIDEORIN),
        .DATAGIN(VIDEOGIN),
        .DATABIN(VIDEOBIN),
        .DATAROUT(DATAROUT),
        .DATAGOUT(DATAGOUT),
        .DATABOUT(DATABOUT)
    );

    assign XPOSITIONW = HCOUNTERIN[10:1] - toVector(CLOCKS_PER_LINE / 2 - DISP_WIDTH - 10);
    assign EVENODD = VCOUNTERIN[1];


    always_ff @(posedge CLK21M or posedge RESET) begin
        if (RESET) begin
            DISP_START_X <= 684 - DISP_WIDTH - 2;
        end else begin
            if ((RATIOMODE == 3'b000 || INTERLACEMODE == 1'b1 || PALMODE == 1'b1) && LEGACY_VGA == 1'b1) begin
                // LEGACY OUTPUT
                DISP_START_X <= RIGHT_X;        // 106
            end else if (PALMODE == 1'b1) begin
                // 50HZ
                DISP_START_X <= PAL_RIGHT_X;    // 87
            end else if (RATIOMODE == 3'b000 || INTERLACEMODE == 1'b1) begin
                // 60HZ
                DISP_START_X <= CENTER_X;       // 72
            end else if ((VCOUNTERIN < toVector(38 + DISP_START_Y + PRB_HEIGHT)) || (VCOUNTERIN > toVector(526 - PRB_HEIGHT) && VCOUNTERIN < 526) ||
                         (VCOUNTERIN > toVector(524 + 38 + DISP_START_Y) && VCOUNTERIN < toVector(524 + 38 + DISP_START_Y + PRB_HEIGHT)) ||
                         (VCOUNTERIN > toVector(524 + 526 - PRB_HEIGHT))) begin
                            // PIXEL RATIO 1:1 (VGA MODE, 60HZ, NOT INTERLACED)  
                            if (EVENODD == 1'b1) begin
                                DISP_START_X <= BASE_LEFT_X +{{29{1'b0}}, ~RATIOMODE}; // 35 TO 41
                            end else begin
                                DISP_START_X <= RIGHT_X;    // 106
                            end
                    end else begin
                            DISP_START_X <= CENTER_X; //72
                    end
        end
    end

    // GENERATE H-SYNC SIGNAL
    always_ff @(posedge CLK21M or posedge RESET) begin
        if (RESET) begin
            FF_HSYNC_N <= 1'b1;
        end else begin
            if (HCOUNTERIN == 0 || HCOUNTERIN == toVector(CLOCKS_PER_LINE / 2)) begin
                FF_HSYNC_N <= 1'b0;
            end else if (HCOUNTERIN == 40 || HCOUNTERIN == toVector(CLOCKS_PER_LINE / 2 + 40)) begin
                FF_HSYNC_N <= 1'b1;
            end
        end
    end

    // GENERATE V-SYNC SIGNAL
    // THE VIDEOVSIN_N SIGNAL IS NOT USED
    always_ff @(posedge CLK21M or posedge RESET) begin
        if (RESET) begin
            FF_VSYNC_N <= 1'b1;
        end else begin
            if (PALMODE == 1'b0) begin
                if (INTERLACEMODE == 1'b0) begin
                    if (VCOUNTERIN == toVector(3*2 + CENTER_Y) || VCOUNTERIN == toVector(524 + 3*2 + CENTER_Y)) begin
                        FF_VSYNC_N <= 1'b0;
                    end else if (VCOUNTERIN == toVector(6*2 + CENTER_Y) || VCOUNTERIN == toVector(524 + 6*2 + CENTER_Y)) begin
                        FF_VSYNC_N <= 1'b1;
                    end
                end else begin
                    if (VCOUNTERIN == toVector(3*2) || VCOUNTERIN == toVector(525 + 3*2+CENTER_Y)) begin
                        FF_VSYNC_N <= 1'b0;
                    end else if (VCOUNTERIN == toVector(6*2+CENTER_Y) || VCOUNTERIN == toVector(525 + 6*2+CENTER_Y)) begin
                        FF_VSYNC_N <= 1'b1;
                    end
                end
            end else begin
                if (INTERLACEMODE == 1'b0) begin
                    if (VCOUNTERIN == toVector(3*2+CENTER_Y+6) || VCOUNTERIN == toVector(626 + 3*2+CENTER_Y+6)) begin
                        FF_VSYNC_N <= 1'b0;
                    end else if (VCOUNTERIN == toVector(6*2+CENTER_Y+6) || VCOUNTERIN == toVector(626 + 6*2+CENTER_Y+6)) begin
                        FF_VSYNC_N <= 1'b1;
                    end
                end else begin
                    if (VCOUNTERIN == toVector(3*2+CENTER_Y+6) || VCOUNTERIN == toVector(625 + 3*2+CENTER_Y+6)) begin
                        FF_VSYNC_N <= 1'b0;
                    end else if (VCOUNTERIN == toVector(6*2+CENTER_Y+6) || VCOUNTERIN == toVector(625 + 6*2+CENTER_Y+6)) begin
                        FF_VSYNC_N <= 1'b1;
                    end
                end
            end
        end
    end

    // GENERATE DATA READ TIMING
    always_ff @(posedge CLK21M or posedge RESET) begin
        if (RESET) begin
            XPOSITIONR <= '0;
        end else begin
            if (HCOUNTERIN == toVector(DISP_START_X) || HCOUNTERIN == toVector(DISP_START_X + CLOCKS_PER_LINE / 2)) begin
                XPOSITIONR <= '0;
            end else begin
                XPOSITIONR <= XPOSITIONR + 1'b1;
            end
        end
    end
    
    // GENERATE VIDEO OUTPUT TIMING
    always_ff @(posedge CLK21M or posedge RESET) begin
        if (RESET) begin
            VIDEOOUTX <= 1'b0;
        end else begin
            if (HCOUNTERIN == toVector(DISP_START_X) || HCOUNTERIN == toVector(DISP_START_X + CLOCKS_PER_LINE / 2) && ~INTERLACEMODE) begin
                VIDEOOUTX <= 1'b1;
            end else if (HCOUNTERIN == toVector(DISP_START_X + DISP_WIDTH) || HCOUNTERIN == toVector(DISP_START_X + DISP_WIDTH + CLOCKS_PER_LINE / 2)) begin
                VIDEOOUTX <= 1'b0;
            end
        end
    end

    assign VIDEOHSOUT_N = FF_HSYNC_N;
    assign VIDEOVSOUT_N = FF_VSYNC_N;
    assign VIDEODEOUT   = VIDEOOUTX;

    // HDMI Support
    assign BLANK_O = (VIDEOOUTX == 1'b0 || FF_VSYNC_N == 1'b0) ? 1'b1 : 1'b0;

endmodule
