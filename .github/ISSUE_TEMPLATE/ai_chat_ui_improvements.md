## 📋 Problem Statement

The current chat interface across all IoT modules uses generic, default styling from the flutter_chat_ui package. This creates several limitations:

- **Lack of module identity**: Chat UI looks the same regardless of which IoT module (temperature sensor, gamepad, servo, light control) the user is interacting with
- **Generic appearance**: Default message bubbles, header, and composer don't align with modern mobile chat experiences (iOS, WhatsApp, Telegram)
- **No dark mode support**: Users cannot use chat in low-light environments comfortably
- **Limited visual polish**: Attachment previews, typing indicators, and transitions lack refinement

**Current State:**
- Simple modal bottom sheet with basic chat interface
- Generic message bubbles without distinctive styling
- Plain header with minimal branding
- Light mode only
- Default flutter_chat_ui components throughout

## 🎯 User Value

**Immediate Benefits:**
- **Module-specific branding**: Each IoT module gets its own color theme, creating a more immersive and contextual experience
- **Modern, polished UI**: iOS-style asymmetric message bubbles provide a familiar, professional chat experience
- **Dark mode support**: Users can chat comfortably in any lighting condition
- **Better visual hierarchy**: Enhanced header, composer, and attachment previews improve usability

**Concrete Examples:**
1. **Temperature Sensor Module**: Blue-themed chat with temperature icon in header, making it clear the AI assistant is helping with temperature control
2. **Gamepad Module**: Green-themed chat with gaming controller icon, perfect for troubleshooting game controls
3. **Dark Mode Users**: Can use chat at night without eye strain, with properly adjusted module colors for contrast

**User Experience Improvements:**
- Faster visual recognition of which module context they're in
- More engaging, branded experience per IoT feature
- Professional, modern chat interface matching industry standards
- Comfortable viewing in all lighting conditions

## 🔧 Technical Requirements

### Architecture Considerations (Clean Architecture)
**Presentation Layer:**
- New widgets in `lib/features/chat/presentation/widgets/`
- Theme provider in `lib/features/chat/presentation/theme/`
- Modifications to existing `ChatContent` and `PxChatBotFloatingButton`

**No Domain/Data Layer Changes:**
- Business logic (UseCases, Repository) remains unchanged
- This is purely a presentation/UI enhancement
- Existing `ChatBloc` state management works as-is

### Technology Stack Components
- **Flutter SDK**: 3.7.2+ (current version)
- **Dependencies**: 
  - `flutter_chat_ui: ^1.6.15` (custom builders)
  - `material_symbols_icons` (module icons)
  - Existing theme system (`AppColors`)

### UI Components Required

**New Components:**
1. `ChatThemeProvider` - Module-specific theme generation (light/dark)
2. `CustomTextMessageBubble` - iOS-style asymmetric bubbles
3. `ChatModalHeader` - Branded header with module icon/avatar
4. Enhanced attachment preview styling

**Modified Components:**
1. `chat_content.dart` - Integrate custom builders and theme
2. `px_chatbot_floating_button.dart` - Use new header component

### Design Specifications

**Message Bubbles:**
- iOS-style asymmetric corners
  - User: `BorderRadius.only(topLeft: 16, topRight: 16, bottomLeft: 16, bottomRight: 4)`
  - Assistant: `BorderRadius.only(topLeft: 16, topRight: 16, bottomLeft: 4, bottomRight: 16)`
- Padding: 16px horizontal, 12px vertical
- Timestamps: Inside bubbles (bottom-right, 11px, subtle)
- Subtle shadows for depth

**Module Color Theming:**
```dart
moduleThemes = {
  'temperature_sensor': AppColors.blue (#2196F3),
  'gamepad': AppColors.lightGreen (#8BC34A),
  'servo': AppColors.red (#F44336),
  'light_control': AppColors.orange (#FF9800),
  'chat': AppColors.purple (#9C27B0),
}
```

**Dark Mode:**
- Lighten module colors by 20% for better contrast
- Use `ChatTheme.dark()` and `ChatTheme.light()`
- Auto-detect from system brightness
- Ensure all custom components support both themes

**Header Design:**
- Left-aligned module icon/avatar (24px)
- Two-line title: "Chat" (12px) + Module Name (16px bold)
- Module-colored background with white text
- Minimize/Close buttons on right
- Subtle shadow for separation

## ✅ Definition of Done

- [x] Branch created: `feat/ai-chat-ui-improvements`
- [ ] Implementation complete following Clean Architecture principles
  - [ ] `ChatThemeProvider` created with module color mappings
  - [ ] `CustomTextMessageBubble` widget with iOS-style corners
  - [ ] `ChatModalHeader` with module branding
  - [ ] Dark mode support fully implemented
  - [ ] Attachment preview enhanced
  - [ ] Typing indicator uses module colors
- [ ] All ABOUTME comments added to new files
- [ ] Code follows Flutter/Dart style guide (`dart format`)
- [ ] Zero analyzer warnings (`flutter analyze`)
- [ ] Tests: **Deferred** per planning session (can be added in follow-up PR)
- [ ] Manual testing completed successfully (see checklist below)
- [ ] Before/after screenshots captured
- [ ] Code review approved by 1 reviewer
- [ ] All CI/CD checks pass
- [ ] PR merged to `develop`

