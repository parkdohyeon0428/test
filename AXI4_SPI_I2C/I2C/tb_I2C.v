`timescale 1ns / 1ps

module tb_I2C_Master;

    // Global control signals
    reg clk = 0;
    reg reset;
    always #5 clk = ~clk;  // 100MHz clock (10ns period)

    // I2C master interface
    reg [7:0] tx_data;
    wire tx_done;
    wire ready;
    reg start;
    reg stop;
    reg I2C_en;

    // Shared I2C bus
    wire SCL;
    wire SDA;

    // Output for verification
    wire [7:0] led;

    // SDA�� SCL ���ο� pullup ���� �� �߰�


    // ������ �ν��Ͻ�
    I2C_Master u_I2C_Master (
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_done(tx_done),
        .ready(ready),
        .start(start),
        .stop(stop),
        .I2C_en(I2C_en),
        .SCL(SCL),
        .SDA(SDA)
    );

    // �����̺� �ν��Ͻ�
    I2C_Slave u_I2C_Slave (
        .clk(clk),
        .reset(reset),
        .SCL(SCL),
        .SDA(SDA),
        .led(led)
    );

    // Test stimulus
    initial begin
        // �ʱ�ȭ
        reset = 1;
        start = 0;
        stop = 0;
        I2C_en = 0;
        tx_data = 8'h95;  // �����̺� �ּ� + W ��Ʈ
        #100;
        reset = 0;

        // START ���� �߻�
        #50;
        I2C_en = 1;
        start = 1;
        #10;
        start = 0;

        // ù ��° ����Ʈ ���� �Ϸ� ���
        wait (tx_done);
        #20;

        // �� ��° ����Ʈ ����
        tx_data = 8'h6F;  // ���� ������
        start = 1;
        #10;
        start = 0;

        wait (tx_done);
        stop = 1;
        #100;
        I2C_en = 0;

        // ��� ���
        $display("Slave LED Value: %h", led);
        #20000 $finish;
    end

endmodule