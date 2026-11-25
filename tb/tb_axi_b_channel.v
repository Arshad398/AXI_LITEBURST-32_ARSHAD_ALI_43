`timescale 1ns/1ps
module tb_axi_b_channel;
    reg        clk = 0; always #5 clk = ~clk;
    reg        resetn = 0, make_response = 0, s_bready = 0;
    reg  [1:0] response_in = 0;
    wire [1:0] s_bresp;
    wire       s_bvalid;
    integer    errors = 0;

    axi_b_channel dut (
        .clk(clk), .resetn(resetn), .make_response(make_response),
        .response_in(response_in), .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready)
    );

    initial begin
        repeat(2) @(posedge clk); resetn = 1;
        @(negedge clk); make_response = 1; response_in = 2'b10;
        @(posedge clk); #1;
        if (!s_bvalid || s_bresp !== 2'b10) errors = errors + 1;
        @(negedge clk); make_response = 0;
        repeat(2) @(posedge clk); #1;
        if (!s_bvalid || s_bresp !== 2'b10) errors = errors + 1; // Backpressure hold check
        @(negedge clk); s_bready = 1;
        @(posedge clk); #1;
        if (s_bvalid) errors = errors + 1;
        $display("tb_axi_b_channel: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
