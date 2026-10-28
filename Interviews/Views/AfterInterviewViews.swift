//
//  AfterInterviewViews.swift
//  Interviews
//

import SwiftUI
import UserNotifications

/// "How did it go?": the debrief and any feedback for one stage, saved to interviews.tools
struct DebriefView: View {
    let interviewId: Int
    let title: String

    @Environment(\.dismiss) private var dismiss
    @State private var rating = 0
    @State private var notes = ""
    @State private var peopleMet = ""
    @State private var questions = ""
    @State private var nextStep = ""
    @State private var hasReplyBy = false
    @State private var replyBy = Date()
    @State private var feedbackType = ""
    @State private var feedbackText = ""
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("How did it go?") {
                    Picker("Rating", selection: $rating) {
                        Text("Not rated").tag(0)
                        ForEach(1...5, id: \.self) { Text(String(repeating: "★", count: $0)).tag($0) }
                    }
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(3...8)
                    TextField("Who you met", text: $peopleMet, axis: .vertical)
                }
                Section {
                    TextField("One question per line", text: $questions, axis: .vertical).lineLimit(3...12)
                } header: {
                    Text("Questions they asked")
                } footer: {
                    Text("These go into your question bank for the next round.")
                }
                Section("What happens next") {
                    TextField("Next step", text: $nextStep)
                    Toggle("They said they'd reply by", isOn: $hasReplyBy)
                    if hasReplyBy {
                        DatePicker("Reply by", selection: $replyBy, displayedComponents: .date)
                    }
                }
                Section("Feedback") {
                    Picker("Feedback", selection: $feedbackType) {
                        Text("Not recorded").tag("")
                        Text("No feedback").tag("NONE")
                        Text("Generic").tag("GENERIC")
                        Text("Specific").tag("SPECIFIC")
                    }
                    if !feedbackType.isEmpty && feedbackType != "NONE" {
                        TextField("What they said", text: $feedbackText, axis: .vertical)
                    }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .disabled(loading)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { Task { await save() } }.disabled(loading) }
            }
            .task { await load() }
        }
    }

    private func load() async {
        defer { loading = false }
        do {
            let saved = try await APIService.shared.fetchDebrief(interviewId: interviewId)
            rating = saved.rating ?? 0
            notes = saved.debriefNotes ?? ""
            peopleMet = saved.peopleMet ?? ""
            questions = saved.questionsAsked ?? ""
            nextStep = saved.nextStep ?? ""
            if let day = APIDates.day(saved.replyBy) { hasReplyBy = true; replyBy = day }
            feedbackType = saved.feedbackType ?? ""
            feedbackText = saved.feedbackText ?? ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func save() async {
        let request = DebriefRequest(
            debrief: .init(rating: rating == 0 ? nil : rating, debriefNotes: notes, peopleMet: peopleMet, questionsAsked: questions,
                           nextStep: nextStep, replyBy: hasReplyBy ? "\(APIDates.dayString(replyBy))T00:00:00.000Z" : nil),
            feedback: .init(type: feedbackType.isEmpty ? nil : feedbackType, text: feedbackType == "NONE" ? "" : feedbackText)
        )
        do {
            try await APIService.shared.saveDebrief(interviewId: interviewId, request)
            DebriefReminders.cancel(interviewId: interviewId)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// Preparation notes for a stage and the STAR stories you plan to use
struct PrepView: View {
    let interviewId: Int
    let title: String

    @Environment(\.dismiss) private var dismiss
    @State private var notes = ""
    @State private var chosen = Set<Int>()
    @State private var stories: [APIStory] = []
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Notes") {
                    TextField("What to read up on, questions to ask…", text: $notes, axis: .vertical).lineLimit(4...12)
                }
                Section {
                    if stories.isEmpty {
                        Text("No STAR stories yet. Add them under Settings → STAR stories.").foregroundStyle(.secondary)
                    }
                    ForEach(stories) { story in
                        Toggle(story.title, isOn: Binding(get: { chosen.contains(story.id) }, set: { if $0 { chosen.insert(story.id) } else { chosen.remove(story.id) } }))
                    }
                } header: {
                    Text("Stories to use")
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Prepare: \(title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            do {
                                try await APIService.shared.savePrep(interviewId: interviewId, APIPrep(notes: notes, storyIds: Array(chosen)))
                                dismiss()
                            } catch { self.error = error.localizedDescription }
                        }
                    }
                }
            }
            .task {
                do {
                    async let prep = APIService.shared.fetchPrep(interviewId: interviewId)
                    async let all = APIService.shared.fetchStories()
                    let (p, s) = try await (prep, all)
                    notes = p.notes
                    chosen = Set(p.storyIds)
                    stories = s
                } catch { self.error = error.localizedDescription }
            }
        }
    }
}

/// Every question you've been asked, newest first, searchable
struct QuestionsView: View {
    @State private var entries: [APIQuestionEntry] = []
    @State private var search = ""
    @State private var error: String?

