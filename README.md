📦 Asynchronous FIFO (16x8)
===========================

This repository contains a **Verilog implementation of an Asynchronous FIFO** with separate read and write clock domains. The design uses **Gray-coded pointers** and **synchronizers** to safely transfer data between clock domains.

* * * * *

🔹 Features
-----------

-   **Depth:** 16 entries (4-bit addressing)

-   **Width:** 8 bits per entry

-   **Dual clock domains:** independent `wr_clk` and `rd_clk`

-   **Safe clock domain crossing:** Gray code + 2-stage synchronizers

-   **FIFO status flags:**

    -   `full` → FIFO cannot accept new data

    -   `empty` → FIFO has no data to read

-   **Resettable:** Active-low reset (`rst_n`)

* * * * *

🔧 Module I/O
-------------

```verilog
module async_fifo (
    input  wire        wr_clk,    // Write clock
    input  wire        rd_clk,    // Read clock
    input  wire        rst_n,     // Active-low reset

    // Write interface
    input  wire        wr_en,     // Write enable
    input  wire [7:0]  wr_data,   // Write data
    output wire        full,      // FIFO full flag

    // Read interface
    input  wire        rd_en,     // Read enable
    output wire [7:0]  rd_data,   // Read data
    output wire        empty      // FIFO empty flag
);
```

* * * * *

📜 How It Works
---------------

1.  **FIFO Memory**:

    -   16 locations (`mem[0:15]`) each 8 bits wide.

2.  **Pointers**:

    -   Write pointer (`wr_ptr_bin`) and Read pointer (`rd_ptr_bin`).

    -   Converted to **Gray code** for safe synchronization across domains.

3.  **Synchronization**:

    -   `wr_ptr_gray` synchronized into read domain.

    -   `rd_ptr_gray` synchronized into write domain.

4.  **Status Flags**:

    -   **Empty:** occurs when `rd_ptr_gray == wr_ptr_gray_sync2`.

    -   **Full:** occurs when write pointer is one cycle behind read pointer with inverted MSBs.

5.  **Data Flow**:

    -   **Write:** Data stored on rising edge of `wr_clk` if `wr_en && !full`.

    -   **Read:** Data available at `rd_data` when `rd_en && !empty`.

* * * * *

🖼 RTL View
-----------

Below is the **RTL schematic view** of the FIFO:

* * * * *

🧪 Testbench Results
--------------------

Simulation results of the FIFO design:

* * * * *


🖼 Adding Images in README
--------------------------

You can include images in **three ways**:

### 1\. Local Image (recommended for repo screenshots)

`![Description](images/fifo_rtl.png)`

### 2\. Online Image (from a hosted URL)

`![Gray Code Example](https://jjmk.dk/MMMI/why/Number_Systems/Gray_code/Binary_to_Gray.jpg)`

### 3\. HTML for Resize/Alignment

![FIFO RTL View](https://github.com/user-attachments/assets/393443d6-3b26-4b09-8c31-ac6f418f883d /)


* * * * *

🚀 Usage
--------

### Simulation

1.  Compile and simulate with your preferred simulator:

    ```bash
    iverilog -o fifo_tb async_fifo.v async_fifo_tb.v
    vvp fifo_tb
    ```
1.  Optionally view waveforms:

    ```bash
    gtkwave dump.vcd`
    ```
* * * * *

🧩 Example Instantiation
------------------------

```verilog
async_fifo u_fifo (
    .wr_clk   (wr_clk),
    .rd_clk   (rd_clk),
    .rst_n    (rst_n),
    .wr_en    (wr_en),
    .wr_data  (wr_data),
    .full     (full),
    .rd_en    (rd_en),
    .rd_data  (rd_data),
    .empty    (empty)
);`
```
* * * * *

📘 References
-------------

-   Cummings, Clifford E. *Simulation and Synthesis Techniques for Asynchronous FIFO Design*

-   ASIC World -- FIFO Design

* * * * *

✍️ **Author**: Nishan Dananjaya