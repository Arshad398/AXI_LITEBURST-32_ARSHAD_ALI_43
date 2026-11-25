//------------------------------------------------------------------------------
// Module      : write_data_path
// Project     : AXI-LiteBurst-32
// Description : Write data and byte-lane strobe conditioning with error gating.
//------------------------------------------------------------------------------
module write_data_path #(
    parameter DATA_WIDTH = 32
)(
    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire [DATA_WIDTH/8-1:0] wstrb,
    input  wire                    write_allow,
    output wire [DATA_WIDTH-1:0]   data_out,
    output wire [DATA_WIDTH/8-1:0] strb_out
);
    localparam integer STRB_W = DATA_WIDTH / 8;

    genvar b;
    generate
        for (b = 0; b < STRB_W; b = b + 1) begin : gen_lane_mask
            assign data_out[8*b +: 8] = (write_allow && wstrb[b]) ? wdata[8*b +: 8] : 8'h00;
            assign strb_out[b]        = write_allow ? wstrb[b] : 1'b0;
        end
    endgenerate
endmodule
