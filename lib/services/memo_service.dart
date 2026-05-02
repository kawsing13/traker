import 'package:intl/intl.dart';
import 'database_service.dart';

class MemoService {
  static final MemoService instance = MemoService._init();
  MemoService._init();

  final DatabaseService _dbService = DatabaseService.instance;

  /// Get all memos visible to the current employee
  /// Only returns memos with 'Finalized' status
  Future<List<Map<String, dynamic>>> getMemos(String empId) async {
    print('DEBUG: getMemos called with empId: $empId');

    final conn = await _dbService.getHrConnection();
    try {
      print('DEBUG: Database connection established');

      const query = '''
      SELECT 
        m.memo_id,
        LPAD(m.memo_id, 8, '0') as formatted_memo_id,
        DATE_FORMAT(m.date, "%M %d, %Y") as formatted_date,
        DATE_FORMAT(m.date, "%Y-%m-%d") as raw_date,
        m.`to` as memo_to, 
        m.`from` as memo_from, 
        m.subject, 
        m.body,
        m.isGrouped,
        m.status,
        m.date as original_date,
        m.dateFinalized,
        m.timeFinalized,
        DATE_FORMAT(m.dateFinalized, "%M %d, %Y") as formatted_dateFinalized,
        TIME_FORMAT(m.timeFinalized, "%r") as formatted_timeFinalized
      FROM hr.memos m 
      WHERE m.status = 'Finalized'
        AND (m.isGrouped = 'Everyone' 
         OR (m.isGrouped != 'Everyone' AND FIND_IN_SET(?, m.`to`)))
      ORDER BY m.memo_id DESC
      ''';

      print('DEBUG: Executing query with empId: $empId');

      var results = await conn.query(query, [empId]);

      print('DEBUG: Query results count: ${results.length}');

      final mappedResults = results.map((row) {
        final mapped = {
          'memo_id': row['memo_id'],
          'formatted_memo_id': row['formatted_memo_id'],
          'formatted_date': row['formatted_date'],
          'raw_date': row['raw_date'],
          'memo_to': row['memo_to'],
          'memo_from': row['memo_from'],
          'subject': row['subject'],
          'body': row['body']?.toString() ?? '',
          'isGrouped': row['isGrouped'],
          'status': row['status'],
          'original_date': row['original_date']?.toString(),
          'dateFinalized': row['dateFinalized']?.toString(),
          'timeFinalized': row['timeFinalized']?.toString(),
          'formatted_dateFinalized': row['formatted_dateFinalized'],
          'formatted_timeFinalized': row['formatted_timeFinalized'],
          // Combined formatted date and time
          'finalized_datetime':
              '${row['formatted_dateFinalized']} at ${row['formatted_timeFinalized']}',
        };
        return mapped;
      }).toList();

      print('DEBUG: Returning ${mappedResults.length} finalized memos');
      return mappedResults;
    } catch (e) {
      print('ERROR: Get Memos Error: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      return [];
    } finally {
      print('DEBUG: Closing database connection');
      await conn.close();
    }
  }

  /// Get detailed memo information by ID including formatted recipient names
  /// Only returns memo if it has 'Finalized' status
  Future<Map<String, dynamic>?> getMemoById(int memoId) async {
    final conn = await _dbService.getHrConnection();
    try {
      print('DEBUG: Getting memo by ID: $memoId');

      var query = '''
      SELECT 
        m.memo_id,
        LPAD(m.memo_id, 8, '0') as formatted_memo_id,
        DATE_FORMAT(m.date, "%M %d, %Y") as formatted_date,
        DATE_FORMAT(m.date, "%Y-%m-%d") as raw_date,
        m.`to` as memo_to, 
        m.`from` as memo_from, 
        m.subject, 
        m.body,
        m.isGrouped,
        m.status,
        m.date as original_date,
        m.dateFinalized,
        m.timeFinalized,
        DATE_FORMAT(m.dateFinalized, "%M %d, %Y") as formatted_dateFinalized,
        TIME_FORMAT(m.timeFinalized, "%r") as formatted_timeFinalized,
        CASE 
          WHEN m.isGrouped = 'Everyone' THEN 'Everyone'
          ELSE (
            SELECT GROUP_CONCAT(
              CONCAT(
                TRIM(CONCAT(
                  IFNULL(e.first_name, ''), 
                  ' ', 
                  IFNULL(e.middle_name, ''), 
                  ' ', 
                  IFNULL(e.surname, '')
                ))
              )
              SEPARATOR ', '
            )
            FROM employee.info e 
            WHERE FIND_IN_SET(e.emp_id, m.`to`)
          )
        END as recipients_display
      FROM hr.memos m 
      WHERE m.memo_id = ? AND m.status = 'Finalized'
      ''';

      var results = await conn.query(query, [memoId]);
      print('DEBUG: getMemoById results count: ${results.length}');

      if (results.isNotEmpty) {
        var row = results.first;

        return {
          'memo_id': row['memo_id'],
          'formatted_memo_id': row['formatted_memo_id'],
          'formatted_date': row['formatted_date'],
          'raw_date': row['raw_date'],
          'memo_to': row['memo_to'],
          'memo_from': row['memo_from'],
          'subject': row['subject'],
          'body': row['body']?.toString() ?? '',
          'isGrouped': row['isGrouped'],
          'status': row['status'],
          'original_date': row['original_date']?.toString(),
          'dateFinalized': row['dateFinalized']?.toString(),
          'timeFinalized': row['timeFinalized']?.toString(),
          'formatted_dateFinalized': row['formatted_dateFinalized'],
          'formatted_timeFinalized': row['formatted_timeFinalized'],
          // Combined formatted date and time
          'finalized_datetime':
              '${row['formatted_dateFinalized']} at ${row['formatted_timeFinalized']}',
          'recipients_display':
              row['recipients_display'] ?? 'Unknown Recipients',
        };
      }
      print('DEBUG: No finalized memo found with ID: $memoId');
      return null;
    } catch (e) {
      print('ERROR: Get Memo By ID Error: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      return null;
    } finally {
      await conn.close();
    }
  }

  /// Get memos count for a specific employee (only finalized memos)
  Future<int> getMemosCount(String empId) async {
    final conn = await _dbService.getHrConnection();
    try {
      var results = await conn.query(
        '''
        SELECT COUNT(*) as memo_count
        FROM hr.memos m 
        WHERE m.status = 'Finalized'
          AND (m.isGrouped = 'Everyone' 
             OR (m.isGrouped != 'Everyone' AND FIND_IN_SET(?, m.`to`)))
        ''',
        [empId],
      );

      if (results.isNotEmpty) {
        return results.first['memo_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Get Memos Count Error: $e');
      return 0;
    } finally {
      await conn.close();
    }
  }

  /// Get recent memos (last 30 days) for a specific employee (only finalized memos)
  Future<List<Map<String, dynamic>>> getRecentMemos(String empId,
      {int days = 30}) async {
    final conn = await _dbService.getHrConnection();
    try {
      var results = await conn.query(
        '''
        SELECT 
          m.memo_id,
          LPAD(m.memo_id, 8, '0') as formatted_memo_id,
          DATE_FORMAT(m.date, "%M %d, %Y") as formatted_date,
          DATE_FORMAT(m.date, "%Y-%m-%d") as raw_date,
          m.`to` as memo_to, 
          m.`from` as memo_from, 
          m.subject, 
          m.body,
          m.isGrouped,
          m.status,
          m.date as original_date,
          m.dateFinalized,
          m.timeFinalized,
          DATE_FORMAT(m.dateFinalized, "%M %d, %Y") as formatted_dateFinalized,
          TIME_FORMAT(m.timeFinalized, "%r") as formatted_timeFinalized
        FROM hr.memos m 
        WHERE m.status = 'Finalized'
          AND (m.isGrouped = 'Everyone' 
             OR (m.isGrouped != 'Everyone' AND FIND_IN_SET(?, m.`to`)))
          AND m.date >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
        ORDER BY m.memo_id DESC
        ''',
        [empId, days],
      );

      return results.map((row) {
        return {
          'memo_id': row['memo_id'],
          'formatted_memo_id': row['formatted_memo_id'],
          'formatted_date': row['formatted_date'],
          'raw_date': row['raw_date'],
          'memo_to': row['memo_to'],
          'memo_from': row['memo_from'],
          'subject': row['subject'],
          'body': row['body']?.toString() ?? '',
          'isGrouped': row['isGrouped'],
          'status': row['status'],
          'original_date': row['original_date']?.toString(),
          'dateFinalized': row['dateFinalized']?.toString(),
          'timeFinalized': row['timeFinalized']?.toString(),
          'formatted_dateFinalized': row['formatted_dateFinalized'],
          'formatted_timeFinalized': row['formatted_timeFinalized'],
          'finalized_datetime':
              '${row['formatted_dateFinalized']} at ${row['formatted_timeFinalized']}',
        };
      }).toList();
    } catch (e) {
      print('Get Recent Memos Error: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  /// Search memos by subject or content (only finalized memos)
  Future<List<Map<String, dynamic>>> searchMemos(
      String empId, String searchQuery) async {
    final conn = await _dbService.getHrConnection();
    try {
      var results = await conn.query(
        '''
        SELECT 
          m.memo_id,
          LPAD(m.memo_id, 8, '0') as formatted_memo_id,
          DATE_FORMAT(m.date, "%M %d, %Y") as formatted_date,
          DATE_FORMAT(m.date, "%Y-%m-%d") as raw_date,
          m.`to` as memo_to, 
          m.`from` as memo_from, 
          m.subject, 
          m.body,
          m.isGrouped,
          m.status,
          m.date as original_date,
          m.dateFinalized,
          m.timeFinalized,
          DATE_FORMAT(m.dateFinalized, "%M %d, %Y") as formatted_dateFinalized,
          TIME_FORMAT(m.timeFinalized, "%r") as formatted_timeFinalized
        FROM hr.memos m 
        WHERE m.status = 'Finalized'
          AND (m.isGrouped = 'Everyone' 
             OR (m.isGrouped != 'Everyone' AND FIND_IN_SET(?, m.`to`)))
          AND (m.subject LIKE ? OR m.body LIKE ? OR m.`from` LIKE ?)
        ORDER BY m.memo_id DESC
        ''',
        [empId, '%$searchQuery%', '%$searchQuery%', '%$searchQuery%'],
      );

      return results.map((row) {
        return {
          'memo_id': row['memo_id'],
          'formatted_memo_id': row['formatted_memo_id'],
          'formatted_date': row['formatted_date'],
          'raw_date': row['raw_date'],
          'memo_to': row['memo_to'],
          'memo_from': row['memo_from'],
          'subject': row['subject'],
          'body': row['body']?.toString() ?? '',
          'isGrouped': row['isGrouped'],
          'status': row['status'],
          'original_date': row['original_date']?.toString(),
          'dateFinalized': row['dateFinalized']?.toString(),
          'timeFinalized': row['timeFinalized']?.toString(),
          'formatted_dateFinalized': row['formatted_dateFinalized'],
          'formatted_timeFinalized': row['formatted_timeFinalized'],
          'finalized_datetime':
              '${row['formatted_dateFinalized']} at ${row['formatted_timeFinalized']}',
        };
      }).toList();
    } catch (e) {
      print('Search Memos Error: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  /// Get memos by date range (only finalized memos)
  Future<List<Map<String, dynamic>>> getMemosByDateRange(
      String empId, DateTime startDate, DateTime endDate) async {
    final conn = await _dbService.getHrConnection();
    try {
      var results = await conn.query(
        '''
        SELECT 
          m.memo_id,
          LPAD(m.memo_id, 8, '0') as formatted_memo_id,
          DATE_FORMAT(m.date, "%M %d, %Y") as formatted_date,
          DATE_FORMAT(m.date, "%Y-%m-%d") as raw_date,
          m.`to` as memo_to, 
          m.`from` as memo_from, 
          m.subject, 
          m.body,
          m.isGrouped,
          m.status,
          m.date as original_date,
          m.dateFinalized,
          m.timeFinalized,
          DATE_FORMAT(m.dateFinalized, "%M %d, %Y") as formatted_dateFinalized,
          TIME_FORMAT(m.timeFinalized, "%r") as formatted_timeFinalized
        FROM hr.memos m 
        WHERE m.status = 'Finalized'
          AND (m.isGrouped = 'Everyone' 
             OR (m.isGrouped != 'Everyone' AND FIND_IN_SET(?, m.`to`)))
          AND m.date BETWEEN ? AND ?
        ORDER BY m.memo_id DESC
        ''',
        [
          empId,
          DateFormat('yyyy-MM-dd').format(startDate),
          DateFormat('yyyy-MM-dd').format(endDate)
        ],
      );

      return results.map((row) {
        return {
          'memo_id': row['memo_id'],
          'formatted_memo_id': row['formatted_memo_id'],
          'formatted_date': row['formatted_date'],
          'raw_date': row['raw_date'],
          'memo_to': row['memo_to'],
          'memo_from': row['memo_from'],
          'subject': row['subject'],
          'body': row['body']?.toString() ?? '',
          'isGrouped': row['isGrouped'],
          'status': row['status'],
          'original_date': row['original_date']?.toString(),
          'dateFinalized': row['dateFinalized']?.toString(),
          'timeFinalized': row['timeFinalized']?.toString(),
          'formatted_dateFinalized': row['formatted_dateFinalized'],
          'formatted_timeFinalized': row['formatted_timeFinalized'],
          'finalized_datetime':
              '${row['formatted_dateFinalized']} at ${row['formatted_timeFinalized']}',
        };
      }).toList();
    } catch (e) {
      print('Get Memos By Date Range Error: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  /// Check if employee has access to a specific memo (only finalized memos)
  Future<bool> hasAccessToMemo(String empId, int memoId) async {
    final conn = await _dbService.getHrConnection();
    try {
      var results = await conn.query(
        '''
        SELECT COUNT(*) as has_access
        FROM hr.memos m 
        WHERE m.memo_id = ?
          AND m.status = 'Finalized'
          AND (m.isGrouped = 'Everyone' 
               OR (m.isGrouped != 'Everyone' AND FIND_IN_SET(?, m.`to`)))
        ''',
        [memoId, empId],
      );

      if (results.isNotEmpty) {
        return (results.first['has_access'] ?? 0) > 0;
      }
      return false;
    } catch (e) {
      print('Check Memo Access Error: $e');
      return false;
    } finally {
      await conn.close();
    }
  }

  /// Get memo statistics for an employee (only finalized memos)
  Future<Map<String, dynamic>> getMemoStatistics(String empId) async {
    final conn = await _dbService.getHrConnection();
    try {
      // Get total count
      var totalResults = await conn.query(
        '''
        SELECT COUNT(*) as total_count
        FROM hr.memos m 
        WHERE m.status = 'Finalized'
          AND (m.isGrouped = 'Everyone' 
             OR (m.isGrouped != 'Everyone' AND FIND_IN_SET(?, m.`to`)))
        ''',
        [empId],
      );

      // Get recent count (last 30 days)
      var recentResults = await conn.query(
        '''
        SELECT COUNT(*) as recent_count
        FROM hr.memos m 
        WHERE m.status = 'Finalized'
          AND (m.isGrouped = 'Everyone' 
             OR (m.isGrouped != 'Everyone' AND FIND_IN_SET(?, m.`to`)))
          AND m.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        ''',
        [empId],
      );

      // Get count for this month
      var monthResults = await conn.query(
        '''
        SELECT COUNT(*) as month_count
        FROM hr.memos m 
        WHERE m.status = 'Finalized'
          AND (m.isGrouped = 'Everyone' 
             OR (m.isGrouped != 'Everyone' AND FIND_IN_SET(?, m.`to`)))
          AND YEAR(m.date) = YEAR(CURDATE()) 
          AND MONTH(m.date) = MONTH(CURDATE())
        ''',
        [empId],
      );

      return {
        'total_memos': totalResults.isNotEmpty
            ? (totalResults.first['total_count'] ?? 0)
            : 0,
        'recent_memos': recentResults.isNotEmpty
            ? (recentResults.first['recent_count'] ?? 0)
            : 0,
        'this_month_memos': monthResults.isNotEmpty
            ? (monthResults.first['month_count'] ?? 0)
            : 0,
      };
    } catch (e) {
      print('Get Memo Statistics Error: $e');
      return {
        'total_memos': 0,
        'recent_memos': 0,
        'this_month_memos': 0,
      };
    } finally {
      await conn.close();
    }
  }

  /// Utility method to strip HTML tags from memo content
  String stripHtmlTags(String htmlString) {
    if (htmlString.isEmpty) return '';

    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString
        .replaceAll(exp, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  /// Utility method to get short preview of memo content
  String getMemoPreview(String content, {int maxLength = 100}) {
    String cleanContent = stripHtmlTags(content);
    if (cleanContent.length <= maxLength) {
      return cleanContent;
    }
    return '${cleanContent.substring(0, maxLength)}...';
  }

  /// Format date for display
  String formatDateForDisplay(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  /// Format date for short display
  String formatDateShort(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }
}
