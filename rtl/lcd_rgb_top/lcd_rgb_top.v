//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           lcd_rgb_top
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        LCD显示顶层模块
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
module lcd_rgb_top(
    input           clk_25m,
    input           clk_12_5m,
    input           rst_n,          //复位
                                         
    //RGB LCD接口                        
    output          lcd_de,         //LCD 数据使能信号
    output          lcd_hs,         //LCD 行同步信号
    output          lcd_vs,         //LCD 场同步信号
    output          lcd_clk,        //LCD 像素时钟
    inout   [15:0]  lcd_rgb,        //LCD RGB565颜色数据
    output          lcd_rst,   
    output          lcd_bl ,

    input   [9:0]   v_shift,        //波形竖直偏移量，bit[9]=0/1:上移/下移
    input   [4:0]   v_scale,        //波形竖直缩放比例，bit[4]=0/1:缩小/放大 
    input   [7:0]   trig_line,      //触发电平  
    input           outrange,    
    input   [15:0]  ui_pixel_data,  //UI像素数据 
    input   [7:0]   wave_data,
    output          ui_data_req,    //UI数据请求信号     
    output  [8:0]   wave_addr,
    output          wave_data_req,  //请求波形数据
    output          wr_over,
    output  [15:0]  lcd_id          //LCD屏ID
    );     

//除480*272屏幕之外，填充黑色    
parameter BACK_COLOR = 16'h0000;    

wire          lcd_pclk          ; //LCD像素时钟              
wire  [10:0]  pixel_xpos        ; //当前像素点横坐标
wire  [10:0]  pixel_ypos        ; //当前像素点纵坐标
wire  [15:0]  lcd_rgb_o         ; //输出的像素数据
wire  [15:0]  lcd_rgb_i         ; //输入的像素数据
wire  [15:0]  pixel_data        ;
wire          data_req          ;
wire  [15:0]  display_pixel_data;

wire  [8:0]   clip_pixel_xpos   ; //裁剪后的像素点横坐标
wire  [8:0]   clip_pixel_ypos   ; //裁剪后的像素点纵坐标

reg  ui_data_req_d0;

//*****************************************************
//**                    main code
//*****************************************************

//像素数据方向切换
assign lcd_rgb = lcd_de ?  lcd_rgb_o :  {16{1'bz}};
assign lcd_rgb_i = lcd_rgb;
//选择输出UI和波形像素点或者填充的像素(填充黑色)
assign pixel_data = ui_data_req_d0 ? display_pixel_data : BACK_COLOR;

//对ui_data_req信号打一拍
always @(posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n) begin
        ui_data_req_d0 <= 1'b0;
    end    
    else begin    
        ui_data_req_d0 <= ui_data_req;
    end
end

//读LCD ID模块
rd_id u_rd_id(
    .clk          (clk_25m),
    .rst_n        (rst_n    ),
    .lcd_rgb      (lcd_rgb_i),
    .lcd_id       (lcd_id   )
    );    

//时钟分频模块    
clk_div u_clk_div(
    .clk_25m       (clk_25m),
    .clk_12_5m     (clk_12_5m),
    .rst_n         (rst_n    ),
    .lcd_id        (lcd_id   ),
    .lcd_pclk      (lcd_pclk )
    );    

//LCD裁剪模块
lcd_clip u_lcd_clip(
    .clk             (lcd_pclk),          
    .rst_n           (rst_n),

    .data_req        (data_req),    
    .lcd_id          (lcd_id    ),
    .pixel_xpos      (pixel_xpos),
    .pixel_ypos      (pixel_ypos),
    .clip_data_req   (ui_data_req),
    .clip_pixel_xpos (clip_pixel_xpos),
    .clip_pixel_ypos (clip_pixel_ypos)
    );    

//LCD显示模块
lcd_display u_lcd_display(          
    .lcd_pclk        (lcd_pclk),    
    .rst_n           (rst_n),
    
    .pixel_xpos      (clip_pixel_xpos),
    .pixel_ypos      (clip_pixel_ypos),
    .pixel_data      (display_pixel_data),
    
    .ui_pixel_data   (ui_pixel_data),
    
    .wave_addr       (wave_addr), 
    .wave_data       (wave_data),
    .wave_data_req   (wave_data_req),
    .wr_over         (wr_over),
    .outrange        (outrange),
    
    .v_shift         (v_shift),
    .v_scale         (v_scale),
    .trig_line       (trig_line)
    );     
    
//LCD驱动模块
lcd_driver u_lcd_driver(
    .lcd_pclk      (lcd_pclk  ),
    .rst_n         (rst_n     ),
    .lcd_id        (lcd_id    ),
    .pixel_data    (pixel_data),
    .pixel_xpos    (pixel_xpos),
    .pixel_ypos    (pixel_ypos),
    .h_disp        (),
    .v_disp        (),
    .data_req      (data_req  ),

    .lcd_de        (lcd_de    ),
    .lcd_hs        (lcd_hs    ),
    .lcd_vs        (lcd_vs    ),   
    .lcd_clk       (lcd_clk   ),
    .lcd_rgb       (lcd_rgb_o ),
    .lcd_rst       (lcd_rst   ),
    .lcd_bl        (lcd_bl)
    );

endmodule
