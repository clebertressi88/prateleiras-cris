param(
    [double]$EspessuraMdf = 3.00,
    [double]$FolgaMontagem = 0.10,
    [double]$KerfLaser = 0.10
)

$ErrorActionPreference = 'Stop'
$Culture = [System.Globalization.CultureInfo]::InvariantCulture
$LarguraRasgo = $EspessuraMdf + $FolgaMontagem - $KerfLaser
$LarguraRasgo = [Math]::Round($LarguraRasgo, 3)
$SheetWidth = 1300.0
$SheetHeight = 1120.0
$entities = [System.Collections.Generic.List[object]]::new()
$labels = [System.Collections.Generic.List[object]]::new()

function F([double]$value) { return $value.ToString('0.###', $Culture) }
function Pt([double]$x, [double]$y) { return ,@($x, $y) }

function Add-Poly {
    param([string]$Name, [string]$Piece, [object[]]$Points)
    $entities.Add([pscustomobject]@{ Type = 'POLY'; Name = $Name; Piece = $Piece; Points = $Points })
}

function Add-Rect {
    param([string]$Name, [string]$Piece, [double]$X, [double]$Y, [double]$W, [double]$H)
    Add-Poly $Name $Piece @((Pt $X $Y), (Pt ($X + $W) $Y), (Pt ($X + $W) ($Y + $H)), (Pt $X ($Y + $H)))
}

function Add-RotatedSlot {
    param([string]$Name, [string]$Piece, [double]$X, [double]$Y, [double]$Length, [double]$AngleDeg)
    $a = $AngleDeg * [Math]::PI / 180.0
    $ux = [Math]::Cos($a); $uy = [Math]::Sin($a)
    $nx = -$uy; $ny = $ux; $half = $LarguraRasgo / 2.0
    Add-Poly $Name $Piece @(
        (Pt ($X + $nx * $half) ($Y + $ny * $half)),
        (Pt ($X + $ux * $Length + $nx * $half) ($Y + $uy * $Length + $ny * $half)),
        (Pt ($X + $ux * $Length - $nx * $half) ($Y + $uy * $Length - $ny * $half)),
        (Pt ($X - $nx * $half) ($Y - $ny * $half))
    )
}

function Add-TabbedPanel {
    param(
        [string]$Name, [double]$X, [double]$Y, [double]$W, [double]$H,
        [object[]]$SideTabs, [object[]]$TopTabs, [object[]]$BottomTabs,
        [double]$SideProjection = 6.0, [double]$EdgeProjection = 6.0
    )
    $p = [System.Collections.Generic.List[object]]::new()
    $p.Add((Pt $X $Y))
    foreach ($t in ($TopTabs | Sort-Object { $_[0] })) {
        $p.Add((Pt ($X + $t[0]) $Y)); $p.Add((Pt ($X + $t[0]) ($Y - $EdgeProjection)))
        $p.Add((Pt ($X + $t[1]) ($Y - $EdgeProjection))); $p.Add((Pt ($X + $t[1]) $Y))
    }
    $p.Add((Pt ($X + $W) $Y))
    foreach ($t in ($SideTabs | Sort-Object { $_[0] })) {
        $p.Add((Pt ($X + $W) ($Y + $t[0]))); $p.Add((Pt ($X + $W + $SideProjection) ($Y + $t[0])))
        $p.Add((Pt ($X + $W + $SideProjection) ($Y + $t[1]))); $p.Add((Pt ($X + $W) ($Y + $t[1])))
    }
    $p.Add((Pt ($X + $W) ($Y + $H)))
    foreach ($t in ($BottomTabs | Sort-Object { -$_[1] })) {
        $p.Add((Pt ($X + $t[1]) ($Y + $H))); $p.Add((Pt ($X + $t[1]) ($Y + $H + $EdgeProjection)))
        $p.Add((Pt ($X + $t[0]) ($Y + $H + $EdgeProjection))); $p.Add((Pt ($X + $t[0]) ($Y + $H)))
    }
    $p.Add((Pt $X ($Y + $H)))
    foreach ($t in ($SideTabs | Sort-Object { -$_[1] })) {
        $p.Add((Pt $X ($Y + $t[1]))); $p.Add((Pt ($X - $SideProjection) ($Y + $t[1])))
        $p.Add((Pt ($X - $SideProjection) ($Y + $t[0]))); $p.Add((Pt $X ($Y + $t[0])))
    }
    Add-Poly $Name $Name $p.ToArray()
}

