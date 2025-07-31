clear
clc

load my_infer_log\my_infer_log.mat %
% load Inference_Physformer_TDC07_sharp2_hid96_head4_layer12_VIPL\Inference_Physformer_TDC07_sharp2_hid96_head4_layer12_VIPL.mat 

% GT_list = importdata('VIPL_fold1_test1.txt');

total_samples = length(outputs_rPPG_concat);

HR_peaks = [];
HR_PSD = [];
% HR_GT = [];

signal =  double(outputs_rPPG_concat);

% framerate = GT_list.data(1,2);
% GT_HR = GT_list.data(1,3);
framerate = 30;

disp(framerate)
disp(length(signal))

%    signal_filtered = signal;
signal_filtered = bpfilter64(signal, framerate);
signal_filtered = (signal_filtered-mean(signal_filtered))/std(signal_filtered);


   
%% PSD for HR 
%     % Single long clip
%    [Pg,f] = pwelch(signal_filtered,[],[],2^13,framerate);
%     Frange = find(f>0.7&f<3); % consider the frequency within [0.7Hz, 4Hz].
%     idxG = Pg == max(Pg(Frange));
%     HR2 = f(idxG)*60;

%     % Separate into three clips
signal_length = length(signal_filtered);
[Pg,f] = pwelch(signal_filtered(1:floor(signal_length/3)),[],[],2^13,framerate);
Frange = find(f>0.7&f<4); % consider the frequency within [0.7Hz, 4Hz].
idxG = Pg == max(Pg(Frange));
HR2_1 = f(idxG)*60;
[Pg,f] = pwelch(signal_filtered(floor(signal_length/3):2*floor(signal_length/3)),[],[],2^13,framerate);
Frange = find(f>0.7&f<4); % consider the frequency within [0.7Hz, 4Hz].
idxG = Pg == max(Pg(Frange));
HR2_2 = f(idxG)*60;
[Pg,f] = pwelch(signal_filtered(2*floor(signal_length/3):signal_length),[],[],2^13,framerate);
Frange = find(f>0.7&f<4); % consider the frequency within [0.7Hz, 4Hz].
idxG = Pg == max(Pg(Frange));
HR2_3 = f(idxG)*60;
HR2 = (HR2_1+HR2_2+HR2_3)/3;

% HR_peaks = [HR_peaks; HR1];
HR_PSD = [HR_PSD; HR2];
% HR_GT = [HR_GT; GT_HR];




%% calculate ErrorMean, ErrorSD, RMSE, R

% Error_PSD = HR_PSD - HR_GT;
% MAE = abs(Error_PSD)


% [HR_PSD; HR2]
% [HR_GT; GT_HR]


% 可视化 rPPG 信号
figure;
subplot(2,1,1);
plot(signal, 'b'); hold on;
plot(signal_filtered, 'r');
legend('Raw rPPG', 'Filtered rPPG');
title('rPPG Signal (Raw & Filtered)');
xlabel('Frame');
ylabel('Amplitude');

% 可视化 PSD
[Pg_all, f_all] =  pwelch(signal_filtered,[],[],2^13,framerate);
subplot(2,1,2);
plot(f_all, Pg_all);
xlim([0 5]);
title('Power Spectral Density of rPPG');
xlabel('Frequency (Hz)');
ylabel('PSD');
hold on;
[~, idx_max] = max(Pg_all(f_all>0.7 & f_all<4));
f_range = f_all(f_all>0.7 & f_all<4);
if ~isempty(f_range)
    hr_pred = f_range(idx_max) * 60;
    xline(hr_pred/60, 'r--', ['Pred HR: ' num2str(hr_pred, '%.1f') ' bpm']);
end

% 打印预测心率
disp(['HR_PSD (3段均值): ' num2str(HR2, '%.2f') ' bpm']);
% disp(['GT_HR: ' num2str(GT_HR, '%.2f') ' bpm']);