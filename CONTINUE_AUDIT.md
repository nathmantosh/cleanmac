# CleanMac UI Audit - Quick Resume

## If conversation broke, paste this in new chat:

```
Continue the CleanMac UI audit. Read the file at:
/Users/mantoshdebnath/Desktop/clean my mac alternative/CONTINUE_AUDIT.md
```

## Context

- **Project**: CleanMac (native macOS app)
- **Location**: `/Users/mantoshdebnath/Desktop/clean my mac alternative/`
- **Goal**: Comprehensive UI audit - find bugs, missing features, UX issues
- **Problem**: mac-control MCP screenshot tool was causing agent crashes (large Retina screenshots causing memory issues)

## What Opus should do

1. Use mac-control MCP tools **carefully** (fewer screenshots, more text-based checks)
2. Open CleanMac app and test each feature:
   - Smart Scan
   - Cleanup
   - Protection
   - Applications
   - My Cache
3. Check sidebar navigation, buttons, animations
4. Document all issues found in a report

## Tips for Opus

- Use `mcp_mac-control_list_windows` instead of screenshots when possible
- Take screenshots ONE at a time with pauses between
- Use `mcp_mac-control_get_frontmost_app` to verify app state
- Don't call multiple mac-control tools in parallel

## Previous Attempts

The "CleanMac Feature Audit" conversation crashed after calling open_app + screenshot quickly.
