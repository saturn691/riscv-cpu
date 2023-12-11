`include "def.sv"

module data_mem #(
        parameter   DATA_WIDTH = 32, 
                    ADDR_WIDTH = 32,
                    MEM_WIDTH = 8
)(
        input  logic                    clk,
        input  logic [2:0]              AddrMode, // for byte addressing
        input  logic [ADDR_WIDTH-1:0]   A, // address
        input  logic [DATA_WIDTH-1:0]   WD, // write data
        input  logic                    WE, // write enable (memwrite from control_unit)
        input  logic                    miss,
        output logic                    cache_en,
        output logic [DATA_WIDTH-1:0]   RD // read data
);

    // Define the data array
    // Each bit is 1 byte (8 bits) wide, with 2^17 bytes memory locations
    logic [MEM_WIDTH-1:0] array [2**17-1:0];

    initial begin
        $display("Loading data into data memory...");
        $readmemh("../rtl/data.hex", array, 17'h10000, 17'h1FFFF);
    end

    always_ff @* begin
        case (AddrMode)  
            `DATA_ADDR_MODE_B:      RD = {{24{array[A][7]}}, array[A]};
            `DATA_ADDR_MODE_BU:     RD = {24'b0, array[A]};
            // `DATA_ADDR_MODE_H:      RD = {{12{array[A][15]}}, array[A+1], array[A]};
            // `DATA_ADDR_MODE_HU:     RD = {12'b0, array[A+1], array[A]};
            default:                RD = {array[A+3], array[A+2], array[A+1], array[A]};
        endcase
    end


    // Read and write operations
    always_ff @(posedge clk) begin
        if (WE && AddrMode == 3'b01x) begin // Write only least significant byte (8 bits)
            array[A] <= WD[7:0];
        end

        else if (WE) begin // Write whole word
            array[A] <= WD[7:0];
            array[A+1] <= WD[15:8];
            array[A+2] <= WD[23:16];
            array[A+3] <= WD[31:24];
        end
        
        cache_en <= miss;
    end

endmodule
