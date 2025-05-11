#!/usr/bin/env dart

import 'dart:io';

// Version bump types
enum BumpType {
  patch, // 1.0.0 -> 1.0.1
  minor, // 1.0.0 -> 1.1.0
  major, // 1.0.0 -> 2.0.0
}

void main(List<String> arguments) async {
  // Default to patch if no arguments provided
  BumpType bumpType = BumpType.patch;
  String releaseNote = '';
  
  // Parse arguments
  if (arguments.isNotEmpty) {
    switch (arguments[0].toLowerCase()) {
      case 'major':
        bumpType = BumpType.major;
        break;
      case 'minor':
        bumpType = BumpType.minor;
        break;
      case 'patch':
        bumpType = BumpType.patch;
        break;
      default:
        printUsage();
        exit(1);
    }
  }
  
  // Get release notes if provided
  if (arguments.length > 1) {
    releaseNote = arguments.sublist(1).join(' ');
  } else {
    print('Enter release note:');
    releaseNote = stdin.readLineSync() ?? '';
  }
  
  // Update versions
  try {
    await updateVersions(bumpType, releaseNote);
    print('✅ Version updated successfully!');
  } catch (e) {
    print('❌ Error updating version: $e');
    exit(1);
  }
}

Future<void> updateVersions(BumpType bumpType, String releaseNote) async {
  // 1. Read current version from pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    throw 'pubspec.yaml not found';
  }
  
  final pubspecContent = await pubspecFile.readAsString();
  final RegExp versionPattern = RegExp(r'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)');
  final match = versionPattern.firstMatch(pubspecContent);
  
  if (match == null) {
    throw 'Could not find version pattern in pubspec.yaml';
  }
  
  // Extract version parts
  int major = int.parse(match.group(1)!);
  int minor = int.parse(match.group(2)!);
  int patch = int.parse(match.group(3)!);
  int build = int.parse(match.group(4)!);
  
  // Calculate new version according to bump type
  switch (bumpType) {
    case BumpType.major:
      major++;
      minor = 0;
      patch = 0;
      break;
    case BumpType.minor:
      minor++;
      patch = 0;
      break;
    case BumpType.patch:
      patch++;
      break;
  }
  
  // Always increment build number
  build++;
  
  // Format new version strings
  final newVersionString = '$major.$minor.$patch';
  final newFullVersionString = '$newVersionString+$build';
  
  // 2. Update pubspec.yaml
  final newPubspecContent = pubspecContent.replaceFirst(
    versionPattern, 
    'version: $newFullVersionString'
  );
  await pubspecFile.writeAsString(newPubspecContent);
  
  // 3. Update VERSION file
  final versionFile = File('VERSION');
  if (versionFile.existsSync()) {
    String versionFileContent = await versionFile.readAsString();
    versionFileContent = '$newVersionString\n${versionFileContent.substring(versionFileContent.indexOf('\n') + 1)}';
    
    // Update version history section
    final date = DateTime.now().toString().split(' ')[0];
    final historyEntry = '\n### $newVersionString - $date\n- $releaseNote\n';
    
    // Find the position after ## Version History
    final versionHistoryPos = versionFileContent.indexOf('## Version History');
    final nextHeaderPos = versionFileContent.indexOf('##', versionHistoryPos + 1);
    
    if (versionHistoryPos != -1 && nextHeaderPos != -1) {
      final insertPosition = versionFileContent.indexOf('\n', versionHistoryPos) + 1;
      versionFileContent = versionFileContent.substring(0, insertPosition) + 
                          historyEntry + 
                          versionFileContent.substring(insertPosition);
    }
    
    await versionFile.writeAsString(versionFileContent);
  }
  
  // 4. Update CHANGELOG.md
  final changelogFile = File('CHANGELOG.md');
  if (changelogFile.existsSync()) {
    String changelogContent = await changelogFile.readAsString();
    final date = DateTime.now().toString().split(' ')[0];
    
    // Create new changelog entry
    final changeLogEntry = '''
## [$newVersionString] - $date

### ${bumpType.name.capitalize()}
- $releaseNote
''';

    // Find position to insert (after header and before first version entry)
    final headerEndPos = changelogContent.indexOf('## [');
    if (headerEndPos != -1) {
      changelogContent = '${changelogContent.substring(0, headerEndPos)}$changeLogEntry\n${changelogContent.substring(headerEndPos)}';
    }
    
    await changelogFile.writeAsString(changelogContent);
  }
}

// Print usage message
void printUsage() {
  print('''
Usage: dart scripts/bump_version.dart [bump_type] [release note]

bump_type: (default: patch)
  - major: 1.0.0 -> 2.0.0
  - minor: 1.0.0 -> 1.1.0
  - patch: 1.0.0 -> 1.0.1

Example:
  dart scripts/bump_version.dart minor "Added dark theme support"
''');
}

// String extension for capitalization
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
} 