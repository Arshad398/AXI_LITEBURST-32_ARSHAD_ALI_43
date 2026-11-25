//------------------------------------------------------------------------------
// Module      : address_decoder
// Project     : AXI-LiteBurst-32
// Description : Decodes byte addresses into multi-bank and word indices with
//               alignment, bounds, and AxPROT[0] privilege protection checks.
//------------------------------------------------------------------------------
module address_decoder #(
    parameter ADDR_WIDTH     = 8,
    parameter NUM_BANKS      = 2,
    parameter BANK_WORDS     = 16,
    parameter [NUM_BANKS-1:0] PROT_BANK_MASK = 2'b10,
    parameter BANK_W         = (NUM_BANKS  > 1) ? $clog2(NUM_BANKS)  : 1,
    parameter WORD_W         = (BANK_WORDS > 1) ? $clog2(BANK_WORDS) : 1
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire                  addr_overflow,
    input  wire [2:0]            prot,
    output wire                  in_range,
    output wire                  aligned,
    output wire                  prot_ok,
    output wire                  decode_err,
    output wire                  addr_valid,
    output wire [BANK_W-1:0]     bank_sel,
    output wire [WORD_W-1:0]     word_index
);
    localparam integer TOTAL_BYTES = NUM_BANKS * BANK_WORDS * 4;
    localparam integer WORD_OFFSET_W = (ADDR_WIDTH > 2) ? (ADDR_WIDTH - 2) : 1;

    wire [WORD_OFFSET_W-1:0] word_offset = addr[ADDR_WIDTH-1:2];
    wire [31:0] bank_calc = {{(32-WORD_OFFSET_W){1'b0}}, word_offset} / BANK_WORDS;
    wire [31:0] idx_calc  = {{(32-WORD_OFFSET_W){1'b0}}, word_offset} % BANK_WORDS;

    assign aligned  = (addr[1:0] == 2'b00);
    assign in_range = !addr_overflow && ({{(32-ADDR_WIDTH){1'b0}}, addr} < TOTAL_BYTES);

    assign bank_sel   = in_range ? bank_calc[BANK_W-1:0] : {BANK_W{1'b0}};
    assign word_index = in_range ? idx_calc[WORD_W-1:0]  : {WORD_W{1'b0}};

    assign prot_ok    = in_range ? (!PROT_BANK_MASK[bank_sel] || prot[0]) : 1'b0;
    assign decode_err = !in_range;
    assign addr_valid = in_range && aligned && prot_ok;
endmodule
