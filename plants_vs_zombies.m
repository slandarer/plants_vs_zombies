function plants_vs_zombies

global map;             %显示地图上各个位置种植的植物种类和种植时间
global bulletmap;
global list;            %植物名字列表
global cardlist;        %卡组排序列表
global cardbank;        %卡组类
global bkg              %背景类
global zeroplace;       %可种植区域左下角位置
global gridsize;        %可种植单元格大小
global stagenumber;     %地图编号：白天 黑天 白天泳池。。。
global Data;            %植物大战僵尸数据集
global energy;          %能量（阳光）
global onhand;          %手中植物种类

global sun;             %阳光类
global sunControlTimer; %阳光行为控制计时器
global sunTargetPos;    %阳光目标降落位置
global sunPos;          %阳光目前位置



global Mainfig;         %主绘图窗口       
global Mainaxes;        %主绘图框架


global DrawBkgHdl;
global DrawPlantsHdl;
global DrawCardBankHdl;
global DrawScoopBkgHdl;
global DrawCardHdl;
global DrawScoopHdl;
global TextEnergyHdl;
global DrawOnHandHdl;

global DrawSunHdl;
global DrawSunProducedHdl;
global DrawGetSunHdl;
global DrawGetSunProducedHdl;
%==========================================================================
%将image可使用图片转为surf可使用图片
%已弃用
    %function tempCDataNan=getCDataNan(temp_CData,temp_Alpha)
        %tempCData1=double(temp_CData(:,:,1))./255;
        %tempCData2=double(temp_CData(:,:,2))./255;
        %tempCData3=double(temp_CData(:,:,3))./255;
        %tempCData1(double(temp_Alpha)==0)=nan;
        %tempCData2(double(temp_Alpha)==0)=nan;
        %tempCData3(double(temp_Alpha)==0)=nan;
        %tempCDataNan(:,:,1)=tempCData1;
        %tempCDataNan(:,:,2)=tempCData2;
        %tempCDataNan(:,:,3)=tempCData3;  
    %end
