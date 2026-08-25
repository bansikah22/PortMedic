# PortMedic

> **The fastest way to free a busy development port on macOS.**

*A lightweight, native macOS developer utility built with Swift and SwiftUI for managing development ports and processes.*

---

# Project Vision

PortMedic is more than a port killer.

It is a lightweight **Developer Productivity Utility** designed to eliminate repetitive development tasks related to managing local processes and occupied network ports.

The first release focuses on solving one of the most common frustrations developers face every day:

> **"Address already in use"**

Rather than forcing developers to remember terminal commands or open a heavyweight IDE, PortMedic provides a fast, native, one-click experience that integrates seamlessly with macOS.

Our long-term vision is to make PortMedic the go-to utility that quietly lives in the background and helps developers stay focused on writing code—not managing processes.

---

# Mission

To eliminate repetitive command-line workflows involved in managing development ports while providing the fastest, lightest, and most intuitive native macOS experience for developers.

---

# Why PortMedic?

During software development it is common for applications to crash, fail to shut down properly, or leave ports occupied.

Developers are often interrupted by messages such as:

```
Address already in use

Port 8080 is already occupied.
```

The typical workflow requires opening the Terminal and executing commands like:

```bash
lsof -i :8080
kill -9 <PID>
```

or

```bash
pkill -f java
```

Although these commands are simple, developers execute them countless times throughout the week.

PortMedic removes this repetitive workflow by allowing developers to release occupied ports with a single click.

---

# Problem Statement

Developers lose valuable time switching between their IDE and the Terminal simply to identify and terminate a process occupying a network port.

The traditional workflow involves:

1. Opening Terminal.
2. Finding the process using a port.
3. Identifying the Process ID (PID).
4. Running another command to terminate it.
5. Returning to the IDE.
6. Restarting the application.

This repetitive context switching slows development and interrupts focus.

---

# Existing Solutions

There are already excellent tools that solve this problem, including:

- PortPal
- Portless
- Command-line utilities
- Shell aliases
- VS Code extensions

These tools demonstrate that this is a genuine problem experienced by developers worldwide.

However, many existing solutions require developers to:

- Open VS Code
- Use a plugin
- Remember terminal commands
- Work inside another application
- Use cross-platform desktop frameworks

PortMedic takes a different approach.

Instead of being another plugin or command-line tool, it is designed as a **native macOS utility** that is always available, launches instantly, consumes minimal system resources, and integrates naturally into the macOS ecosystem.

---

# Why Build It in Swift?

Swift provides several advantages for this type of utility.

## Native Experience

PortMedic feels like a true macOS application rather than a web application wrapped inside a desktop shell.

## Lightweight

Swift applications typically have:

- Faster startup
- Lower memory usage
- Better battery efficiency
- Smaller resource footprint

Compared to opening a heavyweight IDE simply to access a port management plugin, launching PortMedic should feel almost instantaneous.

## macOS Integration

Swift allows us to take advantage of native macOS capabilities such as:

- Menu Bar applications
- Native notifications
- Keyboard shortcuts
- Native dialogs
- Accessibility support
- System appearance (Dark Mode)

## Learning Opportunity

PortMedic is also an excellent project for learning:

- Swift
- SwiftUI
- MVVM
- Native macOS APIs
- Process management
- Asynchronous programming
- System programming concepts

---

# Design Philosophy

Every feature added to PortMedic must satisfy one simple rule:

> **Does this save the developer time?**

If the answer is no, it probably doesn't belong in the application.

Our principles are:

- Lightweight
- Native
- Fast
- Minimal
- Reliable
- Developer-first

---

# Goal

Build a lightweight native macOS application that enables developers to:

- View active ports.
- Search ports or processes.
- View process information.
- Release ports with one click.
- Eliminate repetitive terminal commands.
- Stay focused on development.

---

# Target Users

- Backend Developers
- Full Stack Developers
- DevOps Engineers
- Mobile Developers
- Students
- Software Engineers
- Anyone running local development environments

---

# Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Architecture:** MVVM
- **Platform:** macOS
- **System APIs:** Foundation (`Process`, `Pipe`)
- **Minimum macOS Version:** TBD

No backend.

No database.

No internet connection required.

---

# Core Features (MVP)

## View Active Ports

Display all active listening ports.

| Port | PID | Process |
|------|------|---------|
| 3000 | 9211 | node |
| 5432 | 1122 | postgres |
| 8080 | 4512 | java |

---

## Search

Search by:

- Port
- Process
- PID

---

## One-Click Kill

Terminate a process with one click.

```
Kill
```

---

## Confirmation Dialog

Prevent accidental termination.

```
Kill Java (PID 4512)?

Cancel      Kill
```

---

## Refresh

