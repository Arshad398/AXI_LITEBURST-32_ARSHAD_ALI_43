//------------------------------------------------------------------------------
// Module      : burst_controller
// Project     : AXI-LiteBurst-32
// Description : Controlled burst address & beat counter engine (1..16 beats).
//               Supports FIXED (2'b00) and INCR (2'b01, +4 bytes/beat),
//               prevents address wrap-around overflow, and flags bank boundary
//               crossings and unsupported burst types.
//------------------------------------------------------------------------------
module burst_controller #(
    parameter ADDR_WIDTH = 8,
    parameter NUM_BANKS  = 2,
    parameter BANK_WORDS = 16,
    parameter BANK_W     = (NUM_BANKS > 1) ? $clog2(NUM_BANKS) : 1
)(
    input  wire                  clk,
    input  wire                  resetn,
    input  wire                  start,
    input  wire                  abort,
    input  wire [ADDR_WIDTH-1:0] start_addr,
    input  wire [3:0]            burst_len,   // 0..15 => 1..16 beats
    input  wire [1:0]            burst_type,  // 2'b00 FIXED, 2'b01 INCR
    input  wire                  beat_done,
    output reg                   active,
    output reg  [ADDR_WIDTH-1:0] beat_addr,
    output reg                   addr_overflow,
    output reg  [3:0]            beat_index,
    output reg                   last,
    output reg                   burst_type_err,
    output wire                  cross_bank_err
);
    localparam integer BANK_BYTES    = BANK_WORDS * 4;
    localparam integer TOTAL_BYTES   = NUM_BANKS * BANK_BYTES;
    localparam integer WORD_OFFSET_W = (ADDR_WIDTH > 2) ? (ADDR_WIDTH - 2) : 1;

    reg [3:0]        len_q;
    reg [1:0]        burst_type_q;
    reg [BANK_W-1:0] start_bank_q;
    reg              start_in_range_q;

    wire [ADDR_WIDTH:0] next_addr_ext = {addr_overflow, beat_addr} + {{(ADDR_WIDTH-2){1'b0}}, 3'd4};

    wire [31:0] start_bank_calc = {{(32-WORD_OFFSET_W){1'b0}}, start_addr[ADDR_WIDTH-1:2]} / BANK_WORDS;
    wire [31:0] cur_bank_calc   = {{(32-WORD_OFFSET_W){1'b0}}, beat_addr[ADDR_WIDTH-1:2]} / BANK_WORDS;
    wire cur_in_range = !addr_overflow && ({{(32-ADDR_WIDTH){1'b0}}, beat_addr} < TOTAL_BYTES);

    assign cross_bank_err = active && start_in_range_q && cur_in_range &&
                            (cur_bank_calc[BANK_W-1:0] != start_bank_q);

    always @(posedge clk) begin
        if (!resetn) begin
            active           <= 1'b0;
            beat_addr        <= {ADDR_WIDTH{1'b0}};
            addr_overflow    <= 1'b0;
            beat_index       <= 4'd0;
            len_q            <= 4'd0;
            burst_type_q     <= 2'b01;
            start_bank_q     <= {BANK_W{1'b0}};
            start_in_range_q <= 1'b0;
            last             <= 1'b0;
            burst_type_err   <= 1'b0;
        end else if (abort) begin
            active         <= 1'b0;
            last           <= 1'b0;
            addr_overflow  <= 1'b0;
            burst_type_err <= 1'b0;
        end else if (start && !active) begin
            active           <= 1'b1;
            beat_addr        <= start_addr;
            addr_overflow    <= 1'b0;
            beat_index       <= 4'd0;
            len_q            <= burst_len;
            burst_type_q     <= burst_type;
            start_bank_q     <= start_bank_calc[BANK_W-1:0];
            start_in_range_q <= ({{(32-ADDR_WIDTH){1'b0}}, start_addr} < TOTAL_BYTES);
            last             <= (burst_len == 4'd0);
            burst_type_err   <= (burst_type != 2'b00) && (burst_type != 2'b01);
        end else if (active && beat_done) begin
            if (beat_index >= len_q) begin
                active        <= 1'b0;
                last          <= 1'b0;
                addr_overflow <= 1'b0;
            end else begin
                beat_index <= beat_index + 4'd1;
                last       <= ((beat_index + 4'd1) >= len_q);
                if (burst_type_q == 2'b01) begin
                    beat_addr     <= next_addr_ext[ADDR_WIDTH-1:0];
                    addr_overflow <= next_addr_ext[ADDR_WIDTH];
                end
            end
        end
    end
endmodule
