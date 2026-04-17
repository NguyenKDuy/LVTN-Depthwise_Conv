module weight_buffer #(
    parameter CLUSTER_SIZE  = 256,   // bit per cluster
    parameter NUM_CLUSTERS  = 16,
    parameter INPUT_WIDTH   = 1024,
    parameter CHUNK_WIDTH   = 64     // mỗi phần nhỏ (64 bit)
)(
    input  wire clk,
    input  wire rst_n,
    input  wire i_valid,
    input  wire [INPUT_WIDTH-1:0] i_data,
    input  wire i_done_stage, 
    output reg  [4096-1:0] cluster_flat,
    output reg  o_valid
);

    // ================= INTERNAL =================
    localparam NUM_CHUNKS = INPUT_WIDTH / CHUNK_WIDTH;   // 16
    localparam DEPTH_PER_CLUSTER = 4; // = 4

    reg [$clog2(DEPTH_PER_CLUSTER)-1:0] write_phase; // 0 → 3

    integer i;


    always @(posedge clk) begin
        if (!rst_n) begin
            // cluster_flat <= 0;
            write_phase  <= 0;
            o_valid      <= 0;
        end else begin
            if (i_done_stage) begin
                o_valid <= 0;
            end

            if (i_valid) begin
                // write từng chunk vào từng cluster
                for (i = 0; i < NUM_CHUNKS; i = i + 1) begin
                    cluster_flat[i*CLUSTER_SIZE + write_phase*CHUNK_WIDTH +: CHUNK_WIDTH] 
                        <= i_data[i*CHUNK_WIDTH +: CHUNK_WIDTH];
                end

                // update phase
                if (write_phase == DEPTH_PER_CLUSTER-1) begin
                    write_phase <= 0;
                    o_valid <= 1;  // load đủ 4 cycle → latch valid = 1
                                   // giữ = 1 cho đến lần load kế tiếp
                end else begin
                    write_phase <= write_phase + 1;
                end
            end
        end
    end

endmodule