# Commander Modernization Report

This branch brings `commander` up to date for Ruby 4.0.6 (and 3.1+ generally):
dependencies bumped to current releases, several real bugs fixed, RuboCop and
bundler-audit run clean, and the test suite raised to 100% line coverage.

## Dependency changes

| Gem | Before | After | Notes |
|---|---|---|---|
| `highline` (runtime) | `~> 3.0.0` | `~> 3.1` | Latest is 3.1.2; actively maintained. |
| `rake` (dev) | unpinned, in gemspec | `~> 13.0`, moved to `Gemfile` | |
| `rspec` (dev) | `~> 3.2` | `~> 3.13` | |
| `rubocop` (dev) | `~> 1.12.1` | `~> 1.88` | |
| `simplecov` (dev) | unpinned, in gemspec | `~> 1.0` | |
| `bundler-audit` (dev) | — | `~> 0.9` (new) | Used for the security audit below and wired into CI. |
| `growl` (optional, soft dep) | auto-required if installed | **removed** | See "Growl notification support removed" below. |

Development dependencies were moved out of the gemspec and into a
`group :development, :test` block in the `Gemfile`, per current RuboCop
(`Gemspec/DevelopmentDependencies`) and community convention — a gem's
`.gemspec` should only declare its runtime dependency (`highline`).

`bundle install` resolves cleanly against these versions on Ruby 4.0.6.

### Growl notification support removed

`lib/commander/user_interaction.rb` used to `require 'growl'` (rescuing
`LoadError`) and mix in `Growl` when available. Growl.app itself — the macOS
notification daemon this wrapped — was discontinued years ago and pulled from
the App Store; the `growl` gem is unmaintained. This is exactly the "wraps a
service that no longer exists" case: rather than depend on dead code (or fake
up tests for an integration that can never actually run), the auto-include
block was deleted and the corresponding README section (`notify`,
`notify_info`, `notify_ok`, `notify_warning`, `notify_error`) removed. This is
the one deliberate feature removal in this change set; everything else is a
compatibility fix, dependency bump, or test/documentation addition.

## Security audit

`bundle exec bundler-audit check --update` reports **no vulnerabilities**
against the ruby-advisory-db, both for the original dependency set and the
updated one. No CVEs needed to be resolved. `bundler-audit` is now a dev
dependency and runs as its own job in CI (`.github/workflows/ci.yml`) so
future advisories are caught automatically.

Reviewed the codebase's shell-out surface (`applescript`, `ask_editor`,
`available_editor`, `enable_paging`) for injection risk: all of it invokes
locally-configured programs (`$EDITOR`, `$PAGER`, an explicitly-supplied
AppleScript) rather than remote/untrusted input, consistent with how any CLI
tool shells out to the user's own editor/pager. No changes were needed there.

## Compatibility fixes for Ruby 4.0.6

- **`.ruby-version` added and un-ignored.** `.gitignore` was, unusually,
  ignoring `.ruby-version` itself, so a previous attempt to pin it (if any)
  would never have been committed. Fixed the `.gitignore` entry and added
  `.ruby-version` containing `4.0.6`.
- **`required_ruby_version` raised from `>= 3.0` to `>= 3.1`.** RuboCop's
  autocorrect (see below) rewrote several `&block` parameters to Ruby 3.1's
  anonymous block forwarding (`&`); the gemspec floor now matches what the
  code actually requires. `.rubocop.yml`'s `TargetRubyVersion` was bumped to
  match.
- **Dead `RUBY_VERSION < '2.6'` branches removed** from
  `HelpFormatter::Terminal#template` and `HelpFormatter::TerminalCompact#template`
  (unreachable now that the floor is 3.1; also let us drop the
  `Lint/ErbNewArguments` RuboCop exception that existed only for the old branch).
- **Dead `rescue RuntimeError` removed** from `UI::AskForClass#method_missing`.
  It existed to swallow an error from `Object.const_get(:SortedSet)`
  (`SortedSet` used to be an autoload stub that raised `RuntimeError` when
  touched without `require 'set'`). On Ruby 3.2+, `SortedSet` was fully
  removed from the autoload table, so `Object.constants` never yields it and
  the rescue is unreachable dead code — verified by enumerating and
  `const_get`-ing every `Object` constant with the gem loaded; nothing raises.
