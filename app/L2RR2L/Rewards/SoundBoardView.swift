import SwiftUI

/// Grown-ups' Sound Board (design v2, section 2): every letter sound, held
/// sound, word and Star Voice line with a play button. Mark anything that
/// sounds wrong; the flagged list can be shared so the recordings get fixed.
struct SoundBoardView: View {
    @Environment(AppServices.self) private var services
    @State private var flagged: Set<String> = SoundBoardFlags.load()
    @State private var playing: String?
    @State private var section = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $section) {
                Text("Letter sounds").tag(0)
                Text("Words").tag(1)
                Text("Star Voice").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                switch section {
                case 0:
                    Section("Tap to hear. Held sounds play for 2 seconds.") {
                        ForEach(Self.letterKeys, id: \.self) { key in
                            row(id: "sound:\(key)", title: Self.label(for: key), subtitle: Self.example(for: key),
                                missing: !Self.hasSound(key)) {
                                await services.phonemes.prepare([key])
                                await services.phonemes.tap(key, holdFor: 2)
                            }
                        }
                    }
                case 1:
                    ForEach(Self.words, id: \.self) { word in
                        row(id: "word:\(word)", title: word, subtitle: nil,
                            missing: Speaker.url(word, in: "Media/words") == nil) {
                            _ = await services.speaker.sayWord(word)
                        }
                    }
                default:
                    ForEach(Self.lines.sorted { $0.value < $1.value }, id: \.key) { slug, text in
                        row(id: "line:\(slug)", title: text, subtitle: nil,
                            missing: Speaker.url(slug, in: "Media/voice") == nil) {
                            _ = await services.speaker.play(slug, in: "Media/voice", label: text)
                        }
                    }
                }
            }
        }
        .navigationTitle("Sound Board")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: SoundBoardFlags.report(flagged)) {
                    Label("Share \(flagged.count) flagged", systemImage: "square.and.arrow.up")
                }
                .disabled(flagged.isEmpty)
            }
        }
    }

    private func row(id: String, title: String, subtitle: String?, missing: Bool,
                     play: @escaping () async -> Void) -> some View {
        HStack(spacing: 14) {
            Button {
                playing = id
                Task {
                    await play()
                    if playing == id { playing = nil }
                }
            } label: {
                Image(systemName: playing == id ? "speaker.wave.3.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(missing ? Color.gray : Theme.sky)
            }
            .buttonStyle(.plain)
            .disabled(missing)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(.title3, design: .rounded).weight(.semibold))
                if missing {
                    Text("not recorded yet").font(.caption).foregroundStyle(.secondary)
                } else if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                if flagged.contains(id) { flagged.remove(id) } else { flagged.insert(id) }
                SoundBoardFlags.save(flagged)
            } label: {
                Image(systemName: flagged.contains(id) ? "flag.fill" : "flag")
                    .font(.title3)
                    .foregroundStyle(flagged.contains(id) ? Color.red : Color.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(flagged.contains(id) ? "Flagged as wrong" : "Flag as wrong")
        }
        .padding(.vertical, 4)
    }

    // MARK: Content

    static let letterKeys: [String] = {
        let order = ["s", "a", "t", "p", "i", "n", "m", "d", "g", "o", "c", "k", "ck", "e", "u", "r", "h", "b", "f", "ff",
                     "l", "ll", "ss", "j", "v", "w", "x", "y", "z", "qu", "sh", "ch", "th", "th_v", "wh", "ng", "nk",
                     "a_e", "i_e", "o_e", "u_e", "e_e", "ee", "ea", "ai", "ay", "oa", "ow", "igh", "oo", "oo_book",
                     "ou", "ow_cow", "oi", "oy", "ar", "or", "er", "ir", "ur", "y_i", "y_e"]
        return order
    }()

    static func hasSound(_ key: String) -> Bool {
        Speaker.url(key, in: "Media/phonemes") != nil || Speaker.url("\(key)-long", in: "Media/phonemes") != nil
    }

    static func label(for key: String) -> String {
        switch key {
        case "th_v": "th (voiced)"
        case "oo_book": "oo (short)"
        case "ow_cow": "ow (cow)"
        case "y_i": "y (my)"
        case "y_e": "y (happy)"
        default: key.replacingOccurrences(of: "_", with: "-")
        }
    }

    static func example(for key: String) -> String? {
        let examples: [String: String] = [
            "s": "sun", "a": "ant", "t": "top", "p": "pig", "i": "ink", "n": "net", "m": "map", "d": "dog",
            "g": "gum", "o": "pot", "c": "cat", "k": "kit", "ck": "duck", "e": "egg", "u": "cup", "r": "red",
            "h": "hat", "b": "bed", "f": "fan", "l": "leg", "j": "jam", "v": "van", "w": "web", "x": "box",
            "y": "yak", "z": "zip", "qu": "quilt", "sh": "ship", "ch": "chip", "th": "thin", "th_v": "this",
            "wh": "when", "ng": "ring", "nk": "pink", "a_e": "cake", "i_e": "kite", "o_e": "bone", "u_e": "cube",
            "e_e": "these", "ee": "tree", "ea": "leaf", "ai": "rain", "ay": "tray", "oa": "boat", "ow": "snow",
            "igh": "night", "oo": "moon", "oo_book": "book", "ou": "cloud", "ow_cow": "cow", "oi": "coin",
            "oy": "toy", "ar": "car", "or": "fork", "er": "her", "ir": "bird", "ur": "purse", "y_i": "my", "y_e": "happy",
            "ff": "huff", "ll": "bell", "ss": "kiss",
        ]
        return examples[key].map { "as in \($0)" }
    }

    static let words: [String] = {
        let list = (try? JSONDecoder().decode(VoiceList.self, from: voiceListData))?.words ?? []
        return list.isEmpty ? Curriculum.shared.stages.flatMap { $0.words.map(\.text) } : list
    }()

    static let lines: [String: String] = (try? JSONDecoder().decode(VoiceList.self, from: voiceListData))?.lines ?? [:]

    private struct VoiceList: Decodable {
        let lines: [String: String]
        let words: [String]
    }

    private static var voiceListData: Data {
        Bundle.main.url(forResource: "voice_lines", withExtension: "json", subdirectory: "Media/content")
            .flatMap { try? Data(contentsOf: $0) } ?? Data()
    }
}

/// Flags persist on the device so a grown-up can check sounds over a few days.
enum SoundBoardFlags {
    private static let key = "soundBoardFlags"

    static func load() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    static func save(_ flags: Set<String>) {
        UserDefaults.standard.set(Array(flags).sorted(), forKey: key)
    }

    static func report(_ flags: Set<String>) -> String {
        "Cutisie Reads: sounds that sound wrong\n\n" + flags.sorted().map { "- \($0)" }.joined(separator: "\n")
    }
}
