Strict
Framework BRL.GLMax2D
Import BRL.StandardIO
Import BRL.Random
Import BRL.LinkedList

' Constants for Simulation Parameters (Parameterized Surface-Vectors)
Const SCREEN_WIDTH:Int = 800
Const SCREEN_HEIGHT:Int = 600
Const OCEAN_DEPTH:Int = 400  ' Simulated depth for layers
Const WHALE_COUNT:Int = 40   ' Number of whales
Const TOXIN_COUNT:Int = 800  ' Initial toxins
Const NUTRIENT_DELIVERY:Float = 2.0  ' Buoy multiplier for growth
Const FILTRATION_EFFICIENCY:Float = 0.95  ' Barrier removal rate
Const KARMA_IMPACT_BASE:Int = 80  ' Base karma for eco-help

' Structures for Entities
Type TWhale
    Field x:Float, y:Float
    Field health:Float = 100.0
    Method Update()
        y :+ Rnd(-1,1)  ' Migration
        If y > OCEAN_DEPTH Then y = OCEAN_DEPTH
        health :- Rnd(0,0.4)  ' Degrade from toxins
    End Method
    Method BenefitFromNutrients:Float()
        Return NUTRIENT_DELIVERY * health / 100.0  ' Nutrient effect
    End Method
End Type

Type TToxin
    Field x:Float, y:Float
    Method Update()
        x :+ Rnd(-0.4,0.4)
        y :+ Rnd(0.2,0.6)  ' Drift
    End Method
End Type

Type TBuoy  ' Machinery Simulation for Nutrient Delivery
    Field x:Float = 150, y:Float = 250
    Method Deliver(list:TList)
        Local boost:Float = 0.0
        For Local w:TWhale = EachIn list
            If Distance(x,y,w.x,w.y) < 60 Then
                boost :+ NUTRIENT_DELIVERY
            EndIf
        Next
        Return boost
    End Method
End Type

Type TBarrier  ' Water-System for Filtration
    Field x:Float = 400, y:Float = 300
    Method Filter(debris:TList)
        Local count:Int = 0
        For Local t:TToxin = EachIn debris
            If Distance(x,y,t.x,t.y) < 40 Then
                debris.Remove(t)
                count :+ 1
            EndIf
        Next
        Return count * FILTRATION_EFFICIENCY
    End Method
End Type

' Helper Function
Function Distance:Float(x1:Float, y1:Float, x2:Float, y2:Float)
    Return Sqr((x1-x2)^2 + (y1-y2)^2)
End Function

' Main Simulation Loop
AppTitle = "AquaNet Whale Protection Sim"
Graphics SCREEN_WIDTH, SCREEN_HEIGHT

Local whales:TList = New TList
For Local i:Int = 1 To WHALE_COUNT
    Local w:TWhale = New TWhale
    w.x = Rnd(0, SCREEN_WIDTH)
    w.y = Rnd(0, OCEAN_DEPTH)
    whales.AddLast(w)
Next

Local toxins:TList = New TList
For Local i:Int = 1 To TOXIN_COUNT
    Local t:TToxin = New TToxin
    t.x = Rnd(0, SCREEN_WIDTH)
    t.y = Rnd(0, OCEAN_DEPTH)
    toxins.AddLast(t)
Next

Local buoy:TBuoy = New TBuoy
Local barrier:TBarrier = New TBarrier

Local nutrients:Float = 0.0
Local karmaScore:Int = KARMA_IMPACT_BASE

While Not KeyHit(KEY_ESCAPE)
    Cls
    
    ' Update Entities
    For Local w:TWhale = EachIn whales
        w.Update()
        nutrients :+ w.BenefitFromNutrients()
    Next
    
    For Local t:TToxin = EachIn toxins
        t.Update()
    Next
    
    Local delivered:Float = buoy.Deliver(whales)
    Local filtered:Float = barrier.Filter(toxins)
    karmaScore :+ Int((delivered + filtered) * 0.15)  ' Parameterized karma offset
    
    ' Draw Simulation
    SetColor 0,0,255  ' Ocean
    DrawRect 0,0,SCREEN_WIDTH,SCREEN_HEIGHT
    
    SetColor 255,255,255  ' Whales
    For Local w:TWhale = EachIn whales
        DrawOval w.x, w.y, 12, 6
    Next
    
    SetColor 128,0,0  ' Toxins
    For Local t:TToxin = EachIn toxins
        DrawRect t.x, t.y, 3, 3
    Next
    
    SetColor 0,255,0  ' Buoy
    DrawRect buoy.x, buoy.y, 15, 15
    
    SetColor 255,165,0  ' Barrier
    DrawRect barrier.x, barrier.y, 30, 10
    
    ' Display Metrics
    DrawText "Whales: " + WHALE_COUNT + " Health Avg: " + (nutrients / WHALE_COUNT), 10, 10
    DrawText "Toxins Left: " + toxins.Count(), 10, 30
    DrawText "Nutrients Delivered: " + nutrients, 10, 50
    DrawText "Karma Score Impact: " + karmaScore, 10, 70
    DrawText "Eco-Help Vector: Prevention=" + FILTRATION_EFFICIENCY + " Restore=" + NUTRIENT_DELIVERY, 10, 90
    
    Flip
Wend

End
