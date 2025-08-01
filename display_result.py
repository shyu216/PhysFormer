"""
revised from Inference_HRevaluation_shy.m
"""

import os
import numpy as np
import scipy.io
import scipy.signal
import matplotlib.pyplot as plt

def bpfilter64(signal, fs):
    minfq = 0.8 / (fs / 2)
    maxfq = 3 / (fs / 2)
    if maxfq >= 1:
        fs = 15
        minfq = 0.8 / (fs / 2)
        maxfq = 3 / (fs / 2)
        print('maxfq 超出范围，设置 fs 为 15Hz')
    fir1_len = max(3, int(len(signal) / 10))
    b = scipy.signal.firwin(fir1_len, [minfq, maxfq], pass_zero=False)
    filtered = scipy.signal.filtfilt(b, [1], signal)
    return filtered

def batch_infer_and_save(folder_list):
    for folder in folder_list:
        try:
            mat_file = os.path.join(folder, f"{folder}.mat")
            gt_file = os.path.join(folder, "gt.txt")
            if not os.path.isfile(mat_file) or not os.path.isfile(gt_file):
                print(f"跳过 {folder}，缺少数据文件")
                continue

            mat = scipy.io.loadmat(mat_file)
            outputs_rPPG_concat = mat.get('outputs_rPPG_concat')
            if outputs_rPPG_concat is None:
                print(f"{mat_file} 缺少 outputs_rPPG_concat")
                continue
            signal = outputs_rPPG_concat.squeeze().astype(float)
            print(f"处理文件: {mat_file}, 信号长度: {len(signal)}")

            # 修复 gt.txt 包含字符串导致读取失败的问题
            framerate = None
            with open(gt_file, 'r') as f:
                for line in f:
                    parts = line.strip().split()
                    # 查找包含至少两个数字的行
                    nums = [p for p in parts if p.replace('.', '', 1).isdigit()]
                    if len(nums) >= 2:
                        framerate = float(nums[1])
                        break
            if framerate is None:
                print(f"{gt_file} 未找到有效帧率，跳过")
                continue

            signal_filtered = bpfilter64(signal, framerate)
            signal_filtered = (signal_filtered - np.mean(signal_filtered)) / np.std(signal_filtered)

            save_dir = os.path.join(folder, 'results')
            os.makedirs(save_dir, exist_ok=True)

            # 可视化并保存 rPPG 信号
            fig1, axs = plt.subplots(2, 1, figsize=(10, 8))
            axs[0].plot(signal, 'b', label='Raw rPPG')
            axs[0].plot(signal_filtered, 'r', label='Filtered rPPG')
            axs[0].legend()
            axs[0].set_title('rPPG Signal (Raw & Filtered)')
            axs[0].set_xlabel('Frame')
            axs[0].set_ylabel('Amplitude')

            f_all, Pg_all = scipy.signal.welch(signal_filtered, fs=framerate, nperseg=2**13)
            axs[1].plot(f_all, Pg_all)
            axs[1].set_xlim([0, 5])
            axs[1].set_title('Power Spectral Density of rPPG')
            axs[1].set_xlabel('Frequency (Hz)')
            axs[1].set_ylabel('PSD')
            mask = (f_all > 0.7) & (f_all < 4)
            if np.any(mask):
                idx_max = np.argmax(Pg_all[mask])
                f_range = f_all[mask]
                hr_pred = f_range[idx_max] * 60
                axs[1].axvline(hr_pred / 60, color='r', linestyle='--', label=f'Pred HR: {hr_pred:.1f} bpm')
                axs[1].legend()
            plt.tight_layout()
            plt.savefig(os.path.join(save_dir, 'rPPG_PSD.png'))
            plt.close(fig1)
            

            # 分段可视化并保存
            signal_length = len(signal_filtered)
            seg_len = signal_length // 3
            fig2, axs2 = plt.subplots(3, 2, figsize=(12, 12))
            for seg in range(3):
                if seg == 0:
                    idx = slice(0, seg_len)
                elif seg == 1:
                    idx = slice(seg_len, 2 * seg_len)
                else:
                    idx = slice(2 * seg_len, signal_length)
                axs2[seg, 0].plot(signal[idx], 'b', label='Raw rPPG')
                axs2[seg, 0].plot(signal_filtered[idx], 'r', label='Filtered rPPG')
                axs2[seg, 0].legend()
                axs2[seg, 0].set_title(f'Segment {seg+1} rPPG')
                axs2[seg, 0].set_xlabel('Frame')
                axs2[seg, 0].set_ylabel('Amplitude')

                f_seg, Pg_seg = scipy.signal.welch(signal_filtered[idx], fs=framerate, nperseg=2**13)
                axs2[seg, 1].plot(f_seg, Pg_seg)
                axs2[seg, 1].set_xlim([0, 5])
                axs2[seg, 1].set_title(f'Segment {seg+1} PSD')
                axs2[seg, 1].set_xlabel('Frequency (Hz)')
                axs2[seg, 1].set_ylabel('PSD')
                mask = (f_seg > 0.7) & (f_seg < 4)
                if np.any(mask):
                    idx_max = np.argmax(Pg_seg[mask])
                    f_range = f_seg[mask]
                    hr_pred = f_range[idx_max] * 60
                    axs2[seg, 1].axvline(hr_pred / 60, color='r', linestyle='--', label=f'Pred HR: {hr_pred:.1f} bpm')
                    axs2[seg, 1].legend()
            plt.tight_layout()
            plt.savefig(os.path.join(save_dir, 'rPPG_PSD_segments.png'))
            plt.close(fig2)
            # plt.show()

            print(f'已处理并保存: {folder}')
        except Exception as e:
            print(f'处理过程中出错: {e}')

if __name__ == '__main__':
    # 自动收集所有 *_person_0 文件夹
    # folder_list = [f for f in os.listdir('.') if os.path.isdir(f) and (f.endswith('_person_0') or f.startswith('2025') or f.startswith('my_infer'))]
    
    folder_list = [f for f in os.listdir('.') if os.path.isdir(f) and (f.startswith('my_infer_log_clip'))]
    # 或手动指定
    # folder_list = ['downloaded_video.mp4_person_0']
    batch_infer_and_save(folder_list)