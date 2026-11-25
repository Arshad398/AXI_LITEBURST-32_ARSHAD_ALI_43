//------------------------------------------------------------------------------
// Module      : axi_aw_channel
// Project     : AXI-LiteBurst-32
// Description : Independent AW channel capture register supporting standard
//               AWADDR/AWPROT and custom burst extension fields AWLEN/AWBURST.
//------------------------------------------------------------------------------
module axi_aw_channel #(
    parameter ADDR_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  resetn,
    input  wire [ADDR_WIDTH-1:0] s_awaddr,
    input  wire [3:0]            s_awlen,
    input  wire [1:0]            s_awburst,
    input  wire [2:0]            s_awprot,
    input  wire                  s_awvalid,
    output wire                  s_awready,
    output reg                   aw_pending,
    output reg  [ADDR_WIDTH-1:0] awaddr_q,
    output reg  [3:0]            awlen_q,
    output reg  [1:0]            awburst_q,
    output reg  [2:0]            awprot_q,
    input  wire                  aw_consume
);
    assign s_awready = resetn && !aw_pending;

    always @(posedge clk) begin
        if (!resetn) begin
            aw_pending <= 1'b0;
            awaddr_q   <= {ADDR_WIDTH{1'b0}};
            awlen_q    <= 4'd0;
            awburst_q  <= 2'b01;
            awprot_q   <= 3'd0;
        end else begin
            if (s_awvalid && s_awready) begin
                aw_pending <= 1'b1;
                awaddr_q   <= s_awaddr;
                awlen_q    <= s_awlen;
                awburst_q  <= s_awburst;
                awprot_q   <= s_awprot;
            end else if (aw_consume && aw_pending) begin
                aw_pending <= 1'b0;
            end
        end
    end
endmodule
