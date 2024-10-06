module hps_io #(parameter CONF_STR, CONF_STR_BRAM=1, PS2DIV=0, WIDE=0, VDNUM=1, BLKSZ=2, PS2WE=0)
(
	input             clk_sys,
	inout      [48:0] HPS_BUS,

	// buttons up to 32
	output reg [31:0] joystick_0,
	output reg [31:0] joystick_1,
	output reg [31:0] joystick_2,
	output reg [31:0] joystick_3,
	output reg [31:0] joystick_4,
	output reg [31:0] joystick_5,
	
	// analog -127..+127, Y: [15:8], X: [7:0]
	output reg [15:0] joystick_l_analog_0,
	output reg [15:0] joystick_l_analog_1,
	output reg [15:0] joystick_l_analog_2,
	output reg [15:0] joystick_l_analog_3,
	output reg [15:0] joystick_l_analog_4,
	output reg [15:0] joystick_l_analog_5,

	output reg [15:0] joystick_r_analog_0,
	output reg [15:0] joystick_r_analog_1,
	output reg [15:0] joystick_r_analog_2,
	output reg [15:0] joystick_r_analog_3,
	output reg [15:0] joystick_r_analog_4,
	output reg [15:0] joystick_r_analog_5,

	input      [15:0] joystick_0_rumble, // 15:8 - 'large' rumble motor magnitude, 7:0 'small' rumble motor magnitude
	input      [15:0] joystick_1_rumble,
	input      [15:0] joystick_2_rumble,
	input      [15:0] joystick_3_rumble,
	input      [15:0] joystick_4_rumble,
	input      [15:0] joystick_5_rumble,

	// paddle 0..255
	output reg  [7:0] paddle_0,
	output reg  [7:0] paddle_1,
	output reg  [7:0] paddle_2,
	output reg  [7:0] paddle_3,
	output reg  [7:0] paddle_4,
	output reg  [7:0] paddle_5,

	// spinner [7:0] -128..+127, [8] - toggle with every update
	output reg  [8:0] spinner_0,
	output reg  [8:0] spinner_1,
	output reg  [8:0] spinner_2,
	output reg  [8:0] spinner_3,
	output reg  [8:0] spinner_4,
	output reg  [8:0] spinner_5,

	// ps2 keyboard emulation
	output            ps2_kbd_clk_out,
	output            ps2_kbd_data_out,
	input             ps2_kbd_clk_in,
	input             ps2_kbd_data_in,

	input       [2:0] ps2_kbd_led_status,
	input       [2:0] ps2_kbd_led_use,

	output            ps2_mouse_clk_out,
	output            ps2_mouse_data_out,
	input             ps2_mouse_clk_in,
	input             ps2_mouse_data_in,

	// ps2 alternative interface.

	// [8] - extended, [9] - pressed, [10] - toggles with every press/release
	output reg [10:0] ps2_key /* verilator public */ = 0,

	// [24] - toggles with every event
	output reg [24:0] ps2_mouse = 0 ,
	output reg [15:0] ps2_mouse_ext = 0, // 15:8 - reserved(additional buttons), 7:0 - wheel movements

	output      [1:0] buttons,
	output            forced_scandoubler,
	output            direct_video,
	input             video_rotated,

	//toggle to force notify of video mode change
	input             new_vmode,

	inout      [21:0] gamma_bus,

	output reg [127:0] status /* verilator public */,
	input      [127:0] status_in,
	input              status_set,
	input       [15:0] status_menumask /* verilator public */,

	input             info_req,
	input       [7:0] info,

	// SD config
	output reg [VD:0] img_mounted,  // signaling that new image has been mounted
	output reg        img_readonly, // mounted as read only. valid only for active bit in img_mounted
	output reg [63:0] img_size,     // size of image in bytes. valid only for active bit in img_mounted

	// SD block level access
	input      [31:0] sd_lba[VDNUM],
	input       [5:0] sd_blk_cnt[VDNUM], // number of blocks-1, total size ((sd_blk_cnt+1)*(1<<(BLKSZ+7))) must be <= 16384!
	input      [VD:0] sd_rd,
	input      [VD:0] sd_wr,
	output reg [VD:0] sd_ack,

	// SD byte level access. Signals for 2-PORT altsyncram.
	output reg [AW:0] sd_buff_addr,
	output reg [DW:0] sd_buff_dout,
	input      [DW:0] sd_buff_din[VDNUM],
	output reg        sd_buff_wr,

	// ARM -> FPGA download
	output reg        ioctl_download /* verilator public */ , // signal indicating an active download
	output reg [15:0] ioctl_index /* verilator public */ ,        // menu index used to upload the file
	output reg        ioctl_wr /* verilator public */ ,
	output reg [26:0] ioctl_addr /* verilator public */ ,         // in WIDE mode address will be incremented by 2
	output reg [DW:0] ioctl_dout /* verilator public */ ,
	output reg        ioctl_upload  /* verilator public */ ,   // signal indicating an active upload
	input             ioctl_upload_req /* verilator public */ ,   // request to save (must be supported on HPS side for specific core)
	input       [7:0] ioctl_upload_index /* verilator public */,
	input      [DW:0] ioctl_din /* verilator public */,
	output reg        ioctl_rd /* verilator public */,
	output reg [31:0] ioctl_file_ext /* verilator public */,
	input             ioctl_wait /* verilator public */,

	// [15]: 0 - unset, 1 - set. [1:0]: 0 - none, 1 - 32MB, 2 - 64MB, 3 - 128MB
	// [14]: debug mode: [8]: 1 - phase up, 0 - phase down. [7:0]: amount of shift.
	output reg [15:0] sdram_sz /* verilator public */,

	// RTC MSM6242B layout
	output reg [64:0] RTC,

	// Seconds since 1970-01-01 00:00:00
	output reg [32:0] TIMESTAMP,

	// UART flags
	output reg  [7:0] uart_mode,
	output reg [31:0] uart_speed,

	// for core-specific extensions
	inout      [35:0] EXT_BUS
);

localparam DW = (WIDE) ? 15 : 7;
localparam AW = (WIDE) ? 12 : 13;
localparam VD = VDNUM-1;

endmodule