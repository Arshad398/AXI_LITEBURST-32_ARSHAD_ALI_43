`timescale 1ns/1ps
module tb_axi_aw_channel;
    reg        clk = 0; always #5 clk = ~clk;
    reg        resetn = 0, s_awvalid = 0, aw_consume = 0;
    reg  [7:0] s_awaddr = 0;
    reg  [3:0] s_awlen = 0;
    reg  [1:0] s_awburst = 2'b01;
    reg  [2:0] s_awprot = 0;
    wire       s_awready, aw_pending;
    wire [7:0] awaddr_q;
    wire [3:0] awlen_q;
    wire [1:0] awburst_q;
    wire [2:0] awprot_q;
    integer    errors = 0;

    axi_aw_channel dut (
        .clk(clk), .resetn(resetn), .s_awaddr(s_awaddr), .s_awlen(s_awlen),
        .s_awburst(s_awburst), .s_awprot(s_awprot), .s_awvalid(s_awvalid),
        .s_awready(s_awready), .aw_pending(aw_pending), .awaddr_q(awaddr_q),
        .awlen_q(awlen_q), .awburst_q(awburst_q), .awprot_q(awprot_q), .aw_consume(aw_consume)
    );

    initial begin
        repeat(2) @(posedge clk);
        if (s_awready !== 1'b0 || aw_pending !== 1'b0) errors = errors + 1;
        resetn = 1; #1;
        if (s_awready !== 1'b1) errors = errors + 1;
        @(negedge clk); s_awaddr = 8'h24; s_awlen = 4'd7; s_awburst = 2'b01; s_awprot = 3'b001; s_awvalid = 1;
        @(posedge clk); #1;
        if (!aw_pending || awaddr_q !== 8'h24 || awlen_q !== 4'd7 || awprot_q !== 3'b001) errors = errors + 1;
        @(negedge clk); s_awvalid = 0; aw_consume = 1;
        @(posedge clk); #1;
        if (aw_pending) errors = errors + 1;
        $display("tb_axi_aw_channel: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
