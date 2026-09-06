Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- 檢查 yt-dlp ---
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$localExe = Join-Path $scriptDir "yt-dlp.exe"
if (Test-Path $localExe) { $ytdlp = $localExe }
else { $ytdlp = (Get-Command yt-dlp -ErrorAction SilentlyContinue).Source }
if (-not $ytdlp) {
    [System.Windows.Forms.MessageBox]::Show("找不到 yt-dlp！請先安裝，或將執行檔放在此腳本所在資料夾。", "錯誤", "OK", "Error")
    exit 1
}

# --- 建立表單 ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "yt-dlp 下載器"
$form.Size = New-Object System.Drawing.Size(520, 550)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# --- 控制項 ---
$lblMode = New-Object System.Windows.Forms.Label
$lblMode.Location = New-Object System.Drawing.Point(15, 20)
$lblMode.Size = New-Object System.Drawing.Size(80, 20)
$lblMode.Text = "下載模式："

$cmbMode = New-Object System.Windows.Forms.ComboBox
$cmbMode.Location = New-Object System.Drawing.Point(95, 17)
$cmbMode.Size = New-Object System.Drawing.Size(70, 20)
$cmbMode.DropDownStyle = "DropDownList"
$cmbMode.Items.AddRange(@("音訊", "影片"))

$lblFormat = New-Object System.Windows.Forms.Label
$lblFormat.Location = New-Object System.Drawing.Point(175, 20)
$lblFormat.Size = New-Object System.Drawing.Size(50, 20)
$lblFormat.Text = "格式："

$cmbFormat = New-Object System.Windows.Forms.ComboBox
$cmbFormat.Location = New-Object System.Drawing.Point(225, 17)
$cmbFormat.Size = New-Object System.Drawing.Size(80, 20)
$cmbFormat.DropDownStyle = "DropDownList"

# 音訊 / 影片專用選項面板
$pnlAudio = New-Object System.Windows.Forms.Panel
$pnlAudio.Location = New-Object System.Drawing.Point(15, 50)
$pnlAudio.Size = New-Object System.Drawing.Size(480, 30)

$lblAudioQuality = New-Object System.Windows.Forms.Label
$lblAudioQuality.Location = New-Object System.Drawing.Point(0, 5)
$lblAudioQuality.Size = New-Object System.Drawing.Size(80, 20)
$lblAudioQuality.Text = "音訊品質："
$cmbAudioFormat = New-Object System.Windows.Forms.ComboBox
$cmbAudioFormat.Location = New-Object System.Drawing.Point(80, 2)
$cmbAudioFormat.Size = New-Object System.Drawing.Size(80, 20)
$cmbAudioFormat.DropDownStyle = "DropDownList"
$cmbAudioFormat.Items.AddRange(@("flac", "wav", "mp3"))
$cmbAudioFormat.SelectedIndex = 0
$pnlAudio.Controls.AddRange(@($lblAudioQuality, $cmbAudioFormat))

$pnlVideo = New-Object System.Windows.Forms.Panel
$pnlVideo.Location = New-Object System.Drawing.Point(15, 50)
$pnlVideo.Size = New-Object System.Drawing.Size(480, 55)
$pnlVideo.Visible = $false

$lblContainer = New-Object System.Windows.Forms.Label
$lblContainer.Location = New-Object System.Drawing.Point(0, 5)
$lblContainer.Size = New-Object System.Drawing.Size(50, 20)
$lblContainer.Text = "容器："
$cmbContainer = New-Object System.Windows.Forms.ComboBox
$cmbContainer.Location = New-Object System.Drawing.Point(50, 2)
$cmbContainer.Size = New-Object System.Drawing.Size(80, 20)
$cmbContainer.DropDownStyle = "DropDownList"
$cmbContainer.Items.AddRange(@("mp4", "mkv", "webm", "avi", "wmv", "mov"))
$cmbContainer.SelectedIndex = 0

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Location = New-Object System.Drawing.Point(145, 5)
$lblSub.Size = New-Object System.Drawing.Size(60, 20)
$lblSub.Text = "字幕："
$txtSub = New-Object System.Windows.Forms.TextBox
$txtSub.Location = New-Object System.Drawing.Point(205, 2)
$txtSub.Size = New-Object System.Drawing.Size(120, 20)
$txtSub.Text = "zh-Hant,en"
$pnlVideo.Controls.AddRange(@($lblContainer, $cmbContainer, $lblSub, $txtSub))

$form.Controls.AddRange(@($pnlAudio, $pnlVideo))

# 網址
$lblURL = New-Object System.Windows.Forms.Label
$lblURL.Location = New-Object System.Drawing.Point(15, 110)
$lblURL.Size = New-Object System.Drawing.Size(80, 20)
$lblURL.Text = "網址："
$txtURL = New-Object System.Windows.Forms.TextBox
$txtURL.Location = New-Object System.Drawing.Point(100, 107)
$txtURL.Size = New-Object System.Drawing.Size(390, 20)

