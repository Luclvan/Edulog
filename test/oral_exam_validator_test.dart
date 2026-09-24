import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edulog/core/utils/oral_exam_validator.dart';
import 'package:edulog/features/oral_exam/data/models/exam_question_model.dart';

void main() {
  group('OralExamValidator - Module 1: Student Photo Verification', () {
    test('[8E1] Camera permission denial mapping', () {
      final deniedEx1 = PlatformException(code: 'camera_access_denied', message: 'User denied camera');
      final deniedEx2 = PlatformException(code: 'PERMISSION_DENIED', message: 'Permission denied');
      final deniedEx3 = PlatformException(code: 'error', message: 'Ứng dụng cần quyền camera');

      expect(
        OralExamValidator.mapCameraPlatformException(deniedEx1),
        "Ứng dụng cần quyền truy cập máy ảnh để chụp ảnh xác thực sinh viên",
      );
      expect(
        OralExamValidator.mapCameraPlatformException(deniedEx2),
        "Ứng dụng cần quyền truy cập máy ảnh để chụp ảnh xác thực sinh viên",
      );
      expect(
        OralExamValidator.mapCameraPlatformException(deniedEx3),
        "Ứng dụng cần quyền truy cập máy ảnh để chụp ảnh xác thực sinh viên",
      );
    });

    test('[8E2] Cancelled / Hardware capture failure mapping', () {
      final genericEx = PlatformException(code: 'hardware_failure', message: 'Failed to capture');
      expect(
        OralExamValidator.mapCameraPlatformException(genericEx),
        "Chưa chụp được ảnh xác thực. Vui lòng thực hiện lại",
      );
    });

    test('[8E4] Format check (.jpg, .jpeg, .png, .webp)', () {
      expect(OralExamValidator.validatePhoto(filename: 'photo.gif', bytesLength: 100 * 1024), "Định dạng ảnh không được hỗ trợ");
      expect(OralExamValidator.validatePhoto(filename: 'photo.pdf', bytesLength: 100 * 1024), "Định dạng ảnh không được hỗ trợ");
      expect(OralExamValidator.validatePhoto(filename: 'photo.bmp', bytesLength: 100 * 1024), "Định dạng ảnh không được hỗ trợ");
      expect(OralExamValidator.validatePhoto(filename: 'photo.jpg', bytesLength: 100 * 1024), isNull);
      expect(OralExamValidator.validatePhoto(filename: 'photo.jpeg', bytesLength: 100 * 1024), isNull);
      expect(OralExamValidator.validatePhoto(filename: 'photo.png', bytesLength: 100 * 1024), isNull);
      expect(OralExamValidator.validatePhoto(filename: 'photo.webp', bytesLength: 100 * 1024), isNull);
    });

    test('[8E3] File size max check (> 5MB) and min check (< 20KB)', () {
      const over5MB = 5 * 1024 * 1024 + 1;
      const under20KB = 19 * 1024;
      const validSize = 500 * 1024; // 500KB

      expect(OralExamValidator.validatePhoto(filename: 'student.jpg', bytesLength: over5MB), "Dung lượng ảnh vượt quá giới hạn 5MB");
      expect(OralExamValidator.validatePhoto(filename: 'student.jpg', bytesLength: under20KB), "Dung lượng ảnh quá nhỏ hoặc file bị lỗi");
      expect(OralExamValidator.validatePhoto(filename: 'student.jpg', bytesLength: validSize), isNull);
    });

    test('[8E5 - 8E7] Computer Vision / Quality validation', () {
      // [8E5] Face missing
      expect(
        OralExamValidator.validateFaceAndQuality(detectedFaces: 0),
        "Không phát hiện khuôn mặt trong ảnh chụp. Vui lòng căn chỉnh lại góc chụp",
      );

      // [8E6] Multiple faces detected
      expect(
        OralExamValidator.validateFaceAndQuality(detectedFaces: 2),
        "Khung hình điểm danh chỉ được xuất hiện một sinh viên duy nhất",
      );

      // [8E7] Blur / Lighting check
      expect(
        OralExamValidator.validateFaceAndQuality(detectedFaces: 1, isBlurredOrDark: true),
        "Ảnh quá mờ hoặc thiếu sáng. Vui lòng chụp lại nơi đủ ánh sáng",
      );

      // Valid case: exactly 1 face, good lighting
      expect(
        OralExamValidator.validateFaceAndQuality(detectedFaces: 1, isBlurredOrDark: false),
        isNull,
      );
    });
  });

  group('OralExamValidator - Module 2: Oral Exam Grading & Review', () {
    test('[9E2 - 9E4] Component Question Score validation', () {
      // Null
      expect(OralExamValidator.validateQuestionScore(null), "Vui lòng hoàn tất chấm điểm cho tất cả câu hỏi đã chọn");
      // Not integer
      expect(OralExamValidator.validateQuestionScore(7.5), "Điểm câu hỏi thành phần phải là số nguyên");
      // < 0
      expect(OralExamValidator.validateQuestionScore(-1), "Điểm câu hỏi không được nhỏ hơn 0");
      // > 10
      expect(OralExamValidator.validateQuestionScore(11), "Điểm câu hỏi không được vượt quá 10");
      // Valid integers 0 to 10
      for (int i = 0; i <= 10; i++) {
        expect(OralExamValidator.validateQuestionScore(i), isNull);
      }
    });

    test('[9E1] Mandatory grading for all selected questions', () {
      final q1 = ExamQuestionModel(id: '1', category: ExamCategory.nhanBiet, title: 'Q1', detailedQuestion: 'D1', isSelected: true, score: 8);
      final q2 = ExamQuestionModel(id: '2', category: ExamCategory.hieuLogic, title: 'Q2', detailedQuestion: 'D2', isSelected: true, score: null);
      final q3 = ExamQuestionModel(id: '3', category: ExamCategory.toiUuHoa, title: 'Q3', detailedQuestion: 'D3', isSelected: false, score: null);

      expect(OralExamValidator.validateAllSelectedQuestionsGraded([q1, q2, q3]), "Vui lòng hoàn tất chấm điểm cho tất cả câu hỏi đã chọn");

      q2.score = 5;
      expect(OralExamValidator.validateAllSelectedQuestionsGraded([q1, q2, q3]), isNull);
    });

    test('[10E1 - 10E4] Final Overall Score validation', () {
      // [10E1] Not confirmed
      expect(
        OralExamValidator.validateOverallScore(isScoreConfirmed: false, score: 8.5),
        "Vui lòng bấm Xác nhận điểm số trước khi lưu kết quả",
      );

      // [10E2] < 0.0
      expect(
        OralExamValidator.validateOverallScore(isScoreConfirmed: true, score: -0.5, wholeScore: -1),
        "Điểm số không được nhỏ hơn 0.0",
      );

      // [10E3] > 10.0
      expect(
        OralExamValidator.validateOverallScore(isScoreConfirmed: true, score: 10.5, wholeScore: 11),
        "Điểm số tối đa là 10.0",
      );

      // [10E4] Edge constraint: whole == 10 and decimal > 0
      expect(
        OralExamValidator.validateOverallScore(isScoreConfirmed: true, score: 10.2, wholeScore: 10, decimalScore: 2),
        "Điểm tối đa là 10.0, không thể có số thập phân",
      );

      // Valid scores
      expect(
        OralExamValidator.validateOverallScore(isScoreConfirmed: true, score: 10.0, wholeScore: 10, decimalScore: 0),
        isNull,
      );
      expect(
        OralExamValidator.validateOverallScore(isScoreConfirmed: true, score: 7.4, wholeScore: 7, decimalScore: 4),
        isNull,
      );
      expect(
        OralExamValidator.validateOverallScore(isScoreConfirmed: true, score: 0.0, wholeScore: 0, decimalScore: 0),
        isNull,
      );
    });

    test('[11E1 - 11E3] Teacher Review / Feedback validation', () {
      // Optional / empty is allowed
      expect(OralExamValidator.validateTeacherReview(null), isNull);
      expect(OralExamValidator.validateTeacherReview(""), isNull);
      expect(OralExamValidator.validateTeacherReview("   "), isNull);

      // [11E1] Min length < 5
      expect(OralExamValidator.validateTeacherReview("Tot"), "Nội dung nhận xét tối thiểu từ 5 ký tự");
      expect(OralExamValidator.validateTeacherReview("1234"), "Nội dung nhận xét tối thiểu từ 5 ký tự");

      // [11E2] Max length > 1000
      final longReview = 'A' * 1001;
      expect(OralExamValidator.validateTeacherReview(longReview), "Nội dung nhận xét không được vượt quá 1000 ký tự");

      // [11E3] XSS / Malicious tag sanitize
      expect(OralExamValidator.validateTeacherReview("Sinh viên làm bài tốt <script>alert(1)</script>"), "Nội dung nhận xét chứa ký tự không an toàn");
      expect(OralExamValidator.validateTeacherReview("<iframe src='evil.com'></iframe>"), "Nội dung nhận xét chứa ký tự không an toàn");

      // Valid review
      expect(OralExamValidator.validateTeacherReview("Sinh viên nắm vững kiến trúc hệ thống."), isNull);
      expect(OralExamValidator.validateTeacherReview("[Trả lời lưu loát] Code tổ chức gọn gàng."), isNull);
    });
  });
}
