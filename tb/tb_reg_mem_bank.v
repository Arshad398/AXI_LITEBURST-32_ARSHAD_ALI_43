`timescale 1ns/1ps
module tb_reg_mem_bank;
    reg         clk = 0; always #5 clk = ~clk;
    reg         resetn = 0, clock_enable = 1, wr_en = 0, rd_en = 0;
    reg  [0:0]  wr_bank = 0, rd_bank = 0;
    reg  [3:0]  wr_index = 0, rd_index = 0;
    reg  [31:0] wr_data = 0;
    reg  [3:0]  wr_strb = 0;
    wire [31:0] rd_data;
    integer     errors = 0;

    reg_mem_bank dut (
        .clk(clk), .resetn(resetn), .clock_enable(clock_enable),
        .wr_en(wr_en), .wr_bank(wr_bank), .wr_index(wr_index), .wr_data(wr_data), .wr_strb(wr_strb),
        .rd_en(rd_en), .rd_bank(rd_bank), .rd_index(rd_index), .rd_data(rd_data)
    );

    initial begin
        repeat(2) @(posedge clk);
        resetn = 1;
        @(negedge clk); wr_en = 1; wr_bank = 0; wr_index = 2; wr_data = 32'h12345678; wr_strb = 4'hF;
        @(posedge clk); #1;
        @(negedge clk); wr_en = 0; rd_en = 1; rd_bank = 0; rd_index = 2; #1;
        if (rd_data !== 32'h12345678) errors = errors + 1;

        @(negedge clk); wr_en = 1; wr_bank = 0; wr_index = 2; wr_data = 32'hAAAA0000; wr_strb = 4'b1100;
        @(posedge clk); #1;
        @(negedge clk); wr_en = 0; rd_en = 1; rd_bank = 0; rd_index = 2; #1;
        if (rd_data !== 32'hAAAA5678) errors = errors + 1;

        // Verify bank isolation (Bank 1 index 2 must still be 0)
        @(negedge clk); rd_bank = 1; rd_index = 2; #1;
        if (rd_data !== 32'h00000000) errors = errors + 1;

        $display("tb_reg_mem_bank: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
