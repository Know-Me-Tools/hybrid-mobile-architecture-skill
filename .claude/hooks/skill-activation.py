#!/usr/bin/env python3
"""Thin Claude adapter for the canonical Builder activation manifest."""

from __future__ import annotations

import runpy
from pathlib import Path

ADAPTER = (
    Path(__file__).resolve().parents[2]
    / "templates"
    / "project-skills"
    / "hooks"
    / "skill-activation.py"
)
runpy.run_path(str(ADAPTER), run_name="__main__")
