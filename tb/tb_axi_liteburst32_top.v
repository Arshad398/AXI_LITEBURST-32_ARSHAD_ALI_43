`timescale 1ns/1ps
module tb_axi_liteburst32_top;
    localparam integer ADDR_WIDTH = 8;
    localparam integer DATA_WIDTH = 32;
    localparam integer NUM_BANKS  = 2;
    localparam integer BANK_WORDS = 16;
    localparam integer IDLE_THRESH = 8;

    reg         clk = 0; always #5 clk = ~clk;
    reg         resetn = 0;

    reg  [7:0]  s_awaddr = 0;
    reg  [3:0]  s_awlen = 0;
    reg  [1:0]  s_awburst = 2'b01;
    reg  [2:0]  s_awprot = 3'b000;
    reg         s_awvalid = 0;
    wire        s_awready;

    reg  [31:0] s_wdata = 0;
    reg  [3:0]  s_wstrb = 4'hF;
    reg         s_wlast = 0;
    reg         s_wvalid = 0;
    wire        s_wready;

    wire [1:0]  s_bresp;
    wire        s_bvalid;
    reg         s_bready = 0;

    reg  [7:0]  s_araddr = 0;
    reg  [3:0]  s_arlen = 0;
    reg  [1:0]  s_arburst = 2'b01;
    reg  [2:0]  s_arprot = 3'b000;
    reg         s_arvalid = 0;
    wire        s_arready;

    wire [31:0] s_rdata;
    wire [1:0]  s_rresp;
    wire        s_rlast;
    wire        s_rvalid;
    reg         s_rready = 0;

    reg         low_power_enable = 1;
    wire        low_power_idle;

    axi_liteburst32_top #(
        .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
        .NUM_BANKS(NUM_BANKS), .BANK_WORDS(BANK_WORDS),
        .PROT_BANK_MASK(2'b10), .IDLE_THRESHOLD(IDLE_THRESH)
    ) dut (
        .clk(clk), .resetn(resetn),
        .s_awaddr(s_awaddr), .s_awlen(s_awlen), .s_awburst(s_awburst), .s_awprot(s_awprot),
        .s_awvalid(s_awvalid), .s_awready(s_awready),
        .s_wdata(s_wdata), .s_wstrb(s_wstrb), .s_wlast(s_wlast), .s_wvalid(s_wvalid), .s_wready(s_wready),
        .s_bresp(s_bresp), .s_bvalid(s_bvalid), .s_bready(s_bready),
        .s_araddr(s_araddr), .s_arlen(s_arlen), .s_arburst(s_arburst), .s_arprot(s_arprot),
        .s_arvalid(s_arvalid), .s_arready(s_arready),
        .s_rdata(s_rdata), .s_rresp(s_rresp), .s_rlast(s_rlast), .s_rvalid(s_rvalid), .s_rready(s_rready),
        .low_power_enable(low_power_enable), .low_power_idle(low_power_idle)
    );

    // Golden reference memory (32 words = 2 banks x 16 words)
    reg [31:0] ref_mem [0:31];
    reg [31:0] wr_buf  [0:15];
    reg [31:0] rd_buf  [0:15];
    integer    errors = 0;
    integer    checks = 0;
    integer    cov_hits [1:27];
    integer    i, j, seed;

    // Protocol stability assertions under backpressure
    reg        prev_bvalid = 0;
    reg [1:0]  prev_bresp  = 0;
    reg        prev_rvalid = 0;
    reg [31:0] prev_rdata  = 0;
    reg [1:0]  prev_rresp  = 0;
    reg        prev_rlast  = 0;

    always @(posedge clk) begin
        if (!resetn) begin
            prev_bvalid <= 0;
            prev_rvalid <= 0;
        end else begin
            if (prev_bvalid && !s_bready) begin
                if (!s_bvalid || s_bresp !== prev_bresp) begin
                    $display("ASSERT FAIL @%0t: B channel unstable during BREADY=0", $time);
                    errors = errors + 1;
                end
            end
            if (prev_rvalid && !s_rready) begin
                if (!s_rvalid || s_rdata !== prev_rdata || s_rresp !== prev_rresp || s_rlast !== prev_rlast) begin
                    $display("ASSERT FAIL @%0t: R channel unstable during RREADY=0", $time);
                    errors = errors + 1;
                end
            end
            prev_bvalid <= s_bvalid && !s_bready;
            prev_bresp  <= s_bresp;
            prev_rvalid <= s_rvalid && !s_rready;
            prev_rdata  <= s_rdata;
            prev_rresp  <= s_rresp;
            prev_rlast  <= s_rlast;
        end
    end

    task clear_ref_mem;
        integer k;
        begin
            for (k = 0; k < 32; k = k + 1) ref_mem[k] = 32'h0;
        end
    endtask

    task apply_reset;
        begin
            @(negedge clk);
            resetn    = 0;
            s_awvalid = 0; s_wvalid = 0; s_wlast = 0; s_bready = 0;
            s_arvalid = 0; s_rready = 0;
            repeat(3) @(posedge clk);
            @(negedge clk);
            resetn = 1;
            clear_ref_mem;
            @(posedge clk);
        end
    endtask

    task update_ref_word(input [7:0] baddr, input [31:0] data, input [3:0] strb, input [2:0] prot);
        integer wi, b;
        begin
            if (baddr[1:0] == 2'b00 && baddr < 8'h80) begin
                if (baddr < 8'h40 || prot[0] == 1'b1) begin
                    wi = baddr[6:2];
                    for (b = 0; b < 4; b = b + 1)
                        if (strb[b]) ref_mem[wi][8*b +: 8] = data[8*b +: 8];
                end
            end
        end
    endtask

    task axi_write_burst(
        input [7:0]  addr,
        input [3:0]  len,
        input [1:0]  burst,
        input [2:0]  prot,
        input [3:0]  strb,
        input [1:0]  exp_resp,
        input integer b_bp_cycles,
        input integer aw_w_mode // 0=simultaneous, 1=AW-first, 2=W-first
    );
        integer k;
        reg [7:0] cur_addr;
        begin
            cur_addr = addr;
            if (aw_w_mode == 1) begin
                // AW first
                @(negedge clk);
                s_awaddr = addr; s_awlen = len; s_awburst = burst; s_awprot = prot; s_awvalid = 1;
                @(posedge clk); while (!s_awready) @(posedge clk);
                @(negedge clk); s_awvalid = 0;
                repeat(2) @(posedge clk);
            end else if (aw_w_mode == 2) begin
                // W first (beat 0 arrives before AW)
                @(negedge clk);
                s_wdata = wr_buf[0]; s_wstrb = strb; s_wlast = (len == 0); s_wvalid = 1;
                @(posedge clk); while (!s_wready) @(posedge clk);
                @(negedge clk); s_wvalid = 0; s_wlast = 0;
                repeat(2) @(posedge clk);
                s_awaddr = addr; s_awlen = len; s_awburst = burst; s_awprot = prot; s_awvalid = 1;
                @(posedge clk); while (!s_awready) @(posedge clk);
                @(negedge clk); s_awvalid = 0;
            end else begin
                // Simultaneous AW
                @(negedge clk);
                s_awaddr = addr; s_awlen = len; s_awburst = burst; s_awprot = prot; s_awvalid = 1;
                @(posedge clk); while (!s_awready) @(posedge clk);
                @(negedge clk); s_awvalid = 0;
            end

            for (k = (aw_w_mode == 2 ? 1 : 0); k <= len; k = k + 1) begin
                @(negedge clk);
                s_wdata  = wr_buf[k];
                s_wstrb  = strb;
                s_wlast  = (k == len);
                s_wvalid = 1;
                @(posedge clk);
                while (!s_wready) @(posedge clk);
            end
            @(negedge clk);
            s_wvalid = 0; s_wlast = 0;

            // Update golden ref if expected OKAY (or valid beats)
            if (exp_resp == 2'b00) begin
                for (k = 0; k <= len; k = k + 1) begin
                    update_ref_word(cur_addr, wr_buf[k], strb, prot);
                    if (burst == 2'b01) cur_addr = cur_addr + 8'd4;
                end
            end

            // Wait for BVALID + optional backpressure
            while (!s_bvalid) @(posedge clk);
            if (b_bp_cycles > 0) begin
                repeat(b_bp_cycles) @(posedge clk);
            end
            checks = checks + 1;
            if (s_bresp !== exp_resp) begin
                $display("FAIL write addr=%h len=%0d resp=%b exp=%b @%0t", addr, len, s_bresp, exp_resp, $time);
                errors = errors + 1;
            end
            @(negedge clk); s_bready = 1;
            @(posedge clk);
            @(negedge clk); s_bready = 0;
        end
    endtask

    task axi_read_burst_check(
        input [7:0]   addr,
        input [3:0]   len,
        input [1:0]   burst,
        input [2:0]   prot,
        input [1:0]   exp_resp,
        input integer r_bp_cycles,
        input integer check_ref
    );
        integer k;
        reg [7:0]  cur_addr;
        reg [31:0] exp_data;
        begin
            @(negedge clk);
            s_araddr = addr; s_arlen = len; s_arburst = burst; s_arprot = prot; s_arvalid = 1;
            @(posedge clk); while (!s_arready) @(posedge clk);
            @(negedge clk); s_arvalid = 0;

            cur_addr = addr;
            for (k = 0; k <= len; k = k + 1) begin
                while (!s_rvalid) @(posedge clk);
                if (r_bp_cycles > 0) begin
                    @(negedge clk); s_rready = 0;
                    repeat(r_bp_cycles) @(posedge clk);
                end
                checks = checks + 1;
                if (s_rlast !== (k == len)) begin
                    $display("FAIL RLAST beat=%0d/%0d got=%b @%0t", k, len, s_rlast, $time);
                    errors = errors + 1;
                end
                if (exp_resp != 2'bxx && s_rresp !== exp_resp) begin
                    $display("FAIL RRESP addr=%h beat=%0d got=%b exp=%b @%0t", cur_addr, k, s_rresp, exp_resp, $time);
                    errors = errors + 1;
                end
                if (check_ref) begin
                    exp_data = (exp_resp == 2'b00) ? ref_mem[cur_addr[6:2]] : 32'h0000_0000;
                    if (s_rdata !== exp_data) begin
                        $display("FAIL RDATA addr=%h beat=%0d got=%h exp=%h @%0t", cur_addr, k, s_rdata, exp_data, $time);
                        errors = errors + 1;
                    end
                end
                rd_buf[k] = s_rdata;
                @(negedge clk); s_rready = 1;
                @(posedge clk);
                @(negedge clk); s_rready = 0;
                if (burst == 2'b01) cur_addr = cur_addr + 8'd4;
            end
        end
    endtask

    initial begin
        $dumpfile("d:/hcl project axi liteburst/sim/tb_axi_liteburst32_top.vcd");
        $dumpvars(0, tb_axi_liteburst32_top);
        for (i = 1; i <= 27; i = i + 1) cov_hits[i] = 0;
        seed = 32'h20261125;

        // TC-01: Reset check
        apply_reset;
        checks = checks + 1;
        if (s_awready !== 1'b1 || s_wready !== 1'b1 || s_arready !== 1'b1 || s_bvalid !== 1'b0 || s_rvalid !== 1'b0) begin
            $display("FAIL TC-01 reset state"); errors = errors + 1;
        end
        cov_hits[1] = cov_hits[1] + 1;

        // TC-02 & TC-03: Single write & single read (1-beat burst = min length)
        wr_buf[0] = 32'h12345678;
        axi_write_burst(8'h00, 4'd0, 2'b01, 3'b000, 4'hF, 2'b00, 0, 0);
        axi_read_burst_check(8'h00, 4'd0, 2'b01, 3'b000, 2'b00, 0, 1);
        cov_hits[2] = cov_hits[2] + 1; cov_hits[3] = cov_hits[3] + 1; cov_hits[8] = cov_hits[8] + 1;

        // TC-04 & TC-05: Sequential single writes and reads
        for (i = 0; i < 4; i = i + 1) begin
            wr_buf[0] = 32'hA000_0000 + i;
            axi_write_burst(i * 4, 4'd0, 2'b01, 3'b000, 4'hF, 2'b00, 0, 0);
        end
        for (i = 0; i < 4; i = i + 1) begin
            axi_read_burst_check(i * 4, 4'd0, 2'b01, 3'b000, 2'b00, 0, 1);
        end
        cov_hits[4] = cov_hits[4] + 1; cov_hits[5] = cov_hits[5] + 1;

        // TC-06, TC-07, TC-09, TC-21: Max 16-beat write & read burst with +4 addr increment
        for (i = 0; i < 16; i = i + 1) wr_buf[i] = 32'hCAFE_0000 + i;
        axi_write_burst(8'h00, 4'd15, 2'b01, 3'b000, 4'hF, 2'b00, 0, 0);
        axi_read_burst_check(8'h00, 4'd15, 2'b01, 3'b000, 2'b00, 0, 1);
        cov_hits[6] = cov_hits[6] + 1; cov_hits[7] = cov_hits[7] + 1; cov_hits[9] = cov_hits[9] + 1; cov_hits[21] = cov_hits[21] + 1;

        // TC-10: WSTRB byte-lane masking
        wr_buf[0] = 32'h11223344; axi_write_burst(8'h04, 4'd0, 2'b01, 3'b000, 4'b0001, 2'b00, 0, 0);
        wr_buf[0] = 32'h55667788; axi_write_burst(8'h04, 4'd0, 2'b01, 3'b000, 4'b0010, 2'b00, 0, 0);
        wr_buf[0] = 32'h99AABBCC; axi_write_burst(8'h04, 4'd0, 2'b01, 3'b000, 4'b0100, 2'b00, 0, 0);
        wr_buf[0] = 32'hDDEEFF00; axi_write_burst(8'h04, 4'd0, 2'b01, 3'b000, 4'b1000, 2'b00, 0, 0);
        axi_read_burst_check(8'h04, 4'd0, 2'b01, 3'b000, 2'b00, 0, 1);
        cov_hits[10] = cov_hits[10] + 1;

        // TC-11, TC-13: Invalid unaligned address -> SLVERR
        wr_buf[0] = 32'hDEADBEEF;
        axi_write_burst(8'h01, 4'd0, 2'b01, 3'b000, 4'hF, 2'b10, 0, 0);
        axi_read_burst_check(8'h02, 4'd0, 2'b01, 3'b000, 2'b10, 0, 1);
        cov_hits[11] = cov_hits[11] + 1; cov_hits[13] = cov_hits[13] + 1;

        // TC-12: Unmapped address & overflow -> DECERR
        axi_write_burst(8'h80, 4'd0, 2'b01, 3'b000, 4'hF, 2'b11, 0, 0);
        axi_read_burst_check(8'h80, 4'd0, 2'b01, 3'b000, 2'b11, 0, 1);
        axi_read_burst_check(8'hFC, 4'd3, 2'b01, 3'b000, 2'b11, 0, 1); // overflow wrap-around guard
        cov_hits[12] = cov_hits[12] + 1;

        // TC-23: Memory-bank isolation + Protection (Bank 1 requires AxPROT[0]=1)
        wr_buf[0] = 32'hBEEF_1111;
        axi_write_burst(8'h40, 4'd0, 2'b01, 3'b000, 4'hF, 2'b10, 0, 0); // unprivileged write rejected
        axi_read_burst_check(8'h40, 4'd0, 2'b01, 3'b000, 2'b10, 0, 1); // unprivileged read rejected
        for (i = 0; i < 16; i = i + 1) wr_buf[i] = 32'hB1B1_0000 + i;
        axi_write_burst(8'h40, 4'd15, 2'b01, 3'b001, 4'hF, 2'b00, 0, 0); // privileged 16-beat write OK
        axi_read_burst_check(8'h40, 4'd15, 2'b01, 3'b001, 2'b00, 0, 1); // privileged 16-beat read OK
        axi_read_burst_check(8'h40, 4'd0, 2'b01, 3'b000, 2'b10, 0, 1);  // unprivileged read must return 0!
        cov_hits[23] = cov_hits[23] + 1;

        // TC-15: AW/W timing independence (AW-first and W-first)
        wr_buf[0] = 32'h1111_AAAA; axi_write_burst(8'h08, 4'd0, 2'b01, 3'b000, 4'hF, 2'b00, 0, 1);
        axi_read_burst_check(8'h08, 4'd0, 2'b01, 3'b000, 2'b00, 0, 1);
        wr_buf[0] = 32'h2222_BBBB; axi_write_burst(8'h0C, 4'd0, 2'b01, 3'b000, 4'hF, 2'b00, 0, 2);
        axi_read_burst_check(8'h0C, 4'd0, 2'b01, 3'b000, 2'b00, 0, 1);
        cov_hits[15] = cov_hits[15] + 1;

        // TC-16 & TC-17: B and R backpressure
        wr_buf[0] = 32'h3333_CCCC;
        axi_write_burst(8'h10, 4'd0, 2'b01, 3'b000, 4'hF, 2'b00, 4, 0);
        axi_read_burst_check(8'h00, 4'd3, 2'b01, 3'b000, 2'b00, 3, 1);
        cov_hits[16] = cov_hits[16] + 1; cov_hits[17] = cov_hits[17] + 1;

        // TC-14: Read/Write Concurrency (simultaneous 8-beat write to Bank 0 and 8-beat read from Bank 1)
        for (i = 0; i < 8; i = i + 1) wr_buf[i] = 32'hC0C0_0000 + i;
        fork
            axi_write_burst(8'h00, 4'd7, 2'b01, 3'b000, 4'hF, 2'b00, 0, 0);
            axi_read_burst_check(8'h40, 4'd7, 2'b01, 3'b001, 2'b00, 0, 1);
        join
        axi_read_burst_check(8'h00, 4'd7, 2'b01, 3'b000, 2'b00, 0, 1);
        // Same-word collision test: simultaneous write and read to 0x00 (write-first priority)
        wr_buf[0] = 32'hF00D_CAFE;
        fork
            axi_write_burst(8'h00, 4'd0, 2'b01, 3'b000, 4'hF, 2'b00, 0, 0);
            axi_read_burst_check(8'h00, 4'd0, 2'b01, 3'b000, 2'b00, 0, 0);
        join
        axi_read_burst_check(8'h00, 4'd0, 2'b01, 3'b000, 2'b00, 0, 1);
        cov_hits[14] = cov_hits[14] + 1;

        // FIXED burst (2'b00) & unsupported burst type (2'b10)
        wr_buf[0] = 32'h1010_0001; wr_buf[1] = 32'h1010_0002;
        axi_write_burst(8'h14, 4'd1, 2'b00, 3'b000, 4'hF, 2'b00, 0, 0);
        axi_read_burst_check(8'h14, 4'd1, 2'b00, 3'b000, 2'b00, 0, 1);
        axi_write_burst(8'h14, 4'd0, 2'b10, 3'b000, 4'hF, 2'b10, 0, 0); // WRAP unsupported -> SLVERR
        axi_read_burst_check(8'h14, 4'd0, 2'b10, 3'b000, 2'b10, 0, 1);  // WRAP unsupported -> SLVERR

        // TC-18: Handshake delays & Early/Missing WLAST error
        @(negedge clk);
        s_awaddr = 8'h10; s_awlen = 4'd2; s_awburst = 2'b01; s_awprot = 3'b000; s_awvalid = 1;
        @(posedge clk); while (!s_awready) @(posedge clk);
        @(negedge clk); s_awvalid = 0;
        repeat(2) @(posedge clk);
        // Beat 0 with early WLAST=1 -> should abort cleanly with SLVERR!
        s_wdata = 32'hDEAD0001; s_wstrb = 4'hF; s_wlast = 1; s_wvalid = 1;
        @(posedge clk); while (!s_wready) @(posedge clk);
        @(negedge clk); s_wvalid = 0; s_wlast = 0;
        while (!s_bvalid) @(posedge clk);
        checks = checks + 1;
        if (s_bresp !== 2'b10) begin $display("FAIL early WLAST expected SLVERR got %b", s_bresp); errors = errors + 1; end
        @(negedge clk); s_bready = 1; @(posedge clk); @(negedge clk); s_bready = 0;
        // Missing WLAST on 2-beat write -> SLVERR
        @(negedge clk);
        s_awaddr = 8'h18; s_awlen = 4'd1; s_awburst = 2'b01; s_awprot = 3'b000; s_awvalid = 1;
        @(posedge clk); while (!s_awready) @(posedge clk);
        @(negedge clk); s_awvalid = 0;
        s_wdata = 32'hDEAD0002; s_wstrb = 4'hF; s_wlast = 0; s_wvalid = 1;
        @(posedge clk); while (!s_wready) @(posedge clk);
        @(posedge clk); while (!s_wready) @(posedge clk); // beat 1 still has wlast=0!
        @(negedge clk); s_wvalid = 0;
        while (!s_bvalid) @(posedge clk);
        checks = checks + 1;
        if (s_bresp !== 2'b10) begin $display("FAIL missing WLAST expected SLVERR got %b", s_bresp); errors = errors + 1; end
        @(negedge clk); s_bready = 1; @(posedge clk); @(negedge clk); s_bready = 0;
        cov_hits[18] = cov_hits[18] + 1;

        // TC-22: Burst boundary conditions (Bank 0 -> Bank 1 crossing 0x38 len=3 -> SLVERR)
        for (i = 0; i < 4; i = i + 1) wr_buf[i] = 32'h5555_0000 + i;
        axi_write_burst(8'h38, 4'd3, 2'b01, 3'b001, 4'hF, 2'b10, 0, 0);
        cov_hits[22] = cov_hits[22] + 1;

        // TC-19 & TC-20: Reset during active transaction and active burst
        @(negedge clk);
        s_awaddr = 8'h00; s_awlen = 4'd15; s_awburst = 2'b01; s_awprot = 3'b000; s_awvalid = 1;
        @(posedge clk); @(negedge clk); s_awvalid = 0;
        s_wdata = 32'h99999999; s_wstrb = 4'hF; s_wlast = 0; s_wvalid = 1;
        repeat(3) @(posedge clk);
        apply_reset; // Reset mid-burst!
        wr_buf[0] = 32'h77778888;
        axi_write_burst(8'h00, 4'd0, 2'b01, 3'b000, 4'hF, 2'b00, 0, 0);
        axi_read_burst_check(8'h00, 4'd0, 2'b01, 3'b000, 2'b00, 0, 1);
        cov_hits[19] = cov_hits[19] + 1; cov_hits[20] = cov_hits[20] + 1;

        // TC-24 & TC-25: Low-power idle entry and wake-up
        repeat(IDLE_THRESH + 4) @(posedge clk); #1;
        checks = checks + 1;
        if (low_power_idle !== 1'b1) begin $display("FAIL TC-24 low_power_idle did not assert"); errors = errors + 1; end
        cov_hits[24] = cov_hits[24] + 1;
        axi_read_burst_check(8'h00, 4'd0, 2'b01, 3'b000, 2'b00, 0, 1);
        checks = checks + 1;
        if (low_power_idle !== 1'b0) begin $display("FAIL TC-25 low_power_idle did not clear on wake-up"); errors = errors + 1; end
        cov_hits[25] = cov_hits[25] + 1;

        // TC-27: Repeated randomized transactions (20 bursts)
        for (j = 0; j < 20; j = j + 1) begin
            begin : rand_blk
                reg [3:0] rlen;
                reg [7:0] raddr;
                reg [3:0] rstrb;
                rlen  = ($random(seed) & 4'h7); // 1..8 beats
                raddr = ((($random(seed) & 32'h7)) * 4); // 0x00..0x1C so +8 beats stays in Bank 0
                rstrb = ($random(seed) & 4'hF);
                if (rstrb == 0) rstrb = 4'hF;
                for (i = 0; i <= rlen; i = i + 1) wr_buf[i] = $random(seed);
                axi_write_burst(raddr, rlen, 2'b01, 3'b000, rstrb, 2'b00, 0, j % 3);
                axi_read_burst_check(raddr, rlen, 2'b01, 3'b000, 2'b00, 0, 1);
            end
        end
        cov_hits[27] = cov_hits[27] + 1;

        $display("COVERAGE SUMMARY: TC-01..25,27 executed (TC-26 in tb_axi_liteburst32_param)");
        $display("tb_axi_liteburst32_top: %s (checks=%0d errors=%0d)", errors == 0 ? "PASS" : "FAIL", checks, errors);
        if (errors != 0) $fatal(1);
        $finish;
    end
endmodule
