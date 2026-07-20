# OpenVM

A lightweight, loop-immune nested virtual environment runner for OpenComputers. OpenVM allows you to boot an isolated OpenOS sub-shell using dynamic path redirection while seamlessly passing through core hardware components like network cards and floppy disk drives.

---

## Features

* **Instant Sandboxing:** Isolates execution paths without requiring heavy resource allocation or full hardware emulation.
* **Hardware Passthrough:** Filters component discovery to bridge the host's `modem` (networking) and `floppy` devices straight into the virtual environment.
* **Stack-Overflow Protection:** Bypasses traditional OpenOS boot buffer recursion loops by leveraging shared host runtime tables.
* **Global Access:** Installs directly as a system binary so you can spin up a VM from anywhere.

---

## Installation

Run the automated installer directly inside your OpenComputers terminal to prepare the directories and configure the environment:

```bash
wget [https://raw.githubusercontent.com/YOUR_USERNAME/OpenVM/main/install.lua](https://raw.githubusercontent.com/YOUR_USERNAME/OpenVM/main/install.lua)
lua install.lua
