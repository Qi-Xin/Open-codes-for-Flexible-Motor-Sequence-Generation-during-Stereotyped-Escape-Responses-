clearvars
minnum = 3;
backtimemax = 10000;
frame = 100;
smoothpara = 40;
trial = 9;
gcamp_ref = cell(1,trial);
gcamp_ori = cell(1,trial);
ratio = cell(1,trial);
ratio_smo = cell(1,trial);
smo = cell(1,trial);
time = cell(1,trial);
time_full = cell(1,trial);
for i = 1:trial
    temp = xlsread('datacb.xlsx',i);
    gcamp_ref{i} = temp(:,1);
    gcamp_ori{i} = temp(:,2);
    ratio{i} = temp(:,2)./temp(:,1);
    time{i} = xlsread('timecb.xlsx',i);
end

%%

totaltime = length(gcamp_ref{1});
for i = 1:trial
    ratio_smo{i} = smooth(ratio{i},smoothpara);
	NotANum = isnan(ratio{i});
    NaNPos = find( NotANum ==1 );
    for j = 1:length( NaNPos )
        ratio_smo{i}( NaNPos(j) ) = NaN;
    end
    %mintemp = min(ratio_smo{i});
    %maxtemp = max(ratio_smo{i});
    %smo{i} = ( ratio_smo{i} - mintemp ) ./ mintemp ;
    smo{i} = ratio_smo{i};
end

%% single trial normalization

n = 0;
n_1 = 0;
n_2 = 0;
for i = 1:trial
    for j = 1:size(time{i},2)
        n = n+1;
        if isnan(time{i}(3,j))
            if j ~= size(time{i},2)
                tt = time{i}(1,j):(time{i}(1,j+1)-1);
            else
                tt = time{i}(1,j):(time{i}(2,j)+4*frame);
            end
            n_1 = n_1 + 1;
        else
            tt = time{i}(1,j):time{i}(3,j);
            n_2 = n_2 + 1;
        end
        temp = min(smo{i}(tt));
        smo{i}(tt) = ( smo{i}(tt) - temp ) ./ temp;
        ratio{i}(tt) = ( ratio{i}(tt) - temp ) ./ temp;
    end
end

individual_trial = n;

%{
for i = 1:trial
    temp = min(smo{1});
    smo{i} = ( smo{i} - temp ) ./ temp;
    ratio{i} = ( ratio{i} - temp ) ./ temp;
end
%}
%%
turn = cell(1,backtimemax);
back = cell(1,backtimemax);
heatmap = NaN*zeros(individual_trial+1,2*backtimemax-1);
noturnN = 0;
turnN = n_1;
for i = 1:trial
    for j = 1:size(time{i},2)
        %if isnan(time{i}(3,j)) ~= 0
            
            if isnan(time{i}(3,j)) == 1
                noturnN = noturnN+1;
                n = noturnN;
                plot_t = (time{i}(2,j)):(time{i}(2,j)+4*frame);
            else
                turnN = turnN+1;
                n = turnN;
                plot_t = (time{i}(2,j)):(time{i}(3,j));
            end
            % turn开始之后，turn中
            
            for t = plot_t
                backtime = t-time{i}(2,j)+1;
                if isnan(smo{i}(t)) == 0
                    %turn{backtime} = [turn{backtime},smo{i}(t)];
                    turn{backtime} = [turn{backtime},smo{i}(t)-smo{i}(time{i}(2,j))];
                    %heatmap(n,backtime+backtimemax) = smo{i}(t);
                    heatmap(n,backtime+backtimemax) = smo{i}(t)-smo{i}(time{i}(2,j));
                end
            end
            % turn开始之前，reversal中
            for t = (time{i}(2,j)):(-1):time{i}(1,j)
                backtime = time{i}(2,j)-t+1;
                if isnan(smo{i}(t)) == 0
                    %back{backtime} = [back{backtime},smo{i}(t)];
                    back{backtime} = [back{backtime},smo{i}(t)-smo{i}(time{i}(2,j))];
                    %heatmap(n,backtimemax+1-backtime) = smo{i}(t);
                    heatmap(n,backtimemax+1-backtime) = smo{i}(t)-smo{i}(time{i}(2,j));
                end
            end

        %end
    end
end

figure
hold on

smoback = zeros(1,backtimemax);
smobackstd = zeros(1,backtimemax);
for t = 1:backtimemax
    smoback(t) = mean(turn{t});
    smobackstd(t) = std(turn{t})/sqrt(length(turn{t}));
    if length(turn{t}) >= minnum
        backtimevis = t;
    end
