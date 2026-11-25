`timescale 1ns/1ps
// TC-26: Parameter Variation Testbench (ADDR_WIDTH=10, NUM_BANKS=4, BANK_WORDS=16, PROT_BANK_MASK=4'b1100)
module tb_axi_liteburst32_param;
    reg         clk = 0; always #5 clk = ~clk;
    reg         resetn = 0;
    reg  [9:0]  s_awaddr = 0, s_araddr = 0;
    reg  [3:0]  s_awlen = 0, s_arlen = 0;
    reg  [1:0]  s_awburst = 2'b01, s_arburst = 2'b01;
    reg  [2:0]  s_awprot = 0, s_arprot = 0;
    reg         s_awvalid = 0, s_wvalid = 0, s_wlast = 0, s_bready = 0;
    reg         s_arvalid = 0, s_rready = 0, low_power_enable = 1;
    reg  [31:0] s_wdata = 0;
    reg  [3:0]  s_wstrb = 4'hF;

    wire        s_awready, s_wready, s_bvalid, s_arready, s_rlast, s_rvalid, low_power_idle;
    wire [1:0]  s_bresp, s_rresp;
    wire [31:0] s_rdata;
    integer     errors = 0;

    axi_liteburst32_top #(
        .ADDR_WIDTH(10), .DATA_WIDTH(32),
        .NUM_BANKS(4), .BANK_WORDS(16),
        .PROT_BANK_MASK(4'b1100), .IDLE_THRESHOLD(4)
    ) dut (
        .clk(clk), .resetn(resetn),
        .s_awaddr(s_awaddr), .s_awlen(s_awlen), .s_awburst(s_awburst), .s_awprot(s_awprot),
        .s_awvalid(s_awvalid), .s_awready(s_awready),
        .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wlast(s_wlast), .s_wvalid(s_wvalid), .s_wready(s_wready),
        .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
        .s_araddr(s_araddr), .s_arlen(s_arlen), .s_arburst(s_arburst), .s_arprot(s_arprot),
        .s_arvalid(s_arvalid), .s_arready(s_arready),
        .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast), .s_rvalid(s_rvalid), .s_rready(s_rready),
        .low_power_enable(low_power_enable), .low_power_idle(low_power_idle)
    );

    initial begin
        repeat(3) @(posedge clk);
        @(negedge clk); resetn = 1;

        // Write Bank 3 (0x0C0) with prot[0]=0 -> SLVERR
        @(negedge clk); s_awaddr = 10'h0C0; s_awprot = 3'b000; s_awvalid = 1;
        s_wdata = 32'h12345678; s_wlast = 1; s_wvalid = 1;
        @(posedge clk); @(negedge clk); s_awvalid = 0; s_wvalid = 0; s_wlast = 0;
        while (!s_bvalid) @(posedge clk);
        if (s_bresp !== 2'b10) errors = errors + 1;
        @(negedge clk); s_bready = 1; @(posedge clk); @(negedge clk); s_bready = 0;

        // Write Bank 3 (0x0C0) with prot[0]=1 -> OKAY
        @(negedge clk); s_awaddr = 10'h0C0; s_awprot = 3'b001; s_awvalid = 1;
        s_wdata = 32'hABCD1234; s_wlast = 1; s_wvalid = 1;
        @(posedge clk); @(negedge clk); s_awvalid = 0; s_wvalid = 0; s_wlast = 0;
        while (!s_bvalid) @(posedge clk);
        if (s_bresp !== 2'b00) errors = errors + 1;
        @(negedge clk); s_bready = 1; @(posedge clk); @(negedge clk); s_bready = 0;

        // Read Bank 3 (0x0C0) with prot[0]=1 -> OKAY & 32'hABCD1234
        @(negedge clk); s_araddr = 10'h0C0; s_arprot = 3'b001; s_arvalid = 1;
        @(posedge clk); @(negedge clk); s_arvalid = 0;
        while (!s_rvalid) @(posedge clk);
        if (s_rresp !== 2'b00 || s_rdata !== 32'hABCD1234 || !s_rlast) errors = errors + 1;
        @(negedge clk); s_rready = 1; @(posedge clk); @(negedge clk); s_rready = 0;

        // Access unmapped 0x100 -> DECERR
        @(negedge clk); s_araddr = 10'h100; s_arprot = 3'b001; s_arvalid = 1;
        @(posedge clk); @(negedge clk); s_arvalid = 0;
        while (!s_rvalid) @(posedge clk);
        if (s_rresp !== 2'b11) errors = errors + 1;
        @(negedge clk); s_rready = 1; @(posedge clk); @(negedge clk); s_rready = 0;

        // Idle threshold = 4 check
        repeat(6) @(posedge clk); #1;
        if (!low_power_idle) errors = errors + 1;

        $display("tb_axi_liteburst32_param: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
