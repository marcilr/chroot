# -*- Mode: Makefile -*-
#
# Created Tue Feb 23 16:29:04 AKST 2010
# by Raymond E. Marcil <marcilr@gmail.com>
# Copyright (C) 2010 Raymond E. Marcil
# 
# Permission is granted to copy, distribute and/or modify this document
# under the terms of the GNU Free Documentation License, Version 1.3
# or any later version published by the Free Software Foundation;
# with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
# A copy of the license is included in the section entitled "GNU
# Free Documentation License".
#
# Makefile for a single-file LaTeX document plus optional BibTeX file.
#
# Comment out the BibTeX run in the `dvi' target if you don't have a
# bibliography.
#
# NOTE: Cygwin's xdvi puts a read lock on the *.dvi file
#       and breaks the build. Haven't found a way around this
#       yet. Setting chmod 666 before/after does not help.
#
# Links
# =====
# Makefile Conventions
# http://www.chemie.fu-berlin.de/chemnet/use/info/make/make_14.html
#

BIBTEX = bibtex
CAT    = cat
CP     = cp
CUT    = cut
DVIPS  = dvips
FIND   = find
GREP   = grep
LATEX  = latex
MKDIR  = mkdir
PS2PDF = ps2pdf
RM     = rm -f
SED    = sed
TAR    = tar
TR     = tr


# Set VERSION file to use.
VERSIONFILE = "VERSION"

#
# Extract major,minor, and debug numbers from VERSION file.
# 1. Look at VERSION file with cat.
# 2. Extract "major =" line with grep.
# 3. Get 2nd field with major using cut.
# 4. Strip spaces with tr.
#
MAJOR = `${CAT} ${VERSIONFILE} | ${GREP} major | ${CUT} -d = -f 2 | ${TR} -d " "`
MINOR = `${CAT} ${VERSIONFILE} | ${GREP} minor | ${CUT} -d = -f 2 | ${TR} -d " "`
PATCH = `${CAT} ${VERSIONFILE} | ${GREP} patch | ${CUT} -d = -f 2 | ${TR} -d " "`

# Build VERSION number from MAJOR, MINOR, and PATCH
# The use of shell resolves the cat, grep, cut, and tr commands
# before executing targets.
VERSION = $(shell echo ${MAJOR}.${MINOR}.${PATCH})

# Determine LaTeX document basename dynamically.  Rather than hardcoding.
BASENAME = $(shell ls *.tex.in | ${SED} 's/.tex.in//g')
#BASENAME = $(shell ls *.tex | ${SED} 's/.tex//g')

# Base source distribution filename.
DIST = ${BASENAME}-${VERSION}

# Distribution tarball
BZ2 = ${DIST}.tar.bz2

# Build subsequent filenames.

TEX = ${BASENAME}.tex
SRC = ${TEX}.in
BIB = ${BASENAME}.bib
BLG = ${BASENAME}.blg
BBL = ${BASENAME}.bbl
LOG = ${BASENAME}.log
AUX = ${BASENAME}.aux
TOC = ${BASENAME}.toc
DVI = ${BASENAME}.dvi
PS  = ${BASENAME}.ps
PDF = ${BASENAME}.pdf
LOF = ${BASENAME}.lof
LOT = ${BASENAME}.lot
OUT = ${BASENAME}.out


# Define phony. i.e. non-file targets.
.PHONY: all clean mostlyclean cycle dist

# Run clean, ${DVI}, ${PS}, and ${PDF} targets.
all: cycle

# Substitude version number to input file to generate tex source file.
# NOTE: Embed sed command in double quotes such that environment 
#       variable substitution will work. 
${TEX}:
	${CAT} ${SRC} | ${SED} "s/@VERSION@/${VERSION}/g" > ${TEX}

${DVI}:  ${TEX}
	@echo "Building ${DVI}"
	${LATEX} ${TEX}

# Uncomment this entry if there are \citation entries.
#	${BIBTEX} ${BASENAME}

# Rerun LaTeX again to get the xrefs right.
	${LATEX} ${TEX}
	${LATEX} ${TEX}

${PS}: $(DVI)
# Embed hyperlinks for hyperref package (-z)
# Embed type 1 fonts, optimize for pdf (-Ppdf)
	${DVIPS} -z -f -Ppdf < ${DVI} > ${PS}
# Embed type 1 fonts.
#	${DVIPS} -f -Pcmz < ${DVI} > ${PS}
# Embed type 3 (bitmapped) fonts.
#	${DVIPS} ${DVI} -o

${PDF}: ${PS}
	${PS2PDF} ${PS}

#
# Build source distribution.
# cp doesn't have an exclude option.  Didn't want to use rsync.
# Better way to copy and exclude? Perhaps use of 'grep -v'? 
# o "**" escapes "*" for make.
# o "2> /dev/null" suppresses error for make.
#
dist: ${PDF} mostlyclean 
	${TAR} --exclude=".svn" -cvjpf ${BZ2} *

clean:
	${RM} ${LOG} ${LOF} ${AUX} ${TOC} ${TEX} ${DVI} ${PS} ${PDF}
	${RM} ${BBL} ${BLG} ${PDF} ${LOT} ${OUT} ${BZ2} *.tmp
	${RM} -rf ${DIST}

#
# Like `clean', but may refrain from deleting a few files that people normally 
# don't want to recompile.  In this case the PDF file.
#
mostlyclean:
	${RM} ${LOG} ${LOF} ${AUX} ${TOC} ${TEX} ${DVI} ${PS}
	${RM} ${BBL} ${BLG} ${LOT} ${OUT} ${BZ2} *.tmp
	${RM} -rf ${DIST}

cycle: clean ${PDF}
