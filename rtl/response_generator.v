//------------------------------------------------------------------------------
// Module      : response_generator
// Project     : AXI-LiteBurst-32
// Description : Generates deterministic AXI4-Lite/Burst responses:
//               OKAY (2'b00), SLVERR (2'b10), DECERR (2'b11).
//------------------------------------------------------------------------------
module response_generator (
    input  wire       decode_err,
    input  wire       align_err,
    input  wire       prot_err,
    input  wire       burst_err,
    output reg  [1:0] response
);
    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;
    localparam [1:0] RESP_DECERR = 2'b11;

    always @(*) begin
        if (decode_err) begin
            response = RESP_DECERR;
        end else if (align_err || prot_err || burst_err) begin
            response = RESP_SLVERR;
        end else begin
            response = RESP_OKAY;
        end
    end
endmodule