Refresh the list manually.

---

## Auto Refresh

Automatically refresh running processes every few seconds.

---

# Advanced Features

## Framework Detection

Instead of showing only:

```
java
```

Display:

```
Spring Boot

Ledger Service
```

or

```
Node

BioFlow Backend
```

---

## Project Detection

Display the working directory of the running application whenever possible.

Example:

```
~/Projects/Ledgers
```

This makes it easier to identify which project owns a port when multiple Java or Node processes are running.

---

## Smart Process Recognition

Recognize common developer technologies such as:

- Spring Boot
- React
- Vite
- Next.js
- Node.js
- Docker
- PostgreSQL
- MySQL
- Redis
- MongoDB
- Python

Instead of generic process names, PortMedic will present meaningful information.

---

## Color Coding

🟢 System Processes

🟡 User Applications

🔴 Suspicious or Unknown Processes

---

## Favorites

Pin commonly used ports.

Examples:

- 3000
- 5173
- 5432
- 6379
- 8080
- 8081

---

## Kill by Process

Examples:

- Kill all Java
- Kill all Node
- Kill all Python

---

## Process Details

Display:

- PID
- Process Name
- Executable
- Working Directory
- User
- Port
- Protocol

---

## Notifications

Example:

```
✓ Port 8080 released successfully.
```

---

## History

Maintain a history of recently terminated processes.

---

## Copy Utilities

Quick actions:

- Copy PID
- Copy Port
- Copy Kill Command

---

## Open in Terminal

Inspect the selected process directly in Terminal.

---

## Menu Bar Mode

One of the signature features of PortMedic.

Instead of opening a full application, developers can manage occupied ports directly from the macOS menu bar.

Example:

```
PortMedic

8080   Spring Boot

3000   Node

5432   PostgreSQL

Refresh

Quit
```

This makes releasing a port possible in just a few clicks without interrupting development.

---

# Future Roadmap

PortMedic is envisioned as a broader **Developer Productivity Utility**.

Future versions may include:

- CPU usage
- Memory usage
- Real-time monitoring
- Restart process
- Export process list
- Keyboard shortcuts
- Application icons
- Automatic framework detection improvements
- Docker integration
- Development service monitoring
- Quick actions for common developer workflows

---

# Non-Goals (Version 1)

To keep the first release lightweight and focused, it will **not** include:

- Firewall management
- Remote machine support
- Network monitoring
- Cloud synchronization
- Authentication
- Database integration

---

# User Workflow

```
Launch PortMedic
        ↓
View Active Ports
        ↓
Search (optional)
        ↓
Select Process
        ↓
Click Kill
        ↓
Confirm
        ↓
Port Released
        ↓
Continue Coding
```

---

# Example UI

```
--------------------------------------------------------

                    PortMedic

--------------------------------------------------------

🔍 Search

[______________________________________]

--------------------------------------------------------

PORT     FRAMEWORK      PROCESS        ACTION

3000     React          node           Kill

5173     Vite           node           Kill

5432     PostgreSQL     postgres       Kill

8080     Spring Boot    java           Kill

--------------------------------------------------------

Refresh
```

---

# Competitive Advantages

| Existing Solutions | PortMedic |
|-------------------|-----------|
| Often rely on terminal commands | Native graphical interface |
| VS Code plugins require opening the IDE | Standalone macOS application |
| Cross-platform frameworks | Native SwiftUI experience |
| Generic process names | Framework-aware process detection |
| Basic process killing | Developer productivity focused |
| Designed for multiple platforms | Optimized specifically for macOS |

---

# Why This Project?

PortMedic solves a real problem experienced by thousands of developers every day.

Research shows that developers frequently search for solutions to:

- Address already in use
- Port already occupied
- EADDRINUSE
- How to kill a process on a port

Existing projects and community discussions validate that this pain point is widespread.

Rather than reinventing the idea, PortMedic aims to provide the **best native macOS experience** for solving it.

---

# Long-Term Vision

PortMedic starts as a port management tool but is envisioned as a broader **Developer Productivity Utility** for macOS.

As the project evolves, it can expand into helping developers monitor local development services, manage processes, identify frameworks, and streamline common development workflows—all while remaining lightweight, fast, and native.

---

# Philosophy

> **Developers shouldn't have to leave their workflow to solve a common problem.**

PortMedic exists to remove friction from development.

One click.

One second.

One free port.

One less interruption.

## Menu Bar Integration

PortMedic lives in the macOS menu bar, providing instant access without requiring developers to open a full application.

The menu bar interface allows users to:

- View active development ports.
- Search ports instantly.
- Kill a process with one click.
- Refresh active processes.
- Launch the full application when needed.

This enables developers to resolve occupied ports in seconds without leaving their workflow.
