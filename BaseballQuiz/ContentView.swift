import SwiftUI

// MARK: - 數據模型
struct Question: Identifiable {
    let id = UUID()
    let text: String
    let correctAnswer: String
    let wrongAnswers: [String]
    
    /// 存儲該題固定的選項順序（初始化時設置）
    private(set) var fixedShuffledOptions: [String] = []
    
    /// 初始化函數
    init(text: String, correctAnswer: String, wrongAnswers: [String]) {
        self.text = text
        self.correctAnswer = correctAnswer
        self.wrongAnswers = wrongAnswers
        // 在初始化時就固定選項的隨機順序
        self.fixedShuffledOptions = ([correctAnswer] + wrongAnswers).shuffled()
    }
    
    /// 取得該題固定的選項列表
    var shuffledOptions: [String] {
        fixedShuffledOptions
    }
    
    /// 取得正確答案在隨機排序中的索引
    var correctAnswerIndex: Int {
        shuffledOptions.firstIndex(of: correctAnswer) ?? 0
    }
}

struct ContentView: View {
    // MARK: - 遊戲階段列舉
    enum Stage { case cover, quiz, result }
    
    // MARK: - 狀態變數
    @State private var stage: Stage = .cover
    @State private var allQuestions: [Question] = Self.buildQuestionBank()
    @State private var currentQuestions: [Question] = []
    @State private var questionIndex = 0
    @State private var showAnswer = false
    @State private var selectedIndex: Int? = nil
    @State private var score = 0
    @State private var correctStreak = 0  // 連續答對計數
    @State private var totalScore = 0     // 總分（含Combo獎勵）
    @State private var answeredQuestions = 0  // 已作答題數
    
