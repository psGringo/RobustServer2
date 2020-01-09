object Timers: TTimers
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 150
  Width = 215
  object tWork: TTimer
    Enabled = False
    OnTimer = tWorkTimer
    Left = 32
    Top = 16
  end
  object tMemory: TTimer
    Enabled = False
    OnTimer = tMemoryTimer
    Left = 40
    Top = 80
  end
end
