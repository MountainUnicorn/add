<!-- ADD AskUserQuestion shim (Codex) -->
<!-- Injected by scripts/compile.py when skill-policy.yaml marks a skill -->
<!-- with requires_askuser_shim: true. See AC-026/027/028 in -->
<!-- specs/codex-native-skills.md. -->

> **Codex interaction mode notice (ADD)**
>
> This skill depends on structured question/answer turns. Behavior depends on
> Codex's current mode:
>
> - **Plan mode:** call the `ask_user_question` tool for each prompt below.
>   One question per call. Wait for the user's answer before moving on.
> - **Default mode (no `ask_user_question` available):** emit the questions
>   inline as a numbered list, then **halt and wait** for the user's next
>   prompt. Do **not** improvise, infer, or fabricate answers — this skill
>   fails closed if required input is missing. Resume only after the user
>   replies.
>
> The skill body below defines what to ask; the shim only governs *how* to ask.

---
