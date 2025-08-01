clear
clc

function batch_infer_and_save(folder_list)
% 批量处理 rPPG/HR 推理结果并保存分析图片
for i = 1:length(folder_list)
    folder = folder_list{i};
    try
        mat_file = fullfile(folder, [folder, '.mat']);
        gt_file = fullfile(folder, 'gt.txt');
        if ~isfile(mat_file) || ~isfile(gt_file)
            fprintf('跳过 %s，缺少数据文件\n', folder);
            continue;
        end

        load(mat_file); % 加载 outputs_rPPG_concat
        GT_list = importdata(gt_file);
        signal = double(outputs_rPPG_concat);
        framerate = GT_list.data(1,2);

        signal_filtered = bpfilter64(signal, framerate);
        signal_filtered = (signal_filtered-mean(signal_filtered))/std(signal_filtered);

        % HR 计算（略，参考原脚本）

        % 创建保存目录
        save_dir = fullfile(folder, 'results');
        if ~exist(save_dir, 'dir')
            mkdir(save_dir);
        end

        % 可视化并保存 rPPG 信号
        fig1 = figure('Visible', 'off');
        subplot(2,1,1);
        plot(signal, 'b'); hold on;
        plot(signal_filtered, 'r');
        legend('Raw rPPG', 'Filtered rPPG');
        title('rPPG Signal (Raw & Filtered)');
        xlabel('Frame'); ylabel('Amplitude');
        % PSD
        [Pg_all, f_all] = pwelch(signal_filtered,[],[],2^13,framerate);
        subplot(2,1,2);
        plot(f_all, Pg_all);
        xlim([0 5]);
        title('Power Spectral Density of rPPG');
        xlabel('Frequency (Hz)'); ylabel('PSD');
        hold on;
        [~, idx_max] = max(Pg_all(f_all>0.7 & f_all<4));
        f_range = f_all(f_all>0.7 & f_all<4);
        if ~isempty(f_range)
            hr_pred = f_range(idx_max) * 60;
            xline(hr_pred/60, 'r--', ['Pred HR: ' num2str(hr_pred, '%.1f') ' bpm']);
        end
        saveas(fig1, fullfile(save_dir, 'rPPG_PSD.png'));
        close(fig1);

        % 分段可视化并保存
        signal_length = length(signal_filtered);
        seg_len = floor(signal_length/3);
        fig2 = figure('Visible', 'off');
        for seg = 1:3
            if seg == 1
                idx = 1:seg_len;
            elseif seg == 2
                idx = seg_len+1:2*seg_len;
            else
                idx = 2*seg_len+1:signal_length;
            end
            subplot(3,2,2*seg-1);
            plot(signal(idx), 'b'); hold on;
            plot(signal_filtered(idx), 'r');
            legend('Raw rPPG', 'Filtered rPPG');
            title(['Segment ' num2str(seg) ' rPPG']);
            xlabel('Frame'); ylabel('Amplitude');
            [Pg_seg, f_seg] = pwelch(signal_filtered(idx),[],[],2^13,framerate);
            subplot(3,2,2*seg);
            plot(f_seg, Pg_seg);
            xlim([0 5]);
            title(['Segment ' num2str(seg) ' PSD']);
            xlabel('Frequency (Hz)'); ylabel('PSD');
            hold on;
            [~, idx_max] = max(Pg_seg(f_seg>0.7 & f_seg<4));
            f_range = f_seg(f_seg>0.7 & f_seg<4);
            if ~isempty(f_range)
                hr_pred = f_range(idx_max) * 60;
                xline(hr_pred/60, 'r--', ['Pred HR: ' num2str(hr_pred, '%.1f') ' bpm']);
            end
        end
        saveas(fig2, fullfile(save_dir, 'rPPG_PSD_segments.png'));
        close(fig2);

        fprintf('已处理并保存: %s\n', folder);
    catch ME
        fprintf('处理过程中出错: %s\n', ME.message);
        for k = 1:length(ME.stack)
            fprintf('> %s (第%d行)\n', ME.stack(k).file, ME.stack(k).line);
        end
    end
    end
end



% 自动收集所有 *_person_0 文件夹
folders = dir;
folder_list = {};
for i = 1:length(folders)
    if folders(i).isdir && (endsWith(folders(i).name, '_person_0') || startsWith(folders(i).name, '2025') || startsWith(folders(i).name, 'my_infer'))
        folder_list{end+1} = folders(i).name;
    end
end

% folder_list = {
%     % 'downloaded_video.mp4_person_0'
%     % 'my_infer_log_60'
%     'Inference_Physformer_TDC07_sharp2_hid96_head4_layer12_VIPL'
% };

batch_infer_and_save(folder_list);