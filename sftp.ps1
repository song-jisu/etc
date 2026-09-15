# ==============================
# 화면에 입력 내용을 표시하지 않는 함수
# ==============================
function Read-HiddenInput {
    param (
        [string]$Prompt
    )

    Write-Host $Prompt -NoNewline

    $chars = New-Object System.Collections.Generic.List[char]

    while ($true) {
        $key = [Console]::ReadKey($true)

        # Enter
        if ($key.Key -eq [ConsoleKey]::Enter) {
            break
        }

        # Backspace
        if ($key.Key -eq [ConsoleKey]::Backspace) {
            if ($chars.Count -gt 0) {
                $chars.RemoveAt($chars.Count - 1)
            }
            continue
        }

        # 일반 문자
        if (-not [char]::IsControl($key.KeyChar)) {
            $chars.Add($key.KeyChar)
        }
    }

    Write-Host

    $result = -join $chars
    $chars.Clear()

    return $result
}

# ==============================
# SFTP 접속 정보 입력
# 입력 중에는 아무것도 표시하지 않음
# ==============================
$hostName = Read-HiddenInput "IP: "
$port     = Read-HiddenInput "Port: "
$userName = Read-HiddenInput "Username: "
$password = Read-HiddenInput "PW: "

# ==============================
# 임시 askpass CMD
# 비밀번호 자체는 파일에 저장하지 않음
# ==============================
$askPass = Join-Path $env:TEMP "sftp-askpass-$PID.cmd"

'@powershell.exe -NoProfile -NonInteractive -Command "[Console]::Write($env:SFTP_ASKPASS_PASSWORD)"' |
    Set-Content -Path $askPass -Encoding ASCII

# ==============================
# 환경변수에 비밀번호 전달
# ==============================
$env:SFTP_ASKPASS_PASSWORD = $password
$env:SSH_ASKPASS = $askPass
$env:SSH_ASKPASS_REQUIRE = "force"

# PowerShell 변수에서 제거
$password = $null

# ==============================
# 화면 정리
# ==============================
Clear-Host

try {
    & sftp.exe -q -P $port "$userName@$hostName"
}
finally {
    # 환경변수 제거
    Remove-Item Env:SFTP_ASKPASS_PASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:SSH_ASKPASS -ErrorAction SilentlyContinue
    Remove-Item Env:SSH_ASKPASS_REQUIRE -ErrorAction SilentlyContinue

    # 임시 askpass 삭제
    Remove-Item $askPass -Force -ErrorAction SilentlyContinue
}