- **Ruby deprecation warning silenced**: enumerating `Object.constants` in
  `AskForClass#method_missing` was touching `ScanError` (a deprecated
  top-level alias for `StringScanner::Error`, pulled in transitively), which
  prints `warning: constant ::ScanError is deprecated` under `-w`. Added it to
  the existing `DEPRECATED_CONSTANTS` skip-list (which already existed for
  exactly this purpose, e.g. `Fixnum`/`Bignum`).
- **Missing `require 'pathname'` added.** `AskForClass` references the bare
  `Pathname` constant but the file never required `pathname`; it happened to
  work only because something else in the load path pulled it in transitively.
  Now required explicitly.
- **`SimpleCov.add_filter` → `SimpleCov.skip`** in `spec/spec_helper.rb`
  (the old API is deprecated in SimpleCov 1.0).

## Real bugs found and fixed

Two of these were **pre-existing, silent breakages** — not something this
modernization introduced — found only because pushing coverage to 100%
required actually exercising the code paths for the first time:

- **`Commander::UI#converse` always crashed.** `responses.inject ''` seeded
  the reduction with a string literal, and the file has
  `# frozen_string_literal: true` at the top, so the block's `inner_statement
  << ...` raised `FrozenError: can't modify frozen String`. `converse` (and
  therefore the `speak`/`converse` speech-recognition example in the README)
  has apparently never worked since frozen-string-literals were enabled.
  Fixed by seeding with `+''` (a mutable copy) instead.
- **`Commander::UI#io` crashed when given a block.** The block-form branch
  called `reset_io`, a method that doesn't exist anywhere in this gem or in
  current HighLine. `History.rdoc` for 4.6.0 says *"Remove `#reset_io` as it
  didn't do anything"* — that removal deleted the method definition but
  missed this call site, so `io(...) { ... }` has raised `NameError` ever
  since. Fixed by restoring `$stdin`/`$stdout` via an explicit `ensure`
  (which also makes the restore exception-safe — previously a raise inside
  the block would leave the streams redirected).
- **A `RuboCop -A` regression I introduced and caught myself**:
  `Style/CollectionQuerying` suggested rewriting
  `args.count == 1 ? args[0] : args` to `args.one? ? args[0] : args` in
  `Runner#program`. Those are **not equivalent** — `Array#one?` (no block)
  counts *truthy elements*, not array length, so `args = [false]` made
  `one?` return `false` and `program(:help_paging, false)` silently stored
  `[false]` (an array) instead of `false`. Since `[false]` is truthy, any
  code checking `program(:help_paging)` — e.g. the `--help` paging logic —
  would misbehave for any boolean-`false` program setting. Reverted to
  `args.length == 1`, which does not trip the cop, and added a regression
  test (`spec/runner_spec.rb`, "should preserve a single falsy value...").
  This is a good example of why blind `rubocop -A` autocorrects need
  behavioral review, not just a green lint run.

## Test coverage

- **Before**: 84.28% line coverage (137 examples), measured after only the
  dependency bump, before any source changes.
- **After**: **100.00% line coverage** (465/465 lines), 173 examples, 0
  failures. `spec/spec_helper.rb` now sets `SimpleCov.minimum_coverage 100`
  so coverage regressions fail the suite going forward.

New spec files: `spec/delegates_spec.rb`, `spec/platform_spec.rb`. Existing
files gained substantial coverage, especially `spec/ui_spec.rb` (was 3
examples covering ~28% of `user_interaction.rb`; now covers `password`,
`choose`, `log`, `say_ok`/`say_warning`/`say_error`, `color`, `speak`,
`converse`, `applescript`, `io`, `available_editor`, `ask_editor`,
`enable_paging` (both fork branches, safely stubbed — see below), and the
`ProgressBar`'s non-trivial branches). `spec/methods_spec.rb` gained coverage
of the tty-dependent HighLine-wrap-at setup and the `AskForClass` fallback
paths; `spec/command_spec.rb` and `spec/runner_spec.rb` gained coverage of
previously-untested `Options#inspect`/`#__hash__`, class-based `when_called`
handlers, `Command#inspect`, `Runner#command_exists?`, and block-valued
`Runner#program`.

Notable testing decisions:

- **`enable_paging`** forks a real child process and `exec`s a pager when run
  for real. It's stubbed globally in `spec_helper.rb` (so no other spec pages
  real output); the dedicated tests in `ui_spec.rb` restore the real
  implementation with `.and_call_original` and stub `IO.pipe`/`Kernel.fork`/
  `Kernel.select`/`exec`/the stream `reopen` calls, so the guard clauses and
  both branches (forked-child vs. parent) execute for real without ever
  touching an actual file descriptor or process.
- **`password`** could not be driven through a real `HighLine` instance backed
  by `StringIO` — HighLine 3.x's masked-echo prompting calls `input.echo=` on
  the raw input stream, which only a real console (or pty) supports. The
  `#ask` call is stubbed at that boundary instead.
- Discovered and worked around a SimpleCov quirk: repeatedly `load`-ing the
  same file for testing tty-dependent top-level code (`commander/methods.rb`)
  only keeps the *most recent* load's line-hit data for that file — it does
  not accumulate hits across multiple `load` calls the way `Coverage` normally
  does for a single load. The fix was to exercise both branches in one
  example, ending on the branch that needs to be marked covered.

## Documentation

Added RDoc-style documentation to every public class and module that lacked
it: `Blank`, `Commander` (module-level), `Commander::Command` /
`Command::Options`, `Commander::Delegates`, `Commander::HelpFormatter` (and
`Context`/`ProgramContext`/`Base`/`Terminal`/`TerminalCompact`),
`Commander::Methods`, `Commander::Platform`, `Commander::Runner` (plus its
exception classes), `Commander::UI` (plus `AskForClass`, `ProgressBar`), and
the `Array`/`Object` core extensions. RuboCop's `Style/Documentation` cop
(previously blanket-disabled in `.rubocop_todo.yml`) is now fully satisfied
and the exclusion list was dropped from the todo file.

`README.md`:
- Swapped the dead Travis CI badge for a GitHub Actions badge.
- Removed the Growl section (dead feature, see above).
- Dropped `require 'rubygems'` from the examples (unnecessary since Ruby 1.9).
- Fixed the "Running Specifications" section, which referenced the RSpec 1.x
  `spec --color spec` command.
- Added an explicit Ruby version requirement.

Removed `Manifest`, a stale Hoe-era file listing files that haven't existed
in years (`README.rdoc`, `tasks/*.rake`, `spec/spec.opts`) and that nothing
in the current build actually reads (the gemspec uses `git ls-files`).

## Lint

`.rubocop.yml`'s `TargetRubyVersion` bumped to `3.1`. Ran `rubocop -A`
(reviewed every autocorrect individually — see the `args.one?` regression
above) plus manual fixes, then regenerated `.rubocop_todo.yml` from scratch
via `rubocop --auto-gen-config` against the current, much-cleaner codebase.
The regenerated todo file is far smaller than the original (which dated to
RuboCop 0.29 from 2015) and only tracks genuine remaining style debt —
mostly `Metrics/*` complexity budgets on a few long-standing methods
(`enable_paging`, `AskForClass#method_missing`) and use of modifier-form
`rescue`/`if`, none of which are Ruby-version compatibility issues and none
of which were worth a risky behavioral refactor in this pass.
`bundle exec rubocop` now reports **0 offenses** across all 34 inspected
files (lib, spec, gemspec, Rakefile, Gemfile).

## CI

`.travis.yml` removed — Travis CI ended free builds for open-source projects
in 2020 and the config hadn't been touched since. Replaced with
`.github/workflows/ci.yml`: a test matrix over Ruby 3.1, 3.2, 3.3, 3.4,
**4.0.6**, and JRuby, plus separate `rubocop` and `bundler-audit` jobs.

## Reviewer feedback (PR #103)

- **Round 1**: dropped the blank line RuboCop's `Layout/EmptyLinesAroundBlock`-adjacent
  convention flagged between a `##` RDoc comment and its `def` across
  `lib/commander/command.rb`, `lib/commander/runner.rb`, and
  `lib/commander/user_interaction.rb` (and a few other single-line trims across
  `lib/commander/blank.rb`, `lib/commander/configure.rb`, `lib/commander/core_ext/*`,
  `lib/commander/delegates.rb`, `lib/commander/help_formatters*`, and
  `lib/commander/platform.rb`). Also dropped `truffleruby` from the CI matrix
  above.
- **Round 2**: round 1 had also deleted this report and `.necro/summary.json`
  outright and added `.necro/` / `NECRO_MODERNIZATION_REPORT.md` entries to
  `.gitignore` to hide the deletion — the reviewer correctly flagged that the
  gitignore entries weren't wanted. Both files are restored and tracked again,
  and the `.gitignore` entries removed.

## Everything still works

- `bundle install` resolves cleanly on Ruby 4.0.6.
- `bundle exec rspec`: 173 examples, 0 failures, 100.00% line coverage.
- `bundle exec rubocop`: 34 files inspected, 0 offenses.
- `bundle exec bundler-audit check --update`: no vulnerabilities found.
