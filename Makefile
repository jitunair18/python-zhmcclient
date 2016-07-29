# ------------------------------------------------------------------------------
# Makefile for zhmcclient project
#
# Basic prerequisites for running this Makefile, to be provided manually:
#   One of these OS platforms:
#     Windows with CygWin
#     Linux (any)
#     OS-X
#   All of these commands:
#     make (GNU make)
#     bash, sh
#     rm, find, xargs, grep, sed, tar
#     python (This Makefile uses the active Python environment, virtual Python
#        environments are supported)
#     pip (in the active Python environment)
#
# Additional prerequisites for running this Makefile are installed by running:
#   make develop
# ------------------------------------------------------------------------------

# Determine OS platform make runs on
ifeq ($(OS),Windows_NT)
  PLATFORM := Windows
else
  # Values: Linux, Darwin
  PLATFORM := $(shell uname -s)
endif

# Name of this Python package (top-level Python namespace + Pypi package name)
package_name := zhmcclient

# Package version (full version, including any pre-release suffixes, e.g. "0.1.0-alpha1")
package_version := $(shell python -c "import sys, $(package_name); sys.stdout.write($(package_name).__version__)")

# Python major version
python_major_version := $(shell python -c "import sys; sys.stdout.write('%s'%sys.version_info[0])")

# Python major+minor version for use in file names
python_version_fn := $(shell python -c "import sys; sys.stdout.write('%s%s'%(sys.version_info[0],sys.version_info[1]))")

# Directory for the generated distribution files
dist_dir := dist

# Distribution archives (as built by setup.py)
bdist_file := $(dist_dir)/$(package_name)-$(package_version)-py2.py3-none-any.whl
sdist_file := $(dist_dir)/$(package_name)-$(package_version).tar.gz

# Windows installable (as built by setup.py)
win64_dist_file := $(dist_dir)/$(package_name)-$(package_version).win-amd64.exe

dist_files := $(bdist_file) $(sdist_file) $(win64_dist_file)

# Directory for generated API documentation
doc_build_dir := build_doc

# Directory where Sphinx conf.py is located
doc_conf_dir := docs

# Paper format for the Sphinx LaTex/PDF builder.
# Valid values: a4, letter
doc_paper_format := a4

# Documentation generator command
doc_cmd := sphinx-build
doc_opts := -v -d $(doc_build_dir)/doctrees -c $(doc_conf_dir) -D latex_paper_size=$(doc_paper_format) .

