//------------------------------------------------------------------------------
// Module      : axi_b_channel
// Project     : AXI-LiteBurst-32
// Description : Write response channel holding s_bvalid/s_bresp stable under
//               s_bready backpressure.
//------------------------------------------------------------------------------
module axi_b_channel (
    input  wire       clk,
    input  wire       resetn,
    input  wire       make_response,
    input  wire [1:0] response_in,
    output reg  [1:0] s_bresp,
    output reg        s_bvalid,
    input  wire       s_bready
);
    always @(posedge clk) begin
        if (!resetn) begin
            s_bresp  <= 2'b00;
            s_bvalid <= 1'b0;
        end else begin
            if (make_response && !s_bvalid) begin
                s_bresp  <= response_in;
                s_bvalid <= 1'b1;
            end else if (s_bvalid && s_bready) begin
                s_bvalid <= 1'b0;
            end
        end
    end
endmodule
