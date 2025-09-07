BeforeAll {
    Function Write-EZLog {}
    . $PSScriptRoot\Write-StatusMessage.ps1
    Mock Write-Host { param($Message) }
    Mock Write-Verbose { param($Object) }
    Mock Write-Debug { param($Object) }
    Mock Write-Warning { param($Object) }
    Mock Write-Error { param($Object) }
    Mock Write-EZLog { }
}

Describe "Write-StatusMessage" {

    Context "When called with default parameters" {
        It "Should call Write-Host with the message" {
            Write-StatusMessage -Message "Hello"
            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -eq "Hello" }
        }
    }

    Context "When Verbosity is Verbose" {
        It "Should call Write-Verbose" {
            Write-StatusMessage -Message "Verbose message" -Verbosity "Verbose"
            Assert-MockCalled Write-Verbose -Exactly 1 -Scope It
        }
    }

    Context "When Verbosity is Debug" {
        It "Should call Write-Debug" {
            Write-StatusMessage -Message "Debug message" -Verbosity "Debug"
            Assert-MockCalled Write-Debug -Exactly 1 -Scope It
        }
    }

    Context "When Verbosity is Warning" {
        It "Should call Write-Warning" {
            Write-StatusMessage -Message "Warning message" -Verbosity "Warning"
            Assert-MockCalled Write-Warning -Exactly 1 -Scope It
        }
    }

    Context "When Verbosity is Error" {
        It "Should call Write-Error" {
            Write-StatusMessage -Message "Error message" -Verbosity "Error"
            Assert-MockCalled Write-Error -Exactly 1 -Scope It
        }
    }

    Context "When Indent is specified" {
        It "Should indent the message" {
            Write-StatusMessage -Message "Indented" -Indent 4
            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -eq "    Indented" }
        }
    }

    Context "When Width is specified and message is longer" {
        It "Should truncate the message with ellipsis" {
            Write-StatusMessage -Message "This is a long message" -Width 10
            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -eq "This is..." }
        }
    }

    Context "When Width is specified and message is shorter" {
        It "Should pad the message to the specified width" {
            Write-StatusMessage -Message "Short" -Width 10
            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -eq "Short     " }
        }
    }

    Context "When NoNewLine is specified" {
        It "Should pass NoNewLine to Write-Host" {
            Write-StatusMessage -Message "NoNewLine" -NoNewLine
            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $NoNewLine -eq $true }
        }
    }

    Context "When ForegroundColor is specified" {
        It "Should pass ForegroundColor to Write-Host" {
            Write-StatusMessage -Message "Color" -ForegroundColor "Green"
            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $ForegroundColor -eq "Green" }
        }
    }
}