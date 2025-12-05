# Requirements Document

## Introduction

The Local App Launcher is an optimization feature for the AEGIS RPA Backend that enables efficient application launching without requiring LLM (ADK/Gemini) calls. The system extracts application names from natural language user prompts and launches them directly using Windows Start Menu search via PyAutoGUI keyboard automation. This reduces latency, minimizes API costs, and improves reliability for common app-launching tasks.

## Glossary

- **Local App Launcher**: A pre-processing module that detects and executes application launch requests without LLM involvement
- **App Name Extraction**: The process of identifying application names from natural language text using pattern matching and keyword detection
- **Windows Start Menu Search**: The Windows search interface accessed via the Win key that allows launching applications by typing their names
- **PyAutoGUI**: A Python library for programmatic keyboard and mouse control
- **Fallback Mechanism**: The process of routing requests to the ADK agent when local launching fails or is not applicable
- **Launch Pattern**: A predefined sequence of keyboard actions (Win key → type app name → Enter) used to launch applications
- **App Name Mapping**: A dictionary that maps common app name variations to their canonical Windows search terms

## Requirements

### Requirement 1

**User Story:** As a user, I want the system to quickly launch applications when I request them, so that I can start working with minimal delay.

#### Acceptance Criteria

1. WHEN a user submits an instruction containing "open [app_name]" or "launch [app_name]", THEN the Local App Launcher SHALL extract the application name from the instruction
2. WHEN the Local App Launcher extracts an application name, THEN the Local App Launcher SHALL normalize the name using the App Name Mapping dictionary
3. WHEN the Local App Launcher has a normalized application name, THEN the Local App Launcher SHALL execute the Launch Pattern using PyAutoGUI
4. WHEN the Launch Pattern completes, THEN the Local App Launcher SHALL verify the application launched successfully within 5 seconds
5. WHEN the application launch verification fails, THEN the Local App Launcher SHALL trigger the Fallback Mechanism to route the request to the ADK agent

### Requirement 2

**User Story:** As a system administrator, I want the app launcher to support common application name variations, so that users can use natural language without memorizing exact names.

#### Acceptance Criteria

1. WHEN a user requests "chrome", "google chrome", or "browser", THEN the Local App Launcher SHALL map all variations to the canonical name "chrome"
2. WHEN a user requests "excel", "spreadsheet", or "ms excel", THEN the Local App Launcher SHALL map all variations to the canonical name "excel"
3. WHEN a user requests "word", "document", or "ms word", THEN the Local App Launcher SHALL map all variations to the canonical name "word"
4. WHEN a user requests "notepad", "text editor", or "note pad", THEN the Local App Launcher SHALL map all variations to the canonical name "notepad"
5. WHEN the App Name Mapping dictionary does not contain a requested application, THEN the Local App Launcher SHALL use the extracted name as-is for the Windows search

### Requirement 3

**User Story:** As a developer, I want the launcher to use a reliable keyboard automation sequence, so that applications launch consistently across different Windows configurations.

#### Acceptance Criteria

1. WHEN executing the Launch Pattern, THEN the Local App Launcher SHALL press the Windows key and wait 1 second for the Start Menu to open
2. WHEN the Start Menu is open, THEN the Local App Launcher SHALL type the application name with a 0.1 second interval between characters
3. WHEN the application name is typed, THEN the Local App Launcher SHALL press Enter and wait 1 second for search results to appear
4. WHEN search results appear, THEN the Local App Launcher SHALL press Enter again to launch the top result
5. WHEN any step in the Launch Pattern fails, THEN the Local App Launcher SHALL log the failure and trigger the Fallback Mechanism

### Requirement 4

**User Story:** As a system architect, I want the launcher to integrate seamlessly with the existing preprocessing layer, so that it operates as a transparent optimization.

#### Acceptance Criteria

1. WHEN the preprocessing layer receives a task instruction, THEN the preprocessing layer SHALL check if the Local App Launcher can handle the request before calling the ADK agent
2. WHEN the Local App Launcher successfully launches an application, THEN the preprocessing layer SHALL return a success response without invoking the ADK agent
3. WHEN the Local App Launcher cannot handle a request, THEN the preprocessing layer SHALL route the request to the ADK agent as normal
4. WHEN the Local App Launcher is processing a request, THEN the preprocessing layer SHALL send WebSocket status updates indicating "Launching application locally"
5. WHEN the Local App Launcher completes, THEN the preprocessing layer SHALL record the execution in the history store with the launch method indicated

### Requirement 5

**User Story:** As a quality assurance engineer, I want the launcher to detect when it should not attempt local launching, so that complex multi-step tasks are handled by the full ADK agent.

#### Acceptance Criteria

1. WHEN a user instruction contains multiple sentences or steps, THEN the Local App Launcher SHALL decline to handle the request and defer to the ADK agent
2. WHEN a user instruction contains application-specific actions beyond launching (e.g., "open chrome and navigate to google.com"), THEN the Local App Launcher SHALL decline to handle the request
3. WHEN a user instruction is ambiguous about which application to launch, THEN the Local App Launcher SHALL decline to handle the request
4. WHEN the Local App Launcher declines a request, THEN the Local App Launcher SHALL log the reason and immediately route to the ADK agent
5. WHEN the Local App Launcher accepts a request, THEN the Local App Launcher SHALL complete the launch within 10 seconds or trigger the Fallback Mechanism

### Requirement 6

**User Story:** As a system operator, I want the launcher to provide detailed logging and metrics, so that I can monitor its effectiveness and troubleshoot issues.

#### Acceptance Criteria

1. WHEN the Local App Launcher processes a request, THEN the Local App Launcher SHALL log the extracted application name and normalized name
2. WHEN the Local App Launcher executes the Launch Pattern, THEN the Local App Launcher SHALL log each step with timestamps
3. WHEN the Local App Launcher succeeds or fails, THEN the Local App Launcher SHALL record the outcome with execution time
4. WHEN the Local App Launcher triggers the Fallback Mechanism, THEN the Local App Launcher SHALL log the reason for fallback
5. WHEN the system generates execution history, THEN the history SHALL include a field indicating whether local launching was used

### Requirement 7

**User Story:** As a developer, I want the launcher to be configurable, so that I can adjust timing parameters and add new application mappings without code changes.

#### Acceptance Criteria

1. WHEN the Local App Launcher initializes, THEN the Local App Launcher SHALL load timing parameters from environment variables or configuration files
2. WHEN the Local App Launcher initializes, THEN the Local App Launcher SHALL load the App Name Mapping dictionary from a JSON configuration file
3. WHEN the configuration file is updated, THEN the Local App Launcher SHALL reload the mappings without requiring a server restart
4. WHEN timing parameters are invalid or missing, THEN the Local App Launcher SHALL use default values (1 second for menu open, 0.1 seconds for typing interval)
5. WHEN the App Name Mapping file is missing or invalid, THEN the Local App Launcher SHALL log a warning and operate with an empty mapping dictionary