function Add-LockSlots {
    param([string]$Piece, [double]$X, [double]$Y, [double]$W, [object[]]$Tabs)
    $t = $Tabs[0]
    $cy = $Y + ($t[0] + $t[1]) / 2.0
    Add-Rect "$Piece-trava-E" $Piece ($X - 8.0) ($cy - 5.0) $LarguraRasgo 10.0
    Add-Rect "$Piece-trava-D" $Piece ($X + $W + 8.0 - $LarguraRasgo) ($cy - 5.0) $LarguraRasgo 10.0
}

function Add-ShelfSlots {
    param([string]$Piece, [double]$X, [double]$Y, [double]$Depth, [bool]$RearBar)
    foreach ($xoff in @(55.0, 184.4, 314.0)) {
        Add-Rect "$Piece-frente" $Piece ($X + $xoff) ($Y + 7.0) 20.0 $LarguraRasgo
        if ($RearBar) { Add-Rect "$Piece-travessa" $Piece ($X + $xoff) ($Y + $Depth - 10.0) 20.0 $LarguraRasgo }
    }
}

# 1-2. Laterais externas 300 x 400 mm, com perfil em degraus.
$sideOutline = @((Pt 0 400), (Pt 0 255), (Pt 65 255), (Pt 65 160), (Pt 130 160), (Pt 130 65), (Pt 205 65), (Pt 205 0), (Pt 300 0), (Pt 300 400))
foreach ($side in @(@('L1',20.0), @('L2',340.0))) {
    $name = $side[0]; $ox = [double]$side[1]; $oy = 20.0
    $translated = foreach ($q in $sideOutline) { Pt ($ox + $q[0]) ($oy + $q[1]) }
    Add-Poly $name $name $translated

    # Fundo e base.
    foreach ($yy in @(45.0, 190.0, 335.0)) { Add-Rect "$name-fundo" $name ($ox + 296.0) ($oy + $yy) $LarguraRasgo 25.2 }
    foreach ($off in @(45.0, 225.0)) { Add-Rect "$name-base" $name ($ox + $off) ($oy + 383.0) 25.2 $LarguraRasgo }

    # Tres prateleiras inclinadas 7,83 graus (22 mm de elevacao em 160 mm).
    foreach ($s in @(@(10.0,330.0), @(75.0,235.0), @(140.0,140.0))) {
        foreach ($off in @(25.0,110.0)) {
            $a = -7.829
            $rad = $a * [Math]::PI / 180.0
            Add-RotatedSlot "$name-prateleira" $name ($ox + $s[0] + [Math]::Cos($rad) * $off) ($oy + $s[1] + [Math]::Sin($rad) * $off) 25.2 $a
        }
        $railTop = $s[1] - 70.0
        foreach ($voff in @(10.0,45.0)) { Add-Rect "$name-frente" $name ($ox + $s[0] + 3.0) ($oy + $railTop + $voff) $LarguraRasgo 20.2 }
    }

    # Duas travessas traseiras sob as prateleiras inferiores.
    foreach ($bar in @(@(168.5,308.2), @(233.5,213.2))) {
        Add-Rect "$name-travessa" $name ($ox + $bar[0] - 3.0) ($oy + $bar[1] + 7.0) $LarguraRasgo 20.2
    }
}
$labels.Add([pscustomobject]@{Text='L1 - LATERAL ESQ.'; X=170; Y=225})
$labels.Add([pscustomobject]@{Text='L2 - LATERAL DIR.'; X=490; Y=225})

# 3. Fundo interno 394 x 400 mm; largura externa montada = 400 mm.
$backTabs = @(@(45.0,70.0), @(190.0,215.0), @(335.0,360.0))
Add-TabbedPanel 'F1-FUNDO' 672 20 394 400 $backTabs @() @() 6 6
foreach ($xoff in @(55.0,184.4,314.0)) {
    Add-Rect 'F1-base' 'F1-FUNDO' (672 + $xoff) (20 + 383) 20 $LarguraRasgo
    # A prateleira superior chega ao fundo com inclinacao.
    Add-Rect 'F1-prateleira-3' 'F1-FUNDO' (672 + $xoff) (20 + 116.5) 20 ($LarguraRasgo / [Math]::Cos(7.829 * [Math]::PI / 180.0))
}
$labels.Add([pscustomobject]@{Text='F1 - FUNDO 39,4 x 40 cm'; X=869; Y=225})

