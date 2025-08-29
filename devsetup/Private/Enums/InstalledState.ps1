Add-Type -Language CSharp -TypeDefinition @"
  [System.FlagsAttribute]
  public enum InstalledState {
      NotInstalled           = 0,       
      Installed              = 1 << 0,  
      MinimumVersionMet      = 1 << 1,  
      RequiredVersionMet     = 1 << 2,  
      GlobalVersionMet       = 1 << 3,  
      Pass                   = Installed | MinimumVersionMet | RequiredVersionMet | GlobalVersionMet
  }
"@