end
backtimevis = min(4*frame,backtimevis);
smoback_up = smoback + smobackstd;
smoback_low = smoback - smobackstd;
plot([((1:backtimevis)-1)/frame],[smoback(1:backtimevis)],'r');
fill([((1:backtimevis)-1)/frame fliplr(((1:backtimevis)-1)/frame)],[smoback_low(1:backtimevis) fliplr(smoback_up(1:backtimevis))],'r','facealpha',0.2,'edgealpha',0,'handlevisibility','off');

smoback = zeros(1,backtimemax);
smobackstd = zeros(1,backtimemax);
for t = 1:backtimemax
    smoback(t) = mean(back{t});
    smobackstd(t) = std(back{t})/sqrt(length(back{t}));
    if length(back{t}) >= minnum
        backtimevis = t;
    end
end
backtimevis = min(4*frame,backtimevis);
smoback_up = smoback + smobackstd;
smoback_low = smoback - smobackstd;
plot(fliplr(((1:backtimevis)-backtimevis)/frame),smoback(1:backtimevis),'r','handlevisibility','off');
fill([fliplr(((1:backtimevis)-backtimevis)/frame) ((1:backtimevis)-backtimevis)/frame],[smoback_low(1:backtimevis) fliplr(smoback_up(1:backtimevis))],'r','facealpha',0.2,'edgealpha',0,'handlevisibility','off');

title('RIB GCaMP before and after reversal ends');
xlabel('t/s');
ylabel('dR/R0');

%% heat map
figure
hold on
gca = pcolor(heatmap(:,(backtimemax-3*frame):(backtimemax+3*frame)));
%caxis([-0.02 1]);
set(gca,'LineStyle','none');
colorbar;
title('RIB GCaMP before and after reversal ends');
xlabel('t/s');
ylabel('trial');
plot([3*frame,3*frame],[1,individual_trial],'--w');
plot([1,6*frame],[n_1+1,n_1+1],'r');
axis([0 6*frame 1 individual_trial+1]);
xticks([1 100 200 300 400 500 600]);
xticklabels({'-3','-2','-1','0','1','2','3'});
colormap('jet');

%% single trial
figure

noturnN = 0;
turnN = 45;
for i = 1:trial
    for j = 1:size(time{i},2)
        if isnan(time{i}(3,j)) == 0
            turnN = turnN+1;
            n = turnN;
            subplot(8,9,n);
            hold on
            tt = ( 0:( time{i}(3,j) - time{i}(1,j) ) )/frame;
            plot( tt ,smo{i}(time{i}(1,j):time{i}(3,j)),'b');
            plot( tt ,ratio{i}(time{i}(1,j):time{i}(3,j)),'b:');
            plot( [(time{i}(2,j) - time{i}(1,j))/frame,(time{i}(2,j) - time{i}(1,j))/frame],[-10,10],'r');
        else
            noturnN = noturnN+1;
            n = noturnN;
            subplot(8,9,n);
            hold on
            if j ~= size(time{i},2)
                endtime = min((time{i}(2,j)+3*frame),(time{i}(1,j+1)-1));
            else
                endtime = (time{i}(2,j)+3*frame);
            end
            tt = ( 0:( endtime - time{i}(1,j) ) )/frame;
            plot( tt ,smo{i}(time{i}(1,j):endtime),'b');
            plot( tt ,ratio{i}(time{i}(1,j):endtime),'b:');
            plot( [(time{i}(2,j) - time{i}(1,j))/frame,(time{i}(2,j) - time{i}(1,j))/frame],[-10,10],'g');
        end
        axis([0 7 -0.1 1.5]);
    end
end

%{
subplot(8,9,3);axis([0 7 -0.1 1.5]);
subplot(8,9,19);axis([0 7 -0.1 1.5]);
subplot(8,9,48);axis([0 7 -0.1 1.5]);
subplot(8,9,51);axis([0 10 -0.1 1.5]);
subplot(8,9,52);axis([0 20 -0.1 2]);
subplot(8,9,54);axis([0 15 -0.1 2]);
subplot(8,9,57);axis([0 7 -0.1 1.5]);
subplot(8,9,59);axis([0 7 -0.1 1.5]);
subplot(8,9,61);axis([0 7 -0.1 1.5]);
subplot(8,9,62);axis([0 7 -0.1 1]);
subplot(8,9,70);axis([0 15 -0.1 1.5]);
subplot(8,9,67);axis([0 15 -0.1 1.5]);
subplot(8,9,46);legend('smoothed data','raw data','turn starts');
subplot(8,9,1);legend('smoothed data','raw data','reversal starts');
%}