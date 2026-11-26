# AI usage

## Tool

- **Claude Code**, used as a coding assistant.

## Where it helped

1. **Fonts:** identified the typefaces used in the design (Outfit, Inter, and
   Rubik for Arabic) and added them to the project.
2. **Translations:** replaced the hard-coded strings with translation keys and
   the English/Arabic JSON files. This was done at my request: I chose
   `easy_localization` for languages and translation.
3. **`docs/`:** the screenshots and the demo recording.
4. **Code comments:** wrote the comments, following my instruction to keep them
   short, useful, and only where they are needed.
5. **Data layer:** studied the DummyJSON API, then created `lib/data/` (models
   and data source) and adapted my `Crud` class and the other API-related files
   to this test API.
6. **Network layer:** the `Crud` request pipeline and `QueryCache`.
7. **Tests:** created and ran every test in `test/`, following the testing
   guide and instructions I provided.
8. **Screen sizes:** layout and fit checks across phone screen sizes.
9. **Delivery files:** the README (architecture, state management, packages,
   language switching and RTL/LTR, assumptions and known limitations) and this
   file.
10. **Commits:** wrote the commit messages in the Conventional Commits format
    and made the commits at the end of each stage.
11. **Code review:** ran the `flutter-reviewer` agent on each stage's code
    before it was committed.

## Example instructions

- "Build the network layer on the pattern of my previous project (GetX,
  `Either<StatusRequest, ApiResult>`), with timeout and unexpected-response
  handling and a cache."
- "Replace every hard-coded string with a translation key present in both the
  English and the Arabic file, using `easy_localization`."
- "Keep comments short and useful, and only where they are needed."

## How the output was verified

- DummyJSON parameters were tried with real requests before any code was
  written, and the test fixtures are real API responses.
- Every change had to pass `dart format`, `flutter analyze` and the test suite
  (480 tests, 99.5% line coverage), enforced by a pre-push hook.
- Each fix needed a test that failed before the fix.
- Every screen was compared side by side with the Figma frames in both
  languages and in the three palettes; the release build was also checked on
  my own phone.

## Output that was changed or rejected

- After review I asked for changes: every image goes through one
  `AppAssetImage` widget, choosing the font by language moved into the font
  helper, and the logo got one export per palette.
- Adding `flutter_launcher_icons` as a dev dependency downgraded a package
  that `flutter_svg` uses at runtime; it was reverted and run as a global tool.
- A README draft named a test that does not exist; it was corrected against
  the actual test names.

## Differences from the design

DummyJSON serves products, not properties, so the screens differ from the
design where needed to show real API data:

- location → `brand` (or the category), rating → `rating`, the three Details
  features → `stock`, `weight` and `dimensions` (no units: the API gives none),
  facilities → `tags`, reviews → `reviews`;
- the agent and map sections are left out, since the API has nothing behind
  them;
- the "Details" and "Building Size" filter groups filter by minimum rating,
  minimum stock and weight, and prices use a logarithmic scale;
- "Continue with Google" starts a local guest session;
- controls with no backing feature are shown dimmed and disabled.
