# 批量测试不同 clip_frames 参数下的推理效果
$inputFolder = "C:\Users\LMAPA\Documents\GitHub\Unity-Quest3-EVM\UDPServer\20250320_151150\person_0"
$clipFramesList = @(60, 120, 180, 240, 300, 600)

# 切换到模型脚本目录
Push-Location "C:\Users\LMAPA\Documents\GitHub\vision-black-tech\PhysFormer"

foreach ($clip in $clipFramesList) {
    $logname = "my_infer_log_clip$clip"
    python "inference_OneSample_VIPL_PhysFormer_shy.py" --input_data "$inputFolder" --log "$logname" --clip_frames "$clip"
}

Pop-Location
