//------------------------------------------------------------------------------
// Module      : axi_r_channel
// Project     : AXI-LiteBurst-32
// Description : Read data/response channel supporting 1-beat/cycle streaming,
//               RLAST generation, and full backpressure stability.
//------------------------------------------------------------------------------
module axi_r_channel #(
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  resetn,
    input  wire                  make_response,
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire [1:0]            response_in,
    input  wire                  last_in,
    output reg  [DATA_WIDTH-1:0] s_rdata,
    output reg  [1:0]            s_rresp,
    output reg                   s_rlast,
    output reg                   s_rvalid,
    input  wire                  s_rready
);
    always @(posedge clk) begin
        if (!resetn) begin
            s_rdata  <= {DATA_WIDTH{1'b0}};
            s_rresp  <= 2'b00;
            s_rlast  <= 1'b0;
            s_rvalid <= 1'b0;
        end else begin
            if (make_response && (!s_rvalid || s_rready)) begin
                s_rdata  <= data_in;
                s_rresp  <= response_in;
                s_rlast  <= last_in;
                s_rvalid <= 1'b1;
            end else if (s_rvalid && s_rready) begin
                s_rvalid <= 1'b0;
                s_rlast  <= 1'b0;
            end
        end
    end
endmodule
