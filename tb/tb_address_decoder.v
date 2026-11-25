`timescale 1ns/1ps
module tb_address_decoder;
    reg  [7:0] addr;
    reg        addr_overflow;
    reg  [2:0] prot;
    wire       in_range, aligned, prot_ok, decode_err, addr_valid;
    wire [0:0] bank_sel;
    wire [3:0] word_index;
    integer    errors = 0;

    address_decoder dut (
        .addr(addr), .addr_overflow(addr_overflow), .prot(prot),
        .in_range(in_range), .aligned(aligned), .prot_ok(prot_ok),
        .decode_err(decode_err), .addr_valid(addr_valid),
        .bank_sel(bank_sel), .word_index(word_index)
    );

    initial begin
        addr_overflow = 0; prot = 3'b000;
        addr = 8'h00; #1; if (!addr_valid || bank_sel != 0 || word_index != 0) errors = errors + 1;
        addr = 8'h3C; #1; if (!addr_valid || bank_sel != 0 || word_index != 15) errors = errors + 1;
        addr = 8'h40; #1; if (addr_valid || prot_ok || decode_err) errors = errors + 1; // Bank 1 needs prot[0]=1
        prot = 3'b001; #1; if (!addr_valid || bank_sel != 1 || word_index != 0) errors = errors + 1;
        addr = 8'h01; #1; if (addr_valid || aligned) errors = errors + 1;
        addr = 8'h80; #1; if (!decode_err || addr_valid) errors = errors + 1;
        addr = 8'h00; addr_overflow = 1; #1; if (!decode_err || addr_valid) errors = errors + 1;
        $display("tb_address_decoder: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