%==========================================================================
init()
    function init(~,~)
        Data=load('PlantsVsZombies.mat');      %导入数据集 
        energy=2500;                           %初始化阳光
        sun=Data.sun;                          %初始化阳光类
        sunControlTimer=0;                     %初始化阳光行为控制计时器
        
        onhand=0;                              %手中所持物为空
        cardlist=[2 1 3 4 5];%1 3];
        
        list=Data.list;
        bkg=Data.bkg;
        cardbank=Data.cardbank;
        stagenumber=1;                         %地图类型
        
        map=zeros(bkg.MapSize(stagenumber,1),bkg.MapSize(stagenumber,2),2);
        bulletmap=zeros(bkg.MapSize(stagenumber,1),bkg.MapSize(stagenumber,2),3);
        %该位置生成子弹次数\是否开始生成子弹\生成子弹周期\
        temp_pos=[randi(bkg.MapSize(stagenumber,1)),randi(bkg.MapSize(stagenumber,2))];
        zeroplace=bkg.ZeroPlace(stagenumber,:);
        gridsize=bkg.GridSize(stagenumber,:);
        sunTargetPos=[zeroplace(1)+(temp_pos(2)-1)*(gridsize(1))+min(temp_pos(2),6)*gridsize(4),...
                      zeroplace(2)+(temp_pos(1)-1)*(gridsize(3))+min(temp_pos(2),6)*gridsize(2)]+randi(50,[1 2]);
        sunPos=sunTargetPos+[0 600];
        
       
        %==================================================================
        Mainfig=figure('units','pixels','position',[300 80 900 600],...
                       'Numbertitle','off','menubar','none','resize','off',...
                       'name','Plants Vs Zombies');
        Mainaxes=axes('parent',Mainfig,'position',[0 0 1 1],...
                    'XLim', [0 900],...
                    'YLim', [0 600],...
                    'NextPlot','add',...
                    'layer','bottom',...
                    'Visible','on',...
                    'XTick',[], ...
                    'YTick',[]);
        DrawBkgHdl=image([0 900],[0 600],flipud(bkg.Main(:,:,:,stagenumber)));
        DrawCardBankHdl=image([0 446]+120,[-87 0]+600,flipud(cardbank.CardBkg(:,:,:)));
        DrawScoopBkgHdl=image([0 70]+446+120,[-72 0]+600,flipud(cardbank.ScoopBkg(:,:,:)));
        
        DrawOnHandHdl=image([0 Data.(list{onhand+1}).Size(1)]-Data.(list{onhand+1}).Size(1)/2,...
                            [0 Data.(list{onhand+1}).Size(2)]-Data.(list{onhand+1}).Size(2)/2,...
                            flipud(Data.(list{onhand+1}).Sprite(:,:,:,1)),...
                            'AlphaData',flipud(Data.(list{onhand+1}).Alpha(:,:,1)).*0.5);
                        
        TextEnergyHdl=text(158,527,num2str(energy),'HorizontalAlignment', 'center','fontsize',10);
        
        
        [temp_x,temp_y]=meshgrid(1:sun.Size(1),1:sun.Size(2));      
        DrawSunHdl=surface(temp_x+sunPos(1),...
                        temp_y+sunPos(2),...
                        ones(sun.Size([1 2])),...
                        flipud(sun.CDataNan(:,:,:,1)),...
                        'CDataMapping','direct',...
                        'EdgeColor','none',...
                        'ButtonDownFcn',@onclicksun);
                     
        for i=1:length(cardlist)
            temp_card=Data.(list{cardlist(i)+1}).Card;
            DrawCardHdl(i)=image([0 Data.cardsize(2)].*1.02+198+(i-1)*(Data.cardsize(2)*1.02+0.075),...
                                 [0 Data.cardsize(1)].*1.02+520,...
                                 flipud(temp_card.CData),...                            
                                 'alphaData',flipud(temp_card.Alpha),...
                                 'tag',[num2str(i),num2str(cardlist(i))],...
                                 'ButtonDownFcn',@selectplants);
        end
        DrawScoopHdl=image('XData',[0 Data.cardbank.Scoop.Size(1)].*0.5+570,...
                           'YData',[0 Data.cardbank.Scoop.Size(2)].*0.5+540,...
                           'CData',flipud(Data.cardbank.Scoop.CData),...
                           'alphaData',flipud(Data.cardbank.Scoop.Alpha),...
                           'tag',num2str('-1'),...
                           'ButtonDownFcn',@selectplants); 
        
        for i=1:bkg.MapSize(stagenumber,1)
            for j=1:bkg.MapSize(stagenumber,2)
                DrawPlantsHdl(i,j)=image([0 Data.(list{map(i,j,1)+1}).Size(1)]+zeroplace(1)+(j-1)*(gridsize(1))+min(j,6)*gridsize(4),...
                                         [0 Data.(list{map(i,j,1)+1}).Size(2)]+zeroplace(2)+(i-1)*(gridsize(3))+min(j,6)*gridsize(2),...
                                         flipud(Data.(list{map(i,j,1)+1}).Sprite(:,:,:,mod(map(i,j,2),Data.(list{map(i,j,1)+1}).Len)+1)),...
                                         'alphaData',flipud(Data.(list{map(i,j,1)+1}).Alpha(:,:,mod(map(i,j,2),Data.(list{map(i,j,1)+1}).Len)+1)),...
                                         'tag',[num2str(i),num2str(j),num2str(map(i,j,1))],...
                                         'ButtonDownFcn',@growplants);
            end
        end
        
        for i=1:bkg.MapSize(stagenumber,1)
            for j=1:bkg.MapSize(stagenumber,2)
                  temp_pos=[zeroplace(1)+(j-1)*(gridsize(1))+min(j,6)*gridsize(4),...
                            zeroplace(2)+(i-1)*(gridsize(3))+min(j,6)*gridsize(2)]; 
                  [temp_x,temp_y]=meshgrid(1:sun.Size(1),1:sun.Size(2));      
                  DrawSunProducedHdl(i,j)=surface(temp_x+temp_pos(1),...
                                          temp_y+temp_pos(2),...
                                          ones(sun.Size([1 2])),...
                                          flipud(sun.CDataNan(:,:,:,1)),...
                                          'CDataMapping','direct',...
                                          'EdgeColor','none',...
                                          'tag',num2str(i*10+j),...
                                          'visible','off',...
                                          'ButtonDownFcn',@onclicksun_produced);
            end
        end
    
        fps = 10;                                    
        game = timer('ExecutionMode', 'FixedRate', 'Period',1/fps, 'TimerFcn', @PvZgame);
        set(gcf,'tag','co','CloseRequestFcn',@clo);
        function clo(~,~),stop(game),delete(findobj('tag','co'));clf,close,end 
        start(game)
        set(gcf,'WindowButtonMotionFcn',@onhandfunc)
    end
