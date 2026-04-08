// File: Components/HomeNativeAdCard.swift
// ホーム末尾用のネイティブ広告（UIKit）。読み込み失敗時は高さ 0 でレイアウトに影響しない。

import GoogleMobileAds
import SwiftUI
import UIKit

/// スクロール末尾に置くコンパクトなネイティブ広告。プレミアム時は呼び出し側で非表示にする。
struct HomeNativeAdCard: View {
    var body: some View {
        HomeNativeAdCardRepresentable()
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityHidden(true)
    }
}

private struct HomeNativeAdCardRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> HomeNativeAdContainerView {
        let v = HomeNativeAdContainerView()
        return v
    }

    func updateUIView(_ uiView: HomeNativeAdContainerView, context: Context) {
        uiView.loadIfNeeded()
    }
}

@MainActor
final class HomeNativeAdContainerView: UIView, NativeAdLoaderDelegate {
    private var adLoader: AdLoader?
    private let nativeAdView = NativeAdView()
    private let mediaView = MediaView()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let ctaButton = UIButton(type: .system)
    private let iconImageView = UIImageView()
    private let adChoicesView = AdChoicesView()
    private var heightConstraint: NSLayoutConstraint?

    private var loadedHeight: CGFloat = 0 {
        didSet {
            heightConstraint?.constant = loadedHeight
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: loadedHeight)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        clipsToBounds = true

        nativeAdView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.backgroundColor = .secondarySystemGroupedBackground
        nativeAdView.layer.cornerRadius = AppTheme.cardCornerRadius
        nativeAdView.layer.cornerCurve = .continuous
        nativeAdView.clipsToBounds = true

        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = AppTheme.chipCornerRadius
        mediaView.layer.cornerCurve = .continuous

        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        headlineLabel.textColor = .label
        headlineLabel.numberOfLines = 2

        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = .preferredFont(forTextStyle: .caption1)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2

        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        let ctaBase = UIFont.preferredFont(forTextStyle: .subheadline)
        ctaButton.titleLabel?.font = .systemFont(ofSize: ctaBase.pointSize, weight: .semibold)
        ctaButton.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.systemGray5 : UIColor.systemGray6
        }
        ctaButton.layer.cornerRadius = AppTheme.chipCornerRadius
        ctaButton.layer.cornerCurve = .continuous

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        iconImageView.backgroundColor = .tertiarySystemFill

        adChoicesView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(nativeAdView)
        nativeAdView.addSubview(mediaView)
        nativeAdView.addSubview(iconImageView)
        nativeAdView.addSubview(headlineLabel)
        nativeAdView.addSubview(bodyLabel)
        nativeAdView.addSubview(ctaButton)
        nativeAdView.addSubview(adChoicesView)

        nativeAdView.mediaView = mediaView
        nativeAdView.headlineView = headlineLabel
        nativeAdView.bodyView = bodyLabel
        nativeAdView.callToActionView = ctaButton
        nativeAdView.iconView = iconImageView
        nativeAdView.adChoicesView = adChoicesView

        let hc = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint = hc
        hc.isActive = true

        NSLayoutConstraint.activate([
            nativeAdView.leadingAnchor.constraint(equalTo: leadingAnchor),
            nativeAdView.trailingAnchor.constraint(equalTo: trailingAnchor),
            nativeAdView.topAnchor.constraint(equalTo: topAnchor),
            nativeAdView.bottomAnchor.constraint(equalTo: bottomAnchor),

            mediaView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            mediaView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            mediaView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 12),
            mediaView.heightAnchor.constraint(equalToConstant: 104),

            iconImageView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            iconImageView.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 10),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            headlineLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            headlineLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            headlineLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 10),

            bodyLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),

            ctaButton.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            ctaButton.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            ctaButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 10),
            ctaButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            adChoicesView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 8),
            adChoicesView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -8),

            nativeAdView.bottomAnchor.constraint(equalTo: ctaButton.bottomAnchor, constant: 12)
        ])
    }

    func loadIfNeeded() {
        guard adLoader == nil else { return }
        let loader = AdLoader(
            adUnitID: AdMobConfiguration.nativeHomeAdUnitID,
            rootViewController: UIApplication.kintore_topViewController(),
            adTypes: [AdLoaderAdType.native],
            options: nil
        )
        loader.delegate = self
        adLoader = loader
        loader.load(Request())
    }

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        nativeAd.rootViewController = UIApplication.kintore_topViewController()
        populate(nativeAd)
        loadedHeight = 280
        isHidden = false
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        #if DEBUG
        print("[HomeNativeAd] load failed: \(error.localizedDescription)")
        #endif
        loadedHeight = 0
        isHidden = true
    }

    private func populate(_ nativeAd: NativeAd) {
        headlineLabel.text = nativeAd.headline
        bodyLabel.text = nativeAd.body
        ctaButton.setTitle(nativeAd.callToAction, for: .normal)
        mediaView.mediaContent = nativeAd.mediaContent

        if let icon = nativeAd.icon?.image {
            iconImageView.image = icon
            iconImageView.isHidden = false
        } else {
            iconImageView.image = nil
            iconImageView.isHidden = true
        }

        nativeAdView.nativeAd = nativeAd
    }
}
