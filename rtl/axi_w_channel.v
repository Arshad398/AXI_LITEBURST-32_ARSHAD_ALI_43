//------------------------------------------------------------------------------
// Module      : axi_w_channel
// Project     : AXI-LiteBurst-32
// Description : Independent W channel capture/streaming stage supporting
//               WDATA, WSTRB, and custom burst WLAST with 1-beat/cycle streaming.
//------------------------------------------------------------------------------
module axi_w_channel #(
    parameter DATA_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    resetn,
    input  wire [DATA_WIDTH-1:0]   s_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_wstrb,
    input  wire                    s_wlast,
    input  wire                    s_wvalid,
    output wire                    s_wready,
    input  wire                    accept_en,
    output reg                     w_pending,
    output reg  [DATA_WIDTH-1:0]   wdata_q,
    output reg  [DATA_WIDTH/8-1:0] wstrb_q,
    output reg                     wlast_q,
    input  wire                    w_consume
);
    wire w_accept = s_wvalid && s_wready;
    wire w_clear  = w_consume && w_pending;

    assign s_wready = resetn && accept_en && (!w_pending || w_consume);

    always @(posedge clk) begin
        if (!resetn) begin
            w_pending <= 1'b0;
            wdata_q   <= {DATA_WIDTH{1'b0}};
            wstrb_q   <= {(DATA_WIDTH/8){1'b0}};
            wlast_q   <= 1'b0;
        end else begin
            case ({w_accept, w_clear})
                2'b10,
                2'b11: begin
                    w_pending <= 1'b1;
                    wdata_q   <= s_wdata;
                    wstrb_q   <= s_wstrb;
                    wlast_q   <= s_wlast;
                end
                2'b01: begin
                    w_pending <= 1'b0;
                end
                default: ;
            endcase
        end
    end
endmodule
