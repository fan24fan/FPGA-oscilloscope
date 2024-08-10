//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           touch_gt_cfg
// Last modified Date:  2018/08/16 10:18:45
// Last Version:        V1.0
// Descriptions:        gt9147的驱动
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2018/08/16 10:18:50
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module touch_gt_cfg #(parameter WIDTH = 4'd8)
(
    //system clock
    input                   clk       ,          // 时钟信号
    input                   rst_n     ,          // 复位信号

    //port interface
    output                  scl       ,          // 时钟线scl
    input                   sda_in    ,          // 数据线sda
    output                  sda_out   ,
    output                  sda_dir   ,

    //I2C interface
    input                   bit_ctrl  ,
    input                   i2c_exec  ,          // i2c触发控制
    input                   i2c_rh_wl ,          // i2c读写控制
    input    [15:0]         i2c_addr  ,          // i2c操作地址
    input    [ 7:0]         i2c_data_w,          // i2c写入的数据
    input    [WIDTH-1'b1:0] reg_num   ,
    input                   cfg_switch,
    output   [ 7:0]         i2c_data_r,          // i2c读出的数据
    output                  i2c_done  ,          // i2c操作结束标志
    output                  once_done ,          // 一次读写操作完成
    output                  clk_i2c   ,          // I2C操作时钟
    output                  ack       ,
    //user interface
    output                  cfg_done  ,          // 寄存器配置完成标志
    input    [15:0]         lcd_id   
);

//parameter define
//localparam    SLAVE_ADDR =  7'h5d       ; // 器件地址(SLAVE_ADDR)
//localparam    BIT_CTRL   =  1'b1        ; // 字地址位控制参数(16b/8b)
localparam    CLK_FREQ   = 27'd100_000_000; // i2c_dri模块的驱动时钟频率(CLK_FREQ)
localparam    I2C_FREQ   = 19'd400_000    ; // I2C的SCL时钟频率

//wire define
wire                  cfg_i2c_exec  ;       // i2c触发控制
wire                  cfg_i2c_rh_wl ;       // i2c读写控制
wire   [15:0]         cfg_i2c_addr  ;       // i2c操作地址
wire   [ 7:0]         cfg_i2c_data  ;       // i2c写入的数据
wire                  cfg_once_done ;       // i2c操作结束标志
wire   [WIDTH-1'b1:0] cfg_reg_num   ;       // i2c读出的数据
wire                  m_i2c_exec    ;
wire                  m_i2c_rh_wl   ;
wire   [15:0]         m_i2c_addr    ;
wire   [ 7:0]         m_i2c_data_w  ;
wire   [ 7:0]         m_i2c_data_r  ;
wire   [WIDTH-1'b1:0] m_reg_num     ;
wire                  m_once_done   ;
reg    [6:0]          slave_addr    ;
 
//*****************************************************
//**                    main code
//*****************************************************

always @(*) begin
    if(lcd_id[15:8] == 8'h70 || lcd_id[15:8]== 8'h19)
        slave_addr = 7'h38;
    else 
        slave_addr = 7'h14;
end       

//信号转换
signal_switch #(.WIDTH(WIDTH)
) u1_signal_switch(
    //module1
    .m1_0        (i2c_exec      ),
    .m1_1        (i2c_rh_wl     ),
    .m1_2        (i2c_addr      ),
    .m1_3        (i2c_data_w    ),
    .m1_4        (i2c_data_r    ),
    .m1_5        (reg_num       ),
    .m1_6        (once_done     ),
    //module2
    .m2_0        (cfg_i2c_exec  ),
    .m2_1        (cfg_i2c_rh_wl ),
    .m2_2        (cfg_i2c_addr  ),
    .m2_3        (cfg_i2c_data  ),
    .m2_4        ( ),
    .m2_5        (cfg_reg_num   ),
    .m2_6        (cfg_once_done ),
    //module3
    .m3_0        (m_i2c_exec    ),   // i2c触发控制
    .m3_1        (m_i2c_rh_wl   ),   // i2c读写控制
    .m3_2        (m_i2c_addr    ),   // i2c寄存器地址
    .m3_3        (m_i2c_data_w  ),   // i2c写入的数据
    .m3_4        (m_i2c_data_r  ),   // i2c读出的数据
    .m3_5        (m_reg_num     ),   // 一次读写寄存器的个数
    .m3_6        (m_once_done   ),   // 一次读写操作完成
    //ctrl signal
    .ctrl_switch (cfg_switch    )    // 切换信号
);

//例化i2c_dri_m
i2c_dri_m #(
//    .SLAVE_ADDR  (SLAVE_ADDR),    // slave address从机地址，放此处方便参数传递
    .CLK_FREQ    (CLK_FREQ    ),    // i2c_dri模块的驱动时钟频率(CLK_FREQ)
    .I2C_FREQ    (I2C_FREQ    ),    // I2C的SCL时钟频率
    .WIDTH       (WIDTH       )
) u_i2c_dri(
    //global clock
    .clk         (clk         ),    // i2c_dri模块的驱动时钟(CLK_FREQ)
    .rst_n       (rst_n       ),    // 复位信号
    //i2c interface
    .slave_addr  (slave_addr  ),
    .i2c_exec    (m_i2c_exec  ),    // I2C触发执行信号
    .bit_ctrl    (bit_ctrl    ),    // 器件地址位控制(16b/8b)
    .i2c_rh_wl   (m_i2c_rh_wl ),    // I2C读写控制信号
    .i2c_addr    (m_i2c_addr  ),    // I2C寄存器地址
    .i2c_data_w  (m_i2c_data_w),    // I2C要写的数据
    .i2c_data_r  (m_i2c_data_r),    // I2C读出的数据
    .i2c_done    (i2c_done    ),    // I2C操作完成
    .once_done   (m_once_done ),    // 一次读写操作完成
    .scl         (scl         ),    // I2C的SCL时钟信号
    .sda_in      (sda_in      ),    // I2C的SDA信号
    .sda_out     (sda_out     ),
    .sda_dir     (sda_dir     ),  
    .ack         (ack         ), 
    //user interface
    .reg_num     (m_reg_num   ),     // 一次读写寄存器的个数
    .dri_clk     (clk_i2c     ),     // I2C操作时钟
    .lcd_id      (lcd_id      )
);

//例化i2c_reg_cfg模块
i2c_reg_cfg  u_i2c_reg_cfg(
    //clock & reset
    .clk         (clk_i2c      ),   // i2c_reg_cfg驱动时钟(一般取1MHz)
    .rst_n       (rst_n        ),   // 复位信号
    //i2c interface
    .i2c_exec    (cfg_i2c_exec ),   // I2C触发执行信号
    .i2c_rh_wl   (cfg_i2c_rh_wl),   // I2C读写控制信号
    .i2c_addr    (cfg_i2c_addr ),   // 寄存器地址
    .i2c_data    (cfg_i2c_data ),   // 寄存器数据
    .once_done   (cfg_once_done),   // 一次读写操作完成
    .cfg_done    (cfg_done     ),   // 配置完成
    //user interface
    .reg_num     (cfg_reg_num  ),   // 一次读写寄存器的个数
    .cfg_switch  (cfg_switch   ),   // 切换信号
    .lcd_id      (lcd_id       )    
);

endmodule