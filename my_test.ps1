# 进入 UDPServer 目录
cd "C:\Users\LMAPA\Documents\GitHub\Unity-Quest3-EVM\UDPServer"

# 遍历所有子文件夹，自动运行推理脚本
Get-ChildItem -Directory | ForEach-Object {
    $folder = $_.FullName
    $logname = $_.Name + "_person_0"
    $personFolder = Join-Path $_.FullName "person_0"

    # 切换到模型脚本目录再运行
    Push-Location "C:\Users\LMAPA\Documents\GitHub\vision-black-tech\PhysFormer"
    python "inference_OneSample_VIPL_PhysFormer_shy.py" --input_data "$personFolder" --log "$logname"
    Pop-Location
}