## 🧪 Manual Testing Checklist

### Basic Flow:
- [ ] Open chat modal from temperature sensor module
  - [ ] Verify header is blue-themed with thermostat icon
  - [ ] Send text message - verify user bubble is blue with asymmetric corners
  - [ ] Receive response - verify assistant bubble is gray with opposite asymmetric corners
  - [ ] Check timestamp visibility and formatting (HH:mm)
- [ ] Repeat for all modules (gamepad, servo, light_control, chat)
  - [ ] Verify each has correct color theme
  - [ ] Verify each has correct module icon
- [ ] Attach image
  - [ ] Verify enhanced preview styling with rounded corners
  - [ ] Send image with text - verify both appear correctly
- [ ] Attach file
  - [ ] Verify file preview with better icon styling
  - [ ] Send and verify display

### Dark Mode Testing:
- [ ] Switch device/app to dark mode
- [ ] Open chat in each module
  - [ ] Verify lightened module colors (20% lighter)
  - [ ] Verify text contrast is readable
  - [ ] Verify message bubbles have appropriate dark backgrounds
  - [ ] Verify header is visible with proper contrast
- [ ] Send/receive messages in dark mode
  - [ ] Verify timestamps are visible
  - [ ] Verify attachment previews work
- [ ] Switch back to light mode
  - [ ] Verify seamless theme transition

### Edge Cases:
- [ ] Very long message text
  - [ ] Verify bubble expands correctly
  - [ ] Verify max width constraint (75% screen)
  - [ ] Verify word wrapping works
- [ ] Rapid message sending
  - [ ] Verify bubbles stack properly
  - [ ] Verify typing indicator appears/disappears
- [ ] Multiple attachments
  - [ ] Verify preview layout handles multiple items
- [ ] Small screen (phone) vs large screen (tablet)
  - [ ] Verify responsive bubble sizing
  - [ ] Verify header fits properly

### Error Handling:
- [ ] Network error during message send
  - [ ] Verify error state displays
  - [ ] Verify retry works
- [ ] Image load failure
  - [ ] Verify placeholder/error icon appears
- [ ] Chat session timeout
  - [ ] Verify graceful handling and user notification

### Integration Testing:
- [ ] Chat modal minimize/expand
  - [ ] Verify state persists
  - [ ] Verify draggable sheet works smoothly
- [ ] Switch between modules
  - [ ] Verify theme changes correctly
  - [ ] Verify separate chat sessions maintained
- [ ] Keyboard interaction
  - [ ] Verify composer moves with keyboard
  - [ ] Verify auto-scroll on new messages
  - [ ] Verify send button states (enabled/disabled)

### Performance:
- [ ] Load chat with 50+ messages
  - [ ] Verify smooth scrolling
  - [ ] Verify no lag in message rendering
- [ ] Send image message
  - [ ] Verify no UI freeze during upload
  - [ ] Verify smooth preview display

## 🏗️ Implementation Strategy

**Branch:** `feat/ai-chat-ui-improvements`  
**Base Branch:** `develop`  
**Estimated Effort:** Medium (M) - 6-8 hours total

**Implementation Phases:**
1. **Phase 1**: Theme System (ChatThemeProvider) - 1-2 hours
2. **Phase 2**: Message Bubbles (CustomTextMessageBubble) - 2 hours
3. **Phase 3**: Header Component (ChatModalHeader) - 1-2 hours
4. **Phase 4**: Composer & Attachment Polish - 1-2 hours
5. **Phase 5**: Dark Mode Integration - 1 hour
6. **Phase 6**: Final Polish & Testing - 1 hour

**Dependencies:**
- None - self-contained UI enhancement
- Does not block other features
- Can be developed in parallel with other work

**Commit Convention:**
```bash
feat(chat): add module-specific theming system
feat(chat): implement iOS-style message bubbles
feat(chat): create enhanced header component
feat(chat): add dark mode support
style(chat): polish composer and attachment preview
```

## 📚 Related Documentation

**Planning Session:**
- `.claude/sessions/context_session_ai_chat_ui_improvements.md` (Complete analysis and specifications)

**Architectural References:**
- `.github/copilot-instructions.md` - Clean Architecture guidelines
- `lib/features/chat/` - Current chat implementation
- `lib/theme/app_color.dart` - Color system

**Design Patterns:**
- Flutter Chat UI Builders: https://pub.dev/packages/flutter_chat_ui
- Material Design 3 Chat Patterns
- iOS Message Bubble Design Reference

**Current Implementation:**
- `lib/shared/widgets/chat/px_chatbot_floating_button.dart` - Entry point
- `lib/features/chat/presentation/pages/chat_content.dart` - Main chat UI
- `lib/features/chat/presentation/bloc/chat_bloc.dart` - State management (unchanged)

**Expected Visual Result:**
- Before: Generic default flutter_chat_ui styling
- After: iOS-style bubbles, module-branded colors, full dark mode support
