//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           i2c_reg_cfg
// Last modified Date:  2018/3/22 15:38:09
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2018/3/22 15:38:06
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
`timescale  1ns/1ns
module i2c_reg_cfg #(parameter WIDTH = 4'd8
)(
    input                        clk       ,            // i2c_reg_cfg驱动时钟(一般取1MHz)
    input                        rst_n     ,            // 复位信号
    input                        once_done ,            // I2C一次操作完成反馈信号

    output  reg                  i2c_exec  ,            // I2C触发执行信号
    output  reg                  i2c_rh_wl ,            // I2C读写控制信号
    output  reg  [15:0]          i2c_addr  ,            // 寄存器地址
    output  reg  [ 7:0]          i2c_data  ,            // 寄存器数据
    output  reg                  cfg_done  ,            // WM8978配置完成

    //user interface
    input                        cfg_switch,            // 配置切换
    input        [15:0]          lcd_id,
    output  reg  [WIDTH-1'b1:0]  reg_num
);

//parameter define
localparam    MODE       = 8'h1  ;             // 0X8100用于控制是否将配置保存在本地，写 0，则不保存配置，写 1 则保存配置。
//localparam    REG_NUM_4  = 8'd186;           // 总共需要配置的寄存器个数
//GT9147 部分寄存器定义
localparam    GT_CTRL_REG  = 16'h8040;         // GT系列控制寄存器
localparam    GT_CFGS_REG  = 16'h8050;         // GT系列配置起始地址寄存器
localparam    GT_CHECK_REG = 16'h813C;         // GT系列校验和寄存器

//reg define
reg    [2:0]  start_init_cnt;                  // 初始化时间计数
reg    [7:0]  init_reg_cnt  ;                  // 寄存器配置个数计数器
reg    [7:0]  sum_t1;                          // 计算校验和
reg    [7:0]  REG_NUM;                         // 总共需要配置的寄存器个数

//wire define
wire          rd_en ;
wire   [7:0]  sum_t2;                          // 计算校验和
reg    [9:0]  address;
wire   [7:0]  q;

//*****************************************************
//**                    main code
//*****************************************************

//计算校验和
assign sum_t2 = init_reg_cnt == REG_NUM - 'd3 ? (~sum_t1 + 1'd1) : sum_t2;
assign rd_en = init_reg_cnt <= REG_NUM - 'd3 ? 1'b1: 1'b0;

always @(*) begin
    if(lcd_id ==16'h5084)
        address =init_reg_cnt;
    else if(lcd_id ==16'h1018)
        address =init_reg_cnt+ 8'd184;
    else if(lcd_id == 16'h4384)
        address =init_reg_cnt+ 9'd370;
end

always @(*) begin
    if(lcd_id[15:12] == 4'h1)  // 10.1'
        REG_NUM = 8'd188;
    else 
        REG_NUM = 8'd186;   // 4.3'
end

//I2C开始操作控制
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_init_cnt <= 3'b0;
    end
    else if(cfg_switch) begin
        if(start_init_cnt < 3'h2)
            start_init_cnt <= start_init_cnt + 1'b1;
    end
end

// 触发I2C操作控制
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        i2c_exec <= 1'b0;
    else if(cfg_switch) begin
        if(start_init_cnt == 9'h1)
            i2c_exec <= 1'b1;        
        else
            i2c_exec <= 1'b0;
    end
end

//配置寄存器个数计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        init_reg_cnt <= 8'd0;
    end
    else if(cfg_switch & once_done)
        init_reg_cnt <= init_reg_cnt + 1'b1;
end

//寄存器配置完成信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cfg_done <= 1'b0;
    else if(init_reg_cnt == REG_NUM)
        cfg_done <= 1'b1;
end

//计算校验和
always @(posedge clk) begin
    if(once_done & (init_reg_cnt <= REG_NUM - 'd3))
        sum_t1 = sum_t1 + i2c_data;
    else
        sum_t1 = sum_t1;
end

always @(posedge clk) begin
    if(cfg_switch) begin
        i2c_rh_wl<= 1'b0;
        i2c_addr <= GT_CFGS_REG;
        reg_num  <= REG_NUM;
        if(lcd_id[15:12] == 4'h1) begin  // 16'h1018 10.1'
            case(init_reg_cnt)
                8'd186: i2c_data <= sum_t2;
                8'd187: i2c_data <= MODE ;
                default: i2c_data <= q;
            endcase
        end
        else begin
            case(init_reg_cnt)
                8'd184: i2c_data <= sum_t2;
                8'd185: i2c_data <= MODE ;
                default: i2c_data <= q;
            endcase
        end
     end
end

gt_cfg	gt_cfg_inst (
	.address ( address ),
	.clock ( clk ),
	.rden ( rd_en ),
	.q ( q )
	);

endmodule
