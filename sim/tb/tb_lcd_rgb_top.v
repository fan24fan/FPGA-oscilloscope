//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           tb_lcd_rgb_top
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        LCD显示顶层模块TB
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`timescale  1ns/1ns                     //定义仿真时间单位1ns和仿真时间精度为1ns

module  tb_lcd_rgb_top;              

//parameter  define
parameter  PERIOD_40 = 40;              //时钟周期
parameter  PERIOD_80 = 80;              //时钟周期

//reg define
reg          clk_25m;                   //时钟信号
reg          clk_12_5m;                 //时钟信号
reg          sys_rst_n;                 //复位信号
reg  [7:0]   wave_data;

//wire define
wire         lcd_de ;
wire         lcd_hs ;
wire         lcd_vs ;
wire         lcd_clk;
wire [15:0]  lcd_rgb;
wire         lcd_rst;
wire         lcd_bl ;   
wire         ui_data_req  ;
wire [8:0]   wave_addr    ;
wire         wave_data_req;
wire         wr_over      ;
wire [15:0]  lcd_id       ;

//*****************************************************
//**                    main code
//*****************************************************

//给输入信号初始值
initial begin
    clk_25m     <= 1'b0;
    clk_12_5m   <= 1'b0;  
    sys_rst_n   <= 1'b0;               //开始复位
    #(PERIOD_80+1)  sys_rst_n <= 1'b1; //复位信号信号拉高
end

//25Mhz的时钟，周期则为1/25Mhz=40ns,所以每20ns，电平取反一次
always #(PERIOD_40/2) clk_25m = ~clk_25m;
//12.5Mhz的时钟，周期则为1/12.5Mhz=80ns,所以每40ns，电平取反一次
always #(PERIOD_40/2) clk_12_5m = ~clk_12_5m;

//产生测试数据
always @(posedge clk_25m or negedge sys_rst_n) begin
    if(!sys_rst_n) 
        wave_data <= 8'd0;
    else if(wr_over)
        wave_data <= 8'd0;
    else if(wave_data_req)
        wave_data <= wave_addr;
end

//LCD ID = 16'h4342
assign lcd_rgb[4] = 1'b0;
assign lcd_rgb[10] = 1'b0;
assign lcd_rgb[15] = 1'b0;

//例化LCD顶层模块
lcd_rgb_top u_lcd_rgb_top(
    .clk_25m         (clk_25m  ),
    .clk_12_5m       (clk_12_5m),
    .rst_n           (sys_rst_n),
              
    .lcd_de          (lcd_de ),
    .lcd_hs          (lcd_hs ),
    .lcd_vs          (lcd_vs ),
    .lcd_clk         (lcd_clk),
    .lcd_rgb         (lcd_rgb),
    .lcd_rst         (lcd_rst),
    .lcd_bl          (lcd_bl ),
               
    .v_shift         (10'd0),
    .v_scale         ({1'b1,4'd2}),    //垂直方向放大两倍
    .trig_line       (8'd150),         //触发电平
    .outrange        (1'b0),
    .ui_pixel_data   (16'h5555),
    .wave_data       (wave_data),
    .ui_data_req     (ui_data_req  ),
    .wave_addr       (wave_addr    ),
    .wave_data_req   (wave_data_req),
    .wr_over         (wr_over      ),
    .lcd_id          (lcd_id       )
    );
    
endmodule
