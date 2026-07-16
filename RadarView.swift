import SwiftUI

struct RadarView: View {
    let devices: [DiscoveredDevice]

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let maxRadius = size / 2 - 20

            ZStack {
                // 背景圆环
                ForEach(0..<4) { i in
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        .frame(width: maxRadius * 2 * CGFloat(i + 1) / 4,
                               height: maxRadius * 2 * CGFloat(i + 1) / 4)
                }

                // 十字线
                Path { path in
                    path.move(to: CGPoint(x: center.x, y: 20))
                    path.addLine(to: CGPoint(x: center.x, y: size - 20))
                    path.move(to: CGPoint(x: 20, y: center.y))
                    path.addLine(to: CGPoint(x: size - 20, y: center.y))
                }
                .stroke(Color.green.opacity(0.3), lineWidth: 1)

                // 扫描扇形动画
                RadarSweepAnimation()
                    .frame(width: maxRadius * 2, height: maxRadius * 2)

                // 设备点
                ForEach(devices) { device in
                    DeviceDotView(device: device, center: center, maxRadius: maxRadius)
                }

                // 中心点
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct RadarSweepAnimation: View {
    @State private var angle: Double = 0

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)

            ZStack {
                Path { path in
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: size / 2,
                        startAngle: .degrees(angle - 30),
                        endAngle: .degrees(angle),
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [.green.opacity(0.0), .green.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                angle = 360
            }
        }
    }
}

struct DeviceDotView: View {
    let device: DiscoveredDevice
    let center: CGPoint
    let maxRadius: CGFloat

    @State private var isPulsing = false

    var body: some View {
        let angle = getAngle()
        let distance = getDisplayRadius()
        let x = center.x + CGFloat(cos(angle * .pi / 180)) * distance
        let y = center.y + CGFloat(sin(angle * .pi / 180)) * distance

        ZStack {
            Circle()
                .fill(dotColor.opacity(0.3))
                .frame(width: isPulsing ? 20 : 8, height: isPulsing ? 20 : 8)
                .position(x: x, y: y)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)

            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .position(x: x, y: y)
                .shadow(color: dotColor, radius: 4)
        }
        .onAppear {
            isPulsing = true
        }
    }

    private var dotColor: Color {
        switch device.distanceLevel {
        case .immediate: return .green
        case .near: return .green.opacity(0.7)
        case .medium: return .yellow
        case .far: return .red
        }
    }

    private func getAngle() -> Double {
        let hash = abs(device.id.uuidString.hashValue)
        return Double(hash % 360)
    }

    private func getDisplayRadius() -> CGFloat {
        let maxDistance: Double = 30.0
        let normalized = min(device.estimatedDistance / maxDistance, 1.0)
        return maxRadius * CGFloat(normalized)
    }
}
