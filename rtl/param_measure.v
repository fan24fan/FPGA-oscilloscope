//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           param_measure
// Last modified Date:  2019/3/10 13:26:27
// Last Version:        V1.0
// Descriptions:        参数测量模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/3/10 11:33:57
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module param_measure(
    input               clk ,       // 时钟
    input               rst_n  ,    // 复位信号

    input      [7:0]    trig_level, // 触发电平
    
    input               ad_clk,     // AD时钟
    input      [7:0]    ad_data,    // AD输入数据
    
    output              ad_pulse,   //pulse_gen模块输出的脉冲信号,仅用于调试
    
    output     [19:0]   ad_freq,    // 被测时钟频率输出
    output     [7:0]    ad_vpp,     // AD峰峰值 
    output     [7:0]    ad_max,     // AD最大值
    output     [7:0]    ad_min      // AD最小值
);

//parameter define
parameter CLK_FS = 26'd50_000_000;  // 基准时钟频率值

//脉冲生成模块
pulse_gen u_pulse_gen(
    .rst_n          (rst_n),        //系统复位，低电平有效

    .trig_level     (trig_level),   // 触发电平
    .ad_clk         (ad_clk),       //AD9280驱动时钟
    .ad_data        (ad_data),      //AD输入数据

    .ad_pulse       (ad_pulse)      //输出的脉冲信号
    );

//等精度频率计模块
cymometer #(
    .CLK_FS         (CLK_FS)        // 基准时钟频率值
) u_cymometer(
    .clk_fs         (clk),
    .rst_n          (rst_n),

    .clk_fx         (ad_pulse),     // 被测时钟信号
    .data_fx        (ad_freq)       // 被测时钟频率输出
    );

//计算峰峰值
vpp_measure u_vpp_measure(
    .rst_n          (rst_n),
    
    .ad_clk         (ad_clk), 
    .ad_data        (ad_data),
    .ad_pulse       (ad_pulse),
    .ad_vpp         (ad_vpp),
    .ad_max         (ad_max),
    .ad_min         (ad_min)
    );

endmodule 