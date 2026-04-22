//
//  LoginView.swift
//  TennisMatch
//
//  "Midnight Court" — dark premium login with tennis-ball chartreuse accent.
//

import SwiftUI

// MARK: - Login View

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @State private var appeared = false
    @State private var ballFloat = false
    @State private var glowPulse = false
    @State private var showVerification = false
    @State private var showHelpView = false

    // MARK: Theme
    private let bgTop      = Theme.loginBgTop
    private let bgMid      = Theme.loginBgMid
    private let bgBot      = Theme.loginBgBot
    private let chartreuse = Theme.loginChartreuse
    private let wechat     = Theme.loginWechat
    private let sage       = Theme.loginSage

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background

                CourtLinesBackground()
                    .opacity(0.035)
                    .ignoresSafeArea()

                ambientGlow(size: geo.size)

                VStack(spacing: 0) {
                    Spacer(minLength: 80)

                    heroSection

                    Spacer()

                    buttonsSection

                    footer
                        .padding(.bottom, max(geo.safeAreaInsets.bottom + 8, 24))
                }
            }
            .ignoresSafeArea()
        }
        .onAppear(perform: startAnimations)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $showVerification) {
            PhoneVerificationView(phoneNumber: "+86 138****8888")
        }
        .navigationDestination(isPresented: $showHelpView) {
            HelpView()
        }
    }

    // MARK: - Background

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: bgTop, location: 0),
                .init(color: bgMid, location: 0.45),
                .init(color: bgBot, location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func ambientGlow(size: CGSize) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [chartreuse.opacity(0.07), chartreuse.opacity(0.02), .clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: 180
                )
            )
            .frame(width: 360, height: 360)
            .position(x: size.width / 2, y: size.height * 0.30)
            .opacity(glowPulse ? 1 : 0.5)
    }

    // MARK: - Hero (ball + brand)

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Tennis ball
            TennisBallGraphic(accent: chartreuse)
                .frame(width: 80, height: 80)
                .shadow(color: chartreuse.opacity(0.35), radius: 16, y: 2)
                .shadow(color: chartreuse.opacity(0.10), radius: 40, y: 4)
                .offset(y: ballFloat ? -6 : 6)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -30)
                .animation(.easeOut(duration: 0.8).delay(0.15), value: appeared)

            // Brand
            VStack(spacing: 6) {
                Text("Let's Tennis")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(.white)

                Text("找 到 你 的 網 球 搭 檔")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(sage)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.easeOut(duration: 0.7).delay(0.35), value: appeared)
        }
    }

    // MARK: - Login Buttons

    private var buttonsSection: some View {
        VStack(spacing: 12) {
            // Phone — primary CTA
            loginButton(
                title: "手機號碼登陆",
                icon: "phone.fill",
                bg: chartreuse,
                fg: bgTop,
                delay: 0.50,
                action: { showVerification = true }
            )

            // WeChat
            loginButton(
                title: "微信登录",
                icon: "bubble.left.fill",
                bg: wechat,
                fg: .white,
                delay: 0.60,
                action: { isLoggedIn = true }
            )

            // Apple
            Button(action: { isLoggedIn = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Apple 登录")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .animation(.easeOut(duration: 0.6).delay(0.70), value: appeared)
        }
        .padding(.horizontal, 28)
    }

    private func loginButton(
        title: String, icon: String,
        bg: Color, fg: Color, delay: Double,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(fg)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .animation(.easeOut(duration: 0.6).delay(delay), value: appeared)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 5) {
            Text("登入即表示您同意 \(Text("服務條款").foregroundColor(sage).underline()) 和 \(Text("隱私政策").foregroundColor(sage).underline())")
                .foregroundColor(sage.opacity(0.55))
                .font(.system(size: 11))

            HStack(spacing: 3) {
                Text("還沒有帳號？")
                    .foregroundColor(sage.opacity(0.55))
                Button(action: { showVerification = true }) {
                    Text("立即註冊")
                        .foregroundColor(chartreuse)
                        .underline()
                }
            }
            .font(.system(size: 12))

            HStack(spacing: 3) {
                Text("需要幫助？")
                    .foregroundColor(sage.opacity(0.55))
                Button(action: { showHelpView = true }) {
                    Text("聯繫客服")
                        .foregroundColor(chartreuse.opacity(0.6))
                }
            }
            .font(.system(size: 11))
        }
        .padding(.top, 22)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.85), value: appeared)
    }

    // MARK: - Animations

    private func startAnimations() {
        appeared = true

        withAnimation(
            .easeInOut(duration: 4.0)
            .repeatForever(autoreverses: true)
            .delay(1.0)
        ) {
            ballFloat = true
        }

        withAnimation(
            .easeInOut(duration: 3.5)
            .repeatForever(autoreverses: true)
            .delay(1.5)
        ) {
            glowPulse = true
        }
    }
}

