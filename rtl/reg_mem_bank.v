//------------------------------------------------------------------------------
// Module      : reg_mem_bank
// Project     : AXI-LiteBurst-32
// Description : Configurable multi-bank 32-bit synchronous register file with
//               byte-lane WSTRB write enables and glitch-free clock_enable (CE).
//------------------------------------------------------------------------------
module reg_mem_bank #(
    parameter DATA_WIDTH = 32,
    parameter NUM_BANKS  = 2,
    parameter BANK_WORDS = 16,
    parameter BANK_W     = (NUM_BANKS  > 1) ? $clog2(NUM_BANKS)  : 1,
    parameter WORD_W     = (BANK_WORDS > 1) ? $clog2(BANK_WORDS) : 1
)(
    input  wire                    clk,
    input  wire                    resetn,
    input  wire                    clock_enable,
    input  wire                    wr_en,
    input  wire [BANK_W-1:0]       wr_bank,
    input  wire [WORD_W-1:0]       wr_index,
    input  wire [DATA_WIDTH-1:0]   wr_data,
    input  wire [DATA_WIDTH/8-1:0] wr_strb,
    input  wire                    rd_en,
    input  wire [BANK_W-1:0]       rd_bank,
    input  wire [WORD_W-1:0]       rd_index,
    output wire [DATA_WIDTH-1:0]   rd_data
);
    localparam integer TOTAL_WORDS = NUM_BANKS * BANK_WORDS;
    localparam integer IDX_W       = (TOTAL_WORDS > 1) ? $clog2(TOTAL_WORDS) : 1;

    reg [DATA_WIDTH-1:0] mem [0:TOTAL_WORDS-1];

    wire [31:0] wr_flat_calc = ({{(32-BANK_W){1'b0}}, wr_bank} * BANK_WORDS) +
                               {{(32-WORD_W){1'b0}}, wr_index};
    wire [31:0] rd_flat_calc = ({{(32-BANK_W){1'b0}}, rd_bank} * BANK_WORDS) +
                               {{(32-WORD_W){1'b0}}, rd_index};

    wire [IDX_W-1:0] wr_flat_idx = (wr_flat_calc < TOTAL_WORDS) ? wr_flat_calc[IDX_W-1:0] : {IDX_W{1'b0}};
    wire [IDX_W-1:0] rd_flat_idx = (rd_flat_calc < TOTAL_WORDS) ? rd_flat_calc[IDX_W-1:0] : {IDX_W{1'b0}};

    integer i, b;
    always @(posedge clk) begin
        if (!resetn) begin
            for (i = 0; i < TOTAL_WORDS; i = i + 1) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (clock_enable && wr_en) begin
            for (b = 0; b < DATA_WIDTH/8; b = b + 1) begin
                if (wr_strb[b]) begin
                    mem[wr_flat_idx][8*b +: 8] <= wr_data[8*b +: 8];
                end
            end
        end
    end

    assign rd_data = rd_en ? mem[rd_flat_idx] : {DATA_WIDTH{1'b0}};
endmodule
