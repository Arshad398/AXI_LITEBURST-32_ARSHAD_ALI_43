//------------------------------------------------------------------------------
// Module      : axi_ar_channel
// Project     : AXI-LiteBurst-32
// Description : Independent AR channel capture register supporting standard
//               ARADDR/ARPROT and custom burst extension fields ARLEN/ARBURST.
//------------------------------------------------------------------------------
module axi_ar_channel #(
    parameter ADDR_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  resetn,
    input  wire [ADDR_WIDTH-1:0] s_araddr,
    input  wire [3:0]            s_arlen,
    input  wire [1:0]            s_arburst,
    input  wire [2:0]            s_arprot,
    input  wire                  s_arvalid,
    output wire                  s_arready,
    output reg                   ar_pending,
    output reg  [ADDR_WIDTH-1:0] araddr_q,
    output reg  [3:0]            arlen_q,
    output reg  [1:0]            arburst_q,
    output reg  [2:0]            arprot_q,
    input  wire                  ar_consume
);
    assign s_arready = resetn && !ar_pending;

    always @(posedge clk) begin
        if (!resetn) begin
            ar_pending <= 1'b0;
            araddr_q   <= {ADDR_WIDTH{1'b0}};
            arlen_q    <= 4'd0;
            arburst_q  <= 2'b01;
            arprot_q   <= 3'd0;
        end else begin
            if (s_arvalid && s_arready) begin
                ar_pending <= 1'b1;
                araddr_q   <= s_araddr;
                arlen_q    <= s_arlen;
                arburst_q  <= s_arburst;
                arprot_q   <= s_arprot;
            end else if (ar_consume && ar_pending) begin
                ar_pending <= 1'b0;
            end
        end
    end
endmodule