# 多執行緒
$lblThreads = New-Object System.Windows.Forms.Label
$lblThreads.Location = New-Object System.Drawing.Point(15, 140)
$lblThreads.Size = New-Object System.Drawing.Size(100, 20)
$lblThreads.Text = "同時下載數："
$numThreads = New-Object System.Windows.Forms.NumericUpDown
$numThreads.Location = New-Object System.Drawing.Point(115, 137)
$numThreads.Size = New-Object System.Drawing.Size(60, 20)
$numThreads.Minimum = 0
$numThreads.Maximum = 16
$numThreads.Value = 0
$lblThreadsNote = New-Object System.Windows.Forms.Label
$lblThreadsNote.Location = New-Object System.Drawing.Point(180, 140)
$lblThreadsNote.Size = New-Object System.Drawing.Size(200, 20)
$lblThreadsNote.Text = "(0 = 單線程，建議 4~8)"

# 選項勾選框
$chkSSL = New-Object System.Windows.Forms.CheckBox
$chkSSL.Location = New-Object System.Drawing.Point(15, 170)
$chkSSL.Size = New-Object System.Drawing.Size(180, 20)
$chkSSL.Text = "略過 SSL 憑證檢查"

$chkEmbed = New-Object System.Windows.Forms.CheckBox
$chkEmbed.Location = New-Object System.Drawing.Point(200, 170)
$chkEmbed.Size = New-Object System.Drawing.Size(180, 20)
$chkEmbed.Text = "嵌入縮圖與中繼資料"
$chkEmbed.Checked = $true

$chkDirectWrite = New-Object System.Windows.Forms.CheckBox
$chkDirectWrite.Location = New-Object System.Drawing.Point(15, 195)
$chkDirectWrite.Size = New-Object System.Drawing.Size(180, 20)
$chkDirectWrite.Text = "使用直接寫入模式"

# 開始按鈕
$btnDownload = New-Object System.Windows.Forms.Button
$btnDownload.Location = New-Object System.Drawing.Point(15, 230)
$btnDownload.Size = New-Object System.Drawing.Size(100, 30)
$btnDownload.Text = "開始下載"

# 停止按鈕
$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Location = New-Object System.Drawing.Point(130, 230)
$btnStop.Size = New-Object System.Drawing.Size(100, 30)
$btnStop.Text = "停止下載"
$btnStop.Enabled = $false

# 輸出記錄區
$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(15, 270)
$txtLog.Size = New-Object System.Drawing.Size(475, 200)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true

# 加入表單
$form.Controls.AddRange(@(
    $lblMode, $cmbMode, $lblFormat, $cmbFormat,
    $lblURL, $txtURL,
    $lblThreads, $numThreads, $lblThreadsNote,
    $chkSSL, $chkEmbed, $chkDirectWrite,
    $btnDownload, $btnStop, $txtLog
))

# --- 切換模式事件 ---
$cmbMode.Add_SelectedIndexChanged({
    if ($cmbMode.SelectedIndex -eq 0) {
        $cmbFormat.Items.Clear()
        $cmbFormat.Items.AddRange(@("flac", "wav", "mp3"))
        $cmbFormat.SelectedIndex = 0
        $pnlAudio.Visible = $true
        $pnlVideo.Visible = $false
    } else {
        $cmbFormat.Items.Clear()
        $cmbFormat.Items.AddRange(@("mp4", "mkv", "webm", "avi", "wmv", "mov"))
        $cmbFormat.SelectedIndex = 0
        $pnlAudio.Visible = $false
        $pnlVideo.Visible = $true
    }
})
$cmbMode.SelectedIndex = 0   # 預設音訊

# --- 全域變數 ---
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100
$global:downloadProcess = $null
$global:logQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
$global:processExited = $false

# 計時器事件：讀取輸出 + 檢查進程結束
$timer.Add_Tick({
    # 讀取佇列
    $line = $null
    while ($global:logQueue.TryDequeue([ref]$line)) {
        $txtLog.AppendText($line)
        $txtLog.ScrollToCaret()
    }

    # 檢查下載是否完成（自然結束）
    if ($global:downloadProcess -ne $null -and !$global:processExited) {
        if ($global:downloadProcess.HasExited) {
            $global:processExited = $true
            $exitCode = $global:downloadProcess.ExitCode
            if ($exitCode -eq 0) {
                $txtLog.AppendText("`r`n全部成功下載！完成！`r`n")
            } else {
                $txtLog.AppendText("`r`n部分影片因錯誤跳過（結束代碼：$exitCode），其餘檔案已儲存。完成！`r`n")
            }
            $txtLog.ScrollToCaret()
            $timer.Stop()
            $btnDownload.Enabled = $true
            $btnStop.Enabled = $false
            $global:downloadProcess.Dispose()
            $global:downloadProcess = $null
            $global:processExited = $false
        }
    }
})

# --- 停止按鈕事件 ---
$btnStop.Add_Click({
    if ($global:downloadProcess -ne $null -and !$global:downloadProcess.HasExited) {
        $global:downloadProcess.Kill()
        $global:processExited = $true
        $txtLog.AppendText("`r`n下載已被使用者停止。`r`n")
        $txtLog.ScrollToCaret()
        $timer.Stop()
        $btnDownload.Enabled = $true
        $btnStop.Enabled = $false
        # 等待一下確保進程完全終止
        $global:downloadProcess.WaitForExit(1000)
        $global:downloadProcess.Dispose()
        $global:downloadProcess = $null
        $global:processExited = $false
    }
})