%==========================================================================

    function onclicksun(~,~)
        temp_pos=sunPos;       
        set(DrawSunHdl,'visible','off');
        temp_distance=sqrt(sum(([160,563]-temp_pos).^2));
        temp_vector=([160-35,563-35]-temp_pos)./floor(temp_distance/100);
        [temp_x,temp_y]=meshgrid(1:sun.Size(1),1:sun.Size(2));      
        DrawGetSunHdl=surface(temp_x+temp_pos(1),...
                              temp_y+temp_pos(2),...
                              ones(sun.Size([1 2])),...
                              flipud(sun.CDataNan(:,:,:,1)),...
                              'CDataMapping','direct',...
                              'EdgeColor','none');
        for i=1:floor(temp_distance/100)
            pause(0.001)
            set(DrawGetSunHdl,'XData',temp_x+temp_pos(1)+i*temp_vector(1),...
                              'YData',temp_y+temp_pos(2)+i*temp_vector(2),...
                              'CData',flipud(sun.CDataNan(:,:,:,mod(floor(i/2),sun.Len)+1)));                                        
        end
        delete(DrawGetSunHdl)
        energy=energy+25;
        set(TextEnergyHdl,'string',num2str(energy));
    end

    function onclicksun_produced(object,~)
        temp_tag=object.Tag;
        temp_id=[str2num(temp_tag(1)),str2num(temp_tag(2))];
        set(DrawSunProducedHdl(temp_id(1),temp_id(2)),'visible','off');
        temp_pos=[min(min(object.XData)),min(min(object.YData))];
        temp_distance=sqrt(sum(([160,563]-temp_pos).^2));
        temp_vector=([160-35,563-35]-temp_pos)./floor(temp_distance/100);
        [temp_x,temp_y]=meshgrid(1:sun.Size(1),1:sun.Size(2));  
        DrawGetSunProducedHdl(temp_id(1),temp_id(2))=surface(temp_x+temp_pos(1),...
                              temp_y+temp_pos(2),...
                              ones(sun.Size([1 2])),...
                              flipud(sun.CDataNan(:,:,:,1)),...
                              'CDataMapping','direct',...
                              'EdgeColor','none');
        for i=1:floor(temp_distance/100)
            pause(0.002)
            set(DrawGetSunProducedHdl(temp_id(1),temp_id(2)),'XData',temp_x+temp_pos(1)+i*temp_vector(1),...
                              'YData',temp_y+temp_pos(2)+i*temp_vector(2),...
                              'CData',flipud(sun.CDataNan(:,:,:,mod(floor(i/2),sun.Len)+1)));                                        
        end   
        delete(DrawGetSunProducedHdl(temp_id(1),temp_id(2)))
        energy=energy+25;
        set(TextEnergyHdl,'string',num2str(energy));
    end

    function producesun(pos)
        temp_x=get(DrawSunProducedHdl(pos(1),pos(2)),'XData');
        temp_y=get(DrawSunProducedHdl(pos(1),pos(2)),'YData');
        set(DrawSunProducedHdl(pos(1),pos(2)),'visible','on');
        for i=pi/3:0.1:pi
            pause(0.001)
            set(DrawSunProducedHdl(pos(1),pos(2)),'XData',temp_x+i*10,'YData',temp_y+sin(i)*10);
            set(DrawSunProducedHdl(pos(1),pos(2)),...
                'CData',flipud(sun.CDataNan(:,:,:,mod(sunControlTimer,sun.Len)+1)));
        end
    end
        
%==========================================================================
    function onhandfunc(~,~)
        xy=get(gca,'CurrentPoint');
        x=xy(1,1);y=xy(1,2);
        if onhand~=-1
            set(DrawOnHandHdl,'XData',[0 Data.(list{onhand+1}).Size(1)]-Data.(list{onhand+1}).Size(1)/2+x,...
                              'YData',[0 Data.(list{onhand+1}).Size(2)]-Data.(list{onhand+1}).Size(2)/2+y,...
                              'CData',flipud(Data.(list{onhand+1}).Sprite(:,:,:,1)),...
                              'AlphaData',flipud(Data.(list{onhand+1}).Alpha(:,:,1)).*0.5);        
        else  
            set(DrawOnHandHdl,'XData',[0 cardbank.Scoop.Size(1)].*0.5-cardbank.Scoop.Size(1)/4+x,...
                              'YData',[0 cardbank.Scoop.Size(2)].*0.5-cardbank.Scoop.Size(2)/4+y,...
                              'CData',flipud(cardbank.Scoop.CData),...
                              'AlphaData',flipud(cardbank.Scoop.Alpha)); 
        end
    end

    function selectplants(object,~)
        if str2num(object.Tag)~=-1
            temp_id=str2num(object.Tag(1));
            temp_type=str2num(object.Tag(2:end));
            switch 1
                case onhand==0,onhand=temp_type;
                case onhand~=0,onhand=0;set(DrawScoopHdl,'alphaData',flipud(Data.cardbank.Scoop.Alpha));onhandfunc()               
            end
        else
            disp(1)
            switch 1
                case onhand==-1,onhand=0;set(DrawScoopHdl,'alphaData',flipud(Data.cardbank.Scoop.Alpha));onhandfunc() 
                case onhand~=-1,onhand=-1;set(DrawScoopHdl,'alphaData',flipud(Data.cardbank.Scoop.Alpha).*0);onhandfunc()               
            end
        end
    end

    function growplants(object,~)
        temp_id=[str2num(object.Tag(1)),str2num(object.Tag(2))];
        temp_type=str2num(object.Tag(3:end));
        if onhand~=0&&map(temp_id(1),temp_id(2),1)==0&&onhand~=-1&&energy>=Data.(list{onhand+1}).Cost
            energy=energy-Data.(list{onhand+1}).Cost;
            set(TextEnergyHdl,'string',num2str(energy));
            map(temp_id(1),temp_id(2),1)=onhand;
            map(temp_id(1),temp_id(2),2)=1;
            onhand=0;
            onhandfunc()
        end
        if onhand==-1&&map(temp_id(1),temp_id(2),1)~=0
            map(temp_id(1),temp_id(2),1)=0;
            onhand=0;
            set(DrawScoopHdl,'alphaData',flipud(Data.cardbank.Scoop.Alpha));
            onhandfunc()
        end
    end

