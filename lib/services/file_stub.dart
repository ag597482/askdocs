// Stub file for web platform - File class is not used on web
// This file is only imported when running on web to satisfy conditional imports
class File {
  final String path;
  
  File(this.path);
  
  // This class should never be instantiated on web
  // The uploadPDF method is only called on mobile platforms
}
