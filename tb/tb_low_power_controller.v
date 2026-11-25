`timescale 1ns/1ps
module tb_low_power_controller;
    reg        clk = 0; always #5 clk = ~clk;
    reg        resetn = 0, activity = 0, enable = 1;
    reg  [7:0] idle_threshold = 8'd3;
    wire       idle, clock_enable;
    integer    errors = 0;

    low_power_controller dut (
        .clk(clk), .resetn(resetn), .activity(activity), .enable(enable),
        .idle_threshold(idle_threshold), .idle(idle), .clock_enable(clock_enable)
    );

    initial begin
        repeat(2) @(posedge clk); resetn = 1;
        repeat(5) @(posedge clk); #1;
        if (!idle || clock_enable) errors = errors + 1;
        @(negedge clk); activity = 1; #1;
        if (!clock_enable) errors = errors + 1; // 0-cycle wake-up on clock_enable
        @(posedge clk); #1;
        if (idle || !clock_enable) errors = errors + 1;
        @(negedge clk); activity = 0;
        repeat(5) @(posedge clk); #1;
        if (!idle) errors = errors + 1;
        $display("tb_low_power_controller: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