    var body: some View {
        ZStack {
            // MARK: - 背景設計：修正排版跑掉的問題
            // 利用 Color.clear 鎖定螢幕真實尺寸，將圖片作為 overlay 疊加上去
            Color.clear
                .overlay(
                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.5)
                )
                .ignoresSafeArea() // 讓圖片延伸到瀏海與底部安全區
            
            // 添加毛玻璃效果/遮罩層，確保文字清晰
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // MARK: - 主內容區
            switch stage {
            case .cover:
                coverView
            case .quiz:
                quizView
            case .result:
                resultView
            }
        }
    }
    
    // MARK: - 封面頁面
    private var coverView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 標題
            VStack(spacing: 16) {
                
                Text("⚾ 棒球與中職知識")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 8)
            }
            
            // 描述
            VStack(spacing: 12) {
                Text("挑戰你的棒球知識！")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                
                Text("每次隨機抽取 10 題\n看看你能得到多少分！")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // 開始按鈕
            Button {
                startQuiz()
            } label: {
                Text("開始挑戰 ▶︎")
                    .font(.title3.weight(.bold))
                    .padding(.vertical, 16)
                    .padding(.horizontal, 40)
                    .background(.white.opacity(0.95))
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
                    .shadow(radius: 8)
            }
            
            Spacer()
                .frame(height: 40)
        }
    }
    
    // MARK: - 測驗頁面
    private var quizView: some View {
        VStack(spacing: 0) {
            // 頂部狀態列
            topStatusBar
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(.black.opacity(0.3))
            
            ScrollView {
                VStack(spacing: 24) {
                    // 題目卡片
                    questionCard
                    
                    // 選項按鈕
                    optionsView
                    
                    // 反饋資訊
                    if showAnswer {
                        feedbackView
                    }
                    
                    Spacer()
                        .frame(height: 20)
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            }
            
            // 下一題/結束按鈕
            if showAnswer {
                nextButton
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(.black.opacity(0.3))
            }
        }
    }
    
    // MARK: - 結果頁面
    private var resultView: some View {
        VStack(spacing: 32) {
            Spacer()
                .frame(height: 20)
            
            // 完成標記
            Text("🎉")
                .font(.system(size: 72))
            
            Text("作答完成！")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            
            // 分數卡片
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("最終得分")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("\(totalScore) 分")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                Divider()
                    .background(.white.opacity(0.3))
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("答對題數")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                        Text("\(score)/10")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("正確率")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                        Text("\(score * 10)%")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(24)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 32)
            
            Spacer()
            
            // 按鈕群組
            HStack(spacing: 16) {
                Button {
                    withAnimation {
                        stage = .cover
                    }
                } label: {
                    Text("回到首頁")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.9))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    startQuiz()
                } label: {
                    Text("再玩一次")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.5), lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 40)
        }
    }
    
    // MARK: - 子視圖：頂部狀態列
    private var topStatusBar: some View {
        HStack(spacing: 16) {
            // 題號進度
            VStack(alignment: .leading, spacing: 4) {
                Text("進度")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(answeredQuestions + 1)/10")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            // 分數和連擊
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("得分")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(totalScore) 分")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                }
                
                if correctStreak >= 3 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("連擊")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.yellow)
                        HStack(spacing: 4) {
                            Text("🔥")
                            Text("\(correctStreak)")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.yellow)
                        }
                    }
                    .transition(.scale)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: totalScore)
        .animation(.easeInOut(duration: 0.3), value: correctStreak)
    }
    
    // MARK: - 子視圖：題目卡片
    private var questionCard: some View {
        let current = currentQuestions[questionIndex]
        
        return VStack(alignment: .center, spacing: 16) {
            Text("第 \(answeredQuestions + 1) 題")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 8)
            
            Text(current.text)
                .font(.system(.title3, design: .default).weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .lineSpacing(6)
        }
        .padding(24)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            // 🌟 使用漸層邊框
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.yellow, .orange], // 從黃色漸變到橘色
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 子視圖：選項按鈕
    private var optionsView: some View {
        let current = currentQuestions[questionIndex]
        
        return VStack(spacing: 12) {
            ForEach(0..<current.shuffledOptions.count, id: \.self) { idx in
                let option = current.shuffledOptions[idx]
                let isCorrect = option == current.correctAnswer
                let isSelected = selectedIndex == idx
                let isAnswered = showAnswer
                
                Button {
                    handleOptionTap(index: idx, isCorrect: isCorrect)
                } label: {
                    HStack(alignment: .center, spacing: 14) {
                        // 選項文字
                        Text(option)
                            .font(.body.weight(.medium))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 反饋圖示
                        if isAnswered {
                            if isCorrect {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.green)
                                    .transition(.scale)
                            } else if isSelected {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.red)
                                    .transition(.scale)
                            }
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 18)
                    .background(optionBackgroundColor(idx: idx, isCorrect: isCorrect, isSelected: isSelected, isAnswered: isAnswered))
                    .foregroundStyle(optionForegroundColor(idx: idx, isCorrect: isCorrect, isSelected: isSelected, isAnswered: isAnswered))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(optionBorderColor(idx: idx, isCorrect: isCorrect, isSelected: isSelected, isAnswered: isAnswered), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .disabled(isAnswered)
                .animation(.easeInOut(duration: 0.2), value: isAnswered)
            }
        }
    }
    
    // MARK: - 子視圖：反饋資訊
    private var feedbackView: some View {
        let current = currentQuestions[questionIndex]
        let isCorrect = selectedIndex == current.correctAnswerIndex
        
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isCorrect ? .green : .red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isCorrect ? "答對了！" : "答錯了")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(isCorrect ?
                         (correctStreak >= 3 ? "🔥 Combo! +30 分" : "+10 分") :
                         "-10 分，連擊歸零")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding(14)
            .background(isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 正確答案提示
            if !isCorrect {
                VStack(alignment: .leading, spacing: 8) {
                    Text("正確答案")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text(current.correctAnswer)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                }
                .padding(14)
                .background(.yellow.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - 子視圖：下一題按鈕
    private var nextButton: some View {
        if answeredQuestions < 9 {
            return AnyView(
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        moveToNextQuestion()
                    }
                } label: {
                    Text("下一題 ➜")
                        .font(.body.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.9))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                }
            )
        } else {
            return AnyView(
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        stage = .result
                    }
                } label: {
                    Text("查看結果 ✅")
                        .font(.body.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.9))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                }
            )
        }
    }
    
    // MARK: - 邏輯函數
    
    /// 開始新遊戲：隨機抽取 10 題
    private func startQuiz() {
        currentQuestions = Array(allQuestions.shuffled().prefix(10))
        questionIndex = 0
        answeredQuestions = 0
        score = 0
        totalScore = 0
        correctStreak = 0
        showAnswer = false
        selectedIndex = nil
        stage = .quiz
    }
    
    /// 處理選項點擊
    private func handleOptionTap(index: Int, isCorrect: Bool) {
        selectedIndex = index
        
        if isCorrect {
            // ✅ 答對：計分邏輯
            correctStreak += 1
            
            if correctStreak >= 3 {
                // 觸發 Combo：每題 +30 分
                totalScore += 30
            } else {
                // 基本得分：+10 分
                totalScore += 10
            }
            
            score += 1
        } else {
            // ❌ 答錯：扣分 + 中斷連擊
            totalScore = max(0, totalScore - 10)
            correctStreak = 0
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            showAnswer = true
        }
    }
    
    /// 移動到下一題
    private func moveToNextQuestion() {
        questionIndex += 1
        answeredQuestions += 1
        showAnswer = false
        selectedIndex = nil
    }
    
    // MARK: - UI 輔助函數
    
    /// 選項背景色
    private func optionBackgroundColor(idx: Int, isCorrect: Bool, isSelected: Bool, isAnswered: Bool) -> Color {
        if !isAnswered {
            return .white.opacity(0.15)
        }
        
        if isCorrect {
            return .green.opacity(0.3)
        } else if isSelected {
            return .red.opacity(0.3)
        }
        
        return .white.opacity(0.08)
    }
    
    /// 選項文字色
    private func optionForegroundColor(idx: Int, isCorrect: Bool, isSelected: Bool, isAnswered: Bool) -> Color {
        return .white
    }
    
    /// 選項邊框色
    private func optionBorderColor(idx: Int, isCorrect: Bool, isSelected: Bool, isAnswered: Bool) -> Color {
        if !isAnswered {
            return .white.opacity(0.2)
        }
        
        if isCorrect {
            return .green
        } else if isSelected {
            return .red
        }
        
        return .white.opacity(0.1)
    }
    
    // MARK: - 題庫建立
    
    /// 靜態函數：建立完整的 15 題題庫
    static func buildQuestionBank() -> [Question] {
        [
            // ⚾ 棒球基礎規則
            Question(
                text: "標準的棒球比賽中，每隊同時在場上的防守球員共有幾名？",
                correctAnswer: "9 名",
                wrongAnswers: ["8 名", "10 名", "11 名"]
            ),
            Question(
                text: "請問棒球比賽中，一個半局防守方需要抓到幾個出局數才能換場？",
                correctAnswer: "3 個",
                wrongAnswers: ["2 個", "4 個", "5 個"]
            ),
            Question(
                text: "棒球場上的「熱區」(Hot Corner) 通常是指哪一個守備位置，因為擊出球的速度通常極快？",
                correctAnswer: "三壘手",
                wrongAnswers: ["游擊手", "一壘手", "捕手"]
            ),
            Question(
                text: "指定打擊 (DH) 的主要功能是什麼？",
                correctAnswer: "代替投手進行打擊",
                wrongAnswers: ["代替捕手接球", "專門負責代跑", "在延長賽時才能上場"]
            ),
            Question(
                text: "投手投出「觸身球」(Hit by pitch) 擊中打者時，打者會獲得什麼判決？",
                correctAnswer: "保送一壘",
                wrongAnswers: ["記壞球一個", "記好球一個", "重新打擊"]
            ),
            
            // ⚾ 進階規則與數據
            Question(
                text: "在兩好球之後，打者若未觸擊而擊出界外球，通常會如何計算？",
                correctAnswer: "不計好球，繼續打擊",
                wrongAnswers: ["直接三振出局", "記為壞球", "跑者可以推進"]
            ),
            Question(
                text: "球員若單場擊出「完全打擊」(Hit for the cycle)，必須包含哪些安打？",
                correctAnswer: "一壘、二壘、三壘、全壘打各一支",
                wrongAnswers: ["四支全壘打", "包含內野安打在內的四支安打", "連續四個打席敲出安打"]
            ),
            Question(
                text: "什麼情況下會構成「內野高飛必死球」(Infield Fly) 的宣告條件？",
                correctAnswer: "一二壘或滿壘有人，且未滿兩出局",
                wrongAnswers: ["兩出局滿壘時", "無人在壘時擊出內野高飛球", "任何情況下的內野高飛球"]
            ),
            Question(
                text: "棒球進階數據中，投手數據的「ERA」代表什麼意思？",
                correctAnswer: "防禦率",
                wrongAnswers: ["上壘率", "勝率", "每局被上壘率"]
            ),
            Question(
                text: "棒球比賽中，若雙方在前 9 局打平，第 10 局起採用「突破僵局制」，通常會如何安排開局？",
                correctAnswer: "無人出局，二壘有跑者",
                wrongAnswers: ["一人出局，滿壘", "無人出局，一壘有跑者", "重新從第一棒開始打"]
            ),
            
            // ⚾ 中職（CPBL）歷史與紀錄
            Question(
                text: "台灣中華職棒（CPBL）創立於哪一年？",
                correctAnswer: "1990 年",
                wrongAnswers: ["1988 年", "1992 年", "1995 年"]
            ),
            Question(
                text: "每年中華職棒例行賽結束後，爭奪年度總冠軍的系列賽稱為什麼？",
                correctAnswer: "台灣大賽",
                wrongAnswers: ["中華大賽", "亞洲大賽", "寶島大賽"]
            ),
            Question(
                text: "中華職棒歷史上，第一支達成「三連霸」的球隊是哪一支？",
                correctAnswer: "兄弟象",
                wrongAnswers: ["統一獅", "味全龍", "興農牛"]
            ),
            Question(
                text: "被球迷稱為「大師兄」，並在 2023 年打破聯盟最多全壘打紀錄的球員是？",
                correctAnswer: "林智勝",
                wrongAnswers: ["張泰山", "彭政閔", "陳金鋒"]
            ),
            Question(
                text: "中華職棒歷史上，投出聯盟第一場也是目前唯一一場「完全比賽」的投手是誰？",
                correctAnswer: "瑞安 (Ryan Verdugo)",
                wrongAnswers: ["潘威倫", "羅力 (Mike Loree)", "郭泰源"]
            )
        ]
    }
}

#Preview {
    ContentView()
}
