// Генерує icon_1024.png — іконку застосунку (темний squircle + знак тривоги + радарні дуги).
// Запуск: swift make_icon.swift
import Cocoa

let S: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func col(_ r: CGFloat,_ g: CGFloat,_ b: CGFloat,_ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: a)
}

// 1. Squircle-підкладка з темним градієнтом
let inset: CGFloat = 90
let content = NSRect(x: inset, y: inset, width: S - 2*inset, height: S - 2*inset)
let radius: CGFloat = content.width * 0.225
let bg = NSBezierPath(roundedRect: content, xRadius: radius, yRadius: radius)
bg.addClip()
let grad = NSGradient(colors: [col(18, 28, 48), col(9, 14, 26)])!
grad.draw(in: content, angle: -90)

// 2. Ледь помітна сітка 2×2 (мотив чотирьох карт)
col(255, 255, 255, 0.05).setStroke()
let gridLine = NSBezierPath()
gridLine.lineWidth = 3
gridLine.move(to: NSPoint(x: content.midX, y: content.minY))
gridLine.line(to: NSPoint(x: content.midX, y: content.maxY))
gridLine.move(to: NSPoint(x: content.minX, y: content.midY))
gridLine.line(to: NSPoint(x: content.maxX, y: content.midY))
gridLine.stroke()

let center = NSPoint(x: content.midX, y: content.midY + 20)

// 3. Радарні дуги за знаком тривоги
for (i, r) in [CGFloat(250), 330, 410].enumerated() {
    let alpha = 0.22 - CGFloat(i) * 0.06
    col(255, 176, 32, alpha).setStroke()
    let arc = NSBezierPath()
    arc.lineWidth = 14
    arc.lineCapStyle = .round
    arc.appendArc(withCenter: center, radius: r, startAngle: 35, endAngle: 145)
    arc.stroke()
}

// 4. Знак тривоги — трикутник із бурштиновим градієнтом
let th: CGFloat = 430          // висота трикутника
let tw: CGFloat = 500          // ширина основи
let apex   = NSPoint(x: center.x,          y: center.y + th*0.60)
let left   = NSPoint(x: center.x - tw/2,   y: center.y - th*0.40)
let right  = NSPoint(x: center.x + tw/2,   y: center.y - th*0.40)
let tri = NSBezierPath()
tri.lineJoinStyle = .round
tri.lineWidth = 60               // товстий stroke round-join → скруглені кути
tri.move(to: apex); tri.line(to: left); tri.line(to: right); tri.close()

NSGraphicsContext.current!.saveGraphicsState()
tri.addClip()
let triGrad = NSGradient(colors: [col(255, 196, 60), col(255, 122, 0)])!
triGrad.draw(in: tri.bounds, angle: -90)
NSGraphicsContext.current!.restoreGraphicsState()
// скруглена облямівка того ж кольору, щоб кути були м'якими
col(255, 150, 20).setStroke()
tri.stroke()

// 5. Знак оклику (темний) всередині трикутника
let navy = col(14, 22, 40)
navy.setFill()
let barW: CGFloat = 54
let barTop = center.y + 150
let barBot = center.y - 20
let bar = NSBezierPath(roundedRect: NSRect(x: center.x - barW/2, y: barBot, width: barW, height: barTop - barBot),
                       xRadius: barW/2, yRadius: barW/2)
bar.fill()
let dot = NSBezierPath(ovalIn: NSRect(x: center.x - barW/2, y: center.y - 110, width: barW, height: barW))
dot.fill()

// 6. Акцент прапора України — тонка дво-кольорова смужка знизу
let stripeW: CGFloat = 300
let stripeH: CGFloat = 26
let sx = content.midX - stripeW/2
let sy = content.minY + 70
col(0, 91, 187).setFill()   // синій
NSBezierPath(roundedRect: NSRect(x: sx, y: sy + stripeH, width: stripeW, height: stripeH), xRadius: 8, yRadius: 8).fill()
col(255, 213, 0).setFill()  // жовтий
NSBezierPath(roundedRect: NSRect(x: sx, y: sy, width: stripeW, height: stripeH), xRadius: 8, yRadius: 8).fill()

NSGraphicsContext.restoreGraphicsState()

let png = rep.representation(using: .png, properties: [:])!
let out = URL(fileURLWithPath: "icon_1024.png")
try! png.write(to: out)
print("Готово: \(out.path)")