%==========================================================================
    function PvZgame(~,~) 
        sunControlTimer=sunControlTimer+1;
        for i=1:bkg.MapSize(stagenumber,1)
            for j=1:bkg.MapSize(stagenumber,2)
                set(DrawSunProducedHdl(i,j),...
                'CData',flipud(sun.CDataNan(:,:,:,mod(sunControlTimer,sun.Len)+1)));
                map(i,j,2)=map(i,j,2)+1;
                temp_time=map(i,j,2);
                temp_type=list{map(i,j,1)+1};
                temp_len=Data.(temp_type).Len;
                temp_size=Data.(temp_type).Size;
                temp_Cdata=Data.(temp_type).Sprite(:,:,:,mod(floor(temp_time),temp_len)+1);
                temp_Alpha=Data.(temp_type).Alpha(:,:,mod(floor(temp_time),temp_len)+1);
                if map(i,j,1)==2
                    temp_time=mod(temp_time,180);
                    set(DrawPlantsHdl(i,j),'XData',[0 temp_size(1)]+zeroplace(1)+(j-1)*(gridsize(1))+min(j,6)*gridsize(4),...
                                       'YData',[0 temp_size(2)]+zeroplace(2)+(i-1)*(gridsize(3))+min(j,6)*gridsize(2),...
                                       'CData',flipud(temp_Cdata).*(1+max(0,temp_time-120)*0.01),...
                                       'alphaData',flipud(temp_Alpha));
                    if temp_time==50
                        set(DrawSunProducedHdl(i,j),'visible','off');
                        temp_pos=[zeroplace(1)+(j-1)*(gridsize(1))+min(j,6)*gridsize(4),...
                        zeroplace(2)+(i-1)*(gridsize(3))+min(j,6)*gridsize(2)]; 
                        [temp_x,temp_y]=meshgrid(1:sun.Size(1),1:sun.Size(2));      
                        set(DrawSunProducedHdl(i,j),'XData',temp_x+temp_pos(1),...
                                                    'YData',temp_y+temp_pos(2));
                    end
                    if temp_time==179
                        producesun([i j])
                    end
                else
                    set(DrawPlantsHdl(i,j),'XData',[0 temp_size(1)]+zeroplace(1)+(j-1)*(gridsize(1))+min(j,6)*gridsize(4),...
                                       'YData',[0 temp_size(2)]+zeroplace(2)+(i-1)*(gridsize(3))+min(j,6)*gridsize(2),...
                                       'CData',flipud(temp_Cdata),...
                                       'alphaData',flipud(temp_Alpha)); 
                end
            end
        end
        %==================================================================
        
        
        if mod(sunControlTimer,160)==0
            set(DrawSunHdl,'visible','on')
            temp_pos=[randi(bkg.MapSize(stagenumber,1)),randi(bkg.MapSize(stagenumber,2))];
            sunTargetPos=[zeroplace(1)+(temp_pos(2)-1)*(gridsize(1))+min(temp_pos(2),6)*gridsize(4),...
                          zeroplace(2)+(temp_pos(1)-1)*(gridsize(3))+min(temp_pos(2),6)*gridsize(2)]+randi(50,[1 2]);
            sunPos=sunTargetPos+[0 600];
        end
        if sum(abs(sunPos-sunTargetPos))>1
            sunPos=sunPos-[0 5];
        end
        [temp_x,temp_y]=meshgrid(1:sun.Size(1),1:sun.Size(2)); 
        set(DrawSunHdl,'XData',temp_x+sunPos(1),...
                       'YData',temp_y+sunPos(2),...
                       'CData',flipud(sun.CDataNan(:,:,:,mod(sunControlTimer,sun.Len)+1)));
        
       %==================================================================
    end





end