Add-Type -TypeDefinition @"
using System;
using System.Windows.Forms;

public class MessageBoxExample {
    public static void ShowMessage(string message, string title) {
        MessageBox.Show(message, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
    }
}
"@

[MessageBoxExample]::ShowMessage('Your Windows 11 activation key is invalid. Please purchase a new activation key to continue using Windows 11.', 'Windows Activation Error')