// MARK: - Tennis Ball Graphic

struct TennisBallGraphic: View {
    let accent: Color

    var body: some View {
        ZStack {
            // Body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accent,
                            accent.opacity(0.82),
                            Theme.loginAccentDeep,
                        ],
                        center: .init(x: 0.35, y: 0.30),
                        startRadius: 4,
                        endRadius: 46
                    )
                )

            // Seam
            TennisBallSeam()
                .stroke(
                    Color.white.opacity(0.45),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
                )
                .padding(10)

            // Specular highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.32), .clear],
                        center: .init(x: 0.30, y: 0.25),
                        startRadius: 1,
                        endRadius: 22
                    )
                )
        }
        .clipShape(Circle())
    }
}

struct TennisBallSeam: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()

        // Left curve
        p.move(to: CGPoint(x: w * 0.50, y: 0))
        p.addCurve(
            to:       CGPoint(x: w * 0.50, y: h),
            control1: CGPoint(x: -w * 0.12, y: h * 0.33),
            control2: CGPoint(x: -w * 0.12, y: h * 0.67)
        )

        // Right curve
        p.move(to: CGPoint(x: w * 0.50, y: 0))
        p.addCurve(
            to:       CGPoint(x: w * 0.50, y: h),
            control1: CGPoint(x: w * 1.12, y: h * 0.33),
            control2: CGPoint(x: w * 1.12, y: h * 0.67)
        )

        return p
    }
}

// MARK: - Court Lines Background

struct CourtLinesBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let mx: CGFloat = 36                   // horizontal margin
            let top = h * 0.18, bot = h * 0.82     // court top / bottom
            let svcTop = h * 0.32, svcBot = h * 0.68

            Path { p in
                // Court outline
                p.addRect(CGRect(x: mx, y: top, width: w - mx * 2, height: bot - top))

                // Net (center horizontal)
                p.move(to:    CGPoint(x: mx,     y: h * 0.5))
                p.addLine(to: CGPoint(x: w - mx, y: h * 0.5))

                // Service lines
                let si: CGFloat = 64
                p.move(to:    CGPoint(x: si,     y: svcTop))
                p.addLine(to: CGPoint(x: w - si, y: svcTop))
                p.move(to:    CGPoint(x: si,     y: svcBot))
                p.addLine(to: CGPoint(x: w - si, y: svcBot))

                // Center service line
                p.move(to:    CGPoint(x: w / 2, y: svcTop))
                p.addLine(to: CGPoint(x: w / 2, y: svcBot))

                // Doubles alleys (inner lines, partial)
                let alley: CGFloat = 18
                p.move(to:    CGPoint(x: mx + alley, y: top))
                p.addLine(to: CGPoint(x: mx + alley, y: bot))
                p.move(to:    CGPoint(x: w - mx - alley, y: top))
                p.addLine(to: CGPoint(x: w - mx - alley, y: bot))
            }
            .stroke(Color.white, lineWidth: 0.8)
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
}
