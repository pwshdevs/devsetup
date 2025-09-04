# devsetup
## Installation

To install `devsetup` run the command below, ensure you are running it from an elevated shell (Administrator) when running on Windows as some of the commands need Administrator privileges (for instance, installing NuGet).
```bash
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
iwr https://install.pwshdevs.com/devsetup | iex
```

Once `devsetup` is installed run the command below to initialize your environment.
```bash
devsetup -init
```