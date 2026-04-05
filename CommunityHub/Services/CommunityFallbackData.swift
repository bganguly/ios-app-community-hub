import Foundation

enum CommunityFallbackData {
    static let videos: [ContentItem] = [
        ContentItem(
            id: "113bdcc0-84e4-40eb-b593-13a7f80922e0",
            title: "How to Study - 1 Month Before AP Exams",
            description: "A quick set of practical AP prep habits you can start today.",
            audience: .student,
            category: .ap,
            requiresLogin: true,
            language: .english,
            kind: .video(
                duration: "0:52",
                thumbnailURL: URL(string: "https://img.youtube.com/vi/4NGqgFUg7o0/hqdefault.jpg"),
                thumbnailFallbackURL: URL(string: "https://i.ytimg.com/vi/4NGqgFUg7o0/hqdefault.jpg")
            )
        ),
        ContentItem(
            id: "ee07d043-050e-477a-a228-91a81df04421",
            title: "Winning SAT Advice from Student Tutors",
            description: "Peer tutors share high-impact SAT prep techniques and explain how to use practice results effectively.",
            audience: .student,
            category: .sat,
            requiresLogin: true,
            language: .english,
            kind: .video(
                duration: "2:43",
                thumbnailURL: URL(string: "https://img.youtube.com/vi/TClczWs7tnk/hqdefault.jpg"),
                thumbnailFallbackURL: URL(string: "https://i.ytimg.com/vi/TClczWs7tnk/hqdefault.jpg")
            )
        ),
        ContentItem(
            id: "2d185072-c722-401d-98f4-f233b6a4a272",
            title: "Understanding PSATs - For Parents",
            description: "Learn how PSAT score ranges and benchmarks work across grade levels and what they mean for growth.",
            audience: .parent,
            category: .sat,
            requiresLogin: false,
            language: .english,
            kind: .video(
                duration: "3:26",
                thumbnailURL: URL(string: "https://img.youtube.com/vi/zPNCoSQTDw0/hqdefault.jpg"),
                thumbnailFallbackURL: URL(string: "https://i.ytimg.com/vi/zPNCoSQTDw0/hqdefault.jpg")
            )
        ),
        ContentItem(
            id: "43ccb890-09c3-4ea9-aef9-2851b7f455a3",
            title: "Understanding Financial Aid Award Packages",
            description: "Understand direct and indirect costs, aid types, and how to evaluate your award letter with confidence.",
            audience: .parent,
            category: .financialAid,
            requiresLogin: false,
            language: .english,
            kind: .video(
                duration: "3:01",
                thumbnailURL: URL(string: "https://img.youtube.com/vi/3JJAq0m-9ho/hqdefault.jpg"),
                thumbnailFallbackURL: URL(string: "https://i.ytimg.com/vi/3JJAq0m-9ho/hqdefault.jpg")
            )
        ),
        ContentItem(
            id: "7d35d4cb-8929-413e-9daa-c5f42d69967c",
            title: "How to Make Great College Visits",
            description: "A practical walkthrough to plan, observe, and ask stronger questions during campus visits.",
            audience: .student,
            category: .collegePlanning,
            requiresLogin: false,
            language: .english,
            kind: .video(
                duration: "3:06",
                thumbnailURL: URL(string: "https://img.youtube.com/vi/8Iic1JivdmM/hqdefault.jpg"),
                thumbnailFallbackURL: URL(string: "https://i.ytimg.com/vi/8Iic1JivdmM/hqdefault.jpg")
            )
        )
    ]

    static let articles: [ContentItem] = [
        ContentItem(
            id: "9b889bc1-7497-4577-9aaf-965c6bafea6e",
            title: "Test Scores and College Applications: What You Need to Know",
            description: "What test-optional means, how colleges evaluate scores, and when sending scores can help.",
            audience: .student,
            category: .collegePlanning,
            requiresLogin: false,
            language: .english,
            kind: .article(readTime: "5 min read")
        ),
        ContentItem(
            id: "ca4721c1-9f3b-48e6-9850-610be65488d8",
            title: "FAFSA Tips for the Class of 2026",
            description: "A concise checklist to prepare accounts, documents, and deadlines before FAFSA opens.",
            audience: .student,
            category: .collegePlanning,
            requiresLogin: false,
            language: .english,
            kind: .article(readTime: "5 min read")
        ),
        ContentItem(
            id: "c4314024-a88d-49e2-928c-774200a21976",
            title: "Free Resources to Prepare for AP Exams",
            description: "Use AP Daily practice videos and AP Classroom resources to prepare more effectively.",
            audience: .student,
            category: .ap,
            requiresLogin: false,
            language: .english,
            kind: .article(readTime: "5 min read")
        ),
        ContentItem(
            id: "0a2af09a-c91d-4ad8-9f32-459b92d0b3a0",
            title: "Understanding Your SAT Scores",
            description: "Interpret your SAT report, identify skill gaps, and choose the right next prep actions.",
            audience: .student,
            category: .sat,
            requiresLogin: true,
            language: .english,
            kind: .article(readTime: "5 min read")
        ),
        ContentItem(
            id: "2847f9f3-849c-4ebf-850b-6cc000994d03",
            title: "What is the Difference Between CSS Profile and FAFSA?",
            description: "Understand what each application does, where to submit, and how they work together.",
            audience: .student,
            category: .financialAid,
            requiresLogin: true,
            language: .english,
            kind: .article(readTime: "5 min read")
        )
    ]
}
