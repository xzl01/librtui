PROJECT ?= librtui
PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib
MANDIR ?= $(PREFIX)/share/man

.PHONY: all
all: build

#
# Development
#
.PHONY: run
run:
	examples/tui_test

.PHONY: debug
debug:
	DEBUG=true examples/tui_test

#
# Test
#
.PHONY: test
test:

#
# Build
#
.PHONY: build
build: build-doc

SRC-DOC		:=	src
DOCS		:=	SOURCE
.PHONY: build-doc
build-doc: $(DOCS)

$(SRC-DOC):
	mkdir -p $(SRC-DOC)

SOURCE: $(SRC-DOC)
	echo -e "git clone $(shell git remote get-url origin)\ngit checkout $(shell git rev-parse HEAD)" > "$@"

#
# Documentation
#
.PHONY: serve
serve:
	mdbook serve

.PHONY: serve_zh-CN
serve_zh-CN:
	MDBOOK_BOOK__LANGUAGE=zh-CN mdbook serve -d book/zh-CN

.PHONY: translate
translate:
	MDBOOK_OUTPUT='{"xgettext": {"pot-file": "messages.pot"}}' mdbook build -d po
	for i in po/*.po; \
	do \
		msgmerge --update $$i po/messages.pot; \
	done

.PHONY: update-admonish
update-admonish:
	mdbook-admonish install --css-dir theme/css

#
# Clean
#
.PHONY: distclean
distclean: clean

.PHONY: clean
clean: clean-doc clean-deb

.PHONY: clean-doc
clean-doc:
	rm -rf $(DOCS)

.PHONY: clean-deb
clean-deb:
	rm -rf debian/.debhelper debian/${PROJECT}*/ debian/debhelper-build-stamp debian/files debian/*.debhelper.log debian/*.postrm.debhelper debian/*.substvars

#
# Release
#
.PHONY: dch
dch: debian/changelog
	EDITOR=true gbp dch --ignore-branch --multimaint-merge --commit --release --dch-opt=--upstream

.PHONY: deb
deb: debian
	debuild --no-lintian --lintian-hook "lintian --fail-on error,warning --suppress-tags bad-distribution-in-changes-file -- %p_%v_*.changes" --no-sign -b

.PHONY: release
release:
	gh workflow run .github/workflows/new_version.yml --ref $(shell git branch --show-current)
