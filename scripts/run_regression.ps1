# Automated Regression Runner (Icarus Verilog)
$ErrorActionPreference = "Continue"
$iv  = "C:\Users\arsha\iverilog_ext\app\bin\iverilog.exe"
$vvp = "C:\Users\arsha\iverilog_ext\app\bin\vvp.exe"

$rtl = (Get-ChildItem "d:\hcl project axi liteburst\rtl\*.v").FullName
$tbs = Get-ChildItem "d:\hcl project axi liteburst\tb\*.v" | Sort-Object Name
$logFile = "d:\hcl project axi liteburst\sim\regression.log"
"=== AXI-LiteBurst-32 Regression Log ===" | Out-File $logFile -Encoding utf8

$passed = 0
$failed = 0

foreach ($tb in $tbs) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($tb.Name)
    $outVvp = "d:\hcl project axi liteburst\sim\$name.vvp"
    $compOut = & $iv -Wall -g2005 -s $name -o $outVvp $rtl $tb.FullName 2>&1
    $compOut | Out-File $logFile -Encoding utf8 -Append
    if ($LASTEXITCODE -ne 0) {
        Write-Output "COMPILE FAIL: $name"
        $failed++
        continue
    }
    $simOut = & $vvp $outVvp 2>&1
    $simOut | Out-File $logFile -Encoding utf8 -Append
    $simOut | ForEach-Object { Write-Output $_ }
    if ($LASTEXITCODE -ne 0 -or ($simOut -match "FAIL")) {
        Write-Output "SIM FAIL: $name"
        $failed++
    } else {
        Write-Output "SIM PASS: $name"
        $passed++
    }
}

"REGRESSION TOTAL: passed=$passed failed=$failed" | Out-File $logFile -Encoding utf8 -Append
Write-Output "REGRESSION TOTAL: passed=$passed failed=$failed"
if ($failed -gt 0) { exit 1 }
