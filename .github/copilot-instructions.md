# GitHub Copilot Instruction for Flutter Projects

> **Purpose:**  
> This repository uses GitHub Copilot for AI-assisted code completion. Please follow these instructions to ensure Copilot generates code that matches our standards and requirements for Flutter and Dart.

## Copilot Guidance

- **Code Style:**  
  - Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.
  - Use proper indentation and formatting as enforced by `dartfmt`.
  - Prefer stateless widgets when possible.
  - Use meaningful and descriptive names for classes, methods, and variables.

- **Project Structure:**  
  - Organize code using **feature-first structure** (no domain layer):
    ```
    lib/
      features/
        <feature_name>/
          data/
          presentation/
            widgets/
          <feature_file>.dart
      core/
      main.dart
    ```
    - Place UI in `presentation/`, data access in `data/`.
    - Each feature should be self-contained.

- **State Management:**  
  - Use the `provider` package for state management unless otherwise specified.

- **Documentation:**  
  - Include DartDoc comments (`///`) for all public classes, methods, and properties.
  - Document widget usage and expected behavior.

- **Testing:**  
  - Write unit and widget tests using Flutter's `test` and `flutter_test` packages.
  - Ensure tests cover edge cases and UI interactions.

- **Error Handling:**  
  - Use `try-catch` blocks for async operations and handle exceptions gracefully.
  - Show user-friendly error messages in the UI.

- **Security & Safety:**  
  - Do not hardcode sensitive information (API keys, secrets).
  - Validate user input and handle null safety appropriately.

## Example Copilot Prompt (for Dart/Flutter files)
```dart
// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.
```

## Contribution

When contributing, include or update the Copilot instruction block at the top of new files as needed.

---

*Adjust these rules based on your project’s specific requirements!*