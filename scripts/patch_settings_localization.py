# -*- coding: utf-8 -*-
from pathlib import Path

p = Path("Kintore/Modules/Settings/SettingsView.swift")
t = p.read_text(encoding="utf-8")

def r(a, b):
    global t
    if a not in t:
        raise SystemExit("missing:\n" + a[:180])
    t = t.replace(a, b, 1)

r('Button("購入を復元")', 'Button(String(localized: "settings_restore_purchases"))')
r('Text("プレミアム")\n            } header:', 'Text(String(localized: "settings_section_premium"))\n            } header:')
r('Text("グラフ全期間・iCloud同期・Watch・CSVエクスポートが利用できます。")', 'Text(String(localized: "settings_footer_premium_features"))')

r('''Picker("休憩デフォルト", selection: $defaultRestSeconds) {
                    Text("60秒").tag(60)
                    Text("90秒").tag(90)
                    Text("120秒").tag(120)
                    Text("180秒").tag(180)
                }''',
'''Picker(String(localized: "settings_picker_rest_default"), selection: $defaultRestSeconds) {
                    Text(String(localized: "settings_rest_60s")).tag(60)
                    Text(String(localized: "settings_rest_90s")).tag(90)
                    Text(String(localized: "settings_rest_120s")).tag(120)
                    Text(String(localized: "settings_rest_180s")).tag(180)
                }''')

r('Label("プレート計算"', 'Label(String(localized: "settings_link_plate_calculator")')
r('Label("身体記録"', 'Label(String(localized: "settings_link_body_metrics")')
r('.accessibilityHint("バーとプレートの枚数から目標重量を分解します")', '.accessibilityHint(String(localized: "settings_plate_calculator_a11y_hint"))')
r('.accessibilityHint("体重・体脂肪率などの記録")', '.accessibilityHint(String(localized: "settings_body_metrics_a11y_hint"))')

r('Toggle("ヘルスケアにワークアウトを保存"', 'Toggle(String(localized: "settings_health_save_toggle")')
r('Text("ヘルスケア")\n            } footer:', 'Text(String(localized: "settings_section_health"))\n            } footer:')
r('Text("ワークアウト保存時に、筋力トレーニングとしてヘルスケアに記録します。初回は許可が必要です。")', 'Text(String(localized: "settings_health_footer"))')
r('Text("このデバイスではヘルスケアを利用できません。")', 'Text(String(localized: "settings_health_unavailable"))')

r('Toggle("再開リマインド"', 'Toggle(String(localized: "settings_toggle_reengagement")')
r('.accessibilityHint("記録が途切れた頃に通知でお知らせ")', '.accessibilityHint(String(localized: "settings_reengagement_a11y_hint"))')
r('Toggle("週次サマリ"', 'Toggle(String(localized: "settings_toggle_weekly_summary")')
r('.accessibilityHint("土曜夜に今週の振り返りを通知")', '.accessibilityHint(String(localized: "settings_weekly_summary_a11y_hint"))')
r('Text("通知")\n            } footer:', 'Text(String(localized: "settings_section_notifications"))\n            } footer:')
r('Text("再開リマインドは記録から3日後に1回のみ。週次サマリは次の土曜20時に1回。通知文に今週の実施回数を含めます（起動時に再スケジュール）。")', 'Text(String(localized: "settings_notifications_footer"))')

r('''Picker("外観", selection: $themeRaw) {
                    Text("システムに合わせる").tag("system")
                    Text("常にライト").tag("light")
                    Text("常にダーク").tag("dark")
                }''',
'''Picker(String(localized: "settings_picker_appearance"), selection: $themeRaw) {
                    Text(String(localized: "settings_theme_system")).tag("system")
                    Text(String(localized: "settings_theme_light")).tag("light")
                    Text(String(localized: "settings_theme_dark")).tag("dark")
                }''')

r('Text("表示")\n            }\n\n            Section {\n                NavigationLink(destination: ExerciseListView())', 'Text(String(localized: "settings_section_display"))\n            }\n\n            Section {\n                NavigationLink(destination: ExerciseListView())')

