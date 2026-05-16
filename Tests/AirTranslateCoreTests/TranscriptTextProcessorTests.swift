import Testing
@testable import AirTranslateCore

@Suite
struct TranscriptTextProcessorTests {
    @Test
    func recentCommittedReplayReturnsOnlyNewTail() {
        let committed = """
        And every day we completed nearly 10 feature requests from the critters routine.
        All right Chad this is my last slide.
        """
        let incoming = """
        And every day, we completed nearly 10 feature requests from the critters routine.
        All right, Chad, this is my last slide.
        I'm yeah, I think we'll be ready.
        """

        let replay = TranscriptTextProcessor.incomingTailAfterRecentCommittedReplay(
            incoming,
            committedText: committed,
            languageID: "en-US"
        )

        #expect(replay?.committedText == """
        And every day, we completed nearly 10 feature requests from the critters routine.
        All right, Chad, this is my last slide.
        """)
        #expect(replay?.tailText == "I'm yeah, I think we'll be ready.")
    }

    @Test
    func recentReplayDoesNotCrossParagraphBoundary() {
        let committed = """
        And every day we completed nearly 10 feature requests

        All right Chad this is my last slide
        """
        let incoming = """
        And every day we completed nearly 10 feature requests
        All right Chad this is my last slide
        I'm yeah, I think we'll be ready
        """

        let replay = TranscriptTextProcessor.incomingTailAfterRecentCommittedReplay(
            incoming,
            committedText: committed,
            languageID: "en-US"
        )

        #expect(replay == nil)
    }

    @Test
    func currentPartialRevisionAcceptsWordCompletion() {
        #expect(TranscriptTextProcessor.isRevisionOfCurrentPartial(
            current: "T",
            incoming: "Typically, this kind of loop can truly take anywhere"
        ))
        #expect(TranscriptTextProcessor.isRevisionOfCurrentPartial(
            current: "So to sum",
            incoming: "So to summarize on my piece here"
        ))
    }

    @Test
    func currentPartialRevisionAcceptsJapaneseInternalCorrection() {
        let first = "するの冷たい空気をいで暖かい空気をさない日本では保温光景というのか"
        let second = "するの冷たい空気をいで温かい空気をさない日本では保温光景というのかしら"
        let third = "するの冷たい空気をいで暖かい空気を逃さない日本では保温光景というのかしら"

        #expect(TranscriptTextProcessor.isRevisionOfCurrentPartial(
            current: first,
            incoming: second
        ))
        #expect(TranscriptTextProcessor.isRevisionOfCurrentPartial(
            current: second,
            incoming: third
        ))
        #expect(TranscriptTextProcessor.preferredPartialText(current: second, incoming: third) == third)
    }

    @Test
    func volatileJapaneseFragmentCanBeSuperseded() {
        #expect(TranscriptTextProcessor.isVolatileFragmentSuperseded(
            current: "あ",
            incoming: "するの冷たい空気をいで暖かい空気をさない"
        ))
        #expect(TranscriptTextProcessor.isVolatileFragmentSuperseded(
            current: "こった",
            incoming: "こってるビュー"
        ))
        #expect(!TranscriptTextProcessor.isVolatileFragmentSuperseded(
            current: "あ。",
            incoming: "するの冷たい空気をいで暖かい空気をさない"
        ))
        #expect(!TranscriptTextProcessor.isVolatileFragmentSuperseded(
            current: "네",
            incoming: "다음 문장으로 넘어가겠습니다"
        ))
    }

    @Test
    func committedJapaneseRevisionReplacesRecentLine() {
        let committed = "するの冷たい空気をいで暖かい空気をさない日本では保温光景というのか"
        let incoming = "するの冷たい空気をいで暖かい空気を逃さない日本では保温光景というのかしら"

        let replaced = TranscriptTextProcessor.committedTextByReplacingRevision(
            with: incoming,
            committedText: committed,
            languageID: "ja-JP",
            allowsBackfill: false
        )

        #expect(replaced == incoming)
    }

    @Test
    func unrelatedPartialDoesNotReplaceCurrentPartial() {
        #expect(!TranscriptTextProcessor.isRevisionOfCurrentPartial(
            current: "방금 가",
            incoming: "방금 물"
        ))
        #expect(!TranscriptTextProcessor.isRevisionOfCurrentPartial(
            current: "First sentence from the speaker",
            incoming: "Second sentence from the speaker"
        ))
    }

    @Test
    func repeatedPartialAfterParagraphBreakCanBeRealSpeech() {
        let committed = """
        Previous line
        All right Chad this is my last slide
        """
        let repeated = "All right Chad this is my last slide"

        #expect(!TranscriptTextProcessor.shouldAppendCommittedPartial(
            repeated,
            to: committed,
            pendingParagraphBreak: false
        ))
        #expect(TranscriptTextProcessor.shouldAppendCommittedPartial(
            repeated,
            to: committed,
            pendingParagraphBreak: true
        ))
    }

    @Test
    func displayTailKeepsRecentTextAtLineBoundary() {
        let text = """
        First line that can be hidden
        Second line that should stay visible
        Third line that should also stay visible
        """

        #expect(TranscriptTextProcessor.displayTail(
            from: text,
            maxCharacters: 75
        ) == """
        ...
        Second line that should stay visible
        Third line that should also stay visible
        """)
    }

    @Test
    func displayTailFallsBackToCharacterBoundary() {
        let text = "abcdefghijklmnopqrstuvwxyz"

        #expect(TranscriptTextProcessor.displayTail(
            from: text,
            maxCharacters: 8
        ) == """
        ...
        stuvwxyz
        """)
    }

    @Test
    func organizeTranscriptSplitsEnglishLivePartialIntoStableSegments() {
        let text = """
        It's built on top of the responses API that hundreds of thousands of developers already use. So most of you who have used our platform before should be familiar with the foundation. The second thing is ChatKit. We've heard this one loud and clear, and we're making it easy to bring great chat experiences right into your own apps.
        """

        let organized = TranscriptTextProcessor.organizeTranscript(text, languageID: "en-US")
        let segments = organized.split(separator: "\n", omittingEmptySubsequences: true)

        #expect(segments.count == 4)
        #expect(segments.first == "It's built on top of the responses API that hundreds of thousands of developers already use.")
        #expect(segments.last == "We've heard this one loud and clear, and we're making it easy to bring great chat experiences right into your own apps.")
    }
}