# 4. Base interna 394 x 297 mm.
$baseTabs = @(@(45.0,70.0), @(225.0,250.0))
$shelfTabs = @(@(25.0,50.0), @(110.0,135.0))
$edgeTabs = @(@(55.0,75.0), @(184.4,204.4), @(314.0,334.0))
Add-TabbedPanel 'B1-BASE' 20 455 394 297 $baseTabs @() $edgeTabs 12 8
Add-LockSlots 'B1-BASE' 20 455 394 $baseTabs
$labels.Add([pscustomobject]@{Text='B1 - BASE 39,4 x 29,7 cm'; X=217; Y=600})

# 5-7. Tres prateleiras internas 394 x 160 mm.
$shelfPositions = @(@('P1',450.0,455.0,$true), @('P2',880.0,455.0,$true), @('P3',450.0,650.0,$false))
foreach ($sp in $shelfPositions) {
    $name=$sp[0]; $x=[double]$sp[1]; $y=[double]$sp[2]; $rear=[bool]$sp[3]
    $bottom = @(); if ($name -eq 'P3') { $bottom = $edgeTabs }
    Add-TabbedPanel $name $x $y 394 160 $shelfTabs @() $bottom 12 8
    Add-LockSlots $name $x $y 394 $shelfTabs
    Add-ShelfSlots $name $x $y 160 $rear
    $labels.Add([pscustomobject]@{Text="$name - PRATELEIRA INCLINADA"; X=($x+197); Y=($y+82)})
}

# 8-10. Frentes de contencao 394 x 70 mm.
$railTabs = @(@(10.0,30.0), @(45.0,65.0))
foreach ($r in @(@('FR1',20.0,850.0), @('FR2',450.0,850.0), @('FR3',880.0,850.0))) {
    Add-TabbedPanel $r[0] ([double]$r[1]) ([double]$r[2]) 394 70 $railTabs @() $edgeTabs 6 8
    $labels.Add([pscustomobject]@{Text="$($r[0]) - FRENTE"; X=([double]$r[1]+197); Y=([double]$r[2]+37)})
}

# 11-12. Travessas traseiras com abas superiores para P1 e P2.
$barSideTabs = @(@(7.0,27.0))
foreach ($r in @(@('T1',20.0,975.0), @('T2',450.0,975.0))) {
    Add-TabbedPanel $r[0] ([double]$r[1]) ([double]$r[2]) 394 35 $barSideTabs $edgeTabs @() 6 8
    $labels.Add([pscustomobject]@{Text="$($r[0]) - TRAVESSA"; X=([double]$r[1]+197); Y=([double]$r[2]+21)})
}

# 13. Oito travas tipo cunha para as abas passantes da base e prateleiras.
for ($i=0; $i -lt 8; $i++) {
    $x = 900.0 + ($i % 4) * 65.0; $y = 975.0 + [Math]::Floor($i / 4) * 50.0
    Add-Poly "TR$($i+1)" 'TRAVAS' @((Pt $x $y), (Pt ($x+28) ($y+4)), (Pt ($x+28) ($y+14)), (Pt $x ($y+10)))
}
$labels.Add([pscustomobject]@{Text='TR1-TR8 - TRAVAS'; X=997; Y=1065})

# Cupom de calibracao com quatro larguras de rasgo.
Add-Rect 'CUPOM' 'CUPOM' 20 1050 180 45
foreach ($test in @(@(40.0,2.90), @(75.0,3.00), @(110.0,3.10), @(145.0,3.20))) {
    Add-Rect 'CUPOM-RASGO' 'CUPOM' (20 + $test[0]) 1050 ([double]$test[1]) 18
}
$labels.Add([pscustomobject]@{Text='CUPOM 2,90 / 3,00 / 3,10 / 3,20 mm'; X=110; Y=1110})

