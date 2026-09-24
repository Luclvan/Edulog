import '../../../../core/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../student_dashboard/domain/entities/group_entity.dart';
import '../providers/oral_exam_provider.dart';
import '../../../../core/utils/oral_exam_validator.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/models/exam_question_model.dart';
import '../../../group_management/data/repositories/group_repository.dart';

class OralExamScreen extends ConsumerStatefulWidget {
  final UserModel student;
  final String groupName;
  final GroupEntity group;

  const OralExamScreen({
    super.key,
    required this.student,
    required this.groupName,
    required this.group,
  });

  @override
  ConsumerState<OralExamScreen> createState() => _OralExamScreenState();
}

class _OralExamScreenState extends ConsumerState<OralExamScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ExamQuestionModel> questions = [];

  Map<String, int> get _commitStats {
    final aiSummary = ref.read(aiSummaryProvider(AiSummaryParams(
      studentName: widget.student.name,
      githubUsername: widget.student.githubUsername ?? widget.student.name,
      googleDisplayName: widget.student.googleDisplayName ?? widget.student.name,
      githubStats: widget.group.githubStats ?? [],
      docsLink: widget.group.docsUrl ?? '',
    )));
    
    if (aiSummary is AsyncData<String?> && aiSummary.value != null) {
      try {
        final aiData = jsonDecode(aiSummary.value!);
        final githubEval = aiData['github_evaluation'] ?? {};
        return {
          'total': githubEval['total_commits'] ?? 0,
          'passed': githubEval['passed_commits'] ?? 0,
        };
      } catch (_) {}
    }
    return {'total': 0, 'passed': 0};
  }

  double get commitScore {
    final stats = _commitStats;
    final total = stats['total']!;
    final passed = stats['passed']!;
    if (total == 0) return 0.0;
    return (passed / total) * 10.0;
  }
  int selectedWholeScore = 7;
  int selectedDecimalScore = 4;
  bool isScoreConfirmed = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    questions = [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _updateScoreForEvaluation(ExamQuestionModel question, StudentEvaluation eval) {
    setState(() {
      question.evaluation = eval;
      if (eval == StudentEvaluation.none) {
        question.score = null;
      }
    });
  }

  void _updateScore(ExamQuestionModel question, int score) {
    setState(() {
      question.score = score;
      if (score >= 7) {
        question.evaluation = StudentEvaluation.traLoiTot;
      } else if (score >= 3) {
        question.evaluation = StudentEvaluation.chuaDuY;
      } else {
        question.evaluation = StudentEvaluation.khongTraLoi;
      }
    });
  }

  double get _suggestedScore {
    List<int> validScores = questions.where((q) => q.isSelected && q.score != null).map((q) => q.score!).toList();
    double avgQuestionScore = 0;
    if (validScores.isNotEmpty) {
      avgQuestionScore = validScores.reduce((a, b) => a + b) / validScores.length;
    }
    return (commitScore * 0.3) + (avgQuestionScore * 0.7);
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF1565C0),
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Text(
                'PHIÊN VẤN ĐÁP',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${widget.student.name} — ${widget.groupName}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('1/5', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('GH 34%', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              SizedBox(
                width: 40,
                child: LinearProgressIndicator(value: 0.34, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white)),
              ),
              const SizedBox(width: 16),
              const Text('Docs 41%', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              SizedBox(
                width: 40,
                child: LinearProgressIndicator(value: 0.41, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('✓ Commit Đạt', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Câu hỏi (5) [3]'),
              Tab(text: 'Chấm điểm tổng'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.menu_book, color: Color(0xFF1565C0)),
          title: const Text('Tóm tắt nội dung sinh viên đã làm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ref.watch(aiSummaryProvider(AiSummaryParams(
                studentName: widget.student.name,
                githubUsername: widget.student.githubUsername ?? widget.student.name,
                googleDisplayName: widget.student.googleDisplayName ?? widget.student.name,
                githubStats: widget.group.githubStats ?? [],
                docsLink: widget.group.docsUrl ?? '',
              ))).when(
                data: (data) {
                  if (data == null || data.isEmpty) {
                    return const Center(child: Text('Không thể lấy phản hồi từ AI.'));
                  }
                  try {
                    final aiData = jsonDecode(data);
                    
                    final module = aiData['module_phu_trach'] ?? 'N/A';
                    final githubEval = aiData['github_evaluation'] ?? {};
                    final totalCommits = githubEval['total_commits'] ?? 0;
                    final passedCommits = githubEval['passed_commits'] ?? 0;
                    final status = githubEval['status'] ?? 'N/A';
                    final docsSummary = aiData['docs_summary'] as List<dynamic>? ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MODULE PHỤ TRÁCH',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          module.toString(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'GITHUB COMMITS',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '$totalCommits TỔNG • $passedCommits ĐẠT CHUẨN',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status.toString(),
                                style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'GOOGLE DOCS ĐÃ VIẾT',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        if (docsSummary.isEmpty)
                          const Text('Không có tóm tắt Docs.', style: TextStyle(color: Colors.grey))
                        else
                          ...docsSummary.map((sec) {
                            final title = sec['section_title'] ?? 'Không có tiêu đề';
                            final words = sec['word_count'] ?? 0;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.description, color: Colors.grey),
                                title: Text(
                                  title.toString(),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                trailing: Text(
                                  '$words từ',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  } catch (e) {
                    return Center(child: Text('Lỗi parse dữ liệu AI: $e\nRaw: $data'));
                  }
                },
                loading: () => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('AI đang phân tích dữ liệu...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                error: (e, st) => Center(child: Text('Lỗi AI: $e', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    if (questions.isEmpty) {
      final aiSummary = ref.watch(aiSummaryProvider(AiSummaryParams(
        studentName: widget.student.name,
        githubUsername: widget.student.githubUsername ?? widget.student.name,
        googleDisplayName: widget.student.googleDisplayName ?? widget.student.name,
        githubStats: widget.group.githubStats ?? [],
        docsLink: widget.group.docsUrl ?? '',
      )));

      return aiSummary.when(
        data: (data) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('Không có câu hỏi nào được tạo.', style: TextStyle(color: Colors.grey)),
          ),
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Lỗi tải câu hỏi: $e', style: const TextStyle(color: Colors.red)),
          ),
        ),
      );
    }

    Map<ExamCategory, List<ExamQuestionModel>> grouped = {
      ExamCategory.nhanBiet: [],
      ExamCategory.hieuLogic: [],
      ExamCategory.toiUuHoa: [],
    };
    for (var q in questions) {
      grouped[q.category]!.add(q);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (grouped[ExamCategory.nhanBiet]!.isNotEmpty) ...[
          _buildCategoryHeader('NHẬN BIẾT', grouped[ExamCategory.nhanBiet]!.length, const Color(0xFF2E7D32)),
          ...grouped[ExamCategory.nhanBiet]!.map((q) => _buildQuestionCard(q)),
          const SizedBox(height: 16),
        ],
        if (grouped[ExamCategory.hieuLogic]!.isNotEmpty) ...[
          _buildCategoryHeader('HIỂU LOGIC', grouped[ExamCategory.hieuLogic]!.length, const Color(0xFFEF6C00)),
          ...grouped[ExamCategory.hieuLogic]!.map((q) => _buildQuestionCard(q)),
          const SizedBox(height: 16),
        ],
        if (grouped[ExamCategory.toiUuHoa]!.isNotEmpty) ...[
          _buildCategoryHeader('TỐI ƯU HÓA', grouped[ExamCategory.toiUuHoa]!.length, const Color(0xFFC62828)),
          ...grouped[ExamCategory.toiUuHoa]!.map((q) => _buildQuestionCard(q)),
          const SizedBox(height: 80), 
        ],
      ],
    );
  }

  Widget _buildCategoryHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text(
            '$title • $count CÂU',
            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(ExamQuestionModel question) {
    Color catColor;
    String catText;
    switch (question.category) {
      case ExamCategory.nhanBiet:
        catColor = const Color(0xFF2E7D32);
        catText = 'NHẬN BIẾT';
        break;
      case ExamCategory.hieuLogic:
        catColor = const Color(0xFFEF6C00);
        catText = 'HIỂU LOGIC';
        break;
      case ExamCategory.toiUuHoa:
        catColor = const Color(0xFFC62828);
        catText = 'TỐI ƯU HÓA';
        break;
    }

    return Opacity(
      opacity: question.isSelected ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: question.isSelected ? Colors.blue.shade200 : Colors.grey.shade200),
        ),
        elevation: 0,
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: question.isExpanded ? null : () {
            setState(() {
              question.isExpanded = true;
            });
          },
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: question.isSelected,
                      onChanged: (val) {
                        setState(() {
                          question.isSelected = val ?? false;
                        });
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(catText, style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            if (question.score != null) ...[
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                                  const SizedBox(width: 4),
                                  Text('${question.score}/10', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  question.isExpanded = !question.isExpanded;
                                });
                              },
                              padding: const EdgeInsets.all(4.0),
                              constraints: const BoxConstraints(),
                              icon: Icon(question.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              question.isSelected ? '✓ Đã chọn hỏi sinh viên này' : 'Chưa chọn hỏi',
                              style: TextStyle(
                                fontSize: 12,
                                color: question.isSelected ? Colors.blue.shade700 : Colors.grey,
                                fontWeight: question.isSelected ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Câu ${question.id}', style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (question.isExpanded) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    question.detailedQuestion,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: !question.isSelected ? 0.4 : 1.0,
                  child: AbsorbPointer(
                    absorbing: !question.isSelected,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ĐÁNH GIÁ CÂU TRẢ LỜI SINH VIÊN',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildEvalBtn(question, StudentEvaluation.khongTraLoi, 'Không trả lời', Colors.red)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildEvalBtn(question, StudentEvaluation.chuaDuY, 'Chưa đủ ý', Colors.orange)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildEvalBtn(question, StudentEvaluation.traLoiTot, 'Trả lời tốt', Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(Icons.star_border, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              'CHẤM ĐIỂM CÂU NÀY',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(11, (index) => _buildScoreBtn(question, index)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildEvalBtn(ExamQuestionModel question, StudentEvaluation eval, String text, MaterialColor color) {
    bool isSelected = question.evaluation == eval;
    return InkWell(
      onTap: () => _updateScoreForEvaluation(question, eval),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color.shade700 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBtn(ExamQuestionModel question, int score) {
    bool isSelected = question.score == score;
    bool isValid = true;

    if (question.evaluation == StudentEvaluation.traLoiTot) {
      isValid = score >= 7 && score <= 10;
    } else if (question.evaluation == StudentEvaluation.chuaDuY) {
      isValid = score >= 3 && score <= 6;
    } else if (question.evaluation == StudentEvaluation.khongTraLoi) {
      isValid = score >= 0 && score <= 2;
    }

    Color bgColor = Colors.transparent;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.grey.shade700;

    if (isSelected) {
      bgColor = Colors.blue;
      borderColor = Colors.blue;
      textColor = Colors.white;
    } else if (!isValid) {
      textColor = Colors.grey.shade400;
      borderColor = Colors.grey.shade200;
    }

    return Opacity(
      opacity: isValid ? 1.0 : 0.3,
      child: InkWell(
        onTap: isValid ? () => _updateScore(question, score) : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitExamResult() async {
    // [9E1] Mandatory grading check for all selected questions
    final questionsError = OralExamValidator.validateAllSelectedQuestionsGraded(questions);
    if (questionsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(questionsError), backgroundColor: Colors.red),
      );
      _tabController.animateTo(0);
      return;
    }

    // [10E1 - 10E4] Final overall score check
    final currentFinalScore = selectedWholeScore + (selectedDecimalScore / 10.0);
    final scoreError = OralExamValidator.validateOverallScore(
      isScoreConfirmed: isScoreConfirmed,
      score: currentFinalScore,
      wholeScore: selectedWholeScore,
      decimalScore: selectedDecimalScore,
    );
    if (scoreError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(scoreError), backgroundColor: Colors.red),
      );
      _tabController.animateTo(1);
      return;
    }

    // [11E1 - 11E3] Review / Feedback check
    final reviewError = OralExamValidator.validateTeacherReview(_commentController.text);
    if (reviewError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reviewError), backgroundColor: Colors.red),
      );
      _tabController.animateTo(1);
      return;
    }

    final repo = ref.read(groupRepositoryProvider);
    
    final stats = _commitStats;
    final commitData = {
      'score': double.parse(commitScore.toStringAsFixed(1)),
      'totalCommits': stats['total'],
      'passedCommits': stats['passed'],
    };

    final selectedQuestions = questions.where((q) => q.isSelected).map((q) => {
      'title': q.title,
      'category': q.category.toString(),
      'evaluation': q.evaluation.toString(),
      'score': q.score,
    }).toList();

    try {
      await repo.saveExamResult(
        groupId: widget.group.id,
        studentId: widget.student.uid,
        finalScore: currentFinalScore,
        suggestedScore: _suggestedScore,
        commitData: commitData,
        questions: selectedQuestions,
        teacherReview: _commentController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu điểm thành công!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitExamResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('⭐ Chấm điểm buổi vấn đáp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Hủy', style: TextStyle(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiSummary = ref.watch(aiSummaryProvider(AiSummaryParams(
      studentName: widget.student.name,
      githubUsername: widget.student.githubUsername ?? widget.student.name,
      googleDisplayName: widget.student.googleDisplayName ?? widget.student.name,
      githubStats: widget.group.githubStats ?? [],
      docsLink: widget.group.docsUrl ?? '',
    )));

    if (questions.isEmpty && aiSummary is AsyncData<String?> && aiSummary.value != null) {
      try {
        final aiData = jsonDecode(aiSummary.value!);
        final List<dynamic> rawQuestions = aiData['questions'] ?? [];
        if (rawQuestions.isNotEmpty) {
          questions = rawQuestions.asMap().entries.map((entry) {
            final index = entry.key;
            final q = entry.value;
            
            final typeStr = q['type']?.toString() ?? 'NHẬN BIẾT';
            ExamCategory category = ExamCategory.nhanBiet;
            if (typeStr == 'HIỂU LOGIC') {
              category = ExamCategory.hieuLogic;
            } else if (typeStr == 'TỐI ƯU HÓA') {
              category = ExamCategory.toiUuHoa;
            }

            return ExamQuestionModel(
              id: (index + 1).toString(),
              category: category,
              title: q['title']?.toString() ?? '',
              detailedQuestion: q['detail']?.toString() ?? '',
              isSelected: index == 0,
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('Error parsing questions: $e');
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSummary(),
                      _buildQuestionsList(),
                    ],
                  ),
                ),
                _buildSummaryTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCommitEvaluationCard(),
          const SizedBox(height: 16),
          _buildQuestionScoresCard(),
          const SizedBox(height: 16),
          _buildTotalScoreCard(),
          const SizedBox(height: 16),
          _buildCommentSection(),
          const SizedBox(height: 16),
          _buildManualScorePicker(),
        ],
      ),
    );
  }

  Widget _buildCommitEvaluationCard() {
    final stats = _commitStats;
    final passed = stats['passed'];
    final total = stats['total'];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.commit, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text('Đánh giá Commit GitHub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('✓ Commit Đạt chuẩn', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Số commit đạt chuẩn: $passed / $total',
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text('Tiêu chí: tần suất, nội dung rõ ràng, message đúng format', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('ĐIỂM COMMIT', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(commitScore.toStringAsFixed(1), style: const TextStyle(color: Colors.blue, fontSize: 32, fontWeight: FontWeight.bold)),
                          const Text(' / 10', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionScoresCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_border, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text('Điểm từng câu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Bấm vào tab "Câu hỏi" để chấm từng câu riêng lẻ.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 16),
            ...questions.map((q) {
              return Opacity(
                opacity: q.isSelected ? 1.0 : 0.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 50, child: Text('Câu ${q.id}', style: const TextStyle(fontWeight: FontWeight.w500))),
                      _buildCategoryChip(q.category),
                      const SizedBox(width: 8),
                      if (q.isSelected && q.score != null)
                        _buildEvalChip(q.evaluation),
                      if (!q.isSelected)
                        Text('Không chọn hỏi', style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic, fontSize: 12)),
                      const Spacer(),
                      if (q.isSelected && q.score != null)
                        Text('${q.score}/10', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16))
                      else
                        Text('Chưa chấm', style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic, fontSize: 14)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ExamCategory category) {
    Color color;
    String text;
    switch (category) {
      case ExamCategory.nhanBiet: color = Colors.green; text = 'NHẬN BIẾT'; break;
      case ExamCategory.hieuLogic: color = Colors.orange; text = 'HIỂU LOGIC'; break;
      case ExamCategory.toiUuHoa: color = Colors.red; text = 'TỐI ƯU HÓA'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEvalChip(StudentEvaluation eval) {
    Color color;
    String text;
    switch (eval) {
      case StudentEvaluation.traLoiTot: color = Colors.green; text = 'Trả lời tốt'; break;
      case StudentEvaluation.chuaDuY: color = Colors.orange; text = 'Chưa đủ ý'; break;
      case StudentEvaluation.khongTraLoi: color = Colors.red; text = 'Không trả lời'; break;
      default: return const SizedBox();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTotalScoreCard() {
    List<int> validScores = questions.where((q) => q.isSelected && q.score != null).map((q) => q.score!).toList();
    double avgQuestionScore = 0;
    if (validScores.isNotEmpty) {
      avgQuestionScore = validScores.reduce((a, b) => a + b) / validScores.length;
    }
    double suggestedScore = _suggestedScore;
    String formattedSuggested = suggestedScore.toStringAsFixed(1);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Text('Điểm tổng kết (Tự tính)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Công thức: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                  child: const Text('Commitx30% + Câu hỏix70%', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildScoreBox('COMMIT', commitScore.toStringAsFixed(1), 'x30%', false)),
                const SizedBox(width: 8),
                Expanded(child: _buildScoreBox('CÂU HỎI', avgQuestionScore.toStringAsFixed(1), 'x70%', false)),
                const SizedBox(width: 8),
                Expanded(child: _buildScoreBox('GỢI Ý', formattedSuggested, '/10', true)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Điểm gợi ý: $formattedSuggested/10 — Chỉnh bên dưới để xác nhận.', style: const TextStyle(color: Colors.blue, fontSize: 11))),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedWholeScore = suggestedScore.floor();
                        selectedDecimalScore = ((suggestedScore - suggestedScore.floor()) * 10).round();
                        isScoreConfirmed = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Đồng bộ', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBox(String title, String value, String subtitle, bool isHighlight) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.blue : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isHighlight ? Colors.blue : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: isHighlight ? Colors.white70 : Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: isHighlight ? Colors.white : Colors.blue, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: isHighlight ? Colors.white70 : Colors.grey.shade400, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text('NHẬN XÉT TOÀN BÀI VẤN ĐÁP', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OralExamValidator.quickTags.map((tag) {
                final isIncluded = _commentController.text.contains(tag);
                return FilterChip(
                  label: Text(tag, style: TextStyle(fontSize: 12, color: isIncluded ? Colors.blue.shade900 : Colors.grey.shade800)),
                  selected: isIncluded,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (_commentController.text.trim().isEmpty) {
                          _commentController.text = tag;
                        } else {
                          _commentController.text = '${_commentController.text.trim()} $tag';
                        }
                      } else {
                        _commentController.text = _commentController.text.replaceAll(tag, '').replaceAll('  ', ' ').trim();
                      }
                    });
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Sinh viên nắm vững kiến trúc hệ thống, trình bày rõ ràng, tuy nhiên cần cải thiện phần tối ưu hóa...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualScorePicker() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text('Giảng viên chấm điểm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Center(child: Text('Chọn điểm bằng nút ↑↓ — không cần gõ bàn phím.', style: TextStyle(color: Colors.grey.shade500, fontSize: 11))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    const Text('ĐIỂM NGUYÊN', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildUpDownPicker(
                      value: selectedWholeScore,
                      isWhole: true,
                      onUp: () {
                        if (selectedWholeScore < 10) {
                          setState(() {
                            selectedWholeScore++;
                            if (selectedWholeScore == 10) {
                              selectedDecimalScore = 0;
                            }
                            isScoreConfirmed = false;
                          });
                        }
                      },
                      onDown: () {
                        if (selectedWholeScore > 0) {
                          setState(() {
                            selectedWholeScore--;
                            isScoreConfirmed = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.circle, size: 6, color: Colors.grey),
                ),
                Column(
                  children: [
                    const Text('THẬP PHÂN', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildUpDownPicker(
                      value: selectedDecimalScore,
                      isWhole: false,
                      onUp: () {
                        if (selectedWholeScore == 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Điểm tối đa là 10.0, không thể có số thập phân'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          return;
                        }
                        if (selectedWholeScore < 10 && selectedDecimalScore < 9) {
                          setState(() {
                            selectedDecimalScore++;
                            isScoreConfirmed = false;
                          });
                        }
                      },
                      onDown: () {
                        if (selectedDecimalScore > 0) {
                          setState(() {
                            selectedDecimalScore--;
                            isScoreConfirmed = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ĐIỂM SẼ GHI NHẬN', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('$selectedWholeScore.$selectedDecimalScore', style: const TextStyle(color: Colors.blue, fontSize: 32, fontWeight: FontWeight.bold)),
                          const Text(' /10', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: isScoreConfirmed ? null : () {
                      setState(() {
                        isScoreConfirmed = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isScoreConfirmed ? Colors.green : Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.green,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isScoreConfirmed ? 'Đã xác nhận' : 'Xác nhận', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpDownPicker({required int value, required bool isWhole, required VoidCallback onUp, required VoidCallback onDown}) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          IconButton(
            onPressed: onUp,
            icon: const Icon(Icons.keyboard_arrow_up, color: Colors.blue),
            splashRadius: 20,
          ),
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Text(
              isWhole ? value.toString() : '.$value',
              style: const TextStyle(color: Colors.blue, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: onDown,
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
