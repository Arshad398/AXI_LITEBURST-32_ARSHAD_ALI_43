//------------------------------------------------------------------------------
// Module      : axi_slave_fsm
// Project     : AXI-LiteBurst-32
// Description : Dual concurrent Write/Read FSM coordinating independent AW/W/B
//               and AR/R burst engines with write-first same-word collision
//               arbitration on reg_mem_bank.
//------------------------------------------------------------------------------
module axi_slave_fsm #(
    parameter BANK_W = 1,
    parameter WORD_W = 4
)(
    input  wire              clk,
    input  wire              resetn,

    // Write channel / burst status
    input  wire              aw_pending,
    input  wire              w_pending,
    input  wire              wlast_q,
    input  wire              wr_last,
    input  wire [1:0]        wr_beat_resp,
    input  wire              wr_burst_type_err,
    input  wire              wr_cross_bank_err,
    input  wire              s_bvalid,
    input  wire              s_bready,
    input  wire [BANK_W-1:0] wr_bank,
    input  wire [WORD_W-1:0] wr_word_idx,

    // Write control outputs
    output reg               wr_burst_start,
    output reg               wr_burst_beat_done,
    output reg               wr_burst_abort,
    output reg               w_accept_en,
    output reg               w_consume,
    output reg               aw_consume,
    output reg               wr_mem_en,
    output reg               make_b,
    output reg  [1:0]        b_resp_out,

    // Read channel / burst status
    input  wire              ar_pending,
    input  wire              rd_last,
    input  wire              rd_addr_valid,
    input  wire              rd_burst_type_err,
    input  wire              rd_cross_bank_err,
    input  wire              s_rvalid,
    input  wire              s_rready,
    input  wire [BANK_W-1:0] rd_bank,
    input  wire [WORD_W-1:0] rd_word_idx,

    // Read control outputs
    output reg               rd_burst_start,
    output reg               rd_burst_beat_done,
    output reg               ar_consume,
    output reg               rd_mem_en,
    output reg               make_r,

    // Activity summary for low-power controller
    output wire              fsm_active
);
    localparam [1:0] W_IDLE  = 2'd0,
                     W_BURST = 2'd1,
                     W_RESP  = 2'd2;

    localparam [1:0] R_IDLE      = 2'd0,
                     R_BURST     = 2'd1,
                     R_WAIT_LAST = 2'd2;

    localparam [1:0] RESP_OKAY   = 2'b00,
                     RESP_SLVERR = 2'b10,
                     RESP_DECERR = 2'b11;

    reg [1:0] w_state, w_next_state;
    reg [1:0] r_state, r_next_state;
    reg [1:0] wr_sticky_err, wr_next_err;

    wire wlast_mismatch = (wlast_q != wr_last);
    wire [1:0] wr_eff_resp = (wr_beat_resp == RESP_DECERR) ? RESP_DECERR :
                             ((wr_beat_resp == RESP_SLVERR) || wr_burst_type_err ||
                              wr_cross_bank_err || wlast_mismatch) ? RESP_SLVERR : RESP_OKAY;

    wire same_word_collision = wr_mem_en && (wr_bank == rd_bank) && (wr_word_idx == rd_word_idx);
    wire rd_can_issue        = (!s_rvalid || s_rready) && !same_word_collision;

    assign fsm_active = (w_state != W_IDLE) || (r_state != R_IDLE);

    // Combinational Write FSM
    always @(*) begin
        w_next_state       = w_state;
        wr_next_err        = wr_sticky_err;
        wr_burst_start     = 1'b0;
        wr_burst_beat_done = 1'b0;
        wr_burst_abort     = 1'b0;
        w_accept_en        = 1'b1;
        w_consume          = 1'b0;
        aw_consume         = 1'b0;
        wr_mem_en          = 1'b0;
        make_b             = 1'b0;
        b_resp_out         = wr_sticky_err;

        case (w_state)
            W_IDLE: begin
                w_accept_en = 1'b1;
                wr_next_err = RESP_OKAY;
                if (aw_pending) begin
                    wr_burst_start = 1'b1;
                    w_next_state   = W_BURST;
                end
            end

            W_BURST: begin
                w_accept_en = 1'b1;
                if (w_pending) begin
                    w_consume = 1'b1;
                    wr_mem_en = (wr_eff_resp == RESP_OKAY);

                    if (wr_eff_resp == RESP_DECERR || wr_sticky_err == RESP_DECERR) begin
                        wr_next_err = RESP_DECERR;
                    end else if (wr_eff_resp == RESP_SLVERR || wr_sticky_err == RESP_SLVERR) begin
                        wr_next_err = RESP_SLVERR;
                    end else begin
                        wr_next_err = RESP_OKAY;
                    end

                    if (wr_last || wlast_q) begin
                        wr_burst_abort     = (!wr_last && wlast_q);
                        wr_burst_beat_done = wr_last;
                        make_b             = 1'b1;
                        b_resp_out         = wr_next_err;
                        w_next_state       = W_RESP;
                    end else begin
                        wr_burst_beat_done = 1'b1;
                    end
                end
            end

            W_RESP: begin
                w_accept_en = 1'b0;
                if (s_bvalid && s_bready) begin
                    aw_consume   = 1'b1;
                    w_next_state = W_IDLE;
                end
            end

            default: begin
                w_next_state = W_IDLE;
            end
        endcase
    end

    // Combinational Read FSM
    always @(*) begin
        r_next_state       = r_state;
        rd_burst_start     = 1'b0;
        rd_burst_beat_done = 1'b0;
        ar_consume         = 1'b0;
        rd_mem_en          = 1'b0;
        make_r             = 1'b0;

        case (r_state)
            R_IDLE: begin
                if (ar_pending) begin
                    rd_burst_start = 1'b1;
                    r_next_state   = R_BURST;
                end
            end

            R_BURST: begin
                if (rd_can_issue) begin
                    make_r             = 1'b1;
                    rd_burst_beat_done = 1'b1;
                    rd_mem_en          = rd_addr_valid && !rd_burst_type_err && !rd_cross_bank_err;
                    if (rd_last) begin
                        r_next_state = R_WAIT_LAST;
                    end
                end
            end

            R_WAIT_LAST: begin
                if (s_rvalid && s_rready) begin
                    ar_consume   = 1'b1;
                    r_next_state = R_IDLE;
                end
            end

            default: begin
                r_next_state = R_IDLE;
            end
        endcase
    end

    // Sequential State Registers
    always @(posedge clk) begin
        if (!resetn) begin
            w_state       <= W_IDLE;
            r_state       <= R_IDLE;
            wr_sticky_err <= RESP_OKAY;
        end else begin
            w_state       <= w_next_state;
            r_state       <= r_next_state;
            wr_sticky_err <= wr_next_err;
        end
    end
endmodule
