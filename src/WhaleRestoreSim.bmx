Strict
Framework BRL.GLMax2D
Import BRL.StandardIO
Import BRL.Random
Import BRL.LinkedList

' Constants for Simulation Parameters (Parameterized Surface-Vectors)
Const SCREEN_WIDTH:Int = 800
Const SCREEN_HEIGHT:Int = 600
Const OCEAN_DEPTH:Int = 400  ' Simulated depth for nutrient layers
Const WHALE_COUNT:Int = 50   ' Number of whales to simulate
Const PLASTIC_COUNT:Int = 1000  ' Initial plastic debris
Const NUTRIENT_BOOST:Float = 1.5  ' Whale pump multiplier for plankton growth
Const CLEANUP_EFFICIENCY:Float = 0.9  ' Interceptor removal rate
Const KARMA_IMPACT_BASE:Int = 75  ' Base karma for eco-help

' Structures for Entities
Type TWhale
    Field x:Float, y:Float
    Field health:Float = 100.0
    Method Update()
        y :+ Rnd(-1,1)  ' Simulate migration
        If y > OCEAN_DEPTH Then y = OCEAN_DEPTH
        health :- Rnd(0,0.5)  ' Degrade from pollution
    End Method
    Method RestoreNutrients:Float()
        Return NUTRIENT_BOOST * health / 100.0  ' Whale pump effect
    End Method
End Type

Type TPlastic
    Field x:Float, y:Float
    Method Update()
        x :+ Rnd(-0.5,0.5)
        y :+ Rnd(0.1,0.5)  ' Drift downward
    End Method
End Type

Type TInterceptor  ' Machinery Simulation
    Field x:Float = 100, y:Float = 200
    Method Clean(debris:TList)
        Local count:Int = 0
        For Local p:TPlastic = EachIn debris
            If Distance(x,y,p.x,p.y) < 50 Then
                debris.Remove(p)
                count :+ 1
            EndIf
        Next
        Return count * CLEANUP_EFFICIENCY
    End Method
End Type

' Helper Function
Function Distance:Float(x1:Float, y1:Float, x2:Float, y2:Float)
    Return Sqr((x1-x2)^2 + (y1-y2)^2)
End Function

' Main Simulation Loop
AppTitle = "EcoNet Whale Habitat Restoration Sim"
Graphics SCREEN_WIDTH, SCREEN_HEIGHT

Local whales:TList = New TList
For Local i:Int = 1 To WHALE_COUNT
    Local w:TWhale = New TWhale
    w.x = Rnd(0, SCREEN_WIDTH)
    w.y = Rnd(0, OCEAN_DEPTH)
    whales.AddLast(w)
Next

Local plastics:TList = New TList
For Local i:Int = 1 To PLASTIC_COUNT
    Local p:TPlastic = New TPlastic
    p.x = Rnd(0, SCREEN_WIDTH)
    p.y = Rnd(0, OCEAN_DEPTH)
    plastics.AddLast(p)
Next

Local interceptor:TInterceptor = New TInterceptor

Local nutrients:Float = 0.0
Local karmaScore:Int = KARMA_IMPACT_BASE

While Not KeyHit(KEY_ESCAPE)
    Cls
    
    ' Update Entities
    For Local w:TWhale = EachIn whales
        w.Update()
        nutrients :+ w.RestoreNutrients()
    Next
    
    For Local p:TPlastic = EachIn plastics
        p.Update()
    Next
    
    Local cleaned:Float = interceptor.Clean(plastics)
    karmaScore :+ Int(cleaned * 0.1)  ' Parameterized karma offset
    
    ' Draw Simulation
    SetColor 0,0,255  ' Ocean blue
    DrawRect 0,0,SCREEN_WIDTH,SCREEN_HEIGHT
    
    SetColor 255,255,255  ' Whales
    For Local w:TWhale = EachIn whales
        DrawOval w.x, w.y, 10, 5
    Next
    
    SetColor 255,0,0  ' Plastics
    For Local p:TPlastic = EachIn plastics
        DrawRect p.x, p.y, 2, 2
    Next
    
    SetColor 0,255,0  ' Interceptor
    DrawRect interceptor.x, interceptor.y, 20, 10
    
    ' Display Metrics
    DrawText "Whales: " + WHALE_COUNT + " Health Avg: " + (nutrients / WHALE_COUNT), 10, 10
    DrawText "Plastics Left: " + plastics.Count(), 10, 30
    DrawText "Nutrients Restored: " + nutrients, 10, 50
    DrawText "Karma Score Impact: " + karmaScore, 10, 70
    DrawText "Eco-Help Vector: Prevention=" + CLEANUP_EFFICIENCY + " Restore=" + NUTRIENT_BOOST, 10, 90
    
    Flip
Wend

End
