# Product Overview

AEGIS RPA Backend is a cognitive, intent-driven RPA (Robotic Process Automation) engine that processes natural language instructions and executes desktop automation tasks through intelligent orchestration of RPA tools.

## Core Purpose

Serve as the automation brain for the AEGIS system by leveraging Google Agent Development Kit (ADK) with Gemini to provide intelligent task interpretation, translating high-level natural language instructions into sequences of low-level desktop actions.

## Key Features

- Cognitive task interpretation using Google ADK with Gemini
- Cost-optimized with pre-processing validation and plan caching
- Multi-app orchestration across desktop applications
- Real-time streaming via WebSocket for live execution monitoring
- Robust error handling with automatic retry logic and exponential backoff
- Execution history with persistent storage
- Intelligent strategy selection (coordinate-based vs element-based)

## System Flow

1. **Pre-Processing**: Validate and filter requests before LLM calls
2. **Plan Cache**: Check for cached execution plans to minimize LLM costs
3. **ADK Agent**: Generate execution plan using Gemini with custom RPA toolbox
4. **RPA Engine**: Execute low-level desktop actions (PyAutoGUI, Win32API)
5. **WebSocket Streaming**: Broadcast real-time status updates to frontend
6. **History Storage**: Persist session results for review and debugging

## Target Platform

Windows desktop (primary) with Win32API support. PyAutoGUI provides cross-platform compatibility for future expansion.