    var body: some View {
        List {
            if let error { Text(error).foregroundStyle(.red) }
            ForEach(QuestionBank.filter(entries, search: search)) { entry in
                Section {
                    ForEach(entry.questions, id: \.self) { Text($0) }
                } header: {
                    Text("\(entry.stage) · \(entry.company)")
                } footer: {
                    Text([entry.jobTitle, entry.recruiter.map { "via \($0)" }].compactMap { $0 }.joined(separator: " "))
                }
            }
        }
        .overlay {
            if entries.isEmpty && error == nil {
                ContentUnavailableView("No questions yet", systemImage: "questionmark.bubble", description: Text("Questions you note in a debrief collect here."))
            }
        }
        .searchable(text: $search)
        .navigationTitle("Questions asked")
        .task {
            do { entries = try await APIService.shared.fetchQuestions() } catch { self.error = error.localizedDescription }
        }
    }
}

enum QuestionBank {
    static func filter(_ entries: [APIQuestionEntry], search: String) -> [APIQuestionEntry] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return entries }
        return entries.filter { entry in
            ([entry.company, entry.recruiter, entry.stage, entry.jobTitle, entry.notes].compactMap { $0 } + entry.questions)
                .contains { $0.lowercased().contains(q) }
        }
    }
}

/// Reusable STAR stories
struct StoriesView: View {
    @State private var stories: [APIStory] = []
    @State private var editing: APIStory?
    @State private var adding = false
    @State private var error: String?

    var body: some View {
        List {
            if let error { Text(error).foregroundStyle(.red) }
            ForEach(stories) { story in
                Button { editing = story } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(story.title).foregroundStyle(.primary)
                        if !story.tags.isEmpty { Text(story.tags.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary) }
                        if !story.usedIn.isEmpty {
                            Text("Used \(story.usedIn.count) time\(story.usedIn.count == 1 ? "" : "s")").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete { offsets in
                let ids = offsets.map { stories[$0].id }
                Task {
                    for id in ids { try? await APIService.shared.deleteStory(id: id) }
                    await load()
                }
            }
        }
        .overlay {
            if stories.isEmpty && error == nil {
                ContentUnavailableView("No stories yet", systemImage: "text.book.closed", description: Text("Write up situations you can reuse across interviews: situation, task, action, result."))
            }
        }
        .navigationTitle("STAR stories")
        .toolbar { Button { adding = true } label: { Image(systemName: "plus") } }
        .sheet(item: $editing) { story in StoryEditor(story: story) { await load() } }
        .sheet(isPresented: $adding) { StoryEditor(story: nil) { await load() } }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do { stories = try await APIService.shared.fetchStories(); error = nil } catch { self.error = error.localizedDescription }
    }
}

private struct StoryEditor: View {
    let story: APIStory?
    let onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input = StoryInput()
    @State private var tags = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $input.title)
                Section("Situation") { TextField("", text: $input.situation, axis: .vertical) }
                Section("Task") { TextField("", text: $input.task, axis: .vertical) }
                Section("Action") { TextField("", text: $input.action, axis: .vertical) }
                Section("Result") { TextField("", text: $input.result, axis: .vertical) }
                Section("Tags") { TextField("leadership, conflict…", text: $tags) }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle(story == nil ? "New story" : "Edit story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        input.tags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        Task {
                            do {
                                try await APIService.shared.saveStory(id: story?.id, input)
                                await onSaved()
                                dismiss()
                            } catch { self.error = error.localizedDescription }
                        }
                    }
                    .disabled(input.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                guard let story else { return }
                input = StoryInput(title: story.title, situation: story.situation, task: story.task, action: story.action, result: story.result, tags: story.tags)
                tags = story.tags.joined(separator: ", ")
            }
        }
    }
}

/// "How did it go?" half an hour after each synced interview ends, until it's debriefed
enum DebriefReminders {
    static func reminderDate(start: Date, durationMinutes: Int?) -> Date {
        start.addingTimeInterval(TimeInterval(((durationMinutes ?? 60) + 30) * 60))
    }

    @MainActor
    static func schedule(_ interviews: [Interview]) async {
        let center = UNUserNotificationCenter.current()
        let old = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("debrief-") }
        center.removePendingNotificationRequests(withIdentifiers: old)

        let upcoming = interviews.compactMap { interview -> (Int, String, Date)? in
            guard let id = interview.id, let start = interview.date, interview.outcome == nil || interview.outcome == .scheduled else { return nil }
            let at = reminderDate(start: start, durationMinutes: interview.durationMinutes)
            return at > Date() ? (id, "\(interview.stage?.stage ?? "Interview") at \(interview.company?.name ?? "")", at) : nil
        }
        guard !upcoming.isEmpty, (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
        for (id, title, at) in upcoming.prefix(60) { // iOS keeps 64 pending at most
            let content = UNMutableNotificationContent()
            content.title = "How did it go?"
            content.body = "Note the questions and next steps from your \(title) while they're fresh."
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: at), repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "debrief-\(id)", content: content, trigger: trigger))
        }
    }

    static func cancel(interviewId: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["debrief-\(interviewId)"])
    }
}
