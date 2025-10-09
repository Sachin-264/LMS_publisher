# LMS Publisher - Login UI

A modern Flutter login screen that matches your design specifications, featuring Google Fonts and a responsive layout.

## Features

- **Modern Design**: Clean, professional interface matching your provided design
- **Google Fonts**: Uses Inter font for modern typography
- **Responsive Layout**: Adapts to different screen sizes (mobile, tablet, desktop)
- **Green Color Scheme**: Professional green theme (`#1A5F3F`)
- **Form Validation**: Basic validation for email and password fields
- **Interactive Elements**: Password visibility toggle, hover effects

## Design Elements

### Desktop Layout
- **Left Side**: Login form with email, password, and submit button
- **Right Side**: Placeholder area for your illustrations or content
- **Colors**: White form area with green gradient background

### Mobile Layout
- **Full Screen**: Single column layout with card-based form
- **Green Gradient**: Full background gradient
- **Responsive**: Optimized for mobile devices

## File Structure

```
lib/
├── main.dart                           # App entry point
└── screens/
    ├── login_screen.dart              # Basic login screen
    └── responsive_login_screen.dart   # Responsive login screen (recommended)
```

## Getting Started

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

## Customization

### Colors
The main colors used in the app:
- Primary Green: `Color(0xFF1A5F3F)`
- Secondary Green: `Color(0xFF2D7A5A)`
- Background: `Color(0xFFF8F9FA)` / `Color(0xFFE8F5E8)`
- Text: `Color(0xFF1A1A1A)`
- Placeholder: `Color(0xFF6B7280)`

### Fonts
- **Primary Font**: Inter (via Google Fonts)
- **Weights Used**: 400 (regular), 500 (medium), 600 (semi-bold), 700 (bold)

### Right Side Content
To add your own illustrations or content to the right side:

1. Open `lib/screens/responsive_login_screen.dart`
2. Find the "Right side - Illustration/Content Area" section (around line 152)
3. Replace the placeholder content with your own widgets

Example:
```dart
// Replace this section with your content
Container(
  width: 200,
  height: 200,
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
  ),
  child: YourIllustrationWidget(), // Add your illustration here
),
```

## Usage

The login screen includes:
- Email/Username field
- Password field with visibility toggle
- "Forgot?" link
- "Log In" button
- "Sign Up" link

### Adding Functionality

To implement actual login functionality:

1. Open `responsive_login_screen.dart`
2. Modify the `_handleLogin()` method (line 448)
3. Add your authentication logic
4. Modify the `_handleSignUp()` method (line 478) for sign-up navigation

## Dependencies

- `flutter`: SDK
- `google_fonts`: ^6.1.0 - For modern typography

## Screen Support

- ✅ Desktop (1024px+)
- ✅ Tablet (768px - 1023px)
- ✅ Mobile (< 768px)

The layout automatically adapts based on screen width using `LayoutBuilder`.
