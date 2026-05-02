import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../controllers/employee_controller.dart';
import '../../services/memo_service.dart';
import '../../widgets/common/memo_card.dart';
import '../../config/theme.dart';
import 'memo_detail_screen.dart';

class MemoScreen extends StatefulWidget {
  const MemoScreen({super.key});

  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  final MemoService _memoService = MemoService.instance;
  final employeeController = Get.find<EmployeeController>();
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> memos = [];
  List<Map<String, dynamic>> filteredMemos = [];
  bool isLoading = false;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMemos() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final employeeData = employeeController.getEmployeeData();

      if (employeeData != null) {
        final empId = employeeData['emp_id'];

        final loadedMemos = await _memoService.getMemos(empId);

        setState(() {
          memos = loadedMemos;
          filteredMemos = loadedMemos;
        });
      }
    } catch (e) {
      print('ERROR: Error loading memos: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');

      // Check if mounted before using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading memos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
      _refreshController.refreshCompleted();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMemos = memos;
        isSearching = false;
      } else {
        isSearching = true;
        filteredMemos = memos.where((memo) {
          return (memo['subject'] ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (memo['memo_from'] ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              _memoService
                  .stripHtmlTags(memo['body'] ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _getRecipientsDisplay(Map<String, dynamic> memo) {
    if (memo['isGrouped'] == 'Everyone') {
      return 'Everyone';
    } else {
      return 'Specific Recipients';
    }
  }

  Future<void> _viewMemoDetail(Map<String, dynamic> memo) async {
    try {
      final memoDetail = await _memoService.getMemoById(memo['memo_id']);
      if (memoDetail != null) {
        Get.to(
          () => MemoDetailScreen(memo: memoDetail),
          transition: Transition.rightToLeft,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading memo details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error loading memo detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading memo details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Memos',
          style: AppTheme.titleStyle,
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search memos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: SmartRefresher(
              controller: _refreshController,
              onRefresh: _loadMemos,
              header: const WaterDropHeader(),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredMemos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSearching
                                    ? Icons.search_off
                                    : Icons.mail_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isSearching
                                    ? 'No memos found for your search'
                                    : 'No memos found',
                                style: AppTheme.subtitleStyle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isSearching
                                    ? 'Try a different search term'
                                    : 'Pull down to refresh',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredMemos.length,
                          itemBuilder: (context, index) {
                            final memo = filteredMemos[index];
                            return MemoCard(
                              memoId: memo['formatted_memo_id'] ?? '',
                              date: memo['formatted_date'] ?? '',
                              from: memo['memo_from'] ?? '',
                              subject: memo['subject'] ?? '',
                              recipients: _getRecipientsDisplay(memo),
                              onTap: () => _viewMemoDetail(memo),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
