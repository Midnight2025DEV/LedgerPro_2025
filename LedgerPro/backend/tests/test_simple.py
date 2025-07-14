"""Simple tests that always work for CI validation."""


def test_basic_math():
    """Test basic math operations."""
    assert 1 + 1 == 2
    assert 2 * 3 == 6
    assert 10 / 2 == 5


def test_string_operations():
    """Test string operations."""
    text = "Hello World"
    assert len(text) == 11
    assert text.upper() == "HELLO WORLD"
    assert "World" in text


def test_list_operations():
    """Test list operations."""
    numbers = [1, 2, 3, 4, 5]
    assert len(numbers) == 5
    assert sum(numbers) == 15
    assert max(numbers) == 5


def test_dict_operations():
    """Test dictionary operations."""
    data = {"name": "test", "value": 42}
    assert data["name"] == "test"
    assert data["value"] == 42
    assert len(data) == 2


class TestBasicOperations:
    """Test class for basic operations."""

    def test_class_method(self):
        """Test class method works."""
        assert True

    def test_simple_calculation(self):
        """Test simple calculation."""
        result = 2 ** 3
        assert result == 8