//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           top_touch
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        触摸顶层模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module top_touch(
    input                  sys_clk,          // 系统时钟信号
    input                  sys_rst_n,        // 复位信号（低有效）
    //tft interface
    // inout                  tft_sda,
    input                  tft_sda_i,
    output                 tft_sda_o,
    output                 tft_sda_t,
    output                 tft_scl,
    inout                  tft_int,
    output                 tft_tcs,
    //touch lcd interface    
    input      [15:0]      lcd_id, 
    output                 touch_valid,      // 连续触摸标志
    output     [ 2:0]      tp_num,
    output     [31:0]      tp1_xy,
	//Avalon-ST接口		     	
    input      [ 2:0]      avl_address,      //地址
    input                  avl_write,        //写请求
    input      [31:0]      avl_writedata,    //写数据
    input                  avl_read,         //读请求
    output     [31:0]      avl_readdata      //读数据    
);

//parameter define
parameter   WIDTH = 5'd8;

//wire define
wire                      sda_out   ;
wire                      sda_dir   ;
wire                      ack;
wire                      i2c_exec  ;
wire                      i2c_rh_wl ;
wire    [15:0]            i2c_addr  ;
wire    [ 7:0]            i2c_data_w;
wire    [WIDTH-1'b1:0]    reg_num   ;
wire    [ 7:0]            i2c_data_r;
wire                      i2c_done  ;
wire                      once_done ;
wire                      bit_ctrl  ;
wire                      clk       ;
wire                      cfg_done  ;
wire                      cfg_switch;

//*****************************************************
//**                    main code
//*****************************************************

assign tft_sda_o=sda_out;
assign tft_sda_t=sda_dir;  


touch_clip u_touch_clip(
    .clk                 (sys_clk),
    .rst_n               (sys_rst_n),
                   
    .lcd_id              (lcd_id),
    .tp_num              (tp_num),
    .tp1_xy              (tp1_xy),
 	                
    .avl_address         (avl_address  ),
    .avl_write           (avl_write    ),
    .avl_writedata       (avl_writedata),
    .avl_read            (avl_read     ),
    .avl_readdata        (avl_readdata )
    );
 
touch_gt_cfg #(.WIDTH(4'd8)) u_touch_gt_cfg(
    //module clock
    .clk                (sys_clk   ),          // 时钟信号
    .rst_n              (sys_rst_n ),          // 复位信号
    //port interface
    .scl                (tft_scl    ),         // 时钟线scl
    .sda_in             (tft_sda_i ),          // 数据线sda
    .sda_out            (sda_out),
    .sda_dir            (sda_dir),  
    //I2C interface
    .ack                (ack       ),
    .i2c_exec           (i2c_exec  ),          // i2c触发控制
    .i2c_rh_wl          (i2c_rh_wl ),          // i2c读写控制
    .i2c_addr           (i2c_addr  ),          // i2c操作地址
    .i2c_data_w         (i2c_data_w),          // i2c写入的数据
    .reg_num            (reg_num   ),
    .i2c_data_r         (i2c_data_r),          // i2c读出的数据
    .i2c_done           (i2c_done  ),          // i2c操作结束标志
    .once_done          (once_done ),          // 一次读写操作完成
    .bit_ctrl           (bit_ctrl  ),
    .clk_i2c            (clk       ),          // I2C操作时钟
    .cfg_done           (cfg_done  ),          // 寄存器配置完成标志
    //user interfacd
    .cfg_switch         (cfg_switch),
    .lcd_id             (lcd_id    )           //LCD ID
);

touch_ctrl
    #(.WIDTH(4'd8))                            // 一次读写寄存器的个数的位宽
u_touch_ctrl(
    //module clock
    .clk                (clk      ),           // 时钟信号
    .rst_n              (sys_rst_n),           // 复位信号（低有效）
    .cfg_done           (cfg_done ),           // 配置完成标志
    .tft_tcs            (tft_tcs  ),
    .tft_int            (tft_int  ),

    //I2C interface
    .ack                (ack       ),
    .i2c_exec           (i2c_exec  ),          // i2c触发控制
    .i2c_rh_wl          (i2c_rh_wl ),          // i2c读写控制
    .i2c_addr           (i2c_addr  ),          // i2c操作地址
    .i2c_data_w         (i2c_data_w),          // i2c写入的数据
    .i2c_data_r         (i2c_data_r),          // i2c读出的数据
    .once_done          (once_done ),          // 一次读写操作完成
    .i2c_done           (i2c_done  ),          // i2c操作结束标志
    .bit_ctrl           (bit_ctrl  ),
    .reg_num            (reg_num   ),          // 一次读写寄存器的个数

    //touch lcd interface
    .touch_valid        (touch_valid),
    .tp_num             (tp_num),
    .tp1_xy             (tp1_xy),
    .tp2_xy             (),
    .tp3_xy             (),
    .tp4_xy             (),
    .tp5_xy             (),

    //user interface
    .cfg_switch         (cfg_switch),
    .lcd_id             (lcd_id       )      //LCD ID
);

endmodule
