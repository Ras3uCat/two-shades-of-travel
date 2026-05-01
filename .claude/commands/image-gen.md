Source or generate an image for the client site.

Load `.claude/skills/image-gen/SKILL.md` before proceeding.

---

The subject for this image is: $ARGUMENTS

Follow the full Invocation Workflow from the skill:
1. If $ARGUMENTS is empty, ask the user what the image should show before proceeding.
2. Build the brand-aware prompt using values from `client.json`.
3. Try Gemini Imagen 3 first, then fall back to Unsplash, then Pexels.
4. Save the image to `execution/frontend/app/assets/images/` with a slugified filename.
5. Emit the `IMAGE_GEN_RESULT:` block after success.
6. Remind the user to add `assets/images/` to `pubspec.yaml` if not already declared.
