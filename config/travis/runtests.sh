#!/bin/bash
#
# Script to run tests on Travis-CI.
#
# This file is generated by l2tdevtools update-dependencies.py, any dependency
# related changes should be made in dependencies.ini.

# Exit on error.
set -e;

if test "${TARGET}" = "jenkins";
then
	./config/jenkins/linux/run_end_to_end_tests.sh "travis";

elif test "${TARGET}" = "pylint";
then
	pylint --version

	for FILE in `find setup.py artifacts config tests tools -name \*.py`;
	do
		echo "Checking: ${FILE}";

		pylint --rcfile=.pylintrc ${FILE};
	done

elif test "${TRAVIS_OS_NAME}" = "osx";
then
	PYTHONPATH=/Library/Python/2.7/site-packages/ /usr/bin/python ./run_tests.py;

	python ./setup.py build

	python ./setup.py sdist

	python ./setup.py bdist

	if test -f tests/end-to-end.py;
	then
		PYTHONPATH=. python ./tests/end-to-end.py --debug -c config/end-to-end.ini;
	fi

elif test "${TRAVIS_OS_NAME}" = "linux";
then
	if test -n "${TOXENV}";
	then
		tox --sitepackages ${TOXENV};

	elif test "${TRAVIS_PYTHON_VERSION}" = "2.7";
	then
		coverage erase
		coverage run --source=artifacts --omit="*_test*,*__init__*,*test_lib*" ./run_tests.py
	else
		python ./run_tests.py
	fi

	python ./setup.py build

	python ./setup.py sdist

	python ./setup.py bdist

	TMPDIR="${PWD}/tmp";
	TMPSITEPACKAGES="${TMPDIR}/lib/python${TRAVIS_PYTHON_VERSION}/site-packages";

	mkdir -p ${TMPSITEPACKAGES};

	PYTHONPATH=${TMPSITEPACKAGES} python ./setup.py install --prefix=${TMPDIR};

	if test -f tests/end-to-end.py;
	then
		PYTHONPATH=. python ./tests/end-to-end.py --debug -c config/end-to-end.ini;
	fi
fi
