Add-Type -Language CSharp -TypeDefinition @"
  [System.FlagsAttribute]
  public enum TaskState {
      Unknown         = 0,       
      Pass            = 1 << 0,  
      Warn            = 1 << 1, 
      Fail            = 1 << 2, 
  }
"@