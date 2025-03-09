template <size_t VNUM>
void SimPlayer<VNUM>::HPSpreEvalTick(void) {
	type_Data data;
	CData sd_rd;
	uint16_t sd_rd_id = signalMap["sd_rd"];
	uint16_t sd_ack_id = signalMap["sd_ack"];
	uint16_t sd_lba_id = signalMap["sd_lba"];
	uint16_t sd_buff_dout_id = signalMap["sd_buff_dout"];
	uint16_t sd_buff_addr_id = signalMap["sd_buff_addr"];
	uint16_t sd_buff_wr_id = signalMap["sd_buff_wr"];

	data = signals[sd_rd_id].signal;
	sd_rd = (*reinterpret_cast<CData*>(data.ptr) & data.mask);

	for (size_t i = 0; i < images.size(); i++) {
		if (images[i].size > 0) {
			data = signals[images[i].clock_id].signal;
			bool clk = (*reinterpret_cast<CData*>(data.ptr) & data.mask) > 0 ? true : false;
			if (images[i].last_clk == false && clk) {
				if (images[i].last_rd == false && (sd_rd & (1 << i))) {
					images[i].lba = *static_cast<IData(*)[VNUM]>(signals[sd_lba_id].signals.ptr)[i];

					*reinterpret_cast<CData*>(signals[sd_ack_id].signal.ptr) = (*reinterpret_cast<CData*>(signals[sd_ack_id].signal.ptr) | (1 << i)) & signals[sd_ack_id].signal.mask;
					*reinterpret_cast<CData*>(signals[sd_buff_dout_id].signal.ptr) = images[i].buffer[images[i].lba * 512 + images[i].pos] & signals[sd_buff_dout_id].signal.mask;
					*reinterpret_cast<SData*>(signals[sd_buff_addr_id].signal.ptr) = images[i].pos & signals[sd_buff_addr_id].signal.mask;
					*reinterpret_cast<CData*>(signals[sd_buff_wr_id].signal.ptr) = 1;
					images[i].pos++;
				}
				else if (images[i].pos == 512) {
					images[i].pos = 0;
					*reinterpret_cast<CData*>(signals[sd_ack_id].signal.ptr) = *reinterpret_cast<CData*>(signals[sd_ack_id].signal.ptr) & (~(1 << i) & signals[sd_ack_id].signal.mask);
					*reinterpret_cast<CData*>(signals[sd_buff_wr_id].signal.ptr) = 0;
					*reinterpret_cast<SData*>(signals[sd_buff_addr_id].signal.ptr) = 0;
				}
				else if (images[i].pos > 0) {
					*reinterpret_cast<CData*>(signals[sd_buff_dout_id].signal.ptr) = images[i].buffer[images[i].lba * 512 + images[i].pos] & signals[sd_buff_dout_id].signal.mask;
					*reinterpret_cast<SData*>(signals[sd_buff_addr_id].signal.ptr) = images[i].pos & signals[sd_buff_addr_id].signal.mask;
					images[i].pos++;
				}
				images[i].last_rd = (sd_rd & (1 << i)) ? true : false;
			}
			images[i].last_clk == clk;
		}
	}
}

template <size_t VNUM>
void SimPlayer<VNUM>::HPSpostEvalTick(void) {
	for (size_t i = 0; i < images.size(); i++) {
		if (images[i].size > 0) {

		}
	}
}