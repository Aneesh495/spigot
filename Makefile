.PHONY: all test test-squirrel test-python test-native clean lint help

SQ ?= sq
PYTHON ?= python3
CXX ?= clang++
CXXFLAGS ?= -std=c++20 -O3 -Wall -Wextra -Inative/include -I/opt/homebrew/include
LDFLAGS ?= -L/opt/homebrew/lib -lsquirrel -lsqstdlib

all: test

lint:
	$(PYTHON) scripts/lint_no_em_dashes.py

test: test-squirrel test-python

test-squirrel:
	@echo "=== Running Squirrel Test Suite ==="
	$(SQ) tests/test_runner.nut

test-python:
	@echo "=== Running Python Integration Suite ==="
	$(PYTHON) -m unittest discover -s tests -p "test_*.py"

bin:
	mkdir -p bin

native: bin
	@if [ -f native/src/main.cpp ]; then \
		echo "=== Compiling Spigot Native Runner ==="; \
		$(CXX) $(CXXFLAGS) native/src/*.cpp $(LDFLAGS) -o bin/spigot_native; \
	fi

clean:
	rm -rf bin build *.o *.a *.dylib test_output out.cnut
	find . -type d -name "__pycache__" -exec rm -rf {} +

help:
	@echo "Spigot Build Targets:"
	@echo "  make test          Run all Squirrel and Python test suites"
	@echo "  make test-squirrel Run pure Squirrel test suite"
	@echo "  make test-python   Run Python integration tests"
	@echo "  make native        Compile optional C++ native acceleration binary"
	@echo "  make lint          Run em-dash and code style linters"
	@echo "  make clean         Clean build artifacts and temporary files"