function Build-Svg([bool]$Numbered) {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
    [void]$sb.AppendLine("<svg xmlns=`"http://www.w3.org/2000/svg`" width=`"$(F $SheetWidth)mm`" height=`"$(F $SheetHeight)mm`" viewBox=`"0 0 $(F $SheetWidth) $(F $SheetHeight)`">")
    [void]$sb.AppendLine('  <title>Expositor 40x30x40 cm - MDF 3 mm - escala 1:1</title>')
    [void]$sb.AppendLine("  <desc>Rasgo CAD $(F $LarguraRasgo) mm = MDF $(F $EspessuraMdf) + folga $(F $FolgaMontagem) - kerf $(F $KerfLaser). Unidades geometricas em mm; cotas do manual em cm.</desc>")
    [void]$sb.AppendLine('  <g id="CORTE" fill="none" stroke="#000000" stroke-width="0.1" stroke-linejoin="miter" vector-effect="non-scaling-stroke">')
    foreach ($e in $entities) {
        $pts = ($e.Points | ForEach-Object { "$(F $_[0]),$(F $_[1])" }) -join ' '
        [void]$sb.AppendLine("    <polygon id=`"$($e.Name)`" data-peca=`"$($e.Piece)`" points=`"$pts`"/>")
    }
    [void]$sb.AppendLine('  </g>')
    if ($Numbered) {
        [void]$sb.AppendLine('  <g id="NUMERACAO-NAO-CORTAR" fill="#000000" stroke="none" font-family="Arial, sans-serif" font-size="10" text-anchor="middle">')
        foreach ($l in $labels) { [void]$sb.AppendLine("    <text x=`"$(F $l.X)`" y=`"$(F $l.Y)`">$($l.Text)</text>") }
        [void]$sb.AppendLine('  </g>')
    }
    [void]$sb.AppendLine('</svg>')
    return $sb.ToString()
}

function Add-DxfPair([System.Text.StringBuilder]$Sb, [int]$Code, [object]$Value) {
    [void]$Sb.AppendLine($Code.ToString($Culture)); [void]$Sb.AppendLine([string]$Value)
}

function Build-Dxf {
    $sb = [System.Text.StringBuilder]::new()
    Add-DxfPair $sb 0 'SECTION'; Add-DxfPair $sb 2 'HEADER'
    Add-DxfPair $sb 9 '$ACADVER'; Add-DxfPair $sb 1 'AC1015'
    Add-DxfPair $sb 9 '$INSUNITS'; Add-DxfPair $sb 70 4
    Add-DxfPair $sb 0 'ENDSEC'; Add-DxfPair $sb 0 'SECTION'; Add-DxfPair $sb 2 'TABLES'
    Add-DxfPair $sb 0 'TABLE'; Add-DxfPair $sb 2 'LAYER'; Add-DxfPair $sb 70 2
    foreach ($layer in @(@('CORTE',7), @('GRAVACAO',8))) {
        Add-DxfPair $sb 0 'LAYER'; Add-DxfPair $sb 2 $layer[0]; Add-DxfPair $sb 70 0; Add-DxfPair $sb 62 $layer[1]; Add-DxfPair $sb 6 'CONTINUOUS'
    }
    Add-DxfPair $sb 0 'ENDTAB'; Add-DxfPair $sb 0 'ENDSEC'; Add-DxfPair $sb 0 'SECTION'; Add-DxfPair $sb 2 'ENTITIES'
    foreach ($e in $entities) {
        Add-DxfPair $sb 0 'LWPOLYLINE'; Add-DxfPair $sb 8 'CORTE'; Add-DxfPair $sb 90 $e.Points.Count; Add-DxfPair $sb 70 1
        foreach ($q in $e.Points) { Add-DxfPair $sb 10 (F $q[0]); Add-DxfPair $sb 20 (F ($SheetHeight - $q[1])) }
    }
    foreach ($l in $labels) {
        Add-DxfPair $sb 0 'TEXT'; Add-DxfPair $sb 8 'GRAVACAO'; Add-DxfPair $sb 10 (F $l.X); Add-DxfPair $sb 20 (F ($SheetHeight - $l.Y)); Add-DxfPair $sb 40 8; Add-DxfPair $sb 1 $l.Text; Add-DxfPair $sb 72 1
    }
    Add-DxfPair $sb 0 'ENDSEC'; Add-DxfPair $sb 0 'EOF'
    return $sb.ToString()
}

$utf8 = [System.Text.UTF8Encoding]::new($false)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
[System.IO.File]::WriteAllText((Join-Path $root 'prateleira_40x30_corte.svg'), (Build-Svg $false), $utf8)
[System.IO.File]::WriteAllText((Join-Path $root 'plano_corte_numerado.svg'), (Build-Svg $true), $utf8)
[System.IO.File]::WriteAllText((Join-Path $root 'prateleira_40x30_corte.dxf'), (Build-Dxf), [System.Text.Encoding]::ASCII)
Write-Host "Arquivos gerados. Rasgo CAD: $(F $LarguraRasgo) mm."
