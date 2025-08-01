#!/usr/bin/env python3
"""
Print Statement Migration Script
===============================

Systematically replaces print() statements with structured logging calls
based on context analysis and message patterns.
"""

import ast
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional


class PrintStatementAnalyzer(ast.NodeVisitor):
    """AST visitor to analyze print statements and their context."""
    
    def __init__(self, source_code: str):
        self.source_code = source_code
        self.source_lines = source_code.splitlines()
        self.print_statements = []
        self.current_function = None
        self.current_class = None
        
    def visit_FunctionDef(self, node):
        """Visit function definitions to track context."""
        old_function = self.current_function
        self.current_function = node.name
        self.generic_visit(node)
        self.current_function = old_function
    
    def visit_ClassDef(self, node):
        """Visit class definitions to track context."""
        old_class = self.current_class
        self.current_class = node.name
        self.generic_visit(node)
        self.current_class = old_class
    
    def visit_Call(self, node):
        """Visit function calls to find print statements."""
        if (isinstance(node.func, ast.Name) and node.func.id == 'print'):
            # Extract the print statement context
            line_num = node.lineno
            col_offset = node.col_offset
            
            # Get the full line
            if line_num <= len(self.source_lines):
                full_line = self.source_lines[line_num - 1]
                
                # Analyze the print statement
                print_info = self._analyze_print_statement(node, full_line, line_num)
                print_info.update({
                    'line_number': line_num,
                    'column': col_offset,
                    'function': self.current_function,
                    'class': self.current_class,
                    'full_line': full_line.strip()
                })
                
                self.print_statements.append(print_info)
        
        self.generic_visit(node)
    
    def _analyze_print_statement(self, node: ast.Call, full_line: str, line_num: int) -> Dict:
        """Analyze a print statement to determine its purpose and replacement."""
        # Extract arguments
        args = []
        for arg in node.args:
            if isinstance(arg, ast.Constant):
                args.append(str(arg.value))
            elif isinstance(arg, ast.Str):  # Python < 3.8 compatibility
                args.append(arg.s)
            elif isinstance(arg, ast.JoinedStr):  # f-string
                args.append("f-string")
            else:
                args.append("expression")
        
        message = ' '.join(args) if args else ""
        
        # Determine log level and category based on content
        log_level, category = self._classify_print_statement(message, full_line)
        
        # Generate replacement code
        replacement = self._generate_replacement(message, full_line, log_level, category)
        
        return {
            'message': message,
            'log_level': log_level,
            'category': category,
            'replacement': replacement,
            'args_count': len(node.args)
        }
    
    def _classify_print_statement(self, message: str, full_line: str) -> Tuple[str, str]:
        """Classify print statement based on content patterns."""
        message_lower = message.lower()
        line_lower = full_line.lower()
        
        # Error patterns
        if any(pattern in message_lower for pattern in ['error', 'failed', 'exception', '❌', 'critical']):
            return 'error', 'error'
        
        # Warning patterns  
        if any(pattern in message_lower for pattern in ['warning', 'warn', '⚠️', 'deprecated']):
            return 'warning', 'warning'
        
        # Success patterns
        if any(pattern in message_lower for pattern in ['success', 'completed', 'finished', '✅', 'done']):
            return 'info', 'success'
        
        # Progress patterns
        if any(pattern in message_lower for pattern in ['processing', 'starting', 'loading', '🔄', '🚀']):
            return 'info', 'progress'
        
        # Debug patterns
        if any(pattern in message_lower for pattern in ['debug', 'headers', 'mapping', 'found:', 'detected']):
            return 'debug', 'debug'
        
        # Audit patterns
        if any(pattern in message_lower for pattern in ['user', 'auth', 'login', 'access', 'permission']):
            return 'info', 'audit'
        
        # Performance patterns
        if any(pattern in message_lower for pattern in ['time', 'duration', 'performance', 'ms', 'seconds']):
            return 'info', 'performance'
        
        # Default to info
        return 'info', 'general'
    
    def _generate_replacement(self, message: str, full_line: str, log_level: str, category: str) -> str:
        """Generate the replacement logging code."""
        # Extract the print statement content
        print_match = re.search(r'print\((.*)\)', full_line)
        if not print_match:
            return full_line
        
        print_content = print_match.group(1)
        
        # Determine logger name based on context
        logger_name = self._get_logger_name(category)
        
        # Handle f-strings and format strings
        if 'f"' in print_content or "f'" in print_content:
            # F-string detected
            replacement = f"{logger_name}.{log_level}({print_content})"
        elif '.format(' in print_content or '%' in print_content:
            # Format string detected
            replacement = f"{logger_name}.{log_level}({print_content})"
        else:
            # Simple string
            replacement = f"{logger_name}.{log_level}({print_content})"
        
        # Replace the print statement in the full line
        return full_line.replace(f'print({print_content})', replacement)
    
    def _get_logger_name(self, category: str) -> str:
        """Get appropriate logger name based on category."""
        logger_map = {
            'error': 'logger',
            'warning': 'logger', 
            'debug': 'logger',
            'progress': 'logger',
            'success': 'logger',
            'audit': 'audit_logger',
            'security': 'security_logger',
            'performance': 'logger',
            'general': 'logger'
        }
        return logger_map.get(category, 'logger')


