//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           vpp_measure
// Last modified Date:  2019/3/10 11:33:57
// Last Version:        V1.0
// Descriptions:        峰峰值测量模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/3/10 11:33:57
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module vpp_measure(   
    input               rst_n,      // 复位信号
    
    input               ad_clk,     // AD时钟
    input      [7:0]    ad_data,    // AD输入数据
    input               ad_pulse,   // 由AD波形得到的脉冲信号
    output reg [7:0]    ad_vpp,     // AD峰峰值
    output reg [7:0]    ad_max,     // AD最大值
    output reg [7:0]    ad_min      // AD最小值
);

//reg define
reg         vpp_flag;               // 测量峰峰值标志信号
reg         vpp_flag_d;             // vpp_flag 延时
reg [7:0]   ad_data_max;            // AD一个周期内的最大值
reg [7:0]   ad_data_min;            // AD一个周期内的最小值

//wire define
wire        vpp_flag_pos;           // vpp_flag上升沿标志信号
wire        vpp_flag_neg;           // vpp_flag下降沿标志信号

//*****************************************************
//**                    main code
//*****************************************************

//边沿检测，捕获信号上升/下降沿
assign vpp_flag_pos = (~vpp_flag_d) & vpp_flag;
assign vpp_flag_neg = vpp_flag_d & (~vpp_flag);

//利用vpp_flag标志一个被测时钟周期
always @(posedge ad_pulse or negedge rst_n) begin
    if(!rst_n)
        vpp_flag <= 1'b0; 
    else 
        vpp_flag <= ~vpp_flag; 
end

//将vpp_flag延时一个AD时钟周期
always @(posedge ad_clk or negedge rst_n) begin
    if(!rst_n)
        vpp_flag_d <= 1'b0; 
    else 
        vpp_flag_d <= vpp_flag; 
end

//筛选一个被测时钟周期内的最大/最小值
always @(posedge ad_clk or negedge rst_n) begin
    if(!rst_n) begin
        ad_data_max <= 8'd0; 
        ad_data_min <= 8'd0;
    end
    else if(vpp_flag_pos)begin      //被测时钟周期开始时寄存AD数据
        ad_data_max <= ad_data; 
        ad_data_min <= ad_data;
    end
    else if(vpp_flag_d) begin   
        if(ad_data > ad_data_max)
            ad_data_max <= ad_data; //计算最大值
        if(ad_data < ad_data_min)
            ad_data_min <= ad_data; //计算最小值
    end    
end

//计算被测时钟周期内的峰峰值
always @(posedge ad_clk or negedge rst_n) begin
    if(!rst_n) begin
        ad_vpp <= 8'd0;
        ad_max <= 8'd0;
        ad_min <= 8'd0;
    end
    else if(vpp_flag_neg) begin
        ad_vpp <= ad_data_max - ad_data_min;
        ad_max <= ad_data_max;
        ad_min <= ad_data_min;
    end
end

endmodule 