# --- 開始下載按鈕邏輯 ---
$btnDownload.Add_Click({
    if ($btnDownload.Enabled -eq $false) { return }
    $btnDownload.Enabled = $false
    $btnStop.Enabled = $true
    $txtLog.Clear()
    $global:processExited = $false

    $url = $txtURL.Text.Trim()
    if (-not $url) {
        [System.Windows.Forms.MessageBox]::Show("請輸入網址！", "提示", "OK", "Warning")
        $btnDownload.Enabled = $true
        $btnStop.Enabled = $false
        return
    }

    # 構建參數
    $commonParams = @("--ignore-errors", "--js-runtimes", "deno")

    $sslParam = if ($chkSSL.Checked) { @("--no-check-certificate") } else { @() }
    $embedParams = if ($chkEmbed.Checked) { @("--embed-thumbnail", "--no-write-thumbnail", "--embed-metadata") } else { @() }
    $writeParams = if ($chkDirectWrite.Checked) { @("--no-part") } else { @() }
    
    $threads = $numThreads.Value
    $threadParams = if ($threads -gt 0) { @("-N", $threads.ToString()) } else { @() }

    $mode = $cmbMode.SelectedItem
    $format = $cmbFormat.SelectedItem

    # 動態輸出模板
    if ($url -match "list=") {
        if ($mode -eq "音訊") {
            $output = "OST/%(playlist_title)s/%(playlist_index)02d - %(title)s.%(ext)s"
        } else {
            $output = "VIDEO/%(playlist_title)s/%(playlist_index)02d - %(title)s.%(ext)s"
        }
    } else {
        if ($mode -eq "音訊") {
            $output = "OST/%(title)s.%(ext)s"
        } else {
            $output = "VIDEO/%(title)s.%(ext)s"
        }
    }

    if ($mode -eq "音訊") {
        $args = @(
            $url,
            "-f", "bestaudio",
            "-x", "--audio-format", $format,
            "--audio-quality", "0"
        )
    } else {
        $args = @(
            $url,
            "-f", "bestvideo+bestaudio/best",
            "--merge-output-format", $format
        )
        $subLang = $txtSub.Text.Trim()
        if ($subLang) {
            $args += "--sub-langs"
            $args += $subLang
            $args += "--embed-subs"
        }
    }

    $args += $sslParam
    $args += $threadParams
    $args += $embedParams
    $args += $writeParams
    $args += $commonParams
    $args += "-o"
    $args += $output

    # 記錄命令
    $command = "& '$ytdlp' " + ($args -join ' ')
    $global:logQueue.Enqueue("執行命令：`r`n$command`r`n`r`n")

    # 建立背景進程
    $global:downloadProcess = New-Object System.Diagnostics.Process
    $global:downloadProcess.StartInfo.FileName = $ytdlp

    # 將含空格的參數加上雙引號
    $escapedArgs = foreach ($arg in $args) {
        if ($arg -match '\s') { '"' + $arg + '"' } else { $arg }
    }
    $global:downloadProcess.StartInfo.Arguments = $escapedArgs -join ' '

    $global:downloadProcess.StartInfo.UseShellExecute = $false
    $global:downloadProcess.StartInfo.RedirectStandardOutput = $true
    $global:downloadProcess.StartInfo.RedirectStandardError = $true
    $global:downloadProcess.StartInfo.CreateNoWindow = $true

    $global:downloadProcess.Start() | Out-Null
    $timer.Start()

    # 非同步讀取輸出
    $global:downloadProcess.BeginOutputReadLine()
    $global:downloadProcess.BeginErrorReadLine()

    # 將輸出/錯誤加入佇列
    $outEvent = Register-ObjectEvent -InputObject $global:downloadProcess -EventName OutputDataReceived -Action {
        if (-not [string]::IsNullOrEmpty($EventArgs.Data)) {
            $global:logQueue.Enqueue($EventArgs.Data + "`r`n")
        }
    }
    $errEvent = Register-ObjectEvent -InputObject $global:downloadProcess -EventName ErrorDataReceived -Action {
        if (-not [string]::IsNullOrEmpty($EventArgs.Data)) {
            $global:logQueue.Enqueue("錯誤: " + $EventArgs.Data + "`r`n")
        }
    }
})

# --- 表單關閉事件 ---
$form.Add_FormClosed({
    $timer.Stop()
    $timer.Dispose()
    if ($global:downloadProcess -ne $null -and !$global:downloadProcess.HasExited) {
        $global:downloadProcess.Kill()
        $global:downloadProcess.Dispose()
    }
    Get-EventSubscriber | Unregister-Event -Force -ErrorAction SilentlyContinue
    Remove-Variable downloadProcess -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable logQueue -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable processExited -Scope Global -ErrorAction SilentlyContinue
})

# --- 顯示視窗 ---
$form.ShowDialog() | Out-Null