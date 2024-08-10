//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           lcd_display
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        绘制频谱界面
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module lcd_display(
    input             lcd_pclk,        //lcd驱动时钟
    input             rst_n,           //复位信号
    
    input      [8:0]  pixel_xpos,      //像素点横坐标
    input      [8:0]  pixel_ypos,      //像素点纵坐标
    
    input      [15:0] ui_pixel_data,   //UI像素数据   
    
    input      [7:0]  wave_data,       //波形(AD数据)
    output     [8:0]  wave_addr,       //显示点数
    input             outrange,
    output            wave_data_req,   //请求波形（AD）数据
    output            wr_over,         //绘制波形完成
    output reg [15:0] pixel_data,      //LCD像素点数据

    input      [9:0]  v_shift,         //波形竖直偏移量，bit[9]=0/1:上移/下移 
    input      [4:0]  v_scale,         //波形竖直缩放比例，bit[4]=0/1:缩小/放大 
    input      [7:0]  trig_line        //触发电平
    );    

//parameter define  
localparam WHITE  = 16'b11111_111111_11111;     //RGB565 白色
localparam BLUE   = 16'b00000_000000_11111;     //RGB565 蓝色

//reg define
reg  [15:0] pre_length;
reg         outrange_reg;
reg  [15:0] shift_length;
reg  [9:0]  v_shift_t;
reg  [4:0]  v_scale_t;
reg  [11:0] scale_length;
reg  [7:0]  trig_line_t;

//wire define
wire [15:0] draw_length;

//*****************************************************
//**                    main code
//*****************************************************

//请求像素数据信号
assign wave_data_req = ((pixel_xpos >= 9'd49 - 1'b1) && (pixel_xpos < 9'd349 -1)  
                         && (pixel_ypos >= 9'd49 ) && (pixel_ypos < 9'd250)) 
                       ? 1'b1 : 1'b0;

//根据显示的X坐标计算数据在RAM中的地址
assign wave_addr = wave_data_req ? (pixel_xpos - (9'd49-1'b1)) : 9'd0;

//标志一帧波形绘制完毕
assign wr_over  = (pixel_xpos == 9'd349) && (pixel_ypos == 9'd250);

//寄存输入的参数
always @(posedge lcd_pclk or negedge rst_n)begin
    if(!rst_n) begin
        v_shift_t <= 1'b0;
        v_scale_t <= 1'b0;
        trig_line_t <= 1'b0;
    end    
    else begin
        v_shift_t <= v_shift;
        v_scale_t <= v_scale;
        trig_line_t <= trig_line;    
    end
end

//竖直方向上的缩放
always @(*) begin
    if(v_scale_t[4])   //放大
        scale_length = wave_data * v_scale_t[3:0]-((9'd128*v_scale_t[3:0])-9'd128);
    else               //缩小
        scale_length = (wave_data >> v_scale_t[3:1])+(128-(128>>v_scale_t[3:1]));
    
end

//对波形进行竖直方向的移动
always @(*) begin
    if(v_shift_t[9]) begin  //下移
        if(scale_length >= 12'd2048) 
            shift_length = v_shift_t[8:0]+9'd20-(~{4'hf,scale_length}+1'b1);
        else
            shift_length = scale_length+v_shift_t[8:0]+9'd20;
    end
    else begin              //上移
        if(scale_length >= 12'd2048) 
            shift_length = 16'd0;
        else if(scale_length+9'd20 <= v_shift_t[8:0])
            shift_length = 16'd0;
        else
            shift_length = scale_length+9'd20-v_shift_t[8:0];
    end    
end

//处理负数长度
assign draw_length = shift_length[15] ? 16'd0 : shift_length;

//寄存前一个像素点的纵坐标，用于各点之间的连线
always @(posedge lcd_pclk or negedge rst_n)begin
    if(!rst_n)
        pre_length <= 16'd0;
    else 
    if((pixel_xpos >= 9'd49) && (pixel_xpos < 9'd349)
        && (pixel_ypos >= 9'd49) && (pixel_ypos < 9'd250))
        pre_length <= draw_length;
end

//寄存outrange,用于水平方向移动时处理左右边界
always @(posedge lcd_pclk or negedge rst_n)begin
    if(!rst_n)
        outrange_reg <= 1'b0;
    else 
        outrange_reg <= outrange;
end

//根据读出的AD值，在屏幕上绘点
always @(*) begin
    if(outrange_reg || outrange)    //超出波形显示范围
        pixel_data = ui_pixel_data; //显示UI波形
                                    //坐标点在波形显示范围内    
    else if((pixel_xpos > 9'd49) && (pixel_xpos < 9'd349) &&
                   (pixel_ypos >= 9'd49) && (pixel_ypos < 9'd250)) begin
        if(((pixel_ypos >= pre_length) && (pixel_ypos <= draw_length))
                    ||((pixel_ypos <= pre_length)&&(pixel_ypos >= draw_length)))
            pixel_data = WHITE;     //显示波形
        else if(pixel_ypos == trig_line_t)   
            pixel_data = BLUE;      //显示触发线
        else
            pixel_data = ui_pixel_data;     
    end               
    else
        pixel_data = ui_pixel_data;  
end

endmodule 