class PrintMigrator:
    """Migrates print statements to structured logging."""
    
    def __init__(self, dry_run: bool = True):
        self.dry_run = dry_run
        self.stats = {
            'files_processed': 0,
            'prints_migrated': 0,
            'errors': 0
        }
    
    def migrate_file(self, file_path: Path) -> bool:
        """Migrate print statements in a single file."""
        try:
            # Read source code
            with open(file_path, 'r', encoding='utf-8') as f:
                source_code = f.read()
            
            # Skip if no print statements
            if 'print(' not in source_code:
                return True
                
            print(f"\n📁 Processing: {file_path}")
            
            # Parse and analyze
            try:
                tree = ast.parse(source_code)
            except SyntaxError as e:
                print(f"  ⚠️  Syntax error, skipping: {e}")
                return False
                
            analyzer = PrintStatementAnalyzer(source_code)
            analyzer.visit(tree)
            
            if not analyzer.print_statements:
                print("  ℹ️  No print statements found")
                return True
            
            # Show analysis
            print(f"  🔍 Found {len(analyzer.print_statements)} print statements:")
            
            # Group by category
            by_category = {}
            for stmt in analyzer.print_statements:
                category = stmt['category']
                if category not in by_category:
                    by_category[category] = []
                by_category[category].append(stmt)
            
            for category, statements in by_category.items():
                print(f"    - {category}: {len(statements)} statements")
            
            # Generate migrated code
            migrated_code = self._apply_migrations(source_code, analyzer.print_statements)
            
            # Add logger import if needed
            migrated_code = self._add_logger_imports(migrated_code, analyzer.print_statements)
            
            if not self.dry_run:
                # Write migrated code
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(migrated_code)
                print(f"  ✅ Migrated {len(analyzer.print_statements)} print statements")
            else:
                print(f"  📋 Would migrate {len(analyzer.print_statements)} print statements")
            
            self.stats['prints_migrated'] += len(analyzer.print_statements)
            return True
            
        except Exception as e:
            print(f"  ❌ Error processing {file_path}: {e}")
            self.stats['errors'] += 1
            return False
        finally:
            self.stats['files_processed'] += 1
    
    def _apply_migrations(self, source_code: str, print_statements: List[Dict]) -> str:
        """Apply migrations to source code."""
        lines = source_code.splitlines()
        
        # Sort by line number in reverse order to avoid offset issues
        sorted_statements = sorted(print_statements, key=lambda x: x['line_number'], reverse=True)
        
        for stmt in sorted_statements:
            line_idx = stmt['line_number'] - 1
            if 0 <= line_idx < len(lines):
                # Replace the line
                original_line = lines[line_idx]
                new_line = stmt['replacement']
                
                # Preserve indentation
                indent = len(original_line) - len(original_line.lstrip())
                if indent > 0:
                    new_line = ' ' * indent + new_line.lstrip()
                
                lines[line_idx] = new_line
        
        return '\n'.join(lines)
    
    def _add_logger_imports(self, source_code: str, print_statements: List[Dict]) -> str:
        """Add logger imports to the file."""
        # Check if logging import already exists
        if 'from config.logging_config import' in source_code or 'import logging' in source_code:
            return source_code
        
        # Determine what loggers are needed
        needed_loggers = set()
        for stmt in print_statements:
            logger_name = stmt['replacement'].split('.')[0]
            needed_loggers.add(logger_name)
        
        # Create import statement
        if 'audit_logger' in needed_loggers or 'security_logger' in needed_loggers:
            import_line = "from config.logging_config import get_logger, audit_logger, security_logger\n"
        else:
            import_line = "from config.logging_config import get_logger\n"
        
        # Add logger initialization
        logger_init = "\n# Initialize logger\nlogger = get_logger(__name__)\n"
        
        # Find insertion point (after existing imports)
        lines = source_code.splitlines()
        insert_idx = 0
        
        # Find last import line
        for i, line in enumerate(lines):
            if line.strip().startswith(('import ', 'from ')) and not line.strip().startswith('#'):
                insert_idx = i + 1
        
        # Insert import and logger initialization
        lines.insert(insert_idx, import_line.rstrip())
        lines.insert(insert_idx + 1, logger_init.rstrip())
        
        return '\n'.join(lines)
    
    def migrate_directory(self, directory: Path, exclude_patterns: List[str] = None) -> None:
        """Migrate all Python files in a directory."""
        if exclude_patterns is None:
            exclude_patterns = ['venv/', 'test_', '__pycache__/', '.git/']
        
        python_files = []
        for pattern in ['*.py']:
            for file_path in directory.rglob(pattern):
                # Skip excluded patterns
                if any(exclude in str(file_path) for exclude in exclude_patterns):
                    continue
                python_files.append(file_path)
        
        print(f"🔄 Found {len(python_files)} Python files to process")
        
        success_count = 0
        for file_path in sorted(python_files):
            if self.migrate_file(file_path):
                success_count += 1
        
        print(f"\n📊 Migration Summary:")
        print(f"  Files processed: {self.stats['files_processed']}")
        print(f"  Successful: {success_count}")
        print(f"  Errors: {self.stats['errors']}")
        print(f"  Print statements migrated: {self.stats['prints_migrated']}")


def main():
    """Main migration function."""
    if len(sys.argv) < 2:
        print("Usage: python migrate_to_logging.py <directory> [--execute]")
        print("  --execute: Actually perform the migration (default is dry-run)")
        sys.exit(1)
    
    directory = Path(sys.argv[1])
    dry_run = '--execute' not in sys.argv
    
    if not directory.exists():
        print(f"Error: Directory {directory} does not exist")
        sys.exit(1)
    
    print(f"🚀 Starting print statement migration")
    print(f"📁 Target directory: {directory}")
    print(f"🔄 Mode: {'DRY RUN' if dry_run else 'EXECUTE'}")
    
    if dry_run:
        print("ℹ️  This is a dry run. Use --execute to apply changes.")
    
    migrator = PrintMigrator(dry_run=dry_run)
    migrator.migrate_directory(directory)
    
    print(f"\n✅ Migration {'simulation' if dry_run else ''} complete!")


if __name__ == '__main__':
    main()