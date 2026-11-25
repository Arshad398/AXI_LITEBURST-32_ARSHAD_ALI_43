//------------------------------------------------------------------------------
// Module      : axi_liteburst32_top
// Project     : AXI-LiteBurst-32
// Description : Top-level 5-channel AXI4-Lite-compatible slave IP with
//               controlled custom 1-16 beat burst extension, multi-bank
//               protected register memory, byte-lane WSTRB masking, and
//               glitch-free synchronous low-power clock-enable management.
//------------------------------------------------------------------------------
module axi_liteburst32_top #(
    parameter integer ADDR_WIDTH = 8,
    parameter integer DATA_WIDTH = 32,
    parameter integer NUM_BANKS  = 2,
    parameter integer BANK_WORDS = 16,
    parameter [NUM_BANKS-1:0] PROT_BANK_MASK = 2'b10,
    parameter integer IDLE_THRESHOLD = 8
)(
    input  wire                    clk,
    input  wire                    resetn,

    // Write Address Channel (Standard + Custom Burst Extension)
    input  wire [ADDR_WIDTH-1:0]   s_awaddr,
    input  wire [3:0]              s_awlen,
    input  wire [1:0]              s_awburst,
    input  wire [2:0]              s_awprot,
    input  wire                    s_awvalid,
    output wire                    s_awready,

    // Write Data Channel (Standard + Custom WLAST)
    input  wire [DATA_WIDTH-1:0]   s_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_wstrb,
    input  wire                    s_wlast,
    input  wire                    s_wvalid,
    output wire                    s_wready,

    // Write Response Channel
    output wire [1:0]              s_bresp,
    output wire                    s_bvalid,
    input  wire                    s_bready,

    // Read Address Channel (Standard + Custom Burst Extension)
    input  wire [ADDR_WIDTH-1:0]   s_araddr,
    input  wire [3:0]              s_arlen,
    input  wire [1:0]              s_arburst,
    input  wire [2:0]              s_arprot,
    input  wire                    s_arvalid,
    output wire                    s_arready,

    // Read Data Channel (Standard + Custom RLAST)
    output wire [DATA_WIDTH-1:0]   s_rdata,
    output wire [1:0]              s_rresp,
    output wire                    s_rlast,
    output wire                    s_rvalid,
    input  wire                    s_rready,

    // Low-Power Management
    input  wire                    low_power_enable,
    output wire                    low_power_idle
);
    localparam integer BANK_W = (NUM_BANKS  > 1) ? $clog2(NUM_BANKS)  : 1;
    localparam integer WORD_W = (BANK_WORDS > 1) ? $clog2(BANK_WORDS) : 1;

    // Channel holding wires
    wire                  aw_pending, w_pending, ar_pending;
    wire [ADDR_WIDTH-1:0] awaddr_q, araddr_q;
    wire [3:0]            awlen_q, arlen_q;
    wire [1:0]            awburst_q, arburst_q;
    wire [2:0]            awprot_q, arprot_q;
    wire [DATA_WIDTH-1:0] wdata_q;
    wire [DATA_WIDTH/8-1:0] wstrb_q;
    wire                  wlast_q;
    wire                  aw_consume, w_consume, ar_consume, w_accept_en;

    // Burst controller wires
    wire                  wr_burst_start, wr_burst_beat_done, wr_burst_abort, wr_burst_active;
    wire [ADDR_WIDTH-1:0] wr_beat_addr;
    wire                  wr_addr_overflow, wr_last, wr_burst_type_err, wr_cross_bank_err;
    wire [3:0]            wr_beat_index;

    wire                  rd_burst_start, rd_burst_beat_done, rd_burst_active;
    wire [ADDR_WIDTH-1:0] rd_beat_addr;
    wire                  rd_addr_overflow, rd_last, rd_burst_type_err, rd_cross_bank_err;
    wire [3:0]            rd_beat_index;

    // Address decode & protection wires
    wire              wr_in_range, wr_aligned, wr_prot_ok, wr_decode_err, wr_addr_valid;
    wire [BANK_W-1:0] wr_bank;
    wire [WORD_W-1:0] wr_word_idx;

    wire              rd_in_range, rd_aligned, rd_prot_ok, rd_decode_err, rd_addr_valid;
    wire [BANK_W-1:0] rd_bank;
    wire [WORD_W-1:0] rd_word_idx;

    // Response & datapath wires
    wire [1:0]              wr_beat_resp, rd_beat_resp, b_resp_out;
    wire                    wr_mem_en, rd_mem_en, make_b, make_r;
    wire [DATA_WIDTH-1:0]   wdata_path, mem_rdata, rdata_path;
    wire [DATA_WIDTH/8-1:0] wstrb_path;
    wire                    fsm_active, activity, clock_enable;

    axi_aw_channel #(.ADDR_WIDTH(ADDR_WIDTH)) u_aw_ch (
        .clk        (clk),
        .resetn     (resetn),
        .s_awaddr   (s_awaddr),
        .s_awlen    (s_awlen),
        .s_awburst  (s_awburst),
        .s_awprot   (s_awprot),
        .s_awvalid  (s_awvalid),
        .s_awready  (s_awready),
        .aw_pending (aw_pending),
        .awaddr_q   (awaddr_q),
        .awlen_q    (awlen_q),
        .awburst_q  (awburst_q),
        .awprot_q   (awprot_q),
        .aw_consume (aw_consume)
    );

    axi_w_channel #(.DATA_WIDTH(DATA_WIDTH)) u_w_ch (
        .clk       (clk),
        .resetn    (resetn),
        .s_wdata   (s_wdata),
        .s_wstrb   (s_wstrb),
        .s_wlast   (s_wlast),
        .s_wvalid  (s_wvalid),
        .s_wready  (s_wready),
        .accept_en (w_accept_en),
        .w_pending (w_pending),
        .wdata_q   (wdata_q),
        .wstrb_q   (wstrb_q),
        .wlast_q   (wlast_q),
        .w_consume (w_consume)
    );

    axi_b_channel u_b_ch (
        .clk           (clk),
        .resetn        (resetn),
        .make_response (make_b),
        .response_in   (b_resp_out),
        .s_bresp       (s_bresp),
        .s_bvalid      (s_bvalid),
        .s_bready      (s_bready)
    );

    axi_ar_channel #(.ADDR_WIDTH(ADDR_WIDTH)) u_ar_ch (
        .clk        (clk),
        .resetn     (resetn),
        .s_araddr   (s_araddr),
        .s_arlen    (s_arlen),
        .s_arburst  (s_arburst),
        .s_arprot   (s_arprot),
        .s_arvalid  (s_arvalid),
        .s_arready  (s_arready),
        .ar_pending (ar_pending),
        .araddr_q   (araddr_q),
        .arlen_q    (arlen_q),
        .arburst_q  (arburst_q),
        .arprot_q   (arprot_q),
        .ar_consume (ar_consume)
    );

    axi_r_channel #(.DATA_WIDTH(DATA_WIDTH)) u_r_ch (
        .clk           (clk),
        .resetn        (resetn),
        .make_response (make_r),
        .data_in       (rdata_path),
        .response_in   (rd_beat_resp),
        .last_in       (rd_last),
        .s_rdata       (s_rdata),
        .s_rresp       (s_rresp),
        .s_rlast       (s_rlast),
        .s_rvalid      (s_rvalid),
        .s_rready      (s_rready)
    );

    burst_controller #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .NUM_BANKS  (NUM_BANKS),
        .BANK_WORDS (BANK_WORDS),
        .BANK_W     (BANK_W)
    ) u_wr_burst (
        .clk            (clk),
        .resetn         (resetn),
        .start          (wr_burst_start),
        .abort          (wr_burst_abort),
        .start_addr     (awaddr_q),
        .burst_len      (awlen_q),
        .burst_type     (awburst_q),
        .beat_done      (wr_burst_beat_done),
        .active         (wr_burst_active),
        .beat_addr      (wr_beat_addr),
        .addr_overflow  (wr_addr_overflow),
        .beat_index     (wr_beat_index),
        .last           (wr_last),
        .burst_type_err (wr_burst_type_err),
        .cross_bank_err (wr_cross_bank_err)
    );

    burst_controller #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .NUM_BANKS  (NUM_BANKS),
        .BANK_WORDS (BANK_WORDS),
        .BANK_W     (BANK_W)
    ) u_rd_burst (
        .clk            (clk),
        .resetn         (resetn),
        .start          (rd_burst_start),
        .abort          (1'b0),
        .start_addr     (araddr_q),
        .burst_len      (arlen_q),
        .burst_type     (arburst_q),
        .beat_done      (rd_burst_beat_done),
        .active         (rd_burst_active),
        .beat_addr      (rd_beat_addr),
        .addr_overflow  (rd_addr_overflow),
        .beat_index     (rd_beat_index),
        .last           (rd_last),
        .burst_type_err (rd_burst_type_err),
        .cross_bank_err (rd_cross_bank_err)
    );

    address_decoder #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .NUM_BANKS      (NUM_BANKS),
        .BANK_WORDS     (BANK_WORDS),
        .PROT_BANK_MASK (PROT_BANK_MASK),
        .BANK_W         (BANK_W),
        .WORD_W         (WORD_W)
    ) u_wr_dec (
        .addr          (wr_beat_addr),
        .addr_overflow (wr_addr_overflow),
        .prot          (awprot_q),
        .in_range      (wr_in_range),
        .aligned       (wr_aligned),
        .prot_ok       (wr_prot_ok),
        .decode_err    (wr_decode_err),
        .addr_valid    (wr_addr_valid),
        .bank_sel      (wr_bank),
        .word_index    (wr_word_idx)
    );

    address_decoder #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .NUM_BANKS      (NUM_BANKS),
        .BANK_WORDS     (BANK_WORDS),
        .PROT_BANK_MASK (PROT_BANK_MASK),
        .BANK_W         (BANK_W),
        .WORD_W         (WORD_W)
    ) u_rd_dec (
        .addr          (rd_beat_addr),
        .addr_overflow (rd_addr_overflow),
        .prot          (arprot_q),
        .in_range      (rd_in_range),
        .aligned       (rd_aligned),
        .prot_ok       (rd_prot_ok),
        .decode_err    (rd_decode_err),
        .addr_valid    (rd_addr_valid),
        .bank_sel      (rd_bank),
        .word_index    (rd_word_idx)
    );

    response_generator u_wr_resp (
        .decode_err (wr_decode_err),
        .align_err  (!wr_aligned),
        .prot_err   (!wr_prot_ok),
        .burst_err  (wr_burst_type_err || wr_cross_bank_err),
        .response   (wr_beat_resp)
    );

    response_generator u_rd_resp (
        .decode_err (rd_decode_err),
        .align_err  (!rd_aligned),
        .prot_err   (!rd_prot_ok),
        .burst_err  (rd_burst_type_err || rd_cross_bank_err),
        .response   (rd_beat_resp)
    );

    write_data_path #(.DATA_WIDTH(DATA_WIDTH)) u_wpath (
        .wdata       (wdata_q),
        .wstrb       (wstrb_q),
        .write_allow (wr_mem_en),
        .data_out    (wdata_path),
        .strb_out    (wstrb_path)
    );

    read_data_path #(.DATA_WIDTH(DATA_WIDTH)) u_rpath (
        .mem_data   (mem_rdata),
        .read_allow (rd_mem_en),
        .data_out   (rdata_path)
    );

    axi_slave_fsm #(
        .BANK_W (BANK_W),
        .WORD_W (WORD_W)
    ) u_fsm (
        .clk                (clk),
        .resetn             (resetn),
        .aw_pending         (aw_pending),
        .w_pending          (w_pending),
        .wlast_q            (wlast_q),
        .wr_last            (wr_last),
        .wr_beat_resp       (wr_beat_resp),
        .wr_burst_type_err  (wr_burst_type_err),
        .wr_cross_bank_err  (wr_cross_bank_err),
        .s_bvalid           (s_bvalid),
        .s_bready           (s_bready),
        .wr_bank            (wr_bank),
        .wr_word_idx        (wr_word_idx),
        .wr_burst_start     (wr_burst_start),
        .wr_burst_beat_done (wr_burst_beat_done),
        .wr_burst_abort     (wr_burst_abort),
        .w_accept_en        (w_accept_en),
        .w_consume          (w_consume),
        .aw_consume         (aw_consume),
        .wr_mem_en          (wr_mem_en),
        .make_b             (make_b),
        .b_resp_out         (b_resp_out),
        .ar_pending         (ar_pending),
        .rd_last            (rd_last),
        .rd_addr_valid      (rd_addr_valid),
        .rd_burst_type_err  (rd_burst_type_err),
        .rd_cross_bank_err  (rd_cross_bank_err),
        .s_rvalid           (s_rvalid),
        .s_rready           (s_rready),
        .rd_bank            (rd_bank),
        .rd_word_idx        (rd_word_idx),
        .rd_burst_start     (rd_burst_start),
        .rd_burst_beat_done (rd_burst_beat_done),
        .ar_consume         (ar_consume),
        .rd_mem_en          (rd_mem_en),
        .make_r             (make_r),
        .fsm_active         (fsm_active)
    );

    reg_mem_bank #(
        .DATA_WIDTH (DATA_WIDTH),
        .NUM_BANKS  (NUM_BANKS),
        .BANK_WORDS (BANK_WORDS),
        .BANK_W     (BANK_W),
        .WORD_W     (WORD_W)
    ) u_mem_bank (
        .clk          (clk),
        .resetn       (resetn),
        .clock_enable (clock_enable),
        .wr_en        (wr_mem_en),
        .wr_bank      (wr_bank),
        .wr_index     (wr_word_idx),
        .wr_data      (wdata_path),
        .wr_strb      (wstrb_path),
        .rd_en        (rd_mem_en),
        .rd_bank      (rd_bank),
        .rd_index     (rd_word_idx),
        .rd_data      (mem_rdata)
    );

    assign activity = s_awvalid || s_wvalid || s_arvalid ||
                      aw_pending || w_pending || ar_pending ||
                      s_bvalid || s_rvalid ||
                      wr_burst_active || rd_burst_active || fsm_active;

    low_power_controller #(.COUNTER_WIDTH(8)) u_lp_ctrl (
        .clk            (clk),
        .resetn         (resetn),
        .activity       (activity),
        .enable         (low_power_enable),
        .idle_threshold (IDLE_THRESHOLD[7:0]),
        .idle           (low_power_idle),
        .clock_enable   (clock_enable)
    );
endmodule
