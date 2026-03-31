"""Shared utilities for plugin metadata scripts."""

import re
from typing import Dict


def parse_frontmatter(content: str) -> Dict[str, str]:
    """Parse YAML frontmatter from a markdown file.

    Extracts simple key-value pairs from content between --- markers.
    """
    frontmatter = {}

    match = re.match(r'^---\s*\n(.*?)\n---\s*\n', content, re.DOTALL)
    if match:
        for line in match.group(1).split('\n'):
            line = line.strip()
            if ':' in line:
                key, value = line.split(':', 1)
                frontmatter[key.strip()] = value.strip()

    return frontmatter
