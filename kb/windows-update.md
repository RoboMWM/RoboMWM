## 0x800F0922

I personally encoutered when attempting to install `2026-02 Security Update (KB5077181) (26200.7840)`

This is caused by having Windows Sandbox enabled with Container Manager Service disabled. Setting startup type for the service to Manual allowed the update to succeed.

It seems others have resolved this via disabling Windows Sandbox.

https://learn.microsoft.com/en-us/answers/questions/3908162/kb5050009-error-code-0x800f0922?forum=windows-all&referrer=answers
https://old.reddit.com/r/WindowsHelp/comments/1ia3bp8/error_windows_update_install_error_0x800f0922/