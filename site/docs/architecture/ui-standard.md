---
sidebar_position: 2
title: UI and interaction standard
---

# KnowMe product language

KnowMe is a calm, private personal-intelligence workspace: local-first, inspectable,
continuous across devices, and honest about which model and device perform work.

## Flat 2.0

No visual boundary may depend on a line, border, decorative outline, gradient, or
layout shadow. Adjacent regions use distinct background tokens. Spacing, type,
shape, and content provide hierarchy inside a region. Both light and dark themes
use the same four-step surface ladder: canvas, chrome, surface, and raised surface.

Keyboard focus remains visible with an accessible focus treatment and a state cue;
the ban on decorative borders does not justify hiding focus.

## Component rules

React 19 surfaces prefer Shadcn UI components over raw controls and use Assistant
UI for the thread/composer primitives. Every default border from those libraries
must be removed or translated into a filled surface. Flutter uses equivalent tokens,
real chat bubbles, Riverpod-generated providers, and platform-appropriate accessible
controls. User and assistant bubbles differ by background, alignment, and speaker
label—not an outline.
