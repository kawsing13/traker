import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../providers/api_provider.dart';
import '../../models/employee.dart';
import '../../controllers/employee_controller.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../vars.dart';

class ProfileScreen extends StatelessWidget {
  final AuthService _authService = AuthService.instance;
  // Ensure controller exists; fall back to creating one if not registered yet.
  final employeeController = Get.isRegistered<EmployeeController>()
      ? Get.find<EmployeeController>()
      : Get.put(EmployeeController());

  ProfileScreen({super.key});

  // Helper method to format employee ID to 8 digits
  String _formatEmployeeId(String empId) {
    return empId.padLeft(8, '0');
  }

  @override
  Widget build(BuildContext context) {
    final employeeData = employeeController.getEmployeeData();

    // Get empId from controller or fallback to global empId
    int empIdValue = empId;
    if (employeeData != null &&
        employeeData['emp_id'] != null &&
        employeeData['emp_id'].toString().trim().isNotEmpty) {
      empIdValue = int.tryParse(employeeData['emp_id'].toString()) ?? empId;
    }

    if (empIdValue == 0) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(AppConstants.noEmployeeDataMessage),
              const SizedBox(height: 16),
              ElevatedButton(
                style: AppTheme.primaryButtonStyle,
                onPressed: () => Get.offAllNamed(AppRoutes.login),
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: hrApiProvider.api.fetchProfile(empIdValue),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          print('Profile Error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading profile: ${snapshot.error}',
                      style: const TextStyle(color: AppTheme.errorColor)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: () => Get.back(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final profileData = snapshot.data;
        if (profileData == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No profile data found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: () => Get.back(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Convert Map to Employee object
        final employee = Employee.fromMap(profileData);

        // Get position details from the controller
        final positionDetails = employeeController.getPositionDetails();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
            ),
            title: const Text("Profile", style: AppTheme.titleStyle),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildProfileHeader(employee),
                const SizedBox(height: 32),
                // Add position details card here
                /*_buildPositionDetailsCard(positionDetails),
                const SizedBox(height: AppConstants.verticalSpacingSmall * 2),*/
                _buildPersonalInfoCard(employee),
                const SizedBox(height: AppConstants.verticalSpacingSmall * 2),
                _buildGovernmentIDsCard(employee),
                /*const SizedBox(height: AppConstants.verticalSpacingSmall * 2),
                _buildAccountInfoCard(employee),*/
              ],
            ),
          ),
        );
      },
    );
  }

  // New method to build the position details card
  Widget _buildPositionDetailsCard(Map<String, dynamic> positionDetails) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Position Information",
              style: AppTheme.subtitleStyle,
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Position",
                positionDetails['position']?.toString() ?? 'Not assigned'),
            _buildDivider(),
            _buildInfoRow("Department",
                positionDetails['department']?.toString() ?? 'Not assigned'),
            _buildDivider(),
            _buildInfoRow("Office",
                positionDetails['office']?.toString() ?? 'Not assigned'),
            _buildDivider(),
            _buildInfoRow("Branch",
                positionDetails['branch']?.toString() ?? 'Not assigned'),
            _buildDivider(),
            _buildInfoRow(
                "Unit", positionDetails['unit']?.toString() ?? 'Not assigned'),
            _buildDivider(),
            _buildInfoRow("Company",
                positionDetails['company']?.toString() ?? 'Not assigned'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Employee employee) {
    final formattedEmpId = _formatEmployeeId(empId.toString());
    final imageUrl =
        'https://core10.myapps.ph/img/employee/$formattedEmpId.jpg';

    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.verticalSpacingSmall * 2),
        Text(
          "${employee.firstName} ${employee.middleName} ${employee.surname}",
          style: AppTheme.titleStyle.copyWith(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        // Add the position title below the name for better visibility
        Obx(() => Text(
              employeeController.positionName.value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            )),
      ],
    );
  }

  Widget _buildPersonalInfoCard(Employee employee) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Personal Information",
              style: AppTheme.subtitleStyle,
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Nickname", employee.alias),
            _buildDivider(),
            _buildInfoRow("Birthdate", employee.birthDate),
            _buildDivider(),
            _buildInfoRow("Civil Status", employee.maritalStatus),
            _buildDivider(),
            _buildInfoRow("Sex", employee.sex),
            _buildDivider(),
            _buildInfoRow("Birth Place", employee.birthPlace),
            _buildDivider(),
            _buildInfoRow("Email", employee.email),
            _buildDivider(),
            _buildInfoRow("Date Hired", employee.dateHired),
          ],
        ),
      ),
    );
  }

  Widget _buildGovernmentIDsCard(Employee employee) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Government IDs",
              style: AppTheme.subtitleStyle,
            ),
            const SizedBox(height: 16),
            _buildInfoRow("TIN", employee.tin),
            _buildDivider(),
            _buildInfoRow("SSS", employee.sss),
            _buildDivider(),
            _buildInfoRow("PHIC", employee.phic),
            _buildDivider(),
            _buildInfoRow("HDMF", employee.hdmf),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(Employee employee) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Account Information",
              style: AppTheme.subtitleStyle,
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Employee ID", employee.empId),
            _buildDivider(),
            _buildInfoRow("Username", employee.alias),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 16,
      thickness: 0.5,
      color: Colors.grey[300],
    );
  }
}