# Dependents for Sphinx documentation build
doc_dependent_files := \
    $(doc_conf_dir)/conf.py \
    $(wildcard $(doc_conf_dir)/*.rst) \
    $(wildcard $(doc_conf_dir)/notebooks/*.ipynb) \
    $(wildcard $(package_name)/*.py) \

# Flake8 config file
flake8_rc_file := setup.cfg

# PyLint config file
pylint_rc_file := .pylintrc

# Source files for check (with PyLint and Flake8)
check_py_files := \
    setup.py \
    $(wildcard $(package_name)/*.py) \
    $(wildcard tests/test*.py) \

# Test log
test_log_file := test_$(python_version_fn).log

ifdef TESTCASES
pytest_opts := -k $(TESTCASES)
else
pytest_opts :=
endif

# Files to be put into distribution archive.
# Keep in sync with dist_dependent_files.
# This is used for 'include' statements in MANIFEST.in. The wildcards are used
# as specified, without being expanded.
dist_manifest_in_files := \
    README.rst \
    *.py \
    $(package_name)/*.py \

# Files that are dependents of the distribution archive.
# Keep in sync with dist_manifest_in_files.
dist_dependent_files := \
    README.rst \
    $(wildcard *.py) \
    $(wildcard $(package_name)/*.py) \

# No built-in rules needed:
.SUFFIXES:

.PHONY: help
help:
	@echo 'Makefile for $(package_name) project'
	@echo 'Package version will be: $(package_version)'
	@echo 'Uses the currently active Python environment: Python $(python_version_fn)'
	@echo 'Valid targets are (they do just what is stated, i.e. no automatic prereq targets):'
	@echo '  develop    - Prepare the development environment by installing prerequisites'
	@echo '  build      - Build the distribution files in: $(dist_dir) (requires Linux or OSX)'
	@echo '  buildwin   - Build the Windows installable in: $(dist_dir) (requires Windows 64-bit)'
	@echo '  builddoc   - Build documentation in: $(doc_build_dir)'
	@echo '  check      - Run PyLint and Flake8 on sources and save results in: pylint.log and flake8.log'
	@echo '  test       - Run unit tests (and test coverage) and save results in: $(test_log_file)'
	@echo '               Env.var TESTCASES can be used to specify a py.test expression for its -k option'
	@echo '  all        - Do all of the above (except buildwin when not on Windows)'
	@echo '  install    - Install package in active Python environment'
	@echo '  upload     - build + upload the distribution files to PyPI'
	@echo '  clean      - Remove any temporary files'
	@echo '  clobber    - clean + remove any build products'

.PHONY: develop
develop:
	pip install --upgrade pip
	pip install -r dev-requirements.txt
	@echo '$@ done.'

.PHONY: build
build: $(bdist_file) $(sdist_file)
	@echo '$@ done.'

.PHONY: buildwin
buildwin: $(win64_dist_file)
	@echo '$@ done.'

.PHONY: builddoc
builddoc: html
	@echo '$@ done.'

.PHONY: html
html: $(doc_build_dir)/html/docs/index.html
	@echo '$@ done.'

$(doc_build_dir)/html/docs/index.html: Makefile $(doc_dependent_files)
	rm -f $@
	PYTHONPATH=. $(doc_cmd) -b html $(doc_opts) $(doc_build_dir)/html
	@echo "Done: Created the HTML pages with top level file: $@"

.PHONY: pdf
pdf: Makefile $(doc_dependent_files)
	rm -f $@
	$(doc_cmd) -b latex $(doc_opts) $(doc_build_dir)/pdf
	@echo "Running LaTeX files through pdflatex..."
	$(MAKE) -C $(doc_build_dir)/pdf all-pdf
	@echo "Done: Created the PDF files in: $(doc_build_dir)/pdf/"
	@echo '$@ done.'

.PHONY: man
man: Makefile $(doc_dependent_files)
	rm -f $@
	$(doc_cmd) -b man $(doc_opts) $(doc_build_dir)/man
	@echo "Done: Created the manual pages in: $(doc_build_dir)/man/"
	@echo '$@ done.'

.PHONY: docchanges
docchanges:
	$(doc_cmd) -b changes $(doc_opts) $(doc_build_dir)/changes
	@echo
	@echo "Done: Created the doc changes overview file in: $(doc_build_dir)/changes/"
	@echo '$@ done.'

.PHONY: doclinkcheck
doclinkcheck:
	$(doc_cmd) -b linkcheck $(doc_opts) $(doc_build_dir)/linkcheck
	@echo
	@echo "Done: Look for any errors in the above output or in: $(doc_build_dir)/linkcheck/output.txt"
	@echo '$@ done.'

.PHONY: doccoverage
doccoverage:
	$(doc_cmd) -b coverage $(doc_opts) $(doc_build_dir)/coverage
	@echo "Done: Created the doc coverage results in: $(doc_build_dir)/coverage/python.txt"
	@echo '$@ done.'

.PHONY: check
check: pylint.log flake8.log
	@echo '$@ done.'

.PHONY: install
install:
	python setup.py install
	@echo 'Done: Installed $(package_name) into current Python environment.'
	@echo '$@ done.'

.PHONY: test
test: $(test_log_file)
	@echo '$@ done.'

.PHONY: clobber
clobber: clean
	rm -f pylint.log flake8.log test_*.log
	rm -Rf $(doc_build_dir) htmlcov .tox
	@echo 'Done: Removed everything to get to a fresh state.'
	@echo '$@ done.'

# Also remove any build products that are dependent on the Python version
.PHONY: clean
clean:
	find . -name "*.pyc" -delete
	sh -c "find . -name \"__pycache__\" |xargs -r rm -Rf"
	sh -c "ls -d tmp_* |xargs -r rm -Rf"
	find . -name "*.tmp" -delete
	rm -f MANIFEST .coverage
	rm -Rf build .cache $(package_name).egg-info .eggs
	@echo 'Done: Cleaned out all temporary files.'
	@echo '$@ done.'

.PHONY: all
all: develop check build builddoc test
	@echo '$@ done.'

.PHONY: upload
upload:  $(dist_files)
	echo twine upload $(dist_files)
	@echo 'Done: Uploaded $(package_name) version to PyPI: $(package_version)'
	@echo '$@ done.'

# Note: distutils depends on the right files specified in MANIFEST.in, even when
# they are already specified e.g. in 'package_data' in setup.py.
# We generate the MANIFEST.in file automatically, to have a single point of
# control (this Makefile) for what gets into the distribution archive.
MANIFEST.in: Makefile
	echo '# file GENERATED by Makefile, do NOT edit' >$@
	echo '$(dist_manifest_in_files)' | xargs -r -n 1 echo include >>$@
	@echo 'Done: Created manifest input file: $@'

# Distribution archives.
# Note: Deleting MANIFEST causes distutils (setup.py) to read MANIFEST.in and to
# regenerate MANIFEST. Otherwise, changes in MANIFEST.in will not be used.
$(bdist_file) $(sdist_file): setup.py MANIFEST.in $(dist_dependent_files)
ifneq ($(PLATFORM),Windows)
	rm -rf MANIFEST $(package_name).egg-info .eggs
	python setup.py sdist -d $(dist_dir) bdist_wheel -d $(dist_dir) --universal
	@echo 'Done: Created distribution files: $@'
else
	@echo 'Error: Creating distribution archives requires to run on Linux or OSX'
	@false
endif

$(win64_dist_file): setup.py MANIFEST.in $(dist_dependent_files)
ifeq ($(PLATFORM),Windows)
	rm -rf MANIFEST $(package_name).egg-info .eggs
	python setup.py bdist_wininst -d $(dist_dir) -o -t "$(package_name) v$(package_version)"
	@echo 'Done: Created Windows installable: $@'
else
	@echo 'Error: Creating Windows installable requires to run on Windows'
	@false
endif

# TODO: Once PyLint has no more errors, remove the dash "-"
pylint.log: Makefile $(pylint_rc_file) $(check_py_files)
ifeq ($(python_major_version), 2)
	rm -f $@
	-bash -c "set -o pipefail; PYTHONPATH=. pylint --rcfile=$(pylint_rc_file) --output-format=text $(check_py_files) 2>&1 |tee $@.tmp"
	mv -f $@.tmp $@
	@echo 'Done: Created PyLint log file: $@'
else
	@echo 'Info: PyLint requires Python 2; skipping this step on Python $(python_major_version)'
endif

# TODO: Once Flake8 has no more errors, remove the dash "-"
flake8.log: Makefile $(flake8_rc_file) $(check_py_files)
	rm -f $@
	-bash -c "set -o pipefail; PYTHONPATH=. flake8 $(check_py_files) 2>&1 |tee $@.tmp"
	mv -f $@.tmp $@
	@echo 'Done: Created Flake8 log file: $@'

$(test_log_file): Makefile $(package_name)/*.py tests/*.py .coveragerc
	rm -f $@
	bash -c "set -o pipefail; PYTHONWARNINGS=default PYTHONPATH=. py.test --cov $(package_name) --cov-config .coveragerc --cov-report=html $(pytest_opts) -s 2>&1 |tee $@.tmp"
	mv -f $@.tmp $@
	@echo 'Done: Created test log file: $@'
