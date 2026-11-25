//------------------------------------------------------------------------------
// Module      : low_power_controller
// Project     : AXI-LiteBurst-32
// Description : Monitors AXI bus and burst activity, asserts idle after
//               idle_threshold cycles, and produces glitch-free synchronous
//               clock_enable for FPGA FF CE inputs.
//------------------------------------------------------------------------------
module low_power_controller #(
    parameter COUNTER_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     resetn,
    input  wire                     activity,
    input  wire                     enable,
    input  wire [COUNTER_WIDTH-1:0] idle_threshold,
    output reg                      idle,
    output wire                     clock_enable
);
    reg [COUNTER_WIDTH-1:0] idle_count;

    always @(posedge clk) begin
        if (!resetn) begin
            idle_count <= {COUNTER_WIDTH{1'b0}};
            idle       <= 1'b0;
        end else if (!enable || activity) begin
            idle_count <= {COUNTER_WIDTH{1'b0}};
            idle       <= 1'b0;
        end else if (!idle) begin
            if (idle_threshold == {COUNTER_WIDTH{1'b0}} ||
                idle_count >= (idle_threshold - {{(COUNTER_WIDTH-1){1'b0}}, 1'b1})) begin
                idle <= 1'b1;
            end else begin
                idle_count <= idle_count + {{(COUNTER_WIDTH-1){1'b0}}, 1'b1};
            end
        end
    end

    assign clock_enable = !idle || activity || !enable;
endmodule
