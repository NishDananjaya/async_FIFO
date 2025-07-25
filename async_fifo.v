// EG/19/118

module async_fifo (
    input wire wr_clk ,           
    input wire rd_clk ,           
    input wire rst_n ,            
    input wire wr_en ,            
    input wire [7:0] wr_data ,   
    output wire full ,            
    input wire rd_en ,            
    output wire [7:0] rd_data ,   
    output wire empty             
);

// FIFO memory array: 16 locations, each 8 bits wide
reg [7:0] mem [0:15];

// Binary write pointer
reg [4:0] wr_ptr_bin; 
// Corresponding Gray-coded write pointer
wire [4:0] wr_ptr_gray;

// Write pointer update logic
always @(posedge wr_clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr_bin <= 0;                         // Reset write pointer
    end else if (wr_en && !full) begin
        wr_ptr_bin <= wr_ptr_bin + 1;           // Increment write pointer if not full
    end
end

// Binary to Gray code conversion for write pointer
assign wr_ptr_gray = (wr_ptr_bin >> 1) ^ wr_ptr_bin;

// Binary read pointer
reg [4:0] rd_ptr_bin;
// Corresponding Gray-coded read pointer
wire [4:0] rd_ptr_gray;

// Read pointer update logic
always @(posedge rd_clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_ptr_bin <= 0;                         // Reset read pointer
    end else if (rd_en && !empty) begin
        rd_ptr_bin <= rd_ptr_bin + 1;           // Increment read pointer if not empty
    end
end

// Binary to Gray code conversion for read pointer
assign rd_ptr_gray = (rd_ptr_bin >> 1) ^ rd_ptr_bin;

// Synchronize write pointer into read clock domain (2-stage synchronizer)
reg [4:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
always @(posedge rd_clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr_gray_sync1 <= 0;
        wr_ptr_gray_sync2 <= 0;
    end else begin
        wr_ptr_gray_sync1 <= wr_ptr_gray;
        wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
end

// Synchronize read pointer into write clock domain (2-stage synchronizer)
reg [4:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
always @(posedge wr_clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_ptr_gray_sync1 <= 0;
        rd_ptr_gray_sync2 <= 0;
    end else begin
        rd_ptr_gray_sync1 <= rd_ptr_gray;
        rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
end

// FIFO full condition: write pointer is one cycle behind synchronized read pointer (inverted MSBs)
assign full = (wr_ptr_gray == {~rd_ptr_gray_sync2[4:3], rd_ptr_gray_sync2[2:0]});

// FIFO empty condition: read pointer equals synchronized write pointer
assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);

// Write data into FIFO memory if enabled and not full
always @(posedge wr_clk) begin
    if (wr_en && !full) begin
        mem[wr_ptr_bin[3:0]] <= wr_data;         // Use only lower 4 bits for addressing 16 locations
    end
end

// Read data directly from FIFO memory based on read pointer
assign rd_data = mem[rd_ptr_bin[3:0]];

endmodule
