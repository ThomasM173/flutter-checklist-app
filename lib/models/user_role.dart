/// Back-compat shim. The canonical definitions now live in `profile.dart`
/// (`UserRole` enum + the unified `Profile` model that replaced the old
/// Cognito `UserAccount` and local `User` types).
library;
export 'profile.dart' show UserRole, Profile;
