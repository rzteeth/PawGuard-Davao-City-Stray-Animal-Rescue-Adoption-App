import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pawguard/user_home.dart';

class MatchingPreferencesScreen extends StatefulWidget {
  const MatchingPreferencesScreen({super.key});

  @override
  _MatchingPreferencesScreenState createState() =>
      _MatchingPreferencesScreenState();
}

class _MatchingPreferencesScreenState extends State<MatchingPreferencesScreen> {
  // Options for matching preferences
  final List<String> typeOptions = [
    'Dog',
    'Cat'
  ]; // Corresponds to Firestore's 'type' field
  final List<String> activityOptions = [
    'Playful',
    'Calm',
    'Energetic',
    'Loving'
  ];
  final List<String> sizeOptions = ['Small', 'Medium', 'Large'];

  // Track the selected options for each category
  String? selectedTypeOption;
  String? selectedActivityOption;
  String? selectedSizeOption;

  // Colors for the UI
  static const Color primaryColor = Color(0xFFEF6B39);
  static const Color backgroundColor = Colors.white;
  static const Color textColorDark = Color(0xFF2D3142);
  static const Color textColorLight = Color(0xFF9094A0);

  // Save preferences and navigate to UserHomePage
  void savePreferences() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UserHomePage(
          selectedType: selectedTypeOption, // Pass selected type
          selectedActivityLevel:
              selectedActivityOption, // Pass selected activity level
          selectedSize: selectedSizeOption, // Pass selected size
        ),
      ),
    );
  }

  int _getSelectedCount() {
    int count = 0;

    if (selectedTypeOption != null) count++;
    if (selectedActivityOption != null) count++;
    if (selectedSizeOption != null) count++;

    return count;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildPreferenceSection(
                              'Type of Pet', typeOptions, true),
                          _buildPreferenceSection(
                              'Activity Level', activityOptions, true),
                          _buildPreferenceSection('Size', sizeOptions, true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // Build the app bar
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Preferences',
          style: TextStyle(
            color: textColorDark,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
    );
  }

  // Build the header at the top
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.pets_rounded,
            color: primaryColor.withOpacity(0.7),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select your preferences to help us find your perfect pet match',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: textColorDark.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build a preference section for a specific category
  Widget _buildPreferenceSection(
      String title, List<String> options, bool singleSelect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColorDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10.0,
            runSpacing: 12.0,
            children: options.map((option) {
              // Determine if the option is selected
              bool isSelected;
              if (title == 'Activity Level') {
                isSelected = selectedActivityOption == option;
              } else if (title == 'Size') {
                isSelected = selectedSizeOption == option;
              } else {
                isSelected = selectedTypeOption == option;
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (singleSelect) {
                      if (title == 'Activity Level') {
                        selectedActivityOption = isSelected ? null : option;
                      } else if (title == 'Size') {
                        selectedSizeOption = isSelected ? null : option;
                      } else if (title == 'Type of Pet') {
                        selectedTypeOption = isSelected ? null : option;
                      }
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : textColorLight.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? backgroundColor : textColorDark,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Build the bottom bar with skip and continue buttons
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: savePreferences,
            style: TextButton.styleFrom(
              foregroundColor: textColorLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${_getSelectedCount()}/3',
            style: TextStyle(
              fontSize: 16,
              color: textColorDark.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            height: 48,
            child: ElevatedButton(
              onPressed: savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: backgroundColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
