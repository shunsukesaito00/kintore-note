// File: Core/ModelContainerFactory.swift
// 本番用・Preview/テスト用の ModelContainer を生成する。
//
// 永続ストアはローカルのみ（cloudKitDatabase: .none）。
// App Group 上の既定ストアが開けない場合は、アプリサンドボックス専用の別構成で再試行する。

import Foundation
import SwiftData
import os

enum ModelContainerFactory {

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.shunsukesaito.kintore", category: "ModelContainer")

    /// スキーマは `KintoreSchemaV1` に集約。軽量マイグレーションに加え、将来は `KintoreMigrationPlan` に段階を追加する。
    private static let schema = Schema(versionedSchema: KintoreSchemaV1.self)

    /// 将来 SwiftData + CloudKit を再度有効化する場合のコンテナ ID（entitlements と一致させる）
    static let cloudContainerId = "iCloud.com.shunsukesaito.kintore"

    private static let appGroupIdentifier = "group.com.shunsukesaito.kintore"

    private static let lastOpenErrorKey = "kintore.modelContainer.lastOpenErrorSummary"
    private static let lastOpenErrorTimeKey = "kintore.modelContainer.lastOpenErrorDate"
    private static let usingSandboxFallbackKey = "kintore.modelContainer.usingSandboxFallback"
    private static let pendingEraseKey = "kintore.pendingErasePersistentStore"

    /// 旧実装の名残。CloudKit プライマリ廃止のため常に false 相当（キーは読み取り互換のため残す）。
    static var didFallbackFromCloudKitToLocal: Bool {
        UserDefaults.standard.bool(forKey: "kintore.modelContainer.fallbackFromCloudToLocal")
    }

    /// App Group ストアが開けず、サンドボックス専用のフォールバックで起動している。
    static var isUsingSandboxFallback: Bool {
        UserDefaults.standard.bool(forKey: usingSandboxFallbackKey)
    }

    /// サポート・設定表示用。直近の永続ストアオープン失敗の要約（永続オープン成功時にクリア）。
    static var lastOpenFailureSummary: String? {
        UserDefaults.standard.string(forKey: lastOpenErrorKey)
    }

    /// 設定から「保存データ削除」を予約済みか（次回起動の先頭で削除処理）。
    static var isPendingPersistentStoreErase: Bool {
        UserDefaults.standard.bool(forKey: pendingEraseKey)
    }

    /// 設定の「保存データを削除して次回起動で修復」用。
    static func requestPersistentStoreEraseOnNextLaunch() {
        UserDefaults.standard.set(true, forKey: pendingEraseKey)
    }

    static func recordProductionOpenFailure(_ error: Error, phase: String) {
        let typeName = String(describing: type(of: error))
        let msg = "[\(phase)] \(typeName): \(error.localizedDescription)"
        let truncated = String(msg.prefix(500))
        UserDefaults.standard.set(truncated, forKey: lastOpenErrorKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastOpenErrorTimeKey)
        logger.error("Persistent ModelContainer failed (\(phase, privacy: .public)): \(error.localizedDescription, privacy: .public)")
    }

    static func clearLastOpenFailureRecord() {
        UserDefaults.standard.removeObject(forKey: lastOpenErrorKey)
        UserDefaults.standard.removeObject(forKey: lastOpenErrorTimeKey)
    }

    /// 次回起動用に予約されたローカル SwiftData 関連ファイルを可能な範囲で削除する（ベストエフォート）。
    static func performPendingPersistentStoreEraseIfNeeded() {
        guard UserDefaults.standard.bool(forKey: pendingEraseKey) else { return }
        UserDefaults.standard.set(false, forKey: pendingEraseKey)
        UserDefaults.standard.set(false, forKey: usingSandboxFallbackKey)
        let fm = FileManager.default
        if let groupURL = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            Self.eraseSwiftDataArtifactsInDirectory(groupURL, using: fm)
        }
        if let lib = fm.urls(for: .libraryDirectory, in: .userDomainMask).first {
            let support = lib.appendingPathComponent("Application Support", isDirectory: true)
            if fm.fileExists(atPath: support.path) {
                Self.eraseSwiftDataArtifactsInDirectory(support, using: fm)
            }
        }
        logger.notice("Performed pending persistent store erase (best-effort).")
    }

    private static func eraseSwiftDataArtifactsInDirectory(_ base: URL, using fm: FileManager) {
        guard let items = try? fm.contentsOfDirectory(at: base, includingPropertiesForKeys: nil) else { return }
        for url in items {
            let name = url.lastPathComponent.lowercased()
            let isCandidate =
                name.hasSuffix(".store")
                || name.hasSuffix(".store-shm")
                || name.hasSuffix(".store-wal")
                || name.hasSuffix(".sqlite")
                || name.hasSuffix(".sqlite-shm")
                || name.hasSuffix(".sqlite-wal")
                || name.contains("default.store")
                || name.contains(".swiftdata")
            if isCandidate {
                do {
                    try fm.removeItem(at: url)
                } catch {
                    logger.error("Could not remove \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    /// アプリ本番用（永続化）。まず App Group 既定、失敗時はサンドボックス専用の別ストア。
    static func makeProduction() throws -> ModelContainer {
        UserDefaults.standard.set(false, forKey: "kintore.modelContainer.fallbackFromCloudToLocal")
        UserDefaults.standard.set(false, forKey: usingSandboxFallbackKey)

        let primary = ModelConfiguration(
            nil,
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: KintoreMigrationPlan.self,
                configurations: [primary]
            )
            clearLastOpenFailureRecord()
            return container
        } catch {
            recordProductionOpenFailure(error, phase: "primary_app_group")
            let secondary = ModelConfiguration(
                "KintoreSandboxFallback",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .none,
                cloudKitDatabase: .none
            )
            do {
                let container = try ModelContainer(
                    for: schema,
                    migrationPlan: KintoreMigrationPlan.self,
                    configurations: [secondary]
                )
                UserDefaults.standard.set(true, forKey: usingSandboxFallbackKey)
                let note = String(
                    format: String(localized: "model_store_sandbox_recovery_note_format"),
                    String(describing: type(of: error)),
                    error.localizedDescription
                )
                UserDefaults.standard.set(String(note.prefix(500)), forKey: lastOpenErrorKey)
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastOpenErrorTimeKey)
                logger.notice("Opened secondary sandbox-only persistent store after primary failure.")
                return container
            } catch let secondaryError {
                recordProductionOpenFailure(secondaryError, phase: "secondary_sandbox")
                throw secondaryError
            }
        }
    }

    /// Preview / テスト用（インメモリ）
    static func makeInMemory() throws -> ModelContainer {
        let config = ModelConfiguration(
            nil,
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: KintoreMigrationPlan.self,
            configurations: [config]
        )
    }

    /// エラー文言にマイグレーション関連語が含まれるか（設定画面の案内用）。
    static var lastOpenFailureLooksLikeMigrationIssue: Bool {
        guard let s = lastOpenFailureSummary?.lowercased() else { return false }
        return s.contains("migration")
            || s.contains("schema")
            || s.contains("version")
            || s.contains("マイグレーション")
    }
}
