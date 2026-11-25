`timescale 1ns/1ps
module tb_axi_w_channel;
    reg         clk = 0; always #5 clk = ~clk;
    reg         resetn = 0, s_wvalid = 0, s_wlast = 0, accept_en = 1, w_consume = 0;
    reg  [31:0] s_wdata = 0;
    reg  [3:0]  s_wstrb = 0;
    wire        s_wready, w_pending, wlast_q;
    wire [31:0] wdata_q;
    wire [3:0]  wstrb_q;
    integer     errors = 0;

    axi_w_channel dut (
        .clk(clk), .resetn(resetn), .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wlast(s_wlast),
        .s_wvalid(s_wvalid), .s_wready(s_wready), .accept_en(accept_en),
        .w_pending(w_pending), .wdata_q(wdata_q), .wstrb_q(wstrb_q), .wlast_q(wlast_q), .w_consume(w_consume)
    );

    initial begin
        repeat(2) @(posedge clk); resetn = 1;
        @(negedge clk); s_wdata = 32'hCAFEBABE; s_wstrb = 4'b1010; s_wlast = 1; s_wvalid = 1;
        @(posedge clk); #1;
        if (!w_pending || wdata_q !== 32'hCAFEBABE || wstrb_q !== 4'b1010 || !wlast_q) errors = errors + 1;
        @(negedge clk); s_wvalid = 0; w_consume = 1;
        @(posedge clk); #1;
        if (w_pending) errors = errors + 1;
        $display("tb_axi_w_channel: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
