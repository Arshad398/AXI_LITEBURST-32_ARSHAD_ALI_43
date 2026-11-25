`timescale 1ns/1ps
module tb_read_data_path;
    reg  [31:0] mem_data;
    reg         read_allow;
    wire [31:0] data_out;
    integer     errors = 0;

    read_data_path dut (.mem_data(mem_data), .read_allow(read_allow), .data_out(data_out));

    initial begin
        mem_data = 32'h76543210; read_allow = 1; #1;
        if (data_out !== 32'h76543210) errors = errors + 1;
        read_allow = 0; #1;
        if (data_out !== 32'h00000000) errors = errors + 1;
        $display("tb_read_data_path: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
