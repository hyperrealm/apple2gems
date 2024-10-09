

.scope IOTKCall

        OutputData := $00
        SaveViewport := $01
        RestoreViewport := $02
        GetConsoleStatus := $03
        GetCursorPosition := $04
        GetCharAtCursor := $05
        InitConsole := $06
        InitInput := $0A
        GetInputInfo := $0B
        SetInputInfo := $0C
        Input := $0D
        
.endscope       


.scope IOTKError

None            := $00
InvalidCall     := $01
NoViewportSaved := $02
        
.endscope

.scope IOTKControlCode

        SaveAndResetViewport := $01
        SetViewport := $02
        ClearFromBeginningOfLine := $03
        RestoreViewport := $04
        Bell := $07
        MoveCursorLeft := $08
        MoveCursorDown := $0A
        ClearToEndOfViewport := $0B
        ClearViewport := $0C
        CarriageReturn := $0D
        NormalText := $0E
        InverseText := $0F
        SpaceExpansion := $10
        HorizontalShift := $11
        VerticalPosition := $12
        ClearFromBeginningOfViewport := $13
        HorizontalPosition := $14
        CursorMovement := $15
        ScrollDown := $16
        ScrollUp := $17
        MouseTextOff := $18
        HomeCursor := $19
        ClearLine := $1A
        MouseTextOn := $1B
        MoveCursorRight := $1C
        ClearToEndOfLine := $1D
        AbsolutePosition := $1E
        MoveCursorUp := $1F

.endscope