r('Label("種目一覧"', 'Label(String(localized: "nav_exercise_list")')
r('.accessibilityLabel("種目一覧")', '.accessibilityLabel(String(localized: "nav_exercise_list"))')
r('.accessibilityHint("種目の追加・編集・削除")', '.accessibilityHint(String(localized: "settings_manage_exercises_a11y_hint"))')
r('Label("ルーティン管理"', 'Label(String(localized: "nav_routine_management")')
r('.accessibilityLabel("ルーティン管理")', '.accessibilityLabel(String(localized: "nav_routine_management"))')
r('.accessibilityHint("ルーティンの一覧と編集")', '.accessibilityHint(String(localized: "settings_manage_routines_a11y_hint"))')
r('Text("管理")\n            }\n\n            Section {\n                if premium.isPremium', 'Text(String(localized: "settings_section_manage"))\n            }\n\n            Section {\n                if premium.isPremium')

r('Label("iCloudでバックアップ済み"', 'Label(String(localized: "settings_data_icloud_backup")')
r('.accessibilityLabel("iCloudでバックアップ済み")', '.accessibilityLabel(String(localized: "settings_data_icloud_backup"))')

r('''HStack {
                    Text("記録")
                    Spacer()
                    Text("\\(sessionCount) セッション・\\(setCount) セット")
                        .foregroundStyle(.secondary)
                }''',
'''HStack {
                    Text(String(localized: "settings_data_summary_label"))
                    Spacer()
                    Text(String(format: String(localized: "settings_data_session_set_format"), sessionCount, setCount))
                        .foregroundStyle(.secondary)
                }''')

r('Label("CSVでエクスポート（全期間）"', 'Label(String(localized: "settings_export_csv_full")')
r('Label("期間を指定してエクスポート"', 'Label(String(localized: "settings_export_csv_range")')
r('Text("データ")\n            } footer:', 'Text(String(localized: "settings_section_data"))\n            } footer:')
r('Text("CSVエクスポートはプレミアムで利用できます。")', 'Text(String(localized: "settings_footer_csv_premium_only"))')
r('Text("ワークアウトは全期間または開始日・終了日を指定して出力できます。身体記録は「身体記録」画面からCSV出力できます。")', 'Text(String(localized: "settings_data_footer_csv_help"))')
r('Text("同じ Apple ID の iPhone と iPad では、プレミアム有効時に iCloud 経由で記録が同期されます。どちらか一方で保存した内容が、もう一方の端末に反映されます（ネットワーク状況により反映まで時間がかかることがあります）。")', 'Text(String(localized: "settings_data_footer_icloud_sync"))')
r('Text("複数端末で同じ記録に触れた場合は、最後に保存した内容が優先されます。詳細な競合解決画面はありません。")', 'Text(String(localized: "settings_data_footer_conflict"))')

r('Text("アプリ名")', 'Text(String(localized: "settings_about_app_name"))')
r('Text("バージョン")', 'Text(String(localized: "settings_about_version"))')
r('Text("About")\n            }\n        }\n        .tint', 'Text(String(localized: "settings_section_about"))\n            }\n        }\n        .tint')

r('DatePicker("開始日", selection: $startDate, displayedComponents: .date)', 'DatePicker(String(localized: "settings_export_start_date"), selection: $startDate, displayedComponents: .date)')
r('DatePicker("終了日", selection: $endDate, displayedComponents: .date)', 'DatePicker(String(localized: "settings_export_end_date"), selection: $endDate, displayedComponents: .date)')
r('Text("完了したワークアウトのうち、セッション開始日時がこの期間に含まれる行を出力します。")', 'Text(String(localized: "settings_export_range_footer"))')
r('.navigationTitle("期間を指定")', '.navigationTitle(String(localized: "settings_export_range_title"))')
r('Button("キャンセル") { dismiss() }', 'Button(String(localized: "common_cancel")) { dismiss() }')
r('Button("エクスポート") { runExport() }', 'Button(String(localized: "settings_export_action")) { runExport() }')
r('validationMessage = "終了日は開始日以降にしてください。"', 'validationMessage = String(localized: "settings_export_error_end_before_start")')
r('validationMessage = "CSVの生成に失敗しました。"', 'validationMessage = String(localized: "settings_export_error_csv_failed")')

p.write_text(t, encoding="utf-8")
print("ok")
