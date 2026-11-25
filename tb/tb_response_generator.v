`timescale 1ns/1ps
module tb_response_generator;
    reg        decode_err, align_err, prot_err, burst_err;
    wire [1:0] response;
    integer    errors = 0;

    response_generator dut (
        .decode_err(decode_err), .align_err(align_err),
        .prot_err(prot_err), .burst_err(burst_err), .response(response)
    );

    initial begin
        {decode_err, align_err, prot_err, burst_err} = 4'b0000; #1; if (response !== 2'b00) errors = errors + 1;
        {decode_err, align_err, prot_err, burst_err} = 4'b0100; #1; if (response !== 2'b10) errors = errors + 1;
        {decode_err, align_err, prot_err, burst_err} = 4'b0010; #1; if (response !== 2'b10) errors = errors + 1;
        {decode_err, align_err, prot_err, burst_err} = 4'b0001; #1; if (response !== 2'b10) errors = errors + 1;
        {decode_err, align_err, prot_err, burst_err} = 4'b1111; #1; if (response !== 2'b11) errors = errors + 1;
        $display("tb_response_generator: %s (errors=%0d)", errors == 0 ? "PASS" : "FAIL", errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
