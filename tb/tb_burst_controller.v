`timescale 1ns/1ps
module tb_burst_controller;
    reg        clk = 0; always #5 clk = ~clk;
    reg        resetn = 0, start = 0, abort = 0, beat_done = 0;
    reg  [7:0] start_addr = 0;
    reg  [3:0] burst_len = 0;
    reg  [1:0] burst_type = 2'b01;
    wire       active, addr_overflow, last, burst_type_err, cross_bank_err;
    wire [7:0] beat_addr;
    wire [3:0] beat_index;
    integer    errors = 0;

    burst_controller dut (
        .clk(clk), .resetn(resetn), .start(start), .abort(abort),
        .start_addr(start_addr), .burst_len(burst_len), .burst_type(burst_type),
        .beat_done(beat_done), .active(active), .beat_addr(beat_addr),
        .addr_overflow(addr_overflow), .beat_index(beat_index),
        .last(last), .burst_type_err(burst_type_err), .cross_bank_err(cross_bank_err)
    );

    initial begin
        repeat(2) @(posedge clk); resetn = 1;

        // 4-beat INCR burst starting at 0x10
        @(negedge clk); start_addr = 8'h10; burst_len = 4'd3; burst_type = 2'b01; start = 1;
        @(posedge clk); #1;
        if (!active || beat_addr !== 8'h10 || beat_index !== 0 || last) errors = errors + 1;
        @(negedge clk); start = 0;
        repeat(3) begin
            @(negedge clk); beat_done = 1;
            @(posedge clk); #1;
        end
        @(negedge clk); beat_done = 0; #1;
        if (!active || beat_addr !== 8'h1C || beat_index !== 3 || !last) errors = errors + 1;
        @(negedge clk); beat_done = 1;
        @(posedge clk); #1;
        @(negedge clk); beat_done = 0;
        if (active) errors = errors + 1;

        // Bank crossing check: 0x3C -> 0x40
        @(negedge clk); start_addr = 8'h3C; burst_len = 4'd1; burst_type = 2'b01; start = 1;
        @(posedge clk); #1;
        if (cross_bank_err) errors = errors + 1;
        @(negedge clk); start = 0; beat_done = 1;
        @(posedge clk); #1;
        if (!cross_bank_err) errors = errors + 1;

        $display("tb_burst_controller: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
