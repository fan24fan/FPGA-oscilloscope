//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           pulse_gen
// Last modified Date:  2019/3/7 09:02:10
// Last Version:        V1.0
// Descriptions:        脉冲生成模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/3/7 09:02:10
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module pulse_gen(
    input           rst_n,      //系统复位，低电平有效
    
    input  [7:0]    trig_level,
    input           ad_clk,     //AD9280驱动时钟
    input  [7:0]    ad_data,    //AD输入数据
    
    output          ad_pulse    //输出的脉冲信号
);

parameter THR_DATA = 3;

//reg define
reg          pulse;
reg          pulse_delay;

//*****************************************************
//**                    main code
//*****************************************************

assign ad_pulse = pulse & pulse_delay;

//根据触发电平，将输入的AD采样值转换成高低电平
always @ (posedge ad_clk or negedge rst_n)begin
    if(!rst_n)
        pulse <= 1'b0;
    else begin
        if((trig_level >= THR_DATA) && (ad_data < trig_level - THR_DATA))
            pulse <= 1'b0;
        else if(ad_data > trig_level + THR_DATA)
            pulse <= 1'b1;
    end    
end

//延时一个时钟周期，用于消除抖动
always @ (posedge ad_clk or negedge rst_n)begin
    if(!rst_n)
        pulse_delay <= 1'b0;
    else
        pulse_delay <= pulse;
end

endmodule 