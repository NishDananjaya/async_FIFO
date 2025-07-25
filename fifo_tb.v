`timescale 1ns/1ps

module fifo_tb();
    // Inputs
    reg wr_clk;
    reg rd_clk;
    reg rst_n;
    reg wr_en;
    reg [7:0] wr_data;
    reg rd_en;
    
    // Outputs
    wire [7:0] rd_data;
    wire full;
    wire empty;
    
    // Instantiate the FIFO
    async_fifo uut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .full(full),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty)
    );
    
    // Clock generation
    initial begin
        wr_clk = 0;
        forever #10 wr_clk = ~wr_clk; // 50MHz write clock
    end
    
    initial begin
        rd_clk = 0;
        forever #25 rd_clk = ~rd_clk; // 20MHz read clock
    end
    
    // Reset generation
    initial begin
        rst_n = 0;
        #50 rst_n = 1; // Release reset after 50ns
    end
    
    // Helper signals for debug
    wire [4:0] wr_ptr_bin = uut.wr_ptr_bin;
    wire [4:0] rd_ptr_bin = uut.rd_ptr_bin;
    wire [4:0] wr_ptr_gray = uut.wr_ptr_gray;
    wire [4:0] rd_ptr_gray = uut.rd_ptr_gray;
    wire [4:0] wr_ptr_gray_sync1 = uut.wr_ptr_gray_sync1;
    wire [4:0] wr_ptr_gray_sync2 = uut.wr_ptr_gray_sync2;
    wire [4:0] rd_ptr_gray_sync1 = uut.rd_ptr_gray_sync1;
    wire [4:0] rd_ptr_gray_sync2 = uut.rd_ptr_gray_sync2;

    // Main test sequence
    integer i;
    initial begin
        // Initialize inputs
        wr_en = 0;
        rd_en = 0;
        wr_data = 0;
        
        // Wait for reset to complete
        @(posedge rst_n);
        #10;
        
        // Phase 1: Write 8 values
        $display("\n=== PHASE 1: Writing 8 values ===");
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge wr_clk);
            wr_en = 1;
            wr_data = $random;
            $display("[%0t] WR: Data=%h, wr_ptr=%0d (gray=%b)", 
                    $time, wr_data, wr_ptr_bin, wr_ptr_gray);
            
            // Random delay between writes (0-3 cycles)
            if (i < 7) begin
                wr_en = 0;
                repeat($urandom_range(0,3)) @(posedge wr_clk);
            end
        end
        @(posedge wr_clk);
        wr_en = 0;
        
        // Wait 5 write cycles before reading
        $display("\n=== Waiting 5 write cycles ===");
        repeat(5) @(posedge wr_clk);
        
        // Phase 2: Interleaved read/write
        $display("\n=== PHASE 2: Interleaved operations ===");
        fork
            // Writer thread
            begin
                for (i = 8; i < 16; i = i + 1) begin
                    // Random delay before next write
                    repeat($urandom_range(1,5)) @(posedge wr_clk);
                    
                    if (!full) begin
                        wr_en = 1;
                        wr_data = $random;
                        $display("[%0t] WR: Data=%h, wr_ptr=%0d (gray=%b), sync_rd_ptr=%0d", 
                                $time, wr_data, wr_ptr_bin, wr_ptr_gray, rd_ptr_gray_sync2);
                        @(posedge wr_clk);
                        wr_en = 0;
                    end
                end
            end
            
            // Reader thread
            begin
                for (i = 0; i < 12; i = i + 1) begin
                    // Random delay before next read
                    repeat($urandom_range(1,5)) @(posedge rd_clk);
                    
                    if (!empty) begin
                        rd_en = 1;
                        @(posedge rd_clk);
                        #1; // Small delay for data to appear
                        $display("[%0t] RD: Data=%h, rd_ptr=%0d (gray=%b), sync_wr_ptr=%0d", 
                                $time, rd_data, rd_ptr_bin, rd_ptr_gray, wr_ptr_gray_sync2);
                        rd_en = 0;
                    end
                end
            end
        join
        
        // Final status
        $display("\n=== FINAL STATUS ===");
        $display("Write pointer: %0d (gray: %b)", wr_ptr_bin, wr_ptr_gray);
        $display("Read pointer: %0d (gray: %b)", rd_ptr_bin, rd_ptr_gray);
        $display("FIFO state: %s", empty ? "EMPTY" : full ? "FULL" : "PARTIAL");
        
        #100;
        $display("\nTestbench completed");
        $finish;
    end
    
    // Monitor pointers on each clock edge
    always @(posedge wr_clk) begin
        if (rst_n)
            $display("[%0t] WR_CLK: wr_ptr=%0d (gray=%b), rd_ptr_sync=%0d", 
                    $time, wr_ptr_bin, wr_ptr_gray, rd_ptr_gray_sync2);
    end
    
    always @(posedge rd_clk) begin
        if (rst_n)
            $display("[%0t] RD_CLK: rd_ptr=%0d (gray=%b), wr_ptr_sync=%0d", 
                    $time, rd_ptr_bin, rd_ptr_gray, wr_ptr_gray_sync2);
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("fifo_waveforms.vcd");
        $dumpvars(0, fifo_tb);
    end
endmodule