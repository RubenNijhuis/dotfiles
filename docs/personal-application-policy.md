# Personal application policy

This is the short preference layer for assistants working on this device and
for a personal ChatGPT/Codex project. It makes the everyday application choice
explicit, while preserving a practical fallback when the preferred app is not
available.

| Need | Preferred application | Fallback | Boundary |
| --- | --- | --- | --- |
| Email and desktop contacts | Thunderbird | Provider webmail only when requested or Thunderbird is unavailable | Do not read, send, delete, or alter mail without a direct instruction. |
| Calendar on Apple devices | Apple Calendar | Thunderbird or the calendar web app on non-Apple computers | One operational calendar source; never duplicate events between services. Creating or changing events needs direct instruction. |
| Browser | Zen | Chrome only for a demonstrated compatibility issue | Keep browser sessions and profile data local. |
| Notes and Markdown | Obsidian | Plain Markdown files | Keep notes in the defined personal file structure; never move or publish notes implicitly. |
| Code | VS Code, then Neovim in a terminal | None | Project instructions override personal defaults. |
| Terminal | cmux | macOS Terminal only when cmux is unavailable | Nix owns shell tooling; do not add a package manager as a fallback. |
| Private messaging | Signal | None | Sending, reading, or account changes require direct instruction. |
| Illustration | Krita | Affinity/Figma where a project requires them | Preserve editable source files. |
| RAW photographs | RawTherapee | Apple Photos for library viewing | Treat photo libraries as personal data. |
| Video editing | DaVinci Resolve | HandBrake for graphical conversion | Do not use command-line media conversion unless explicitly requested. |

## Assistant rules

1. Use the preferred application first. If it cannot do the job, say why and
   name the smallest viable fallback before using it.
2. Never infer permission to inspect or act on private communication,
   calendars, credentials, photos, messages, or cloud storage.
3. Keep app credentials, mail stores, browser profiles, and databases outside
   Nix and outside the dotfiles repository.
4. Treat Nix as the installation source of truth. Homebrew is only for a
   documented macOS exception; do not introduce a new Brew dependency where
   the pinned Nix package works.
5. Apply the same preferred application choices on Linux and Windows where the
   application exists. Platform-native calendar notifications are the one
   intentional Apple-specific exception.

## ChatGPT project instruction

Paste this into the instructions of a personal ChatGPT project when you want
new chats to start with these preferences:

> My preferred applications are: Thunderbird for email and desktop contacts;
> Apple Calendar on Apple devices and Thunderbird elsewhere; Zen as my primary
> browser; Obsidian for notes and Markdown; VS Code and Neovim for code; cmux
> for terminal work; Signal for private messaging; Krita for illustration;
> RawTherapee for RAW photos; DaVinci Resolve for video editing; and HandBrake
> for graphical media conversion. Use the preferred app first and do not fall
> back to webmail, another browser, or a competing service without explaining
> why. Never access, send, delete, or change private email, calendars,
> messages, files, or credentials without my direct instruction.
