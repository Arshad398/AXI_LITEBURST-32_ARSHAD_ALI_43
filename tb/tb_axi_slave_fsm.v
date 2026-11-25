`timescale 1ns/1ps
module tb_axi_slave_fsm;
    reg        clk = 0; always #5 clk = ~clk;
    reg        resetn = 0;
    reg        aw_pending = 0, w_pending = 0, wlast_q = 0, wr_last = 0;
    reg  [1:0] wr_beat_resp = 0;
    reg        wr_burst_type_err = 0, wr_cross_bank_err = 0, s_bvalid = 0, s_bready = 0;
    reg  [0:0] wr_bank = 0, rd_bank = 0;
    reg  [3:0] wr_word_idx = 0, rd_word_idx = 0;
    reg        ar_pending = 0, rd_last = 0, rd_addr_valid = 1, rd_burst_type_err = 0, rd_cross_bank_err = 0;
    reg        s_rvalid = 0, s_rready = 1;

    wire       wr_burst_start, wr_burst_beat_done, wr_burst_abort, w_accept_en, w_consume, aw_consume, wr_mem_en, make_b;
    wire [1:0] b_resp_out;
    wire       rd_burst_start, rd_burst_beat_done, ar_consume, rd_mem_en, make_r, fsm_active;
    integer    errors = 0;

    axi_slave_fsm dut (
        .clk(clk), .resetn(resetn),
        .aw_pending(aw_pending), .w_pending(w_pending), .wlast_q(wlast_q), .wr_last(wr_last),
        .wr_beat_resp(wr_beat_resp), .wr_burst_type_err(wr_burst_type_err), .wr_cross_bank_err(wr_cross_bank_err),
        .s_bvalid(s_bvalid), .s_bready(s_bready), .wr_bank(wr_bank), .wr_word_idx(wr_word_idx),
        .wr_burst_start(wr_burst_start), .wr_burst_beat_done(wr_burst_beat_done), .wr_burst_abort(wr_burst_abort),
        .w_accept_en(w_accept_en), .w_consume(w_consume), .aw_consume(aw_consume),
        .wr_mem_en(wr_mem_en), .make_b(make_b), .b_resp_out(b_resp_out),
        .ar_pending(ar_pending), .rd_last(rd_last), .rd_addr_valid(rd_addr_valid),
        .rd_burst_type_err(rd_burst_type_err), .rd_cross_bank_err(rd_cross_bank_err),
        .s_rvalid(s_rvalid), .s_rready(s_rready), .rd_bank(rd_bank), .rd_word_idx(rd_word_idx),
        .rd_burst_start(rd_burst_start), .rd_burst_beat_done(rd_burst_beat_done),
        .ar_consume(ar_consume), .rd_mem_en(rd_mem_en), .make_r(make_r), .fsm_active(fsm_active)
    );

    initial begin
        repeat(2) @(posedge clk); resetn = 1;
        // Start concurrent write and read to DIFFERENT words
        @(negedge clk); aw_pending = 1; ar_pending = 1; #1;
        if (!wr_burst_start || !rd_burst_start) errors = errors + 1;
        @(posedge clk); #1;

        // Collision test on same word (0, 0): write wins, read suppressed 1 cycle
        @(negedge clk); w_pending = 1; wlast_q = 1; wr_last = 1; rd_last = 1;
        wr_bank = 0; wr_word_idx = 0; rd_bank = 0; rd_word_idx = 0; #1;
        if (!wr_mem_en || make_r) errors = errors + 1;

        $display("tb_axi_slave_fsm: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
