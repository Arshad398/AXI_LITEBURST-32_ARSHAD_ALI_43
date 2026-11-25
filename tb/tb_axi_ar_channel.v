`timescale 1ns/1ps
module tb_axi_ar_channel;
    reg        clk = 0; always #5 clk = ~clk;
    reg        resetn = 0, s_arvalid = 0, ar_consume = 0;
    reg  [7:0] s_araddr = 0;
    reg  [3:0] s_arlen = 0;
    reg  [1:0] s_arburst = 2'b01;
    reg  [2:0] s_arprot = 0;
    wire       s_arready, ar_pending;
    wire [7:0] araddr_q;
    wire [3:0] arlen_q;
    wire [1:0] arburst_q;
    wire [2:0] arprot_q;
    integer    errors = 0;

    axi_ar_channel dut (
        .clk(clk), .resetn(resetn), .s_araddr(s_araddr), .s_arlen(s_arlen),
        .s_arburst(s_arburst), .s_arprot(s_arprot), .s_arvalid(s_arvalid),
        .s_arready(s_arready), .ar_pending(ar_pending), .araddr_q(araddr_q),
        .arlen_q(arlen_q), .arburst_q(arburst_q), .arprot_q(arprot_q), .ar_consume(ar_consume)
    );

    initial begin
        repeat(2) @(posedge clk); resetn = 1;
        @(negedge clk); s_araddr = 8'h0C; s_arlen = 4'd15; s_arburst = 2'b01; s_arprot = 3'b001; s_arvalid = 1;
        @(posedge clk); #1;
        if (!ar_pending || araddr_q !== 8'h0C || arlen_q !== 4'd15) errors = errors + 1;
        @(negedge clk); s_arvalid = 0; ar_consume = 1;
        @(posedge clk); #1;
        if (ar_pending) errors = errors + 1;
        $display("tb_axi_ar_channel: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
