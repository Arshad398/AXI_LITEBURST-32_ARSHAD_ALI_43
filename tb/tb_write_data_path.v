`timescale 1ns/1ps
module tb_write_data_path;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         write_allow;
    wire [31:0] data_out;
    wire [3:0]  strb_out;
    integer     errors = 0;

    write_data_path dut (
        .wdata(wdata), .wstrb(wstrb), .write_allow(write_allow),
        .data_out(data_out), .strb_out(strb_out)
    );

    initial begin
        wdata = 32'h89ABCDEF; wstrb = 4'b0101; write_allow = 1; #1;
        if (data_out !== 32'h00AB00EF || strb_out !== 4'b0101) errors = errors + 1;
        write_allow = 0; #1;
        if (data_out !== 32'h00000000 || strb_out !== 4'b0000) errors = errors + 1;
        $display("tb_write_data_path: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
