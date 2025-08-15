#!/usr/bin/env python3
"""
Auto-fix common flake8 style violations
"""
import re
import os
from pathlib import Path


def fix_f_string_placeholders(content):
    """Fix F541 - f-strings without placeholders."""
    # Pattern: f"text" or f'text' without any {}
    pattern = r'f(["\'])([^{}\1]*?)\1'
    
    def replacer(match):
        quote = match.group(1)
        text = match.group(2)
        return f'{quote}{text}{quote}'
    
    return re.sub(pattern, replacer, content)


def fix_spacing_issues(content):
    """Fix E231 - missing whitespace after colon."""
    # Add space after colons in dict/print statements, but not in slices
    lines = content.split('\n')
    fixed_lines = []
    
    for line in lines:
        # Skip if it's already formatted or if it's a slice
        if ':' not in line:
            fixed_lines.append(line)
            continue
            
        # Look for patterns like f"text:{variable}" or print(f"text:{var}")
        # Add space after colon if it's followed by a non-space character
        if re.search(r'f["\'][^"\']*:[^}\s"\']', line):
            line = re.sub(r':(?=[^}\s"\'])', ': ', line)
        
        fixed_lines.append(line)
    
    return '\n'.join(fixed_lines)


def fix_sim_violations(content):
    """Fix SIM violations."""
    # SIM910: Use config.get("key") instead of config.get("key", None)
    content = re.sub(
        r'\.get\((["\'][^"\']+["\'])\s*,\s*None\)',
        r'.get(\1)',
        content
    )
    
    # SIM105: Use contextlib.suppress
    content = re.sub(
        r'try:\s*\n([^\n]*)\s*\nexcept ([^:]+):\s*\n\s*pass',
        r'with contextlib.suppress(\2):\n\1',
        content
    )
    
    return content


def process_file(file_path):
    """Process a single Python file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Apply fixes
        content = fix_f_string_placeholders(content)
        content = fix_spacing_issues(content)
        content = fix_sim_violations(content)
        
        # Only write if content changed
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed: {file_path}")
            return True
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        
    return False


def main():
    """Main function."""
    backend_dir = Path('.')
    files_fixed = 0
    
    # Process all Python files
    for py_file in backend_dir.rglob('*.py'):
        if ('venv' in str(py_file) or 
            '__pycache__' in str(py_file) or
            str(py_file).endswith('fix_style_violations.py')):
            continue
            
        if process_file(py_file):
            files_fixed += 1
    
    print(f"\nFixed {files_fixed} files")


if __name__ == '__main__':
    